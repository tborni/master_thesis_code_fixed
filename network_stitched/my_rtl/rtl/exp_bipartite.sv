module exp_bipartite #(
	int unsigned  SIMD,
	bit  EXCLUDE_POS = 0,   // 1: assume input in (-inf, 0]
	bit  FORCE_BEHAVIORAL = 0,

	// Bipartite table geometry.
	//
	// fdat[22:0] = f in [0,1) is split into three contiguous fields:
	//   x_0 = fdat[22 -: ADDR_WIDTH_0]                                 (top)
	//   x_1 = fdat[22-ADDR_WIDTH_0 -: ADDR_WIDTH_1]                    (middle)
	//   x_2 = fdat[22-ADDR_WIDTH_0-ADDR_WIDTH_1 -: ADDR_WIDTH_2]       (lower)
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

	parameter  RAM_STYLE = "distributed"	// Allowed: "auto", "block", "distributed", "registers", "ultra", "mixed"
)(
	input	logic  clk,
	input	logic  rst,

	input	logic [SIMD-1:0][31:0]  idat,
	input	logic  ivld,
	output	logic  irdy,

	output	logic [SIMD-1:0][31:0]  odat,
	output	logic  ovld,
	input	logic  ordy
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
	// Bipartite tables for f(x) = 2^x on x in [0, 1).
	//
	// Following the original bipartite-table paper, the input x is split
	// into three contiguous fields x_0 | x_1 | x_2 and the two tables
	// approximate the Taylor split
	//   f(x_0 + x_1 + x_2) ~= f(x_0 + x_1 + delta_2 + delta_3)
	//                       + f'(x_0 + delta_1 + delta_2 + delta_3)
	//                         * (x_2 - delta_2)
	// where the deltas are the midpoints of the truncated tails (so the
	// linearization is centered, halving the worst-case error vs. a naive
	// expansion around x_0 alone).
	//
	// f(x) = 2^x lands in [1, 2) for x in [0, 1), so the result's leading
	// 1 is fixed -- only the fractional part is stored. Concretely
	// rom_upper stores  f(...) - 1  (WORD_WIDTH fractional bits, unsigned)
	// and rom_lower stores  f'(...) * (x_2 - delta_2)  in the same Q0.W
	// fixed-point format, sign-extended (a signed two's-complement value
	// truncated to WORD_WIDTH_LOWER bits with bit [WORD_WIDTH_LOWER-1]
	// serving as the sign).
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

		automatic real  ln2 = 0.6931471805599453;

		// Real-valued staging tables. We build the exact (un-quantized) table
		// values first, apply the underflow-guard lift on the upper table,
		// and only then quantize into the ROMs. This mirrors rsqrt_bipartite:
		// the lift has to compare/adjust real values, before fixed-point
		// truncation, to guarantee upper + lower >= 1 at every address.
		//
		// NOTE: lookup_upper stages the *full* value f(...) = 2^(...) in
		// [1, 2) (not f(...) - 1). Keeping the leading 1 here lets the lift
		// compare against 1.0 exactly as in rsqrt; the implicit-1 subtraction
		// happens in the quantization pass below.
		automatic real  lookup_upper[0:(1 << ADDR_WIDTH_UPPER)-1];
		automatic real  lookup_lower[0:(1 << ADDR_WIDTH_LOWER)-1];

		// --- Upper table: f(x_0 + x_1 + delta_2 + delta_3) ---------------
		// Address layout:  i = (x_0 index << ADDR_WIDTH_1) | x_1 index.
		for(int unsigned  i = 0; i < (1 << ADDR_WIDTH_UPPER); i++) begin
			automatic real  x_0 = real'((i >> ADDR_WIDTH_1) & ((1 << ADDR_WIDTH_0) - 1))
								/ real'(1 << ADDR_WIDTH_0);
			automatic real  x_1 = real'(i & ((1 << ADDR_WIDTH_1) - 1))
								/ real'(1 << (ADDR_WIDTH_0 + ADDR_WIDTH_1));
			lookup_upper[i] = $pow(2.0, x_0 + x_1 + delta_2 + delta_3);
		end

		// --- Lower table: f'(x_0 + delta_1 + delta_2 + delta_3) * (x_2 - delta_2) ---
		// f'(x) = ln(2) * 2^x. Address layout:
		//   i = (x_0 index << ADDR_WIDTH_2) | x_2 index.
		for(int unsigned  i = 0; i < (1 << ADDR_WIDTH_LOWER); i++) begin
			automatic real  x_0 = real'((i >> ADDR_WIDTH_2) & ((1 << ADDR_WIDTH_0) - 1))
								/ real'(1 << ADDR_WIDTH_0);
			automatic real  x_2 = real'(i & ((1 << ADDR_WIDTH_2) - 1))
								/ real'(1 << (ADDR_WIDTH_0 + ADDR_WIDTH_1 + ADDR_WIDTH_2));
			automatic real  derivative = ln2 * $pow(2.0, x_0 + delta_1 + delta_2 + delta_3);
			lookup_lower[i] = derivative * (x_2 - delta_2);
		end

		// --- Underflow-guard lift (mirrors rsqrt_bipartite) --------------
		// The lower table's centered correction is most negative at x_2 = 0;
		// at the bottom of the domain (x_0 = x_1 = 0) the upper value is so
		// close to 1 that upper + lower would dip below 1.0, which the
		// unsigned mantissa field (implicit leading 1) would wrap to ~2.0
		// (~100% error at fdat = 0). For each x_0 group, find the most
		// negative lower entry and lift any upper entry in that group whose
		// worst-case sum would fall below the min_bound, so 1.0 <= upper + lower
		// holds at every address. The min_bound sits one ULP above 1
		// (1 + 2^-WORD_WIDTH): now that the lower table rounds to nearest for
		// both signs, that ULP absorbs the up-to-half-ULP the correction can
		// lose on the low side, keeping the stored sum >= 1.0 without a
		// toward-zero bias. (No `factor` dimension here -- unlike 1/sqrt,
		// 2^x has no even/odd-exponent split.)
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
		// f(x) = 2^x is increasing (f' > 0), so the lower correction
		// f'*(x_2 - delta_2) is most positive at the top of x_2; near the top
		// of the domain (max x_0, x_1) the upper value 2^(almost 1) is close
		// to 2, so upper + lower could reach 2.0, leaving [1, 2) (the implicit
		// leading one would wrap into the exponent). For each x_0 group, find
		// the most positive lower entry and lower any upper entry whose worst-
		// case sum would exceed the max_bound, so 1.0 <= upper + lower < 2.0 holds
		// at every address and the plain WORD_WIDTH-wide add stays valid. The
		// max_bound is two ULPs below 2 (2 - 2^(1-WORD_WIDTH)): one for the largest
		// representable value in [1, 2), plus one so the independent round-to-
		// nearest quantization of the upper and lower entries (each up to half
		// a ULP) can never push the stored sum back up to 2^WORD_WIDTH.
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
		// can add on the low side). Matches rsqrt_bipartite.
		for(int unsigned  i = 0; i < (1 << ADDR_WIDTH_LOWER); i++) begin
			automatic real  lookup_shifted = lookup_lower[i] * (1 << WORD_WIDTH);
			automatic int  lookup_int = int'(lookup_shifted);
			rom_lower[i] = lookup_int[WORD_WIDTH_LOWER-1:0];
		end
	end

	//---------------------------------------------------------------------
	// Range reduction: idat -> (k, f) with f in [0, 1).
	//---------------------------------------------------------------------
	uwire [SIMD-1:0][ 7:0]  kdat;
	uwire [SIMD-1:0][22:0]  fdat;
	uwire  kfvld;
	uwire  kfrdy;

	range_reduction #(
		.SIMD(SIMD), .EXCLUDE_POS(EXCLUDE_POS), .FORCE_BEHAVIORAL(FORCE_BEHAVIORAL)
	) rr_inst (
		.clk, .rst,
		.idat, .ivld, .irdy,
		.kdat, .fdat, .kfvld(kfvld), .kfrdy(kfrdy)
	);

	//---------------------------------------------------------------------
	// Local pipeline (per SIMD lane the data path is independent, but the
	// valid/handshake is shared):
	//   stage 0: register addr_upper/addr_lower (and kdat for alignment)
	//   stage 1: ROM read    -> LookupUpper / LookupLower (and kdat)
	//   stage 2: sum + assemble -> output flop (MdatR, KdatR)
	// Total LATENCY = 3 cycles inside this wrapper.
	//---------------------------------------------------------------------
	localparam int unsigned  LATENCY = 3;

	logic [LATENCY-1:0]  Vld = '0;
	uwire  enable = ordy || !Vld[LATENCY-1];
	always_ff @(posedge clk) begin
		if(rst)         Vld <= '0;
		else if(enable) Vld <= { Vld[LATENCY-2:0], kfvld };
	end
	assign	kfrdy = enable;
	assign	ovld  = Vld[LATENCY-1];

	for(genvar  i = 0; i < SIMD; i++) begin : gLane

		//-----------------------------------------------------------------
		// Address split: x_0 (top), x_1 (mid), x_2 (low) inside fdat[22:0].
		//-----------------------------------------------------------------
		uwire [ADDR_WIDTH_UPPER-1:0]  addr_upper = fdat[i][22 -: ADDR_WIDTH_UPPER];
		uwire [ADDR_WIDTH_LOWER-1:0]  addr_lower = {
			fdat[i][22 -: ADDR_WIDTH_0],
			fdat[i][(22 - ADDR_WIDTH_0 - ADDR_WIDTH_1) -: ADDR_WIDTH_2]
		};

		//-----------------------------------------------------------------
		// Stage 0: register the addresses to break the path from the
		// range_reduction output flops into the ROM input registers.
		//-----------------------------------------------------------------
		logic [ADDR_WIDTH_UPPER-1:0]  AddrUpperR = '0;
		logic [ADDR_WIDTH_LOWER-1:0]  AddrLowerR = '0;
		always_ff @(posedge clk) begin
			if(rst) begin
				AddrUpperR <= '0;
				AddrLowerR <= '0;
			end
			else if(enable) begin
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
			else if(enable) begin
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
		// WORD_WIDTH bits before adding. The true sum is guaranteed to
		// remain in [1,2) (so the implicit leading 1 doesn't move), which
		// means a plain WORD_WIDTH-wide add is enough -- no carry out, no
		// exponent fixup.
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
		// kdat must travel alongside fdat through the local pipeline so
		// it lines up with mdat at the output flop.
		//-----------------------------------------------------------------
		logic [LATENCY-2:0][7:0]  KPipe = '{ default: '0 };
		always_ff @(posedge clk) begin
			if(rst)         KPipe <= '{ default: '0 };
			else if(enable) begin
				KPipe[0] <= kdat[i];
				for(int  s = 1; s < LATENCY-1; s++)  KPipe[s] <= KPipe[s-1];
			end
		end

		//-----------------------------------------------------------------
		// Output register stage. Both kdat and mdat leave the module
		// straight out of a flop.
		//-----------------------------------------------------------------
		logic [ 7:0]  KdatR = '0;
		logic [22:0]  MdatR = '0;
		always_ff @(posedge clk) begin
			if(rst) begin
				KdatR <= '0;
				MdatR <= '0;
			end
			else if(enable) begin
				KdatR <= KPipe[LATENCY-2];
				MdatR <= mdat_next;
			end
		end

		//-----------------------------------------------------------------
		// Assemble result.
		//-----------------------------------------------------------------
		assign	odat[i] = { 1'b0, KdatR, MdatR };

	end : gLane

endmodule : exp_bipartite
