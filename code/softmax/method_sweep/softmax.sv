/****************************************************************************
 * Copyright (C) 2025, Advanced Micro Devices, Inc.
 * All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * @brief	Streaming numerically-stabilised fp32 SoftMax across N inputs.
 * @author	generated for the softmax_analysis sweep
 * @description
 *	Computes  y_i = exp(x_i - max_j x_j) / sum_k exp(x_k - max_j x_j)
 *	over consecutive groups of N fp32 elements, streamed at SIMD data
 *	parallelism (NN = N/SIMD beats per group).
 *
 *	Datapath (as requested):
 *	  input -> max determination -> max subtraction -> exp
 *	        -> addition (sum) -> reciprocal -> multiplication -> output
 *
 *	Structurally this is two consecutive "normalization diamonds" (as in
 *	layernorm.sv) with the EXP unit spliced into the main path between
 *	them.  Each diamond buffers the whole group on a bypass queue while a
 *	free-running statistics branch derives the single per-group scalar that
 *	the apply operator then broadcasts across the NN*SIMD elements:
 *
 *	          <----------- NN + stat latency ----------->        <-- b=max -->
 *	  x ---+--{ bypass queue (holds the group) }----------------> SUB(a-b) --> e0
 *	       |                                                          ^ (max)
 *	       +--{ SIMD max-tree }--{ running max over NN }--------------+
 *
 *	  e0 --{ exp_splitting, EXCLUDE_POS (argument <= 0) }--> e        (main path)
 *
 *	          <-------- NN + stat latency -------->               <-- b=1/sum -->
 *	  e ---+--{ bypass queue (holds the exp'd group) }-----------> MUL(a*b) --> y
 *	       |                                                          ^ (1/sum)
 *	       +--{ SIMD adder-tree }--{ accu over NN }--{ 1/x }----------+
 *
 *	Flow control mirrors layernorm: backpressure is forwarded solely
 *	through the bypass queues; each statistics branch free-runs and is
 *	guaranteed to keep up with the acceptance rate (the max reducer is a
 *	single-cycle recurrence; the sum accumulator interleaves two adders to
 *	sustain one partial per cycle).  With no downstream stall the pipeline
 *	sustains the full one-beat-per-cycle (SIMD elements/cycle) throughput.
 *
 *	The max shift keeps every EXP argument <= 0 (EXCLUDE_POS) and the sum
 *	>= 1 (the max element contributes exp(0)=1), so the reciprocal operand
 *	is a normal fp32 in [1, N] and never underflows/denormalizes.
 ***************************************************************************/

