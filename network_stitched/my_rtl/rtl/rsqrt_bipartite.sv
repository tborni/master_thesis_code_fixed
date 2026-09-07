module rsqrt_bipartite #(
	int unsigned  ADDR_WIDTH_0 = 5,
	int unsigned  ADDR_WIDTH_1 = 5,
	int unsigned  ADDR_WIDTH_2 = 5,
	int unsigned  WORD_WIDTH = 13,
	int unsigned  NUM_NEWTON_STEPS = 0,	// Allowed values: 0, 1 or 2 (only for II = 1)
	int unsigned  SUSTAINABLE_INTERVAL = 1,	// Average II sustained over 12 Cycles
	// Guarantee readiness at II, do not expose delays of arbitrating between iterations:
	//  - by intermittent input delays or
	//  - by revoking readiness.
	bit  STABLE_READINESS = 1,
	bit  FORCE_BEHAVIORAL = 0,

	parameter  RAM_STYLE = "distributed"	// Allowed: "auto", "block", "distributed", "registers", "ultra", "mixed"
)(
	// Global Control
	input	logic  clk,
	input	logic  rst,

	input	logic [31:0]  x,
	input	logic  xvld,
	output	logic  xrdy,

	output	logic [31:0]  r,
	output	logic  rvld
);

initial begin
	// Bipartite construction is only meaningful for w0 > L-2 (thesis Sec. 4.1.2).
	// For invsqrt L = n0+n1+1, so L-2 = ADDR_WIDTH_0+ADDR_WIDTH_1-1; a direct
	// lookup is at least as accurate at or below this width. (rec/exp use L-2 =
	// n0+n1-2 because their L = n0+n1.)
	if(WORD_WIDTH <= ADDR_WIDTH_0 + ADDR_WIDTH_1 - 1) begin
		$error("WORD_WIDTH (%0d) must be greater than (ADDR_WIDTH_0 + ADDR_WIDTH_1 - 1) (%0d)", WORD_WIDTH, ADDR_WIDTH_0 + ADDR_WIDTH_1 - 1);
		$finish;
	end
	if(SUSTAINABLE_INTERVAL == 0) begin
		$error("SUSTAINABLE_INTERVAL (%0d) must be positive.", SUSTAINABLE_INTERVAL);
		$finish;
	end
	if (!(RAM_STYLE == "auto" || RAM_STYLE == "block" || RAM_STYLE == "distributed"
			|| RAM_STYLE == "registers" || RAM_STYLE == "ultra" || RAM_STYLE == "mixed")) begin
		$error("RAM_STYLE (%s) is invalid. Allowed: heuristic, auto, block, distributed, registers, ultra, mixed.", RAM_STYLE);
		$finish;
	end
end

localparam int unsigned  ADDR_WIDTH_UPPER = ADDR_WIDTH_0 + ADDR_WIDTH_1 + 1;
localparam int unsigned  ADDR_WIDTH_LOWER = ADDR_WIDTH_0 + ADDR_WIDTH_2 + 1;
// Only store non-trivial bits in the second table (thesis Sec. 4.1.2):
//   w1 = w0 - (L - 2),  with  L = n0 + n1 + 1  for invsqrt.
// Hence w1 = WORD_WIDTH - (ADDR_WIDTH_0 + ADDR_WIDTH_1) + 1, one bit narrower
// than the rec/exp value (their L = n0 + n1 gives ... + 2). The extra invsqrt
// leading sign bit is guaranteed redundant because |f(xi0)/f'(xi1)| = sqrt(2)
// for f(y) = y^(-1/2), whose log2 rounds the order-of-magnitude gap up by one.
// Set WORD_WIDTH_LOWER = 1 for invalid parameters to avoid errors at elaboration time and trigger the intended error at runtime
localparam int unsigned  WORD_WIDTH_LOWER = (WORD_WIDTH <= ADDR_WIDTH_0 + ADDR_WIDTH_1 - 1) ? 1 :
											(WORD_WIDTH - (ADDR_WIDTH_0 + ADDR_WIDTH_1) + 1);

