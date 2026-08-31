module rec_bipartite #(
	// Bipartite table geometry.
	//
	// m_in[22:0] = m in [0,1) is split into three contiguous fields:
	//   x_0 = m_in[22 -: ADDR_WIDTH_0]                                  (top)
	//   x_1 = m_in[22-ADDR_WIDTH_0 -: ADDR_WIDTH_1]                     (middle)
	//   x_2 = m_in[22-ADDR_WIDTH_0-ADDR_WIDTH_1 -: ADDR_WIDTH_2]        (lower)
	//
	// Table 0 (upper) is indexed by { x_0, x_1 }     -> stores a value in [1, 2)
	//   as WORD_WIDTH fractional bits (the leading 1 is implicit).
	// Table 1 (lower) is indexed by { x_0, x_2 }     -> stores a small signed
	//   correction. Its magnitude is bounded by ~ 1/2^(ADDR_WIDTH_0+ADDR_WIDTH_1-1),
	//   so only the bottom WORD_WIDTH_LOWER bits carry information; the top bit
	//   is the sign for two's-complement representation.
	int unsigned  ADDR_WIDTH_0 = 5,
	int unsigned  ADDR_WIDTH_1 = 5,
	int unsigned  ADDR_WIDTH_2 = 5,
	int unsigned  WORD_WIDTH   = 23,
	int unsigned  NUM_NEWTON_STEPS = 0,	// Allowed values: 0 or 1
	int unsigned  SUSTAINABLE_INTERVAL = 1,	// Average II sustained over 2*DSP_LATENCY cycles
	// Guarantee readiness at II, do not expose delays of arbitrating between iterations:
	//  - by intermittent input delays or
	//  - by revoking readiness.
	bit  STABLE_READINESS = 1,
	bit  FORCE_BEHAVIORAL = 0,

	parameter shortreal  NEWTON_COEFF = 2.0,	// Constant term in the Newton step: x_{n+1} = x_n * (NEWTON_COEFF - b * x_n)
	parameter  RAM_STYLE = "distributed"	// Allowed: "auto", "block", "distributed", "registers", "ultra", "mixed"
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
		if(WORD_WIDTH <= ADDR_WIDTH_0 + ADDR_WIDTH_1 - 2) begin
			$error("WORD_WIDTH (%0d) must be greater than (ADDR_WIDTH_0 + ADDR_WIDTH_1 - 2) (%0d)", WORD_WIDTH, ADDR_WIDTH_0 + ADDR_WIDTH_1 - 2);
			$finish;
		end
		if(WORD_WIDTH > 23) begin
			$error("WORD_WIDTH (%0d) must be <= 23 (the fp32 mantissa width).", WORD_WIDTH);
			$finish;
		end
		if(ADDR_WIDTH_0 + ADDR_WIDTH_1 + ADDR_WIDTH_2 > 23) begin
			$error("ADDR_WIDTH_0+ADDR_WIDTH_1+ADDR_WIDTH_2 (%0d) must be <= 23.", ADDR_WIDTH_0 + ADDR_WIDTH_1 + ADDR_WIDTH_2);
			$finish;
		end
		if(ADDR_WIDTH_0 + ADDR_WIDTH_1 < 3) begin
			$error("ADDR_WIDTH_0+ADDR_WIDTH_1 (%0d) must be >= 3 (lower table needs at least a sign bit + 1 data bit).", ADDR_WIDTH_0 + ADDR_WIDTH_1);
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
		if(!(RAM_STYLE == "auto" || RAM_STYLE == "block" || RAM_STYLE == "distributed"
				|| RAM_STYLE == "registers" || RAM_STYLE == "ultra" || RAM_STYLE == "mixed")) begin
			$error("RAM_STYLE (%s) is invalid. Allowed: auto, block, distributed, registers, ultra, mixed.", RAM_STYLE);
			$finish;
		end
	end

	localparam int unsigned  ADDR_WIDTH_UPPER = ADDR_WIDTH_0 + ADDR_WIDTH_1;
	localparam int unsigned  ADDR_WIDTH_LOWER = ADDR_WIDTH_0 + ADDR_WIDTH_2;
	// Only store non-trivial bits in the second table; top bit serves as sign.
	// Clamped to 1 for invalid parameter combinations so elaboration still
	// succeeds and the runtime $error above fires deterministically.
	localparam int unsigned  WORD_WIDTH_LOWER = (WORD_WIDTH <= ADDR_WIDTH_0 + ADDR_WIDTH_1 - 2) ? 1 :
												(WORD_WIDTH - (ADDR_WIDTH_0 + ADDR_WIDTH_1) + 2);

	//---------------------------------------------------------------------
	// Bipartite tables for g(m) = 2/(1+m) - 1 on m in [0, 1). The input
	// mantissa carries an implicit leading 1, so the value to reciprocate
	// is 1+m in [1, 2); 2/(1+m) lands in (1, 2] and is renormalized by the
	// surrounding exponent decrement (253 - e_in) -- only the fractional
	// part g(m) = 2/(1+m) - 1 in (0, 1] needs to be approximated here.
	//---------------------------------------------------------------------
	(* RAM_STYLE = RAM_STYLE *)
	logic [WORD_WIDTH      -1:0]  rom_upper[0:(1 << ADDR_WIDTH_UPPER)-1];
	(* RAM_STYLE = RAM_STYLE *)
	logic [WORD_WIDTH_LOWER-1:0]  rom_lower[0:(1 << ADDR_WIDTH_LOWER)-1];
	initial begin
		// Midpoints of the truncated tails. delta_k offsets the
		// linearization point by half the resolution of the next-finer
		// field (and the trailing -1/2^24 accounts for the discarded bits
		// below the bipartite addressing).
		automatic real  delta_1 = 1.0 / (1 << (ADDR_WIDTH_0 + 1))
								- 1.0 / (1 << (ADDR_WIDTH_0 + ADDR_WIDTH_1 + 1));
		automatic real  delta_2 = 1.0 / (1 << (ADDR_WIDTH_0 + ADDR_WIDTH_1 + 1))
								- 1.0 / (1 << (ADDR_WIDTH_0 + ADDR_WIDTH_1 + ADDR_WIDTH_2 + 1));
		automatic real  delta_3 = 1.0 / (1 << (ADDR_WIDTH_0 + ADDR_WIDTH_1 + ADDR_WIDTH_2 + 1))
								- 1.0 / (1 << (23 + 1));

		// Real-valued staging tables. We build the exact (un-quantized) table
		// values first, apply the underflow-guard lift on the upper table,
		// and only then quantize into the ROMs. This mirrors exp_bipartite:
		// the lift has to compare/adjust real values, before fixed-point
		// truncation, to guarantee upper + lower >= 1 at every address.
		//
		// NOTE: lookup_upper stages the *full* value f(...) = 2/(...) in
		// (1, 2] (not f(...) - 1). Keeping the leading 1 here lets the lift
		// compare against 1.0 directly; the implicit-1 subtraction happens
		// in the quantization pass below.
		automatic real  lookup_upper[0:(1 << ADDR_WIDTH_UPPER)-1];
		automatic real  lookup_lower[0:(1 << ADDR_WIDTH_LOWER)-1];

		// --- Upper table: f(1 + x_0 + x_1 + delta_2 + delta_3), with
		// f(y) = 2/y. Address layout: i = (x_0 index << ADDR_WIDTH_1) | x_1 index.
		for(int unsigned  i = 0; i < (1 << ADDR_WIDTH_UPPER); i++) begin
			automatic real  x_0 = real'((i >> ADDR_WIDTH_1) & ((1 << ADDR_WIDTH_0) - 1))
								/ real'(1 << ADDR_WIDTH_0);
			automatic real  x_1 = real'(i & ((1 << ADDR_WIDTH_1) - 1))
								/ real'(1 << (ADDR_WIDTH_0 + ADDR_WIDTH_1));
			lookup_upper[i] = 2.0 / (1.0 + x_0 + x_1 + delta_2 + delta_3);
		end

		// --- Lower table: f'(1 + x_0 + delta_1 + delta_2 + delta_3) * (x_2 - delta_2) ---
		// f'(y) = -2/y^2. Address layout:
		//   i = (x_0 index << ADDR_WIDTH_2) | x_2 index.
		for(int unsigned  i = 0; i < (1 << ADDR_WIDTH_LOWER); i++) begin
			automatic real  x_0 = real'((i >> ADDR_WIDTH_2) & ((1 << ADDR_WIDTH_0) - 1))
								/ real'(1 << ADDR_WIDTH_0);
			automatic real  x_2 = real'(i & ((1 << ADDR_WIDTH_2) - 1))
								/ real'(1 << (ADDR_WIDTH_0 + ADDR_WIDTH_1 + ADDR_WIDTH_2));
			automatic real  y          = 1.0 + x_0 + delta_1 + delta_2 + delta_3;
			automatic real  derivative = -2.0 / (y * y);
			lookup_lower[i] = derivative * (x_2 - delta_2);
		end

		// --- Underflow-guard lift (mirrors exp_bipartite) ----------------
		// The lower table's centered correction is most negative at the top
		// of x_2 (where f'(y) = -2/y^2 is negative and the residual factor
		// is positive); at the top of the domain (max x_0, max x_1) the
		// upper value 2/(1+...) is so close to 1 that upper + lower would
		// dip below 1.0, which the unsigned mantissa field (implicit
		// leading 1) would wrap to ~2.0 (~100% error at m near 1). For
		// each x_0 group, find the most negative lower entry and lift any
		// upper entry in that group whose worst-case sum would fall below
		// the min_bound, so 1.0 <= upper + lower holds at every address. The
		// min_bound sits one ULP above 1 (1 + 2^-WORD_WIDTH): now that the lower
		// table rounds to nearest for both signs, that ULP absorbs the up-to-
		// half-ULP the correction can lose on the low side, keeping the stored
		// sum >= 1.0 without a toward-zero bias.
		for(int unsigned  x_0 = 0; x_0 < (1 << ADDR_WIDTH_0); x_0++) begin
			automatic real  min_bound = 1.0 + 1.0 / (1 << WORD_WIDTH);
			automatic real  lookup_lower_min = 0.0;
			for(int unsigned  x_2 = 0; x_2 < (1 << ADDR_WIDTH_2); x_2++) begin
				automatic real  lookup_value = lookup_lower[(x_0 << ADDR_WIDTH_2) | x_2];
				if(lookup_value < lookup_lower_min) begin
					lookup_lower_min = lookup_value;
				end
			end
			if(lookup_lower_min < 0.0) begin
				for(int unsigned  x_1 = 0; x_1 < (1 << ADDR_WIDTH_1); x_1++) begin
					automatic int unsigned  idx = (x_0 << ADDR_WIDTH_1) | x_1;
					if(lookup_upper[idx] + lookup_lower_min < min_bound) begin
						lookup_upper[idx] = min_bound - lookup_lower_min;
					end
				end
			end
		end

		// --- Overflow-guard max_bound (symmetric to the underflow lift) --
		// The lower table's correction is most positive at x_2 = 0 (f' < 0 for
		// 2/y, so f'*(x_2 - delta_2) is positive when x_2 < delta_2); at the
		// bottom of the domain (x_0 = x_1 = 0) the upper value 2/(1+...) is so
		// close to 2 that upper + lower could reach 2.0, leaving [1, 2) (the
		// implicit leading one would wrap into the exponent). For each x_0 group,
		// find the most positive lower entry and lower any upper entry whose
		// worst-case sum would exceed the max_bound, so 1.0 <= upper + lower < 2.0
		// holds at every address and the plain WORD_WIDTH-wide add stays valid.
		// The max_bound is two ULPs below 2 (2 - 2^(1-WORD_WIDTH)): one for the largest
		// representable value in [1, 2), plus one so the independent round-to-
		// nearest quantization of the upper and lower entries (each up to half a
		// ULP) can never push the stored sum back up to 2^WORD_WIDTH.
		for(int unsigned  x_0 = 0; x_0 < (1 << ADDR_WIDTH_0); x_0++) begin
			automatic real  max_bound = 2.0 - 2.0 / (1 << WORD_WIDTH);
			automatic real  lookup_lower_max = 0.0;
			for(int unsigned  x_2 = 0; x_2 < (1 << ADDR_WIDTH_2); x_2++) begin
				automatic real  lookup_value = lookup_lower[(x_0 << ADDR_WIDTH_2) | x_2];
				if(lookup_value > lookup_lower_max) begin
					lookup_lower_max = lookup_value;
				end
			end
			if(lookup_lower_max > 0.0) begin
				for(int unsigned  x_1 = 0; x_1 < (1 << ADDR_WIDTH_1); x_1++) begin
					automatic int unsigned  idx = (x_0 << ADDR_WIDTH_1) | x_1;
					if(lookup_upper[idx] + lookup_lower_max > max_bound) begin
						lookup_upper[idx] = max_bound - lookup_lower_max;
					end
				end
			end
		end

		// --- Quantize the staged tables into the ROMs --------------------
		// Upper: store f(...) - 1 as WORD_WIDTH fractional bits (the leading
		// 1 is implicit). int'(real) rounds to nearest (ties away from zero).
		for(int unsigned  i = 0; i < (1 << ADDR_WIDTH_UPPER); i++) begin
			automatic real  lookup_shifted = (lookup_upper[i] - 1.0) * (1 << WORD_WIDTH);
			automatic int unsigned  lookup_int = int'(lookup_shifted);
			rom_upper[i] = lookup_int[WORD_WIDTH-1:0];
		end

		// Lower: signed value in the same Q0.W fixed-point format as the upper
		// table (so the add lines up bit-for-bit), truncated to its low
		// WORD_WIDTH_LOWER bits. Round to nearest for both signs: the unbiased
		// rounding is more accurate than rounding negatives toward zero, and the
		// underflow lift already keeps the sum >= 1.0 (its target sits one ULP
		// above 1, absorbing the half-ULP the nearest-rounding of the correction
		// can add on the low side). Matches exp_bipartite.
		for(int unsigned  i = 0; i < (1 << ADDR_WIDTH_LOWER); i++) begin
			automatic real  lookup_shifted = lookup_lower[i] * (1 << WORD_WIDTH);
			automatic int  lookup_int = int'(lookup_shifted);
			rom_lower[i] = lookup_int[WORD_WIDTH_LOWER-1:0];
		end
	end

	localparam int unsigned  SEED_LATENCY = 3;
	localparam int unsigned  DSP_LATENCY  = 4;

	//---------------------------------------------------------------------
	// Isolate input from the arbitration between interleaved iterations as
	// needed.  A small skid buffer reshapes a uniformly II-spaced arrival
	// into the burst-acceptance pattern of the dense interleave schedule
	// (1 < II < 5) so that `irdy` does not flap on cycles that merely lack
	// an issue slot.  The overlapped and exclusive bands accept on a clean
	// periodic schedule (once per II) and need no skid; the pure-seed and
	// II = 1 configurations run at full throughput and just wire `xx` to the
	// input.  (Mirrors rec_lookup's genSkid.)
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

	//---------------------------------------------------------------------
	// Input split: sign is dropped (softmax reciprocal target is positive),
	// exponent feeds the linear transform, mantissa feeds the bipartite
	// approximation.  Sourced from `xx` so the acceptance handshake gates the
	// operand stream that enters the seed pipeline.
	//---------------------------------------------------------------------
	uwire [ 7:0]  e_in = xx[30:23];
	uwire [22:0]  m_in = xx[22: 0];

	//-----------------------------------------------------------------
	// Address split: x_0 (top), x_1 (mid), x_2 (low) inside m_in[22:0].
	//-----------------------------------------------------------------
	uwire [ADDR_WIDTH_UPPER-1:0]  addr_upper = m_in[22 -: ADDR_WIDTH_UPPER];
	uwire [ADDR_WIDTH_LOWER-1:0]  addr_lower = {
		m_in[22 -: ADDR_WIDTH_0],
		m_in[(22 - ADDR_WIDTH_0 - ADDR_WIDTH_1) -: ADDR_WIDTH_2]
	};

	//-----------------------------------------------------------------
	// Stage 0: register the addresses to break the path from the
	// input flops into the ROM input registers.
	//-----------------------------------------------------------------
	logic [ADDR_WIDTH_UPPER-1:0]  AddrUpperR = '0;
	logic [ADDR_WIDTH_LOWER-1:0]  AddrLowerR = '0;
	always_ff @(posedge clk) begin
		if(rst) begin
			AddrUpperR <= '0;
			AddrLowerR <= '0;
		end
		else begin
			AddrUpperR <= addr_upper;
			AddrLowerR <= addr_lower;
		end
	end

	//-----------------------------------------------------------------
	// Stage 1: synchronous ROM read.
	//-----------------------------------------------------------------
	logic [WORD_WIDTH      -1:0]  LookupUpper = '0;
	logic [WORD_WIDTH_LOWER-1:0]  LookupLower = '0;
	always_ff @(posedge clk) begin
		if(rst) begin
			LookupUpper <= '0;
			LookupLower <= '0;
		end
		else begin
			LookupUpper <= rom_upper[AddrUpperR];
			LookupLower <= rom_lower[AddrLowerR];
		end
	end

	//-----------------------------------------------------------------
	// Stage 2: combine the two table outputs.
	//
	// LookupUpper holds WORD_WIDTH fractional bits of a value in [1,2)
	// (leading 1 is implicit, not stored). LookupLower is a small
	// signed correction in two's complement; sign-extend it to
	// WORD_WIDTH bits before adding. The table-generation step is
	// expected to keep the true sum in [1,2) (so the implicit leading
	// 1 doesn't move) -- given that, a plain WORD_WIDTH-wide add is
	// enough: no carry out, no exponent fixup.
	//-----------------------------------------------------------------
	uwire [WORD_WIDTH-1:0]  lower_sext = {
		{(WORD_WIDTH - WORD_WIDTH_LOWER){LookupLower[WORD_WIDTH_LOWER-1]}},
		LookupLower
	};
	uwire [WORD_WIDTH-1:0]  man_sum = LookupUpper + lower_sext;

	// Left-justify WORD_WIDTH fractional bits into the 23-bit mantissa
	// field (zero-pad the LSBs if WORD_WIDTH < 23). The two arms are
	// split structurally so the zero-pad expression isn't elaborated
	// (with an illegal 0-bit replication) when WORD_WIDTH == 23.
	uwire [22:0]  mdat_next;
	if(WORD_WIDTH == 23) begin : gFullWidth
		assign  mdat_next = man_sum;
	end : gFullWidth
	else begin : gPad
		assign  mdat_next = { man_sum, {(23 - WORD_WIDTH){1'b0}} };
	end : gPad

	//-----------------------------------------------------------------
	// Exponent path: 253 - e_in is combinational; the result rides the
	// local pipeline alongside the mantissa so it lines up at the
	// output flop.
	//-----------------------------------------------------------------
	uwire [7:0]  e_out = 8'd253 - e_in;
	logic [SEED_LATENCY-2:0][7:0]  EPipe = '{ default: '0 };
	always_ff @(posedge clk) begin
		if(rst)  EPipe <= '{ default: '0 };
		else begin
			EPipe[0] <= e_out;
			for(int  s = 1; s < SEED_LATENCY-1; s++)  EPipe[s] <= EPipe[s-1];
		end
	end

	//-----------------------------------------------------------------
	// Seed output register stage. Both e_dat and mdat leave the seed
	// pipeline straight out of a flop -- this is the bipartite
	// approximation x0 ~= 1/(1+m) used by Newton (if enabled) or
	// directly as the module output.
	//-----------------------------------------------------------------
	logic [ 7:0]  EdatR = '0;
	logic [22:0]  MdatR = '0;
	always_ff @(posedge clk) begin
		if(rst) begin
			EdatR <= '0;
			MdatR <= '0;
		end
		else begin
			EdatR <= EPipe[SEED_LATENCY-2];
			MdatR <= mdat_next;
		end
	end

	uwire [31:0]  x0 = { 1'b0, EdatR, MdatR };	// bipartite approximation of 1/b

	localparam logic [31:0]  NEWTON_C = $shortrealtobits(NEWTON_COEFF);

	if(NUM_NEWTON_STEPS == 0) begin : genPureSeed
		//-------------------------------------------------------------
		// Pure seed: no recurrence, so it always sustains II = 1 and
		// SUSTAINABLE_INTERVAL is ignored.  Assemble result straight out
		// of the seed output flop; sign = 0 for softmax reciprocal.
		//-------------------------------------------------------------
		assign	xxrdy = 1'b1;

		logic [SEED_LATENCY-1:0]  Vld = '0;
		always_ff @(posedge clk) begin
			if(rst)  Vld <= '0;
			else     Vld <= { Vld[SEED_LATENCY-2:0], xxvld };
		end
		assign	ovld = Vld[SEED_LATENCY-1];
		assign	odat = x0;
	end : genPureSeed
	else begin : genSeedWithNewton
		//-------------------------------------------------------------
		// Bipartite seed + 1 Newton-Raphson step for y = 1/b:
		//    t   = NEWTON_COEFF - b * x0   (mode SUB)
		//    x1  = x0 * t                  (mode MUL)
		// where b is the operand to be reciprocated (aligned with x0)
		// and x0 = { 1'b0, EdatR, MdatR } is the bipartite approximation
		// of 1/b as a proper FP32 word.  NEWTON_COEFF = 2.0 yields the
		// textbook Newton-Raphson update; values slightly off 2.0 can
		// be used to bias-correct for the ROM rounding direction.
		//
		// The bipartite seed pipeline has SEED_LATENCY = 3 (vs. 1 for the
		// rec_lookup ROM), so the shared-DSP schedule is anchored on the
		// operand acceptance delayed by SEED_LATENCY; everything downstream
		// (csel/passB/rvld offsets, the X0 feed-back depth) is measured in
		// DSP_LATENCY offsets from that anchor and is otherwise identical to
		// rec_lookup's genSharedDSP.
		//-------------------------------------------------------------
		case(SUSTAINABLE_INTERVAL)
		1: begin : genII1
			//-----------------------------------------------------
			// II = 1: fully pipelined, one DSP per pass (2 DSPs).
			// Accepts a new operand every cycle.
			//   cy 0:  xx sampled            (addr_*/e_out combinational)
			//   cy 3:  EdatR/MdatR -> x0 valid; BDly[2] -> aligned b
			//   cy 3:  applied to DSP0 (a=x0, b=b, SUB)
			//   cy 7:  t = DSP0 output
			//   cy 7:  applied to DSP1 (a=x0 delayed, d=t, MUL)
			//   cy 11: x1 = DSP1 output -> odat
			// Total latency = SEED_LATENCY + 2*DSP_LATENCY = 11 cycles.
			//-----------------------------------------------------
			localparam int unsigned  LAT = SEED_LATENCY + 2*DSP_LATENCY;

			assign	xxrdy = 1'b1;

			logic [LAT-1:0]  Vld = '0;
			always_ff @(posedge clk) begin
				if(rst)  Vld <= '0;
				else     Vld <= { Vld[LAT-2:0], xxvld };
			end
			assign	ovld = Vld[LAT-1];

			// Delay xx by SEED_LATENCY so b aligns with x0 at the seed output.
			logic [31:0]  BDly[SEED_LATENCY] = '{ default: 'x };
			always_ff @(posedge clk) begin
				if(rst)  BDly <= '{ default: 'x };
				else     BDly <= { xx, BDly[0:SEED_LATENCY-2] };
			end
			uwire [31:0]  b = BDly[SEED_LATENCY-1];

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
			// which x0 / b are jointly valid at the DSP input.  The bipartite
			// seed pipeline free-runs, so the operand accepted at cycle T
			// reaches the seed output (x0) at T + SEED_LATENCY; that cycle is
			// the issue cycle.  At the issue cycle the DSP performs passA; the
			// matching passB follows DSP_LATENCY cycles later, taking the passA
			// result `t` back through the d = r loop-back.  A result therefore
			// occupies the multiplier at { issue, issue+DSP_LATENCY }.
			//
			//   accept : counter/phase-driven; gates xxrdy and marks the operand.
			//   IssueA : accept delayed by SEED_LATENCY -> x0/b valid now.
			//
			// The free-running seed pipeline is a pure delay line, so the x0 at
			// the issue cycle is exactly the seed of the operand accepted
			// SEED_LATENCY cycles earlier; `b` is `xx` through a matching
			// SEED_LATENCY delay, so x0 and b share provenance (both are the
			// accepted `xx` word).
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
			uwire  accept;	// operand consumed this cycle (schedule & xxvld)
			uwire  bsel;	// passA issue (load b multiply)
			uwire  csel;	// SUB select, aligned to the passA product
			uwire  aload;	// load DSP A register
			uwire  xsel;	// new x0 vs. delayed x0 on the A port
			uwire  rvld;	// result valid

			// passA issues SEED_LATENCY cycles after the operand is accepted,
			// when the free-running seed pipeline presents x0 and the matching
			// delayed operand b is valid.
			logic [SEED_LATENCY-1:0]  IssueP = '0;
			always_ff @(posedge clk) begin
				if(rst)  IssueP <= '0;
				else     IssueP <= { IssueP[SEED_LATENCY-2:0], accept };
			end
			uwire  IssueA = IssueP[SEED_LATENCY-1];

			// Aligned operand b: xx delayed by SEED_LATENCY, tapped at issue.
			logic [31:0]  BDly[SEED_LATENCY] = '{ default: 'x };
			always_ff @(posedge clk) begin
				if(rst)  BDly <= '{ default: 'x };
				else     BDly <= { xx, BDly[0:SEED_LATENCY-2] };
			end
			uwire [31:0]  b = BDly[SEED_LATENCY-1];

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
				// passA at ISSUE_DELAY (= SEED_LATENCY) cycles from now and passB
				// DSP_LATENCY after that -- are still free.  Because the DSP is
				// never double-booked by construction, no phase/parity reasoning
				// is required, and when the input idles the vector drains so
				// `xxrdy` stays high, WAITING for the next operand instead of
				// marching on a reset-anchored lattice.  That is what lets a
				// must-accept, phase-drifting producer (e.g. softmax's per-group
				// sum, whose arrival cycle wanders with input bubbles) be served
				// at II = NN: the ready phase follows the data, not the clock.
				//-------------------------------------------------
				// Delay from an accept to the cycle its passA consumes the
				// shared multiplier: the free-running seed pipeline depth.
				localparam int unsigned  ISSUE_DELAY = SEED_LATENCY;
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
				// (Cnt == 0) until an operand is actually present, then walks the
				// full 0 .. II-1 traversal exactly as before.  Parking is sound
				// because passB / csel / rvld are derived from the IssueA shift
				// registers (which advance every cycle), NOT from Cnt -- so the
				// extra idle cycles at 0 never skip a pass.  Once launched the
				// next accept cannot occur for >= II cycles, so consecutive issues
				// are >= II apart (>= the original's exact-II dense spacing), and
				// the original non-collision argument (II does not divide
				// DSP_LATENCY for II in 5..7) holds a fortiori.  Idle => Cnt sits
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
	end : genSeedWithNewton

endmodule : rec_bipartite


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
