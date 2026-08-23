module rec_lookup #(
	int unsigned  ADDR_WIDTH = 10,
	int unsigned  WORD_WIDTH = 10,
	int unsigned  NUM_NEWTON_STEPS = 0,	// Allowed values: 0 or 1
	int unsigned  SUSTAINABLE_INTERVAL = 1,	// Average II sustained over 8 cycles
	// Guarantee readiness at II, do not expose delays of arbitrating between iterations:
	//  - by intermittent input delays or
	//  - by revoking readiness.
	bit  STABLE_READINESS = 1,
	bit  FORCE_BEHAVIORAL = 0,

	parameter shortreal  NEWTON_COEFF = 2.0,	// Constant term in the Newton step: x_{n+1} = x_n * (NEWTON_COEFF - b * x_n)
	parameter  RAM_STYLE = "distributed"	// Allowed: "heuristic", "auto", "block", "distributed", "registers", "ultra", "mixed"
)(
	input	logic  clk,
	input	logic  rst,

	input	logic [31:0]  idat,
	input	logic  ivld,
	output	logic  irdy,

	output	logic [31:0]  odat,
	output	logic  ovld
);

	initial begin
		if(ADDR_WIDTH == 0 || ADDR_WIDTH > 23) begin
			$error("ADDR_WIDTH (%0d) must be in [1, 23].", ADDR_WIDTH);
			$finish;
		end
		if(WORD_WIDTH == 0 || WORD_WIDTH > 23) begin
			$error("WORD_WIDTH (%0d) must be in [1, 23].", WORD_WIDTH);
			$finish;
		end
		if(NUM_NEWTON_STEPS > 1) begin
			$error("NUM_NEWTON_STEPS (%0d) must be 0 or 1.", NUM_NEWTON_STEPS);
			$finish;
		end
		if(SUSTAINABLE_INTERVAL == 0) begin
			$error("SUSTAINABLE_INTERVAL (%0d) must be positive.", SUSTAINABLE_INTERVAL);
			$finish;
		end
		if(!(RAM_STYLE == "heuristic" || RAM_STYLE == "auto" || RAM_STYLE == "block" || RAM_STYLE == "distributed"
				|| RAM_STYLE == "registers" || RAM_STYLE == "ultra" || RAM_STYLE == "mixed")) begin
			$error("RAM_STYLE (%s) is invalid. Allowed: heuristic, auto, block, distributed, registers, ultra, mixed.", RAM_STYLE);
			$finish;
		end
	end

	// Determine flag for memory
	localparam  RAM_STYLE_HEURISTIC = (ADDR_WIDTH >= 10) ? "block" : "distributed";
	localparam  RAM_STYLE_FINAL     = (RAM_STYLE == "heuristic") ? RAM_STYLE_HEURISTIC : RAM_STYLE;

	// Memory for lookup
	(* RAM_STYLE = RAM_STYLE_FINAL *)
	logic [WORD_WIDTH-1:0]  rom[0:(1 << ADDR_WIDTH)-1];
	initial begin
		for(int unsigned  i = 0; i < (1 << ADDR_WIDTH); i++) begin
			automatic real  value_min   = real'(i) / real'(1 << ADDR_WIDTH);
			automatic real  value_range = 1.0 / (1 << ADDR_WIDTH) - 1.0 / (1 << 23);
			automatic real  value_max   = value_min + value_range;

			// RMSRE-optimal lookup value for f(x) = 1/x over the reciprocated
			// argument interval [x_lo, x_lo + d] with x_lo = 1 + value_min and
			// d = value_range, using the closed form c* = 3(2 x_lo + d) /
			// (2(3 x_lo^2 + 3 x_lo d + d^2)) (see thesis Sec. 4.1.1). The
			// leading 2.0 factor is the range-reduction scaling mapping the
			// result into (1,2].
			automatic real  x_lo         = 1.0 + value_min;
			automatic shortreal  lookup_value = shortreal'(2.0 * 3.0 * (2.0*x_lo + value_range) / (2.0 * (3.0*x_lo*x_lo + 3.0*x_lo*value_range + value_range*value_range)));
			//automatic shortreal  lookup_value = shortreal'(2.0 * $ln((1.0 + value_max) / (1.0 + value_min)) / value_range);
			//automatic shortreal  lookup_value = shortreal'(2.0 / (1.0 + value_min + 0.0*value_range));
			automatic logic [31:0]  lookup_bits = $shortrealtobits(lookup_value);

			// round_nearest
			if(lookup_value >= shortreal'(2.0)) begin
				// Out of the [1, 2) mantissa range; clamp to the largest
				// in-range encoding (1.111...1 ~= 2.0 - ULP).
				rom[i] = '1;
			end
			else if(WORD_WIDTH == 23) begin
				rom[i] = lookup_bits[22 -: WORD_WIDTH];
			end
			else begin
				automatic logic [23:0]  rounded = {1'b0, lookup_bits[22:0]} + (24'd1 << (22 - WORD_WIDTH));
				rom[i] = rounded[23] ? '1 : rounded[22 -: WORD_WIDTH];
			end
		end
	end

	//---------------------------------------------------------------------
	// Isolate input from the arbitration between interleaved iterations as
	// needed.  A small skid buffer reshapes a uniformly II-spaced arrival
	// into the burst-acceptance pattern of the dense interleave schedule
	// (1 < II < 5) so that `irdy` does not flap on cycles that merely lack
	// an issue slot.  The overlapped and exclusive bands accept on a clean
	// periodic schedule (once per II) and need no skid.
	// (Mirrors rsqrt_lookup's genSkid.)
	//---------------------------------------------------------------------
	uwire [31:0]  xx;
	uwire  xxvld;
	uwire  xxrdy;
	if((NUM_NEWTON_STEPS > 0) && STABLE_READINESS && (1 < SUSTAINABLE_INTERVAL) && (SUSTAINABLE_INTERVAL < 5)) begin : genSkid
		queue #(.DATA_WIDTH(32), .ELASTICITY(2)) input_queue (
			.clk, .rst,
			.idat, .ivld, .irdy,
			.odat(xx), .ovld(xxvld), .ordy(xxrdy)
		);
	end : genSkid
	else begin : genReg
		assign	xx    = idat;
		assign	xxvld = ivld;
		assign	irdy  = xxrdy;
	end : genReg

	uwire [ 7:0]  e_in = xx[30:23];
	uwire [22:0]  m_in = xx[22: 0];
	uwire [ADDR_WIDTH-1:0]  addr = m_in[22 -: ADDR_WIDTH];

	localparam int unsigned  DSP_LATENCY = 4;
	localparam logic [31:0]  NEWTON_C = $shortrealtobits(NEWTON_COEFF);

	if(NUM_NEWTON_STEPS == 0) begin : genPureLookup
		//-------------------------------------------------------------
		// LATENCY = 1: register the ROM read and the transformed
		// exponent, then reassemble the FP32 output.  A pure lookup
		// carries no recurrence, so it always sustains II = 1.
		//-------------------------------------------------------------
		assign	xxrdy = 1'b1;

		uwire [ 7:0]  e_out = 8'd253 - e_in;
		logic [7:0]  EDly = 'x;
		always_ff @(posedge clk) begin
			if(rst)  EDly <= 'x;
			else     EDly <= e_out;
		end

		logic [WORD_WIDTH-1:0]  RomQ = 'x;
		always_ff @(posedge clk) begin
			if(rst)  RomQ <= 'x;
			else     RomQ <= rom[addr];
		end
		uwire [22:0]  mdat = (WORD_WIDTH == 23) ? RomQ : { RomQ, {(23 - WORD_WIDTH){1'b0}} };

		logic  Vld = 0;
		always_ff @(posedge clk) begin
			if(rst)  Vld <= 0;
			else     Vld <= xxvld;
		end

		assign	odat = { 1'b0, EDly, mdat };
		assign	ovld = Vld;
	end : genPureLookup
	else begin : genLookupWithNewton
		//-------------------------------------------------------------
		// Lookup + 1 Newton-Raphson step for y = 1/b:
		//    x_{n+1} = x0 * (NEWTON_COEFF - b * x0)
		// realised as two DSP passes (MAC mode in parentheses):
		//    passA (SUB): t  = NEWTON_COEFF - x0 * b
		//    passB (MUL): x1 = x0 * t
		// NEWTON_COEFF = 2.0 yields the textbook Newton-Raphson update;
		// values slightly off 2.0 bias-correct for the ROM rounding.
		//
		// Both passes drive the multiplier with a = x0, so the same `a`
		// operand serves the whole iteration (only the multiply partner
		// and the add/sub mode differ).  This lets a single physical DSP
		// host both passes when the initiation interval allows it.
		//
		// DSP wrapper timing (recf_dspfp32, 4-cycle latency):
		//    r(T+4) reflects a / b / d / bsel presented at cycle T, but
		//    csel presented at cycle T+2.  The shared-DSP control therefore
		//    asserts the SUB select two cycles after the passA operands.
		//-------------------------------------------------------------

		// Combinational reconstruction of x0 ~= 1/b in FP32 from the ROM
		// read.  The ROM is synchronous, so x0 is valid one cycle after the
		// operand `xx` it belongs to; the operand is registered alongside.
		logic [31:0]  XX1  = 'x;
		logic [WORD_WIDTH-1:0]  RomQ = 'x;
		always_ff @(posedge clk) begin
			if(rst) begin
				XX1  <= 'x;
				RomQ <= 'x;
			end
			else if(xxrdy) begin
				XX1  <= xx;
				RomQ <= rom[addr];
			end
		end

		uwire [ 7:0]  e_xx1 = XX1[30:23];
		uwire [ 7:0]  e_x0  = 8'd253 - e_xx1;
		uwire [22:0]  m_x0  = (WORD_WIDTH == 23) ? RomQ : { RomQ, {(23 - WORD_WIDTH){1'b0}} };
		uwire [31:0]  x0    = { 1'b0, e_x0, m_x0 };	// lookup approximation of 1/b
		uwire [31:0]  b     = XX1;	// operand to be reciprocated, aligned with x0

		case(SUSTAINABLE_INTERVAL)
		1: begin : genII1
			//-----------------------------------------------------
			// II = 1: fully pipelined, one DSP per pass (2 DSPs).
			// Accepts a new operand every cycle.
			//   cy 0: xx sampled (addr / e_in combinational)
			//   cy 1: RomQ, XX1 valid -> x0, b combinational
			//   cy 1: applied to DSP0 (a=x0, b=b, SUB)
			//   cy 5: t = DSP0 output
			//   cy 5: applied to DSP1 (a=x0 delayed, d=t, MUL)
			//   cy 9: x1 = DSP1 output -> odat
			// Total latency = 1 + 2*DSP_LATENCY = 9 cycles.
			//-----------------------------------------------------
			localparam int unsigned  LAT = 1 + 2*DSP_LATENCY;

			assign	xxrdy = 1'b1;

			logic [LAT-1:0]  Vld = '0;
			always_ff @(posedge clk) begin
				if(rst)  Vld <= '0;
				else     Vld <= { Vld[LAT-2:0], xxvld };
			end
			assign	ovld = Vld[LAT-1];

			// Align x0 with the DSP0 output for DSP1: DSP_LATENCY cycles.
			logic [31:0]  X0Dly[DSP_LATENCY] = '{ default: 'x };
			always_ff @(posedge clk) begin
				if(rst)  X0Dly <= '{ default: 'x };
				else     X0Dly <= { x0, X0Dly[0:DSP_LATENCY-2] };
			end

			uwire [31:0]  t;	// DSP0 result  (NEWTON_COEFF - x0 * b)
			uwire [31:0]  x1;	// DSP1 result  (x0 * t)

			// DSP0: t = NEWTON_COEFF - x0 * b    (mode SUB, c = NEWTON_COEFF)
			recf_dspfp32 #(.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)) DSP0 (
				.clk, .rst,
				.ena('1), .bsel('1), .csel('1),
				.a(x0), .b(b), .c(NEWTON_C), .d('x),
				.rvld('0), .r(t)
			);

			// DSP1: x1 = x0_delayed * t          (mode MUL)
			recf_dspfp32 #(.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)) DSP1 (
				.clk, .rst,
				.ena('1), .bsel('0), .csel('0),
				.a(X0Dly[DSP_LATENCY-1]), .b('x), .c('x), .d(t),
				.rvld(Vld[LAT-1]), .r(x1)
			);

			assign	odat = x1;
		end : genII1
		default: begin : genSharedDSP
			//-----------------------------------------------------
			// II >= 2: one physical DSP time-multiplexes both passes.
			//
			// The schedule is anchored on the *issue* cycle: the cycle on
			// which x0 / b are combinationally valid (one cycle after the
			// operand has been accepted into XX1 / RomQ, because the ROM is
			// synchronous).  At the issue cycle the DSP performs passA; the
			// matching passB follows DSP_LATENCY cycles later, taking the
			// passA result `t` back through the d = r loop-back.  A result
			// therefore occupies the multiplier at { issue, issue+DSP_LATENCY }.
			//
			//   accept : counter-driven; gates XX1/RomQ load and xxrdy.
			//   IssueA : accept registered by one cycle  -> x0/b valid now.
			//
			// Control selects per cycle (all derived from IssueA):
			//   bsel : 1 = load operand b on the multiplier B port (passA)
			//          0 = use the looped-back d port             (passB)
			//   csel : 1 = subtract from NEWTON_COEFF (passA, asserted
			//              DSP_LATENCY/2 cycles after the passA operands to
			//              meet the wrapper's csel timing)
			//          0 = pass the product through                (passB)
			//   aload: capture a new `a` (= x0) into the DSP A register
			//   xsel : 1 = the A operand is the freshly looked-up x0
			//          0 = the A operand is a delayed (fed-back) x0
			//-----------------------------------------------------
			uwire  accept;	// operand consumed this cycle (counter & xxvld)
			uwire  bsel;	// passA issue (load b multiply)
			uwire  csel;	// SUB select, aligned to the passA product
			uwire  aload;	// load DSP A register
			uwire  xsel;	// new x0 vs. delayed x0 on the A port
			uwire  rvld;	// result valid

			// passA issues one cycle after the operand is accepted, when the
			// synchronous ROM read (x0) and the registered operand (b) are valid.
			logic  IssueA = 0;
			always_ff @(posedge clk) begin
				if(rst)  IssueA <= 0;
				else     IssueA <= accept;
			end

			// Delayed x0 for the passB A operand and for the feed-back of
			// interleaved iterations.  The shift advances every cycle, so
			// X0[DSP_LATENCY-1] is the x0 issued exactly DSP_LATENCY cycles
			// earlier -- precisely the passA x0 of the result whose passB is
			// due this cycle.  Between issues the head simply holds its value
			// until it shifts down.
			logic [31:0]  X0[DSP_LATENCY] = '{ default: 'x };
			always_ff @(posedge clk) begin
				if(rst)  X0 <= '{ default: 'x };
				else     X0 <= { (IssueA ? x0 : X0[0]), X0[0:DSP_LATENCY-2] };
			end
			uwire [31:0]  a = xsel ? x0 : X0[DSP_LATENCY-1];

			// Common downstream control pipeline shared by all three sub-bands:
			//   IssueA -> csel  @ +DSP_LATENCY/2
			//   IssueA -> passB @ +DSP_LATENCY
			//   passB  -> rvld  @ +DSP_LATENCY
			logic [DSP_LATENCY/2-1:0]  CSelP  = '0;
			logic [DSP_LATENCY-1:0]    PassBP = '0;
			logic [DSP_LATENCY-1:0]    RVldP  = '0;
			uwire  passB = PassBP[DSP_LATENCY-1];
			always_ff @(posedge clk) begin
				if(rst) begin
					CSelP  <= '0;
					PassBP <= '0;
					RVldP  <= '0;
				end
				else begin
					CSelP  <= { CSelP [DSP_LATENCY/2-2:0], IssueA };
					PassBP <= { PassBP[DSP_LATENCY-2:0],   IssueA };
					RVldP  <= { RVldP [DSP_LATENCY-2:0],   passB  };
				end
			end
			assign	bsel  = IssueA;
			assign	xsel  = IssueA;
			assign	csel  = CSelP[DSP_LATENCY/2-1];
			assign	rvld  = RVldP[DSP_LATENCY-1];

			if(SUSTAINABLE_INTERVAL < 5) begin : genInterleave
				//-------------------------------------------------
				// 1 < II < 5: dense interleave.  Up to DSP_LATENCY results
				// (ceil(window/II) = 4..2) are kept in flight through the
				// single DSP at once, so the A register is reloaded every
				// cycle for the differing owners (aload = 1) and each owner's
				// x0 rides the X0 feed-back shift.
				//
				// SELF-TIMED acceptance (mirrors rsqrt_bipartite's genII2
				// reservation map): rather than free-run a window phase and
				// accept blindly on the first half, we track the shared DSP's
				// future occupancy in a small in-flight bit vector `Busy` and
				// admit an operand only when BOTH cycles its iteration needs --
				// passA at ISSUE_DELAY cycles from now and passB DSP_LATENCY
				// after that -- are still free.  Because the DSP is never double-
				// booked by construction, no phase/parity reasoning is required,
				// and when the input idles the vector drains so `xxrdy` stays
				// high, WAITING for the next operand instead of marching on a
				// reset-anchored lattice.  That is what lets a must-accept,
				// phase-drifting producer (e.g. softmax's per-group sum, whose
				// arrival cycle wanders with input bubbles) be served at II = NN:
				// the ready phase follows the data rather than the clock.
				//-------------------------------------------------
				// Delay from an accept to the cycle its passA actually consumes
				// the shared multiplier: here the accept register (IssueA) plus
				// the synchronous ROM already folded into x0, i.e. 1 cycle.
				localparam int unsigned  ISSUE_DELAY = 1;
				// Reservation map of the shared DSP's multiplier: Busy[j] set ==
				// "already claimed at j cycles from now".  Width covers the
				// farthest slot a new iteration reserves (passB at
				// ISSUE_DELAY+DSP_LATENCY) plus the current cycle.
				localparam int unsigned  WIN = ISSUE_DELAY + DSP_LATENCY + 1;
				logic [WIN-1:0]  Busy = '0;
				// An iteration admitted this cycle t claims the multiplier at
				// t+ISSUE_DELAY (passA) and t+ISSUE_DELAY+DSP_LATENCY (passB);
				// admit only if both are still free.
				uwire  slots_free = !Busy[ISSUE_DELAY] && !Busy[ISSUE_DELAY + DSP_LATENCY];
				uwire  take = slots_free && xxvld;
				always_ff @(posedge clk) begin
					if(rst)  Busy <= '0;
					else begin
						// Shift down one cycle (time advances: offset k -> k-1),
						// then stamp the two slots the admitted iteration claims
						// (expressed in the next cycle's frame, hence -1).
						automatic logic [WIN-1:0]  nxt = { 1'b0, Busy[WIN-1:1] };
						if(take) begin
							nxt[ISSUE_DELAY - 1]             = 1'b1;	// passA slot
							nxt[ISSUE_DELAY - 1 + DSP_LATENCY] = 1'b1;	// passB slot
						end
						Busy <= nxt;
					end
				end

				assign	aload  = 1'b1;	// A reloaded every cycle (interleaved owners)
				assign	xxrdy  = slots_free;
				assign	accept = take;
			end : genInterleave
			else if(SUSTAINABLE_INTERVAL < 2*DSP_LATENCY) begin : genOverlapped
				//-------------------------------------------------
				// 5 <= II < 2*DSP_LATENCY: overlapped.  Consecutive
				// iterations still overlap (the next passA issues while the
				// previous result is still draining), but at most two
				// iterations coexist (ceil(window/II) = 2), so no per-owner
				// rotation is needed -- a single counter drives the schedule.
				//
				// SELF-TIMED variant: the counter PARKS at its accept phase
				// (Cnt == 0) until an operand is actually present, then walks
				// the full 0 .. II-1 traversal exactly as before.  Parking is
				// sound because passB / csel / rvld are derived from the
				// IssueA shift registers (which advance every cycle), NOT from
				// Cnt -- so the extra idle cycles at 0 never skip a pass.  Once
				// launched the next accept cannot occur for >= II cycles, so
				// consecutive issues are >= II apart (>= the original's exact-II
				// dense spacing), and the original non-collision argument (II
				// mod 4 != 0 for II in 5..7) holds a fortiori.  Idle => Cnt sits
				// at 0 with xxrdy high, waiting for the operand.
				//-------------------------------------------------
				logic [$clog2(SUSTAINABLE_INTERVAL)-1:0]  Cnt = '0;
				uwire  parked = (Cnt == '0);
				always_ff @(posedge clk) begin
					if(rst)  Cnt <= '0;
					else     Cnt <= parked? (xxvld? 1 : '0)			// hold at 0 until an operand arrives
					                      : (Cnt == SUSTAINABLE_INTERVAL-1)? '0 : Cnt + 1;
				end
				assign	xxrdy  = parked;
				assign	accept = parked && xxvld;
				assign	aload  = IssueA || passB;
			end : genOverlapped
			else begin : genExclusive
				//-------------------------------------------------
				// II >= 2*DSP_LATENCY: exclusive.  The window fits entirely
				// within one initiation interval, so iterations never overlap.
				// Identical self-timed control to the overlapped band: the
				// counter parks at 0 until an operand arrives, then walks
				// 0 .. II-1 while the iteration owns the DSP for its
				// 2*DSP_LATENCY-cycle traversal.  Kept separate to mirror the
				// band structure (here no overlap ever occurs).
				//-------------------------------------------------
				logic [$clog2(SUSTAINABLE_INTERVAL)-1:0]  Cnt = '0;
				uwire  parked = (Cnt == '0);
				always_ff @(posedge clk) begin
					if(rst)  Cnt <= '0;
					else     Cnt <= parked? (xxvld? 1 : '0)			// hold at 0 until an operand arrives
					                      : (Cnt == SUSTAINABLE_INTERVAL-1)? '0 : Cnt + 1;
				end
				assign	xxrdy  = parked;
				assign	accept = parked && xxvld;
				assign	aload  = IssueA || passB;
			end : genExclusive

			uwire [31:0]  r;	// shared-DSP result (NEWTON_COEFF - x0*b on passA, x0*t on passB)
			recf_dspfp32 #(.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)) DSP (
				.clk, .rst,
				.ena(aload), .bsel, .csel,
				.a, .b, .c(NEWTON_C), .d(r),
				.rvld, .r
			);

			assign	odat = r;
			assign	ovld = rvld;
		end : genSharedDSP
		endcase
	end : genLookupWithNewton

endmodule : rec_lookup


// ================================================================================================================
// ================================================================================================================
// ================================================================================================================


// Local DSP58 instantiation wrapper for the reciprocal Newton step.
// Computes one of (4-cycle pipeline latency):
//   csel == 0:  r = a * (bsel ? b : d)
//   csel == 1:  r = c - a * (bsel ? b : d)
// Identical control flow to rsqrtf_dspfp32 in rsqrt_lookup.sv, but
// the subtract operand comes from C (FP32 input port) instead of a
// hard-coded constant, which is required to subtract from 2.0 here.
module recf_dspfp32 #(
	bit  FORCE_BEHAVIORAL = 0
)(
	input  logic         clk,
	input  logic         rst,

	input  logic         ena,
	input  logic         bsel,
	input  logic         csel,
	input  logic [31:0]  a,
	input  logic [31:0]  b,
	input  logic [31:0]  c,
	input  logic [31:0]  d,

	input  logic         rvld,
	output logic [31:0]  r
);

	logic  invalid;
	logic  overflow;
	logic  underflow;
	localparam logic [6:0]  MODE_MUL = { 2'b00, 3'b010, 2'b01 };
	localparam logic [6:0]  MODE_SUB = { 2'b01, 3'b110, 2'b01 };

	if(FORCE_BEHAVIORAL) begin : genBehav
		logic [31:0]  A1 = 'x;
		logic [31:0]  B1 = 'x;
		logic [31:0]  D1 = 'x;
		logic         BSel1 = 'x;
		logic         CSel3 = 'x;
		logic [31:0]  M[2:3] = '{ default: 'x };
		logic [31:0]  P4 = 'x;

		always_ff @(posedge clk) begin
			if(ena)  A1 <= a;
			B1 <= b;
			D1 <= d;
			BSel1 <= bsel;
			CSel3 <= csel;
			M <= {
				$shortrealtobits($bitstoshortreal(A1)*$bitstoshortreal(BSel1? B1 : D1)),
				M[2]
			};
			P4 <= CSel3? $shortrealtobits($bitstoshortreal(c) - $bitstoshortreal(M[3])) : M[3];
		end

		assign	r = P4;

		always_comb begin
			invalid = 0;
			overflow = 0;
			underflow = 0;

			if(&r[30-:8]) begin
				if(|r[0+:23])  invalid = 1;
				else           overflow = 1;
			end
		end
	end : genBehav
	else begin : genDSP
		DSPFP32 #(
			.A_FPTYPE("B32"),
			.A_INPUT("DIRECT"),
			.BCASCSEL("B"),
			.B_D_FPTYPE("B32"),
			.B_INPUT("DIRECT"),
			.PCOUTSEL("FPA"),
			.USE_MULT("MULTIPLY"),
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
			.ACASCREG(1),
			.AREG(1),
			.FPA_PREG(1),
			.FPBREG(1),
			.FPCREG(0),
			.FPDREG(1),
			.FPMPIPEREG(1),
			.FPM_PREG(1),
			.FPOPMREG(1),
			.INMODEREG(1),
			.RESET_MODE("SYNC")
		) DSPFP32_inst (
			.ACOUT_EXP(), .ACOUT_MAN(), .ACOUT_SIGN(),
			.BCOUT_EXP(), .BCOUT_MAN(), .BCOUT_SIGN(),
			.PCOUT(),
			.FPM_INVALID(), .FPM_OVERFLOW(), .FPM_UNDERFLOW(), .FPM_OUT(),
			.FPA_INVALID(invalid), .FPA_OVERFLOW(overflow), .FPA_UNDERFLOW(underflow), .FPA_OUT(r),
			.ACIN_EXP('x), .ACIN_MAN('x), .ACIN_SIGN('x),
			.BCIN_EXP('x), .BCIN_MAN('x), .BCIN_SIGN('x),
			.PCIN('x),
			.CLK(clk), .FPINMODE(bsel), .FPOPMODE(csel? MODE_SUB : MODE_MUL),
			.A_SIGN(a[31]), .A_EXP(a[30:23]), .A_MAN(a[22:0]),
			.B_SIGN(b[31]), .B_EXP(b[30:23]), .B_MAN(b[22:0]),
			.C(c),
			.D_SIGN(d[31]), .D_EXP(d[30:23]), .D_MAN(d[22:0]),
			.ASYNC_RST('0),
			.CEA1('0), .CEA2(ena),
			.CEB('1), .CEC('0), .CED('1),
			.CEFPA('1), .CEFPINMODE('1), .CEFPM('1), .CEFPMPIPE('1), .CEFPOPMODE('1),
			.RSTA('0), .RSTB('0), .RSTC('0), .RSTD('0),
			.RSTFPA('0), .RSTFPINMODE('0), .RSTFPM('0), .RSTFPMPIPE('0), .RSTFPOPMODE('0)
		);
	end : genDSP

	always_ff @(posedge clk) begin
		if(!rst && rvld) begin
			assert(!invalid) else $warning("%m generated invalid output.");
			assert(!overflow) else $warning("%m generated an overflow.");
			assert(!underflow) else $warning("%m generated an underflow.");
		end
	end

endmodule : recf_dspfp32