// Bipartite tables
(* RAM_STYLE = RAM_STYLE *)
logic [WORD_WIDTH      -1:0]  rom_upper[0:(1 << ADDR_WIDTH_UPPER)-1];
(* RAM_STYLE = RAM_STYLE *)
logic [WORD_WIDTH_LOWER-1:0]  rom_lower[0:(1 << ADDR_WIDTH_LOWER)-1];
initial begin
	// Midpoints of the truncated tails. delta_k offsets the linearization point
	// by half the resolution of the next-finer field (and the trailing -1/2^24
	// accounts for the discarded bits below the bipartite addressing).
	automatic real  delta_1 = 1.0 / (1 << (ADDR_WIDTH_0 + 1)) - 1.0 / (1 << (ADDR_WIDTH_0 + ADDR_WIDTH_1 + 1));
	automatic real  delta_2 = 1.0 / (1 << (ADDR_WIDTH_0 + ADDR_WIDTH_1 + 1)) - 1.0 / (1 << (ADDR_WIDTH_0 + ADDR_WIDTH_1 + ADDR_WIDTH_2 + 1));
	automatic real  delta_3 = 1.0 / (1 << (ADDR_WIDTH_0 + ADDR_WIDTH_1 + ADDR_WIDTH_2 + 1)) - 1.0 / (1 << (23 + 1));

	// Real-valued staging tables. We build the exact (un-quantized) table values
	// first, apply the underflow/overflow guards on the upper table, and only then
	// quantize into the ROMs. This mirrors rec_bipartite/exp_bipartite. The top
	// address bit of each table selects the range-reduction factor (1 or 2) for the
	// odd/even input exponent, so the guard groups below are indexed by {factor, x_0}.
	//
	// NOTE: lookup_upper stages the *full* value 2/sqrt(...) in (1, 2] (not the
	// value - 1). Keeping the leading 1 here lets the guards compare against 1.0
	// directly; the implicit-1 subtraction happens in the quantization pass below.
	automatic real  lookup_upper[0:(1 << ADDR_WIDTH_UPPER)-1];
	automatic real  lookup_lower[0:(1 << ADDR_WIDTH_LOWER)-1];

	// --- Upper table: a0 = f(x_0 + x_1 + t_2 + t_3), the standard bipartite point
	// sample of eq (3.20) with f(y) = 1/sqrt(y). The mantissa argument is
	// factor*(1 + x_0 + x_1 + delta_2 + delta_3) and the leading 2.0 is the range-
	// reduction scaling into (1, 2]. Address: i = { factor, x_0, x_1 }.
	for(int unsigned  i = 0; i < (1 << ADDR_WIDTH_UPPER); i++) begin
		automatic real  factor = 1.0 + 1.0*((i & (1 << (ADDR_WIDTH_UPPER - 1))) == 0);
		automatic real  x_0 = real'((i >> ADDR_WIDTH_1) & ((1 << ADDR_WIDTH_0) - 1)) / real'(1 << ADDR_WIDTH_0);
		automatic real  x_1 = real'(i & ((1 << ADDR_WIDTH_1) - 1)) / real'(1 << (ADDR_WIDTH_0 + ADDR_WIDTH_1));
		lookup_upper[i] = 2.0 / $sqrt(factor * (1.0 + x_0 + x_1 + delta_2 + delta_3));
	end

	// --- Lower table: a1 = f'(x_0 + t_1 + t_2 + t_3) * (x_2 - delta_2), with
	// f'(y) = -1/2 * y^(-3/2). The factor enters twice (once inside f' via the
	// scaled argument, once from d/dm of factor*(1+m)). Address: i = { factor, x_0, x_2 }.
	for(int unsigned  i = 0; i < (1 << ADDR_WIDTH_LOWER); i++) begin
		automatic real  factor = 1.0 + 1.0*((i & (1 << (ADDR_WIDTH_LOWER - 1))) == 0);
		automatic real  x_0 = real'((i >> ADDR_WIDTH_2) & ((1 << ADDR_WIDTH_0) - 1)) / real'(1 << ADDR_WIDTH_0);
		automatic real  x_2 = real'(i & ((1 << ADDR_WIDTH_2) - 1)) / real'(1 << (ADDR_WIDTH_0 + ADDR_WIDTH_1 + ADDR_WIDTH_2));
		lookup_lower[i] = 2.0 * (-0.5) * $pow(factor * (1.0 + x_0 + delta_1 + delta_2 + delta_3), -1.5) * factor * (x_2 - delta_2);
	end

	// --- Underflow-guard lift ----------------------------------------------------
	// The lower table's correction is most negative at the top of x_2; where the
	// upper value 2/sqrt(1+...) is close to 1, upper + lower could fall below 1.0,
	// which the unsigned mantissa (implicit leading 1) would wrap to ~2.0. For each
	// {factor, x_0} group, find the most negative lower entry and lift any upper
	// entry whose worst-case sum would fall below the min_bound, so 1.0 <= upper +
	// lower holds at every address. The min_bound sits one ULP above 1
	// (1 + 2^-WORD_WIDTH): now that the lower table rounds to nearest for both
	// signs, that ULP absorbs the up-to-half-ULP the correction can lose on the low
	// side, keeping the stored sum >= 1.0 without a toward-zero bias.
	for(int unsigned  factor_x_0 = 0; factor_x_0 < (1 << (ADDR_WIDTH_0 + 1)); factor_x_0++) begin
		automatic real  min_bound = 1.0 + 1.0 / (1 << WORD_WIDTH);
		automatic real  lookup_lower_min = 0.0;
		for(int unsigned  x_2 = 0; x_2 < (1 << ADDR_WIDTH_2); x_2++) begin
			automatic real  lookup_value = lookup_lower[(factor_x_0 << ADDR_WIDTH_2) | x_2];
			if(lookup_value < lookup_lower_min) begin
				lookup_lower_min = lookup_value;
			end
		end
		if(lookup_lower_min < 0.0) begin
			for(int unsigned  x_1 = 0; x_1 < (1 << ADDR_WIDTH_1); x_1++) begin
				automatic int unsigned  idx = (factor_x_0 << ADDR_WIDTH_1) | x_1;
				if(lookup_upper[idx] + lookup_lower_min < min_bound) begin
					lookup_upper[idx] = min_bound - lookup_lower_min;
				end
			end
		end
	end

	// --- Overflow-guard cap (symmetric to the underflow lift) --------------------
	// The lower table's correction is most positive at x_2 = 0 (f' < 0 for 1/sqrt,
	// so f'*(x_2 - delta_2) is positive when x_2 < delta_2); at the bottom of the
	// domain (x_0 = x_1 = 0) the upper value 2/sqrt(1+...) is so close to 2 that
	// upper + lower could reach 2.0, leaving [1, 2) (the leading one would carry
	// into the exponent). For each {factor, x_0} group, find the most positive
	// lower entry and lower any upper entry whose worst-case sum would exceed the
	// max_bound, so 1.0 <= upper + lower < 2.0 holds at every address and a plain
	// WORD_WIDTH-wide add (no carry, no exponent fixup) suffices. The max_bound is
	// two ULPs below 2 (2 - 2^(1-WORD_WIDTH)): one for the largest representable
	// value in [1, 2), plus one so the independent round-to-nearest quantization of
	// the upper and lower entries (each up to half a ULP) can never push the stored
	// sum back up to 2^WORD_WIDTH.
	for(int unsigned  factor_x_0 = 0; factor_x_0 < (1 << (ADDR_WIDTH_0 + 1)); factor_x_0++) begin
		automatic real  max_bound = 2.0 - 2.0 / (1 << WORD_WIDTH);
		automatic real  lookup_lower_max = 0.0;
		for(int unsigned  x_2 = 0; x_2 < (1 << ADDR_WIDTH_2); x_2++) begin
			automatic real  lookup_value = lookup_lower[(factor_x_0 << ADDR_WIDTH_2) | x_2];
			if(lookup_value > lookup_lower_max) begin
				lookup_lower_max = lookup_value;
			end
		end
		if(lookup_lower_max > 0.0) begin
			for(int unsigned  x_1 = 0; x_1 < (1 << ADDR_WIDTH_1); x_1++) begin
				automatic int unsigned  idx = (factor_x_0 << ADDR_WIDTH_1) | x_1;
				if(lookup_upper[idx] + lookup_lower_max > max_bound) begin
					lookup_upper[idx] = max_bound - lookup_lower_max;
				end
			end
		end
	end

	// --- Quantize the staged tables into the ROMs --------------------------------
	// Upper: store f(...) - 1 as WORD_WIDTH fractional bits (the leading 1 is
	// implicit). int'(real) rounds to nearest (ties away from zero).
	for(int unsigned  i = 0; i < (1 << ADDR_WIDTH_UPPER); i++) begin
		automatic real  lookup_shifted = (lookup_upper[i] - 1.0) * (1 << WORD_WIDTH);
		automatic int unsigned  lookup_int = int'(lookup_shifted);
		rom_upper[i] = lookup_int[WORD_WIDTH-1:0];
	end

	// Lower: signed value in the same Q0.W fixed-point format as the upper table
	// (so the add lines up bit-for-bit), truncated to its low WORD_WIDTH_LOWER
	// bits. Round to nearest for both signs: the unbiased rounding is more accurate
	// than rounding negatives toward zero, and the underflow lift already keeps the
	// sum >= 1.0 (its target sits one ULP above 1, absorbing the half-ULP the
	// nearest-rounding of the correction can add on the low side).
	for(int unsigned  i = 0; i < (1 << ADDR_WIDTH_LOWER); i++) begin
		automatic real  lookup_shifted = lookup_lower[i] * (1 << WORD_WIDTH);
		automatic int  lookup_int = int'(lookup_shifted);
		rom_lower[i] = lookup_int[WORD_WIDTH_LOWER-1:0];
	end