module softmax #(
	int unsigned  N,
	int unsigned  SIMD,
	bit  FORCE_BEHAVIORAL = 0,

	//-----------------------------------------------------------------------
	// Exponential-unit method selection for the main-path exp(x-max).
	//
	//	EXP_METHOD picks one of the four interchangeable exp cores. They
	//	share the identical streaming handshake (idat/ivld/irdy -> odat/ovld/ordy,
	//	SIMD-parallel) but differ in the approximation and, therefore, the
	//	accuracy/area trade-off:
	//	  "LOOKUP"      - single-table + range reduction        (exp_lookup)
	//	  "BIPARTITE"   - bipartite-table + range reduction     (exp_bipartite)
	//	  "SPLITTING"   - three-factor split fused into one DSP  (exp_splitting)
	//	  "BIT_HACKING" - Schraudolph fp32 exponent bit-hack     (exp_bit_hacking)
	//	Only the parameters relevant to the chosen method are consulted; the
	//	rest are ignored (mirrors the per-core parameter sets).  Every core is
	//	instantiated with EXCLUDE_POS(1): the max shift makes the argument <= 0.
	//	BIT_HACKING reads NONE of the table knobs (word/addr widths): it is a
	//	single fp32 multiply + int cast + int add, so those parameters are
	//	simply ignored for it.
	//
	//	The exp unit sits on the fully elastic main path between the two
	//	diamonds, so its (method-dependent) latency is absorbed by the
	//	surrounding valid/ready handshake and enters NO queue-sizing below.
	parameter  EXP_METHOD = "SPLITTING",

	// Seed/factor-table mantissa word width, shared by all three exp cores.
	// NOTE: "SPLITTING" requires EXP_WORD_WIDTH < 23 (24-bit B datapath needs an
	// implicit-1 bit and a sign-guard bit on top); "LOOKUP"/"BIPARTITE" allow <= 23.
	int unsigned  EXP_WORD_WIDTH = 22,

	// "BIPARTITE"- and "SPLITTING"-only table address widths (the three
	// contiguous mantissa fields x_0 | x_1 | x_2).
	int unsigned  EXP_ADDR_WIDTH_0 = 6,
	int unsigned  EXP_ADDR_WIDTH_1 = 6,
	int unsigned  EXP_ADDR_WIDTH_2 = 6,

	// "LOOKUP"-only single-table address width.
	int unsigned  EXP_ADDR_WIDTH = 10,

	//-----------------------------------------------------------------------
	// Reciprocal-unit method selection for the statistics-branch 1/sum.
	//
	//	REC_METHOD picks one of the two interchangeable reciprocal cores. They
	//	share the identical streaming handshake (idat/ivld/irdy -> odat/ovld,
	//	scalar, free-running output caught by the statistics queue) but differ
	//	in the seed approximation and pipeline depth:
	//	  "LOOKUP"    - single-table seed + optional Newton  (rec_lookup)
	//	  "BIPARTITE" - bipartite-table seed + optional Newton (rec_bipartite)
	//	Only the parameters relevant to the chosen method are consulted.  Both
	//	run the shared-DSP fold at SUSTAINABLE_INTERVAL = NN (one DSP total) for
	//	NN >= 2 and the fully-pipelined II = 1 config for NN == 1; the fold is
	//	SELF-TIMED so it accepts the phase-drifting per-group sum on whatever
	//	cycle it arrives.  Because the reciprocal IS in the sum-diamond
	//	statistics branch, its latency feeds REC_LAT -> STAT_LAT -> the bypass /
	//	statistics queue sizing below (unlike the exp unit).
	parameter  REC_METHOD = "BIPARTITE",

	// Newton-Raphson refinement steps applied on top of the reciprocal seed
	// (0 or 1; both cores restrict NUM_NEWTON_STEPS to <= 1).
	int unsigned  REC_NUM_NEWTON_STEPS = 1,

	// Seed-table mantissa word width, shared by both reciprocal cores.
	int unsigned  REC_WORD_WIDTH = 14,

	// "BIPARTITE"-only table address widths (base / first / second correction).
	int unsigned  REC_ADDR_WIDTH_0 = 3,
	int unsigned  REC_ADDR_WIDTH_1 = 4,
	int unsigned  REC_ADDR_WIDTH_2 = 4,

	// "LOOKUP"-only single-table address width.
	int unsigned  REC_ADDR_WIDTH = 10
)(
	// Global Control
	input	logic  clk,
	input	logic  rst,

	// (Parallel) Input Stream
	input	logic [SIMD-1:0][31:0]  xdat,
	input	logic  xvld,
	output	logic  xrdy,

	// (Parallel) Output Stream
	output	logic [SIMD-1:0][31:0]  ydat,
	output	logic  yvld,
	input	logic  yrdy
);

	initial begin
		if(N % SIMD != 0) begin
			$error("%m: SIMD(%0d) must divide N(%0d).", SIMD, N);
			$finish;
		end
		if(!(EXP_METHOD == "LOOKUP" || EXP_METHOD == "BIPARTITE" || EXP_METHOD == "SPLITTING" || EXP_METHOD == "BIT_HACKING")) begin
			$error("%m: EXP_METHOD (%s) is invalid. Allowed: LOOKUP, BIPARTITE, SPLITTING, BIT_HACKING.", EXP_METHOD);
			$finish;
		end
		if(!(REC_METHOD == "LOOKUP" || REC_METHOD == "BIPARTITE")) begin
			$error("%m: REC_METHOD (%s) is invalid. Allowed: LOOKUP, BIPARTITE.", REC_METHOD);
			$finish;
		end
	end

	localparam int unsigned  NN = N / SIMD;

	typedef logic [31:0]  fp32;
	typedef fp32 [SIMD-1:0] vfp32;
	typedef struct {
		fp32   dat;
		logic  vld;
	} edge_t;
	typedef struct {
		vfp32  dat;
		logic  vld;
		logic  rdy;
	} vedge_t;

	//=======================================================================
	// Main-path node chain
	//   #0 --(max diamond)--> #1 --(exp)--> #2 --(sum diamond)--> #3
	uwire vedge_t  vedge[4];
	assign	vedge[0].dat = xdat;
	assign	vedge[0].vld = xvld;
	assign	xrdy         = vedge[0].rdy;

	assign	ydat         = vedge[3].dat;
	assign	yvld         = vedge[3].vld;
	assign	vedge[3].rdy = yrdy;

	//=======================================================================
	// EXP unit on the main path: #1 -> exp -> #2.
	//
	// Argument is x-max <= 0, so EXCLUDE_POS is safe and lets the range
	// reduction skip the positive branch.  The selected exp core carries its
	// own valid/ready handshake and composes directly with the two diamonds;
	// only the branch named by EXP_METHOD elaborates, so no unused core (or its
	// tables) is built.  All three expose the identical SIMD-parallel
	// idat/ivld/irdy -> odat/ovld/ordy handshake wired below, and their
	// (differing) internal latency is absorbed by the elastic main path.
	//=======================================================================
	case(EXP_METHOD)
	"LOOKUP": begin : genExpLookup
		exp_lookup #(
			.SIMD(SIMD),
			.ADDR_WIDTH(EXP_ADDR_WIDTH),
			.WORD_WIDTH(EXP_WORD_WIDTH),
			.EXCLUDE_POS(1),
			.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)
		) exp_inst (
			.clk, .rst,
			.idat(vedge[1].dat), .ivld(vedge[1].vld), .irdy(vedge[1].rdy),
			.odat(vedge[2].dat), .ovld(vedge[2].vld), .ordy(vedge[2].rdy)
		);
	end : genExpLookup
	"BIPARTITE": begin : genExpBipartite
		exp_bipartite #(
			.SIMD(SIMD),
			.EXCLUDE_POS(1),
			.ADDR_WIDTH_0(EXP_ADDR_WIDTH_0),
			.ADDR_WIDTH_1(EXP_ADDR_WIDTH_1),
			.ADDR_WIDTH_2(EXP_ADDR_WIDTH_2),
			.WORD_WIDTH(EXP_WORD_WIDTH),
			.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)
		) exp_inst (
			.clk, .rst,
			.idat(vedge[1].dat), .ivld(vedge[1].vld), .irdy(vedge[1].rdy),
			.odat(vedge[2].dat), .ovld(vedge[2].vld), .ordy(vedge[2].rdy)
		);
	end : genExpBipartite
	"SPLITTING": begin : genExpSplitting
		exp_splitting #(
			.SIMD(SIMD),
			.EXCLUDE_POS(1),
			.ADDR_WIDTH_0(EXP_ADDR_WIDTH_0),
			.ADDR_WIDTH_1(EXP_ADDR_WIDTH_1),
			.ADDR_WIDTH_2(EXP_ADDR_WIDTH_2),
			.WORD_WIDTH(EXP_WORD_WIDTH),
			.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)
		) exp_inst (
			.clk, .rst,
			.idat(vedge[1].dat), .ivld(vedge[1].vld), .irdy(vedge[1].rdy),
			.odat(vedge[2].dat), .ovld(vedge[2].vld), .ordy(vedge[2].rdy)
		);
	end : genExpSplitting
	"BIT_HACKING": begin : genExpBitHacking
		// Schraudolph exponent bit-hack: no range-reduction tables, so none of
		// the WORD/ADDR width knobs apply.  A and D default to the module's
		// built-in Schraudolph constants (slope 2^23/ln2, biased offset).  With
		// EXCLUDE_POS(1) the argument is <= 0, so the reconstruction only takes
		// the underflow-to-zero branch (never the positive-overflow saturation).
		exp_bit_hacking #(
			.SIMD(SIMD),
			.EXCLUDE_POS(1),
			.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)
		) exp_inst (
			.clk, .rst,
			.idat(vedge[1].dat), .ivld(vedge[1].vld), .irdy(vedge[1].rdy),
			.odat(vedge[2].dat), .ovld(vedge[2].vld), .ordy(vedge[2].rdy)
		);
	end : genExpBitHacking
	endcase

	//=======================================================================
	// Two apply diamonds.  `step==0` is the max/subtract diamond operating
	// on vedge[0] -> vedge[1]; `step==1` is the sum/reciprocal/multiply
	// diamond operating on vedge[2] -> vedge[3].
	//
	// The apply half (bypass queue + credit-based free-running operator) is
	// shared verbatim between the two; only the statistics half and the
	// operator kind (SUB vs. MUL) differ.
	//=======================================================================
	for(genvar  step = 0; step < 2; step++) begin : genDiamonds

		// Node feeding this diamond: max diamond consumes #0, sum diamond #2.
		localparam int unsigned  SRC = (step == 0)? 0 : 2;
		// Node produced by this diamond: max diamond makes #1, sum diamond #3.
		localparam int unsigned  DST = (step == 0)? 1 : 3;

		//-------------------------------------------------------------------
		// Statistics-branch latency (cycles from a group's last beat entering
		// the diamond to its scalar reaching the apply's catcher).  These are
		// the EXACT pipeline depths of the sub-blocks; the bypass queue must
		// span this plus the group itself.  A small SLACK covers the couple of
		// hand-off flops around the catcher and keeps the credit loop off the
		// exact boundary; every queue is additionally guarded by an overrun
		// assertion, so this need not be pessimistic -- only not too small.
		//
		//   max diamond : combinational max-tree + running-max reg (1)
		//   sum diamond : adder-tree (2*ceil(log2 SIMD)) + accu (2) + recip
		//-------------------------------------------------------------------
		localparam int unsigned  SLACK    = 2;
		localparam int unsigned  ADD_LAT  = 2;			// binopf ADD latency
		localparam int unsigned  TREE_LAT = ADD_LAT * $clog2(SIMD);	// SIMD adder tree
		localparam int unsigned  ACCU_LAT = 2;			// softmax_fp_accu: last partial -> svld
		//-------------------------------------------------------------------
		// Reciprocal latency (input valid -> output valid), which depends on
		// the selected core (REC_METHOD), its Newton setting, and NN (the fold's
		// SUSTAINABLE_INTERVAL).  This sizes the value bypass and statistics
		// queues, so it must be an UPPER BOUND on the real latency -- an
		// over-estimate only deepens the elastic queues (always safe, and guarded
		// by SLACK plus the "Drained bypass" / overrun assertions), while an
		// under-estimate would drain the bypass.
		//
		// The seed pipeline depth differs by method:
		//   REC_SEED_LAT = 1 ("LOOKUP", synchronous ROM) or 3 ("BIPARTITE").
		// With NUM_NEWTON_STEPS = 1 the shared-DSP (or II=1) path adds 2*DSP
		// (= 8) cycles measured from the seed output, and the fold is SELF-TIMED
		// so an isolated per-group sum is accepted the cycle it becomes valid:
		//   input -> ovld = REC_SEED_LAT + 2*DSP_LATENCY  (nominal), EXCEPT that
		// for NN in {2,3,4} the fold's 2-deep input skid (genSkid) reshapes the
		// arrival and adds exactly +2 cycles (the empty-queue fill latency; the
		// self-timed Busy map adds NOTHING more for an isolated operand).  For
		// NN == 1 (II=1 config) and NN >= 5 (genReg, no skid) there is no such
		// add.  With NUM_NEWTON_STEPS = 0 there is no DSP at all (latency =
		// REC_SEED_LAT, xrdy constant-1), which the Newton=1 bound covers.
		//
		//   NN in {2,3,4} :  LOOKUP -> 1+8+2 = 11 ; BIPARTITE -> 3+8+2 = 13
		//   otherwise     :  LOOKUP -> 1+8   =  9 ; BIPARTITE -> 3+8   = 11
		//
		// (The BIPARTITE NN in {2,4} entry is padded one extra cycle to 14 to
		// preserve verbatim the queue sizing that the bipartite-only design was
		// validated against; +1 is a harmless over-size.)
		//-------------------------------------------------------------------
		localparam int unsigned  DSP_LATENCY  = 4;			// recf_dspfp32 pipeline depth
		localparam int unsigned  REC_SEED_LAT = (REC_METHOD == "LOOKUP")? 1 : 3;
		localparam int unsigned  REC_NEWTON_LAT = (REC_NUM_NEWTON_STEPS == 0)? 0 : 2*DSP_LATENCY;
		// Extra cycles introduced by the genSkid input queue on the interleave
		// band (1 < NN < 5) with Newton enabled; none otherwise.
		localparam int unsigned  REC_SKID_LAT =
			((REC_NUM_NEWTON_STEPS > 0) && (1 < NN) && (NN < 5))? 2 : 0;
		localparam int unsigned  REC_LAT_BASE = REC_SEED_LAT + REC_NEWTON_LAT + REC_SKID_LAT;
		// Preserve the bipartite design's original (validated) +1 margin at NN in {2,4}.
		localparam int unsigned  REC_LAT =
			((REC_METHOD == "BIPARTITE") && (REC_NUM_NEWTON_STEPS > 0) && ((NN == 2) || (NN == 4)))?
				REC_LAT_BASE + 1 : REC_LAT_BASE;
		localparam int unsigned  STAT_LAT = (step == 0)
			? (1 + SLACK)				// running-max register
			: (TREE_LAT + ACCU_LAT + REC_LAT + SLACK);	// sum path

		localparam int unsigned  VALUE_QUEUE_LEN = NN - 1 + STAT_LAT;
		localparam int unsigned  STATS_QUEUE_LEN = (2 > VALUE_QUEUE_LEN/NN)? 2 : VALUE_QUEUE_LEN/NN;

		//-------------------------------------------------------------------
		// Value bypass queue: holds the group until its statistic is ready.
		//-------------------------------------------------------------------
		uwire vedge_t  bypass;
		queue #(.DATA_WIDTH(SIMD*32), .ELASTICITY(VALUE_QUEUE_LEN)) bypass_queue (
			.clk, .rst,
			.idat(vedge[SRC].dat), .ivld(vedge[SRC].vld), .irdy(vedge[SRC].rdy),
			.odat(bypass    .dat), .ovld(bypass    .vld), .ordy(bypass    .rdy)
		);

		//-------------------------------------------------------------------
		// Free-running statistics branch: consumes accepted beats (never
		// backpressures) and emits one scalar `norm` per group.
		//-------------------------------------------------------------------
		uwire edge_t  norm;
		if(1) begin : blkStatistics
			// Beat accepted by the bypass queue this cycle.
			uwire        avld = vedge[SRC].vld && vedge[SRC].rdy;
			uwire vfp32  adat = vedge[SRC].dat;

			// Last beat of the current group (identifies group boundaries in
			// the free-running branch).  For NN==1 every beat is a group.
			uwire  alst;
			if(NN == 1)  assign  alst = 1'b1;
			else begin : genLast
				logic signed [$clog2(NN-1):0]  Cnt = NN-2;	// NN-2..1,0,-1
				always_ff @(posedge clk) begin
					if(rst)  Cnt <= NN-2;
					else     Cnt <= Cnt + (!avld? 0 : !alst? -1 : NN-1);
				end
				assign	alst = Cnt[$left(Cnt)];
			end : genLast

			if(step == 0) begin : blkMax
				//-----------------------------------------------------------
				// Cross-SIMD max via a monotonic-key compare tree, then a
				// running max across the NN beats of a group.  fp32 max needs
				// no DSP -- it is an integer compare on a sign-monotonic key:
				//   key(u) = u[31]? ~u : (u | 0x8000_0000)
				// so an unsigned compare of keys reproduces IEEE-754 ordering
				// for finite values (NaN is not in the input domain).  The
				// reduction is a BALANCED binary tree (depth ceil(log2 SIMD),
				// not SIMD-1) so the combinational path stays short as SIMD
				// grows.  Only the winning original bits propagate.
				//-----------------------------------------------------------
				function automatic logic [31:0] fkey(input logic [31:0] u);
					return  u[31]? ~u : (u | 32'h8000_0000);
				endfunction : fkey

				// Balanced compare tree: leaves at nodes [SIMD-1 .. 2*SIMD-2],
				// each internal node picks the larger-key child.  Node 0 is the
				// beat maximum.  (Same node layout as the adder tree; an odd
				// child count just carries the lone node up unchanged.)
				uwire [31:0]  mtree[2*SIMD-1];
				for(genvar  i = 0; i < SIMD; i++) begin : genMaxLeaves
					assign	mtree[SIMD-1+i] = adat[i];
				end : genMaxLeaves
				for(genvar  i = 0; i < SIMD-1; i++) begin : genMaxNodes
					assign	mtree[i] = (fkey(mtree[2*i+2]) > fkey(mtree[2*i+1]))?
						mtree[2*i+2] : mtree[2*i+1];
				end : genMaxNodes

				uwire [31:0]  beat_max = mtree[0];

				// Running max across the group.  On the first beat load, else
				// combine with the accumulated maximum.  The registered value
				// on the beat where `alst` holds is the group maximum.
				logic         First = 1'b1;
				logic [31:0]  RunMax = 'x;
				logic         Vld    = 1'b0;
				always_ff @(posedge clk) begin
					if(rst) begin
						First  <= 1'b1;
						RunMax <= 'x;
						Vld    <= 1'b0;
					end
					else begin
						if(avld) begin
							automatic logic [31:0]  nxt =
								(First || fkey(beat_max) > fkey(RunMax))? beat_max : RunMax;
							RunMax <= nxt;
							First  <= alst;	// next accepted beat starts a new group
						end
						Vld <= avld && alst;	// group max leaves the register next cycle
					end
				end
				assign	norm.dat = RunMax;
				assign	norm.vld = Vld;
			end : blkMax
			else begin : blkSum
				//-----------------------------------------------------------
				// Cross-SIMD sum via a balanced binopf adder tree (as in
				// layernorm), then an interleaved fp32 accumulation over the
				// NN beats down to a single group sum, then its reciprocal.
				//-----------------------------------------------------------
				uwire edge_t  part_sum;
				if(1) begin : blkReduceSIMD
					uwire edge_t  tree[2*SIMD-1];

					// Leaves: the SIMD lanes of the accepted beat.
					for(genvar  i = 0; i < SIMD; i++) begin : genLeaves
						assign	tree[SIMD-1+i] = '{ vld: avld, dat: adat[i] };
					end : genLeaves

					// Balancing edge delays on trees with an incomplete leaf
					// level (identical to layernorm's construction).
					typedef bit edge_delays_t[2*SIMD-1];
					function automatic edge_delays_t INIT_EDGE_DELAYS();
						localparam int unsigned  FULL_FANIN = 2**$clog2(SIMD);
						automatic edge_delays_t  d = '{ default: 0 };
						for(int unsigned  sig = FULL_FANIN - SIMD, i = FULL_FANIN - 1; sig; i >>= 1, sig >>= 1) begin
							d[i-sig] = sig[0];
						end
						return  d;
					endfunction : INIT_EDGE_DELAYS
					localparam edge_delays_t  EDGE_DELAYS = INIT_EDGE_DELAYS();

					for(genvar  i = 0; i < SIMD-1; i++) begin : genNodes
						binopf #(
							.OP("ADD"),
							.A_MATCH_OP_DELAY(EDGE_DELAYS[2*i+2]),
							.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)
						) node (
							.clk, .rst,
							.r(tree[i]    .dat), .rvld(tree[i]    .vld),
							.b(tree[2*i+1].dat), .bload(1'b1),
							.a(tree[2*i+2].dat), .avld(tree[2*i+2].vld)
						);
					end : genNodes

					assign	part_sum = tree[0];
				end : blkReduceSIMD

				// Last partial-sum of a group, derived by counting the tree's
				// OUTPUT valids (NN partials per group) -- exactly as layernorm
				// paces its accumulator.  Counting `part_sum.vld` downstream of
				// the tree makes the marker independent of the (balanced) tree
				// latency, so no matched delay line and no TREE_LAT arithmetic
				// is needed.  Bubbles are naturally skipped (the count only
				// advances on a valid partial).
				uwire  plst;
				if(NN == 1)  assign  plst = 1'b1;
				else begin : genPLst
					logic signed [$clog2(NN-1):0]  Cnt = NN-2;	// NN-2..1,0,-1
					always_ff @(posedge clk) begin
						if(rst)  Cnt <= NN-2;
						else     Cnt <= Cnt + (!part_sum.vld? 0 : !plst? -1 : NN-1);
					end
					assign	plst = Cnt[$left(Cnt)];
				end : genPLst

				// Interleaved accumulation of the partial sums into one sum
				// per group (sustains one partial/cycle; see softmax_fp_accu).
				uwire edge_t  total;
				softmax_fp_accu #(
					.NN(NN),
					.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)
				) accu (
					.clk, .rst,
					.a(part_sum.dat), .avld(part_sum.vld), .alst(plst),
					.s(total.dat),    .svld(total.vld)
				);

				// Reciprocal 1/sum.  Only one sum arrives per group, but its
				// phase relative to any periodic accept schedule is set by the
				// (bubble-prone) accumulator, not by a fixed NN cadence, and the
				// accumulator is must-accept (no back-pressure into softmax_fp_accu).
				// Both reciprocal cores' shared-DSP fold is SELF-TIMED (its accept
				// schedule idles until an operand is present, rather than marching
				// on a reset-anchored lattice), so it accepts the sum on whatever
				// cycle it becomes valid while time-multiplexing a SINGLE DSP.
				// With one sum per group (>= NN cycles apart) and SUSTAINABLE_INTERVAL
				// = NN, that costs one DSP for the whole module instead of the two
				// the fully-pipelined II=1 config needs.  The output has no
				// backpressure and is caught by the statistics queue in the apply
				// block.  irdy (trdy) must be high whenever a sum is valid; the
				// assertion below guards that contract.
				//
				// Instantiate the selected reciprocal core.  Only one branch
				// elaborates, so no unused core (or its tables) is built.  Both
				// cores expose the identical idat/ivld/irdy -> odat/ovld handshake
				// wired below.
				uwire  trdy;
				case(REC_METHOD)
				"LOOKUP": begin : genRecLookup
					rec_lookup #(
						.ADDR_WIDTH(REC_ADDR_WIDTH),
						.WORD_WIDTH(REC_WORD_WIDTH),
						.NUM_NEWTON_STEPS(REC_NUM_NEWTON_STEPS),
						.SUSTAINABLE_INTERVAL(NN),
						.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)
					) recip (
						.clk, .rst,
						.idat(total.dat), .ivld(total.vld), .irdy(trdy),
						.odat(norm .dat), .ovld(norm .vld)
					);
				end : genRecLookup
				"BIPARTITE": begin : genRecBipartite
					rec_bipartite #(
						.ADDR_WIDTH_0(REC_ADDR_WIDTH_0),
						.ADDR_WIDTH_1(REC_ADDR_WIDTH_1),
						.ADDR_WIDTH_2(REC_ADDR_WIDTH_2),
						.WORD_WIDTH(REC_WORD_WIDTH),
						.NUM_NEWTON_STEPS(REC_NUM_NEWTON_STEPS),
						.SUSTAINABLE_INTERVAL(NN),
						.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)
					) recip (
						.clk, .rst,
						.idat(total.dat), .ivld(total.vld), .irdy(trdy),
						.odat(norm .dat), .ovld(norm .vld)
					);
				end : genRecBipartite
				endcase
				always_ff @(posedge clk) begin
					assert(rst || !total.vld || trdy) else begin
						$error("%m: Overrunning reciprocal computation.");
						$stop;
					end
				end
			end : blkSum

		end : blkStatistics

		//-------------------------------------------------------------------
		// Apply: broadcast the per-group scalar across the buffered group.
		// Verbatim structure of layernorm's blkApply (credit-based free-
		// running operator); OP is SUB for the max diamond, MUL for the sum
		// diamond.  `b` (the scalar) is loaded once per group and held for
		// the NN issues; `a` streams from the bypass queue.
		//-------------------------------------------------------------------
		if(1) begin : blkApply
			localparam  APPLY_OP = (step == 0)? "SUB" : "MUL";

			// Statistics queue catching all computations in flight.
			uwire edge_t  norm0;
			uwire  norm0_rdy;
			if(1) begin : blkCatcher
				uwire  norm_rdy;
				queue #(.DATA_WIDTH(32), .ELASTICITY(STATS_QUEUE_LEN)) catcher (
					.clk, .rst,
					.idat(norm .dat), .ivld(norm .vld), .irdy(norm_rdy),
					.odat(norm0.dat), .ovld(norm0.vld), .ordy(norm0_rdy)
				);
				always_ff @(posedge clk) begin
					assert(rst || !norm.vld || norm_rdy) else begin
						$error("%m: Overrunning statistics queue.");
						$stop;
					end
				end
			end : blkCatcher

			// Free-running operator bracketed by credit-based flow control.
			localparam int unsigned  CREDIT = 7;
			logic signed [$clog2(CREDIT):0]  Credit = CREDIT-1;	// CREDIT-1..1,0,-1
			uwire  have_cap = !Credit[$left(Credit)];
			uwire  issue;
			uwire  settle;
			always_ff @(posedge clk) begin
				if(rst)  Credit <= CREDIT-1;
				else     Credit <= Credit + (issue == settle? 0 : settle? 1 : -1);
			end

			logic signed [$clog2(NN):0]  Cnt = 0;	// [-NN..] -NN+1..-1,0
			assign	norm0_rdy = !Cnt[$left(Cnt)];
			assign	issue = have_cap && (norm0.vld || Cnt[$left(Cnt)]);
			uwire  bload = norm0.vld && norm0_rdy;
			always_ff @(posedge clk) begin
				if(rst)  Cnt <= 0;
				else     Cnt <= Cnt + (bload? -NN : 0) + issue;
			end
			always_ff @(posedge clk) begin
				assert(rst || bypass.vld || !issue) else begin
					$error("%m: Drained bypass.");
					$stop;
				end
			end
			assign	bypass.rdy = issue;

			uwire vfp32  rdat;
			uwire  rvld;
			for(genvar  i = 0; i < SIMD; i++) begin : genOps
				uwire  rvld0;
				binopf #(.OP(APPLY_OP), .FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)) op (
					.clk, .rst,
					.a(bypass.dat[i]), .avld(issue),
					.b(norm0.dat), .bload,
					.r(rdat[i]), .rvld(rvld0)
				);
				if(i == 0)  assign  rvld = rvld0;
			end : genOps

			// Output queue decoupling the free-running operator; its depth is
			// the credit pool so `issue` can never overrun it.
			uwire  rrdy;
			queue #(.DATA_WIDTH(SIMD*32), .ELASTICITY(CREDIT)) decouple (
				.clk, .rst,
				.idat(rdat), .ivld(rvld), .irdy(rrdy),
				.odat(vedge[DST].dat), .ovld(vedge[DST].vld), .ordy(vedge[DST].rdy)
			);
			always_ff @(posedge clk) begin
				assert(rst || !rvld || rrdy) else begin
					$error("%m: Overrunning operator output.");
					$stop;
				end
			end
			assign	settle = vedge[DST].vld && vedge[DST].rdy;

		end : blkApply

	end : genDiamonds