end

// Isolate input from arbitration between iterations as needed
uwire [31:0]  xx;
uwire  xxvld;
uwire  xxrdy;
if((NUM_NEWTON_STEPS > 0) && STABLE_READINESS && (1 < SUSTAINABLE_INTERVAL) && (SUSTAINABLE_INTERVAL < 9)) begin : genSkid
	queue #(.DATA_WIDTH(32), .ELASTICITY(2)) input_queue (
		.clk, .rst,
		.idat(x), .ivld(xvld), .irdy(xrdy),
		.odat(xx), .ovld(xxvld), .ordy(xxrdy)
	);
end : genSkid
else begin : genReg
	logic [31:0]  X = 'x;
	logic  Vld = 0;
	always_ff @(posedge clk) begin
		if (rst) begin
			X   <= 'x;
			Vld <= 0;
		end
		else if (xxrdy || !Vld) begin
			X   <= x;
			Vld <= xvld;
		end
	end
	assign	xx = X;
	assign	xrdy = xxrdy || !Vld;
	assign	xxvld = Vld;
end : genReg

uwire [ADDR_WIDTH_UPPER-1:0]  addr_upper = xx[23 -: ADDR_WIDTH_UPPER];
uwire [ADDR_WIDTH_LOWER-1:0]  addr_lower = { xx[23 -: (1 + ADDR_WIDTH_0)], xx[(23 - ADDR_WIDTH_UPPER) -: ADDR_WIDTH_2] };
uwire [WORD_WIDTH      -1:0]  lookup_upper = rom_upper[addr_upper];
uwire [WORD_WIDTH_LOWER-1:0]  lookup_lower = rom_lower[addr_lower];