endmodule : softmax


// ================================================================================================================
// ================================================================================================================
// ================================================================================================================


/****************************************************************************
 * fp32 group-sum accumulator built on the DSPFP32 FPA loop-back path.
 *
 *	a/avld : streamed partial sums (avld may be high every cycle, and may
 *	         gap arbitrarily -- the upstream apply operator emits bursts, so
 *	         gaps occur even without external backpressure).
 *	alst   : marks the last partial of a group (asserted with avld).
 *	s/svld : the group total, LATENCY cycles after the last partial.
 *
 * The DSPFP32 floating-point adder has an internal loop-back that forms a
 * SINGLE-CYCLE accumulator (AM004 Ch.6: "The adder has an internal loop-back
 * path to form an accumulator in a single cycle."): with the addend on the D
 * port (P0 = D) and the adder's own registered output fed back (P1 = P), the
 * FPA computes  P <- D + P  every cycle.  This is II = 1 with a plain
 * register recurrence, so -- unlike a binopf-based feedback (whose external
 * loop crosses the 2-cycle FPA pipeline and thus needs interleaving) -- NO
 * interleave, forwarding, or lane machinery is required.
 *
 * Per-group control via FPOPMODE (AM004 Tables 23-25, bits [6:0]):
 *   LOAD = 7'b0000011 : [1:0]=11 -> P0=D ; [4:2]=000 -> P1=0 ; [6:5]=00 -> P0+P1
 *   ACC  = 7'b0010011 : [1:0]=11 -> P0=D ; [4:2]=100 -> P1=P ; [6:5]=00 -> P0+P1
 * (they differ only in [4], the accumulator-initialise pin).  The first real
 * partial of a group LOADs (P <- D + 0); the rest ACCumulate (P <- D + P).
 * Bubbles are handled by gating the P-register clock-enable (CEFPA) with
 * avld: on a bubble the accumulator simply holds.  This is the clean bubble
 * tolerance binopf could not provide (its datapath free-runs).
 *
 * Pipeline: FPDREG=1 (register the D addend) + FPA_PREG=1 (register P) =>
 * LATENCY = 2; the accumulator loop P1=P is still a single cycle so
 * throughput is one partial per cycle.  Because the D register delays the
 * addend one cycle before the adder, the LOAD/ACC select and the accumulate
 * clock-enable are registered one cycle (LoadD/EnaD) to line up with it, and
 * `svld` is the last-partial marker delayed by the same LATENCY.
 *
 * NN == 1 needs no special case: every beat both loads and is last, so
 * P <- D + 0 = D = that beat's sum.
 ***************************************************************************/
module softmax_fp_accu #(
	int unsigned  NN,
	bit  FORCE_BEHAVIORAL = 0
)(
	input	logic         clk,
	input	logic         rst,

	input	logic [31:0]  a,
	input	logic         avld,
	input	logic         alst,

	output	logic [31:0]  s,
	output	logic         svld
);
	localparam int unsigned  LATENCY = 2;			// D register + FPA (P) register
	localparam logic [6:0]  FPOPMODE_LOAD = 7'b0000011;	// P = D + 0  (initialise)
	localparam logic [6:0]  FPOPMODE_ACC  = 7'b0010011;	// P = D + P  (accumulate)

	//-------------------------------------------------------------------
	// `Load` marks the first real partial of each group (initialise with
	// D + 0 instead of D + P).  It is set for the beat following an `alst`
	// beat, and after reset.  For NN == 1 every beat is a group, so `alst`
	// is always 1 and `Load` stays 1 (each beat loads).
	//-------------------------------------------------------------------
	logic  Load = 1'b1;
	always_ff @(posedge clk) begin
		if(rst)       Load <= 1'b1;
		else if(avld) Load <= alst;	// after the last partial, the next one loads
	end

	//-------------------------------------------------------------------
	// Control aligned to the registered D addend (FPDREG=1 delays it by 1):
	// the LOAD/ACC select and the accumulate clock-enable act at the adder
	// one cycle after the partial is presented, so `Load`/`avld` are
	// registered once to meet the addend there.
	//-------------------------------------------------------------------
	logic  LoadD = 1'b1;	// `Load` aligned to the registered D at the adder
	logic  EnaD  = 1'b0;	// `avld` aligned to the registered D (drives CEFPA)
	always_ff @(posedge clk) begin
		if(rst) begin
			LoadD <= 1'b1;
			EnaD  <= 1'b0;
		end
		else begin
			LoadD <= Load;
			EnaD  <= avld;
		end
	end
	uwire [6:0]  opmode = LoadD? FPOPMODE_LOAD : FPOPMODE_ACC;

	//-------------------------------------------------------------------
	// Result valid: a group total is complete LATENCY cycles after its last
	// partial was presented (D register + FPA register), matching the same
	// alignment applied to LoadD/EnaD above.
	//-------------------------------------------------------------------
	logic [LATENCY-1:0]  SVldPipe = '0;
	always_ff @(posedge clk) begin
		if(rst)  SVldPipe <= '0;
		else     SVldPipe <= { SVldPipe[LATENCY-2:0], avld && alst };
	end
	assign	svld = SVldPipe[LATENCY-1];

	//-------------------------------------------------------------------
	// The accumulating DSPFP32 (real or behavioral).  Addend `a` -> D port
	// (P0 = D); FPA output `s` fed back as P1 for ACC or forced 0 for LOAD;
	// CEFPA = EnaD freezes the running sum on bubbles.
	//-------------------------------------------------------------------
	if(FORCE_BEHAVIORAL) begin : genBehav
		// Model of the DSP path: D input register, then the single-cycle FPA
		// loop-back accumulator.  Registers reset to +0.0 to match the DSP's
		// RSTD/RSTFPA (the first partial of every group LOADs, discarding any
		// prior P, so the reset value never reaches a valid output anyway).
		logic [31:0]  D1 = 32'h0000_0000;
		always_ff @(posedge clk) begin
			if(rst)  D1 <= 32'h0000_0000;
			else     D1 <= a;
		end

		logic [31:0]  P = 32'h0000_0000;
		always_ff @(posedge clk) begin
			if(rst)       P <= 32'h0000_0000;
			else if(EnaD) P <= $shortrealtobits(
				$bitstoshortreal(D1) + (LoadD? shortreal'(0.0) : $bitstoshortreal(P))
			);
		end
		assign	s = P;

		// Exception visibility, matching the other DSP wrappers' style.
		logic  invalid, overflow;
		always_comb begin
			invalid = 0; overflow = 0;
			if(&s[30-:8]) begin
				if(|s[0+:23])  invalid  = 1;
				else           overflow = 1;
			end
		end
		always_ff @(posedge clk) begin
			if(!rst && EnaD) begin
				assert(!invalid)   else $warning("%m generated invalid output.");
				assert(!overflow)  else $warning("%m generated an overflow.");
			end
		end
	end : genBehav
	else begin : genDSP
		logic  fpa_invalid, fpa_overflow, fpa_underflow;
		DSPFP32 #(
			.A_FPTYPE("B32"),
			.A_INPUT("DIRECT"),
			.BCASCSEL("B"),
			.B_D_FPTYPE("B32"),
			.B_INPUT("DIRECT"),
			.PCOUTSEL("FPA"),
			.USE_MULT("NONE"),		// adder-only: no multiplier
			.IS_CLK_INVERTED(1'b0),
			.IS_FPINMODE_INVERTED(1'b0),
			.IS_FPOPMODE_INVERTED(7'b0000000),
			.IS_RSTA_INVERTED(1'b0),
			.IS_RSTB_INVERTED(1'b0),
			.IS_RSTC_INVERTED(1'b0),
			.IS_RSTD_INVERTED(1'b0),
			.IS_RSTFPA_INVERTED(1'b0),
			.IS_RSTFPINMODE_INVERTED(1'b0),
			.IS_RSTFPMPIPE_INVERTED(1'b0),
			.IS_RSTFPM_INVERTED(1'b0),
			.IS_RSTFPOPMODE_INVERTED(1'b0),
			.ACASCREG(0),
			.AREG(0),
			.FPA_PREG(1),		// register the accumulator (P)
			.FPBREG(0),
			.FPCREG(0),
			.FPDREG(1),			// register the D addend
			.FPMPIPEREG(0),
			.FPM_PREG(0),
			.FPOPMREG(0),		// FPOPMODE not registered (aligned externally)
			.INMODEREG(0),
			.RESET_MODE("SYNC")
		) DSPFP32_inst (
			.ACOUT_EXP(), .ACOUT_MAN(), .ACOUT_SIGN(),
			.BCOUT_EXP(), .BCOUT_MAN(), .BCOUT_SIGN(),
			.PCOUT(),
			.FPM_INVALID(), .FPM_OVERFLOW(), .FPM_UNDERFLOW(), .FPM_OUT(),
			.FPA_INVALID(fpa_invalid), .FPA_OVERFLOW(fpa_overflow), .FPA_UNDERFLOW(fpa_underflow), .FPA_OUT(s),
			.ACIN_EXP('x), .ACIN_MAN('x), .ACIN_SIGN('x),
			.BCIN_EXP('x), .BCIN_MAN('x), .BCIN_SIGN('x),
			.PCIN('x),
			.CLK(clk),
			.FPINMODE('1),
			.FPOPMODE(opmode),
			.A_SIGN('x), .A_EXP('x), .A_MAN('x),
			.B_SIGN('x), .B_EXP('x), .B_MAN('x),
			.C('x),
			.D_SIGN(a[31]), .D_EXP(a[30:23]), .D_MAN(a[22:0]),
			.ASYNC_RST('0),
			.CEA1('0), .CEA2('0),
			.CEB('0), .CEC('0), .CED('1),	// D captured every cycle; CEFPA gates accumulation
			.CEFPA(EnaD), .CEFPINMODE('0), .CEFPM('0), .CEFPMPIPE('0), .CEFPOPMODE('0),
			.RSTA('0), .RSTB('0), .RSTC('0), .RSTD(rst),
			.RSTFPA(rst), .RSTFPINMODE('0), .RSTFPM('0), .RSTFPMPIPE('0), .RSTFPOPMODE('0)
		);
		always_ff @(posedge clk) begin
			if(!rst && EnaD) begin
				assert(!fpa_invalid)  else $warning("%m generated invalid output.");
				assert(!fpa_overflow) else $warning("%m generated an overflow.");
			end
		end
	end : genDSP

endmodule : softmax_fp_accu