logic [31:0] XX = 'x;
logic  VldDelay = 0;
logic [WORD_WIDTH      -1:0]  LookupUpper = 'x;
logic [WORD_WIDTH_LOWER-1:0]  LookupLower = 'x;

always_ff @(posedge clk) begin
	if(rst) begin
		XX <= 'x;
		VldDelay <= 0;
		LookupUpper <= 'x;
		LookupLower <= 'x;
	end
	else if (xxrdy) begin
		XX <= xx;
		VldDelay <= xxvld;
		LookupUpper <= lookup_upper;
		LookupLower <= lookup_lower;
	end
end

// Sign extend LookupLower. The table-generation step (underflow lift + overflow
// max_bound) keeps the true sum in [1, 2), so the implicit leading one never moves:
// a plain WORD_WIDTH-wide add is enough -- no carry out, no exponent fixup.
uwire [WORD_WIDTH-1:0]  man_sum = LookupUpper + { {(WORD_WIDTH - WORD_WIDTH_LOWER){LookupLower[WORD_WIDTH_LOWER-1]}}, LookupLower };
uwire [22:0]  man_lookup      = (WORD_WIDTH == 23) ? man_sum[22:0] : { man_sum[WORD_WIDTH-1:0], {(23-WORD_WIDTH){1'b0}} };
uwire [ 8:0]  exp_plus_one    = { 1'b0, XX[30:23] } + 9'd1;	// Use 9 bits to handle infinity input properly
uwire [ 7:0]  exp_lookup      = 8'd190 - exp_plus_one[8:1];	// No negative exp_lookup value possible, since exp_plus_one[8:1] <= 127
uwire [31:0]  float_lookup    = { 1'b0, exp_lookup, man_lookup };

if(NUM_NEWTON_STEPS == 0) begin : genPureLookup
	logic [31:0]  R = 'x;
	logic Vld = 0;
	always_ff @(posedge clk) begin
		if(rst) R <= 'x;
		else    R <= float_lookup;
	end
	always_ff @(posedge clk) begin
		if(rst) Vld <= 0;
		else    Vld <= VldDelay;
	end

	assign	r = R;
	assign	rvld = Vld;
	assign	xxrdy = 1;
end : genPureLookup
else begin : genLookupWithNewton
	uwire  xsel;  // Feed new input vs. re-feed for interleaving
	uwire [31:0]  afb;
	uwire [31:0]  a = xsel ? float_lookup : afb;
	uwire [31:0]  b = { XX[31], XX[30:23]-1, XX[22:0]}; // 0.5*x
	uwire [31:0]  c = $shortrealtobits(1.5);

	case(SUSTAINABLE_INTERVAL)
	1: begin : genII1
		localparam int unsigned  DSP_LATENCY = 4;
		localparam int unsigned  LAT = NUM_NEWTON_STEPS*3*DSP_LATENCY;
		if(NUM_NEWTON_STEPS == 1) begin : genII_1step
			logic  Vld[LAT] = '{ default: 0 };
			logic [31:0]  A[8] = '{ default: 'x };
			uwire [31:0]  p[2];
			always_ff @(posedge clk) begin
				if(rst) begin
					Vld <= '{ default: 0 };
					A <= '{ default: 'x };
				end
				else begin
					Vld <= { VldDelay, Vld[0:LAT-2] };
					A <= { a, A[0:6] };
				end
			end
			assign	xsel = 1;
			assign	xxrdy = 1;
			assign	rvld = Vld[LAT-1];

			rsqrtf_dspfp32 #(.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)) DSP0 (
				.clk, .rst,
				.ena('1), .bsel('1), .csel('0),
				.a, .b, .c('x), .d('x),
				.rvld('0), .r(p[0])
			);

			rsqrtf_dspfp32 #(.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)) DSP1 (
				.clk, .rst,
				.ena('1), .bsel('0), .csel('1),
				.a(A[3]), .b('x), .c, .d(p[0]),
				.rvld('0), .r(p[1])
			);

			rsqrtf_dspfp32 #(.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)) DSP2 (
				.clk, .rst,
				.ena('1), .bsel('0), .csel('0),
				.a(A[7]), .b('x), .c('x), .d(p[1]),
				.rvld, .r
			);
		end : genII_1step
		else begin : genII1_2step
			logic  Vld[LAT] = '{ default: 0 };

			logic [31:0]  A[8]  = '{ default: 'x };
			logic [31:0]  B[12] = '{ default: 'x };
			logic [31:0]  Mid[8] = '{ default: 'x };

			uwire [31:0]  p[4];
			uwire [31:0]  mid;

			always_ff @(posedge clk) begin
				if(rst) begin
					Vld <= '{ default: 0 };
					A   <= '{ default: 'x };
					B   <= '{ default: 'x };
					Mid <= '{ default: 'x };
				end
				else begin
					Vld <= { VldDelay, Vld[0:LAT-2] };
					A   <= { a,   A[0:6]   };
					B   <= { b,   B[0:10]  };
					Mid <= { mid, Mid[0:6] };
				end
			end

			assign  xsel  = 1;
			assign  xxrdy = 1;
			assign  rvld  = Vld[LAT-1];

			rsqrtf_dspfp32 #(.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)) DSP0 (
				.clk, .rst,
				.ena('1), .bsel('1), .csel('0),
				.a, .b, .c('x), .d('x),
				.rvld('0), .r(p[0])
			);
			rsqrtf_dspfp32 #(.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)) DSP1 (
				.clk, .rst,
				.ena('1), .bsel('0), .csel('1),
				.a(A[3]), .b('x), .c, .d(p[0]),
				.rvld('0), .r(p[1])
			);
			rsqrtf_dspfp32 #(.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)) DSP2 (
				.clk, .rst,
				.ena('1), .bsel('0), .csel('0),
				.a(A[7]), .b('x), .c('x), .d(p[1]),
				.rvld('0), .r(mid)
			);

			rsqrtf_dspfp32 #(.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)) DSP3 (
				.clk, .rst,
				.ena('1), .bsel('1), .csel('0),
				.a(mid), .b(B[11]), .c('x), .d('x),
				.rvld('0), .r(p[2])
			);
			rsqrtf_dspfp32 #(.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)) DSP4 (
				.clk, .rst,
				.ena('1), .bsel('0), .csel('1),
				.a(Mid[3]), .b('x), .c, .d(p[2]),
				.rvld('0), .r(p[3])
			);
			rsqrtf_dspfp32 #(.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)) DSP5 (
				.clk, .rst,
				.ena('1), .bsel('0), .csel('0),
				.a(Mid[7]), .b('x), .c('x), .d(p[3]),
				.rvld, .r
			);
		end : genII1_2step
	end : genII1
	2: begin : genII2

		logic  Vld[12] = '{ default: 0 };
		always_ff @(posedge clk) begin
			if(rst)  Vld <= '{ default: 0 };
			else     Vld <= { xxrdy && VldDelay, Vld[0:10] };
		end

		logic [31:0]  A[8] = '{ default: 'x };
		always_ff @(posedge clk) begin
			if(rst)  A <= '{ default: 'x };
			else     A <= { a, A[0:6] };
		end

		assign	rvld = Vld[11];
		assign	xxrdy = !Vld[7];
		assign	xsel = xxrdy;
		assign	afb = A[7];

		uwire [31:0]  p;  // Second DSP Output
		rsqrtf_dspfp32 #(.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)) DSP0 (
			.clk, .rst,
			.ena('1), .bsel(xsel), .csel('0),
			.a, .b, .c('x), .d(p),
			.rvld, .r
		);

		rsqrtf_dspfp32 #(.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)) DSP1 (
			.clk, .rst,
			.ena('1), .bsel('0), .csel('1),
			.a(A[3]), .b('x), .c, .d(r),
			.rvld('0), .r(p)
		);
	end : genII2
	default: begin : genSharedDSP
		uwire  aload;
		uwire  bsel;
		uwire  csel;

		if(SUSTAINABLE_INTERVAL < 9) begin : genInterleave
			typedef enum logic [1:0] {
							// bsel/3  csel/1
				IDLE  = 2'b11, //   1       x
				ITER1 = 2'b00, //   0       0
				ITER2 = 2'b01, //   0       1
				ITER3 = 2'b10, //   1       0
				BSEL  = 2'b1x,
				CSEL  = 2'bx1
			} maturity_t;

			maturity_t  Maturity[4] = '{ default: IDLE };
			logic [31:0]  A[4] = '{ default: 'x };
			always_ff @(posedge clk) begin
				if(rst) begin
					Maturity <= '{ default: IDLE };
					A <= '{ default: 'x };
				end
				else begin
					unique casex(Maturity[3])
					ITER1:  Maturity[0] <= ITER2;
					ITER2:  Maturity[0] <= ITER3;
					ITER3,
					IDLE:   Maturity[0] <= VldDelay? ITER1 : IDLE;
					endcase
					Maturity[1:3] <= Maturity[0:2];
					A <= { a, A[0:2] };
				end
			end
			assign	bsel = Maturity[3] ==? BSEL;
			assign	csel = Maturity[1] ==? CSEL;
			assign	xsel = bsel;
			assign	xxrdy = bsel;
			assign	rvld = Maturity[3] ==? ITER3;
			assign	aload = 1;
			assign	afb = A[3];
		end : genInterleave
		else if(SUSTAINABLE_INTERVAL < 12) begin : genOverlapped
			logic [3:0]  Cnt  = 8;
			logic [3:0]  RVld = '0;
			uwire  cnt7 = Cnt ==? 4'bx111;
			uwire  cnt8 = Cnt ==? 4'b1xxx;
			always_ff @(posedge clk) begin
				if(rst) begin
					Cnt <= 8;
					RVld <= '0;
				end
				else begin
					Cnt <= Cnt + (!cnt8? 1 : VldDelay? 8 : 0);
					RVld <= { cnt7, RVld[3:1] };
				end
			end
			assign	bsel = Cnt[3];
			assign	csel = Cnt[2];
			assign	xsel = 1;
			assign	xxrdy = bsel;
			assign	rvld = RVld[0];
			assign	aload = bsel;
		end : genOverlapped
		else begin : genExclusive
			logic signed [3:0]  Cnt = -1;
			logic  RVld = 0;
			uwire  cnt10 = Cnt ==? 4'b101x;
			always_ff @(posedge clk) begin
				if(rst) begin
					Cnt <= -1;
					RVld <= 0;
				end
				else begin
					Cnt <= Cnt + (cnt10? 'b101 : VldDelay || !bsel);
					RVld <= cnt10;
				end
			end
			assign	bsel = &Cnt[3:2];
			assign	csel = Cnt[2];
			assign	xsel = 1;
			assign	xxrdy = bsel;
			assign	rvld = RVld;
			assign	aload = bsel;
		end : genExclusive

		rsqrtf_dspfp32 #(.FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)) DSPFP32_inst (
			.clk, .rst,
			.ena(aload), .bsel, .csel,
			.a, .b, .c, .d(r),
			.rvld, .r
		);
	end : genSharedDSP
	endcase
end : genLookupWithNewton

endmodule : rsqrt_bipartite


// ================================================================================================================
// ================================================================================================================
// ================================================================================================================


// Local DSP instantiation wrapper.
module rsqrtf_dspfp32 #(
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
			P4 <= CSel3? $shortrealtobits(1.5 - $bitstoshortreal(M[3])) : M[3];
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

endmodule : rsqrtf_dspfp32
