module exp_splitting #(
	int unsigned  SIMD,
	bit  EXCLUDE_POS = 0,   // 1: assume input in (-inf, 0]
	bit  FORCE_BEHAVIORAL = 0,

	// Splitting table geometry.
	//
	// fdat[22:0] = f in [0,1) is split into three contiguous fields:
	//   x_0 = fdat[22                          -: ADDR_WIDTH_0]   (top)
	//   x_1 = fdat[22-ADDR_WIDTH_0             -: ADDR_WIDTH_1]   (middle)
	//   x_2 = fdat[22-ADDR_WIDTH_0-ADDR_WIDTH_1-: ADDR_WIDTH_2]   (lower)
	//
	// Each table j is addressed by x_j alone (2^ADDR_WIDTH_j entries) and
	// conceptually stores the WORD_WIDTH most-significant fractional bits
	// of 2^x_j (round-to-nearest from fp32). Because every x_j lies in
	// [0,1), every 2^x_j lies in [1,2), so the leading 1 is implicit.
	//
	// Optimisation for tables 1 and 2: because x_1 and x_2 are themselves
	// very small, 2^x_j - 1 has a known number Z_j of leading zero bits.
	// We therefore store only the bottom WORD_WIDTH - Z_j bits per entry
	// and re-inject the Z_j zeros at read time. The leading-zero count
	// is derived analytically from the upper bound
	//   v_max_j = 2^( 2^-S_{j-1} - 2^-S_j )
	// and pinned down to the nearest fp32 representable value (with a
	// safety +1 ULP if the down-rounded fp32 sits below v_max_j).
	//
	// Reconstruction fuses the three factors into ONE DSP58:
	//   factor m_0 -> goes on the multiplier B port as (1 + m_0).
	//   factors m_1, m_2 -> go on the pre-adder D and A ports; the
	//     pre-adder evaluates (1 + m_1 + m_2), which approximates
	//     (1 + m_1)(1 + m_2) up to the m_1 * m_2 cross term (bounded by
	//     ln(2)^2 * 2^(-2*AW0) << 2^-23 for the default geometry).
	//   The multiplier then yields (1 + m_0) * (1 + m_1 + m_2) ~= 2^f.
	//
	// WORD_WIDTH must be < 23 so {0, 1, Lookup0} fits in the 24-bit
	// B datapath with a sign-guard bit (the DSP58 multiplier is signed).
	int unsigned  ADDR_WIDTH_0 = 8,
	int unsigned  ADDR_WIDTH_1 = 8,
	int unsigned  ADDR_WIDTH_2 = 7,
	int unsigned  WORD_WIDTH   = 22,   // must be < 23 (B-port sign-guard bit)

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
		if(ADDR_WIDTH_0 + ADDR_WIDTH_1 + ADDR_WIDTH_2 > 23) begin
			$error("ADDR_WIDTH_0+ADDR_WIDTH_1+ADDR_WIDTH_2 (%0d) must be <= 23 (the fp32 mantissa width).",
			       ADDR_WIDTH_0 + ADDR_WIDTH_1 + ADDR_WIDTH_2);
			$finish;
		end
		if(ADDR_WIDTH_0 == 0 || ADDR_WIDTH_1 == 0 || ADDR_WIDTH_2 == 0) begin
			$error("All ADDR_WIDTH_{0,1,2} must be >= 1.");
			$finish;
		end
		if(WORD_WIDTH == 0) begin
			$error("WORD_WIDTH must be >= 1.");
			$finish;
		end
		// WORD_WIDTH must leave room above for two safety bits in the
		// 24-bit DSP58 B datapath: the implicit leading 1 of (1 + m_0)
		// (bit WORD_WIDTH) and a zero sign-extension guard (bit
		// WORD_WIDTH + 1). So the encoded value occupies bits
		// [WORD_WIDTH+1 : 0], i.e. WORD_WIDTH + 2 bits total, which
		// must fit in 24 -> WORD_WIDTH <= 22 i.e. WORD_WIDTH < 23.
		if(WORD_WIDTH >= 23) begin
			$error("WORD_WIDTH (%0d) must be < 23 (the 24-bit B datapath needs an implicit-1 bit and a sign-guard bit on top).", WORD_WIDTH);
			$finish;
		end
		if(!(RAM_STYLE == "auto" || RAM_STYLE == "block" || RAM_STYLE == "distributed"
				|| RAM_STYLE == "registers" || RAM_STYLE == "ultra" || RAM_STYLE == "mixed")) begin
			$error("RAM_STYLE (%s) is invalid. Allowed: auto, block, distributed, registers, ultra, mixed.", RAM_STYLE);
			$finish;
		end
	end

	//---------------------------------------------------------------------
	// Three single-input tables for 2^x_j on x_j in [0, 2^-S_{j-1}).
	//
	// Storage convention (matches exp_lookup.sv): every 2^x_j lies in
	// [1, 2), so its fp32 representation has biased exponent 127 and the
	// 23-bit mantissa field IS the fractional part. We capture that
	// mantissa to fp32 precision via $shortrealtobits, then round-to-
	// nearest down to WORD_WIDTH bits using a +half-ULP add with carry
	// to the implicit leading 1 (which saturates to all-ones, i.e. the
	// representable value just below 2).
	//
	// Tables 1 and 2 take advantage of the fact that 2^x_j - 1 has a
	// known number Z_j of leading zero bits in its WORD_WIDTH-wide
	// mantissa: those bits are NOT stored. Each entry holds the bottom
	// WORD_WIDTH - Z_j bits of the would-be WORD_WIDTH-wide mantissa.
	// Z_j is derived from the upper bound
	//   v_max_j = 2^( 2^-S_{j-1} - 2^-S_j )
	// rounded to the nearest fp32 (with a +1 ULP safety bump if fp32
	// rounded down) -- so any actual entry is guaranteed <= v_max_j
	// after fp32 rounding, hence has at least Z_j leading zeros in its
	// fp32 mantissa.
	//---------------------------------------------------------------------
	localparam int unsigned  SHIFT_0 = ADDR_WIDTH_0;
	localparam int unsigned  SHIFT_1 = ADDR_WIDTH_0 + ADDR_WIDTH_1;
	localparam int unsigned  SHIFT_2 = ADDR_WIDTH_0 + ADDR_WIDTH_1 + ADDR_WIDTH_2;

	// Compute the number of guaranteed leading zero bits in the fp32
	// mantissa of any entry of a single-piece table for 2^x on
	//   x in [ 0, 2^-(s_lo) - 2^-(s_hi) ]
	// where s_lo < s_hi. The upper bound is
	//   v_max = 2^(2^-s_lo - 2^-s_hi)
	// We round v_max to fp32, bump +1 ULP if the rounded value sits
	// below the true v_max (so the result is a valid upper bound), and
	// then count the leading zero bits of its 23-bit mantissa field.
	function automatic int unsigned compute_leading_zeros(input int unsigned s_lo, input int unsigned s_hi);
		automatic real         x_max_real = 2.0 ** (-real'(s_lo)) - 2.0 ** (-real'(s_hi));
		automatic real         v_max_real = 2.0 ** x_max_real;
		automatic shortreal    v_max_sr   = shortreal'(v_max_real);
		automatic logic [31:0] v_max_bits = $shortrealtobits(v_max_sr);
		// Safety: if fp32 rounded down, the true v_max_real lies above
		// v_max_sr -- step one ULP up to recover an upper bound.
		if(real'(v_max_sr) < v_max_real)  v_max_bits = v_max_bits + 1;
		// v_max in [1, 2) -> biased exp = 127, mantissa = v_max_bits[22:0].
		// Walk from MSB downward; first set bit terminates the count.
		for(int p = 22; p >= 0; p--) begin
			if(v_max_bits[p])  return  22 - p;
		end
		return  23;	// mantissa is all zero (table degenerates to v == 1)
	endfunction : compute_leading_zeros

	// Z_*_RAW: the actual leading-zero count from the analytical bound.
	// Z_*: clamped to WORD_WIDTH-1 so downstream elaboration (ROM widths,
	// part-selects) never sees a value that would produce a non-positive
	// stored width or an out-of-range bit index. If RAW exceeds the
	// clamp, the initial-block check below fires at simulation start.
	localparam int unsigned  Z_1_RAW = compute_leading_zeros(SHIFT_0, SHIFT_1);
	localparam int unsigned  Z_2_RAW = compute_leading_zeros(SHIFT_1, SHIFT_2);
	localparam int unsigned  Z_1     = (Z_1_RAW >= WORD_WIDTH)? WORD_WIDTH - 1 : Z_1_RAW;
	localparam int unsigned  Z_2     = (Z_2_RAW >= WORD_WIDTH)? WORD_WIDTH - 1 : Z_2_RAW;

	// Number of bits actually stored per entry in each table.
	localparam int unsigned  WW_1 = WORD_WIDTH - Z_1;
	localparam int unsigned  WW_2 = WORD_WIDTH - Z_2;

	initial begin
		if(Z_1_RAW >= WORD_WIDTH) begin
			$error("Table 1 collapses to zero useful bits (Z_1=%0d >= WORD_WIDTH=%0d): increase WORD_WIDTH or reduce ADDR_WIDTH_0.", Z_1_RAW, WORD_WIDTH);
			$finish;
		end
		if(Z_2_RAW >= WORD_WIDTH) begin
			$error("Table 2 collapses to zero useful bits (Z_2=%0d >= WORD_WIDTH=%0d): increase WORD_WIDTH or reduce ADDR_WIDTH_0+ADDR_WIDTH_1.", Z_2_RAW, WORD_WIDTH);
			$finish;
		end
	end

	(* RAM_STYLE = RAM_STYLE *)
	logic [WORD_WIDTH-1:0]  rom_0 [0:(1 << ADDR_WIDTH_0)-1];
	(* RAM_STYLE = RAM_STYLE *)
	logic [WW_1-1:0]        rom_1 [0:(1 << ADDR_WIDTH_1)-1];
	(* RAM_STYLE = RAM_STYLE *)
	logic [WW_2-1:0]        rom_2 [0:(1 << ADDR_WIDTH_2)-1];
	initial begin
		// Table 0: x_0 = i / 2^SHIFT_0, stores top WORD_WIDTH fractional
		// bits of 2^x_0 (round-to-nearest, ties carry through).
		for(int unsigned  i = 0; i < (1 << ADDR_WIDTH_0); i++) begin
			automatic real            x           = real'(i) / real'(1 << SHIFT_0);
			automatic shortreal       v           = shortreal'(2.0 ** x);
			automatic logic [31:0]    bits        = $shortrealtobits(v);
			automatic logic [23:0]    rounded     = {1'b0, bits[22:0]} + (24'd1 << (22 - WORD_WIDTH));
			rom_0[i] = rounded[23] ? '1 : rounded[22 -: WORD_WIDTH];
		end

		// Table 1: x_1 = i / 2^SHIFT_1. The conceptual WORD_WIDTH-wide
		// mantissa of 2^x_1 has Z_1 known leading zeros; only the
		// bottom WW_1 = WORD_WIDTH - Z_1 bits carry information and are
		// stored. The Z_1 zeros are re-injected at read time.
		for(int unsigned  i = 0; i < (1 << ADDR_WIDTH_1); i++) begin
			automatic real            x           = real'(i) / real'(1 << SHIFT_1);
			automatic shortreal       v           = shortreal'(2.0 ** x);
			automatic logic [31:0]    bits        = $shortrealtobits(v);
			automatic logic [23:0]    rounded     = {1'b0, bits[22:0]} + (24'd1 << (22 - WORD_WIDTH));
			automatic logic [WORD_WIDTH-1:0]  full_mantissa = rounded[23] ? '1 : rounded[22 -: WORD_WIDTH];

			rom_1[i] = full_mantissa[WW_1-1:0];
		end

		// Table 2: x_2 = i / 2^SHIFT_2, stores bottom WW_2 bits of the
		// WORD_WIDTH-wide mantissa of 2^x_2 (with Z_2 leading zeros
		// re-injected at read time).
		for(int unsigned  i = 0; i < (1 << ADDR_WIDTH_2); i++) begin
			automatic real            x           = real'(i) / real'(1 << SHIFT_2);
			automatic shortreal       v           = shortreal'(2.0 ** x);
			automatic logic [31:0]    bits        = $shortrealtobits(v);
			automatic logic [23:0]    rounded     = {1'b0, bits[22:0]} + (24'd1 << (22 - WORD_WIDTH));
			automatic logic [WORD_WIDTH-1:0]  full_mantissa = rounded[23] ? '1 : rounded[22 -: WORD_WIDTH];

			rom_2[i] = full_mantissa[WW_2-1:0];
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
	//   stage 0  : synchronous ROM reads -> Lookup0/1/2
	//   stage 1  : DSP58 BREG (= B = {0, 1, Lookup0}) and ADREG
	//              (= D + A = {0, 1, Z_1 zeros, Lookup1}
	//                       + {0,    Z_2 zeros, Lookup2});
	//              pre-adder evaluates (1 + m_1 + m_2) * 2^WORD_WIDTH
	//   stage 2  : DSP58 MREG (= AD * B, integer multiply)
	//   stage 3  : DSP58 PREG (= M, passthrough P = M+0)
	// kdat travels through a parallel 4-deep shift register so it lines
	// up with the DSP P output. Total LATENCY = 4 cycles.
	//---------------------------------------------------------------------
	localparam int unsigned  LATENCY = 4;

	// Implicit-1 bit position of the multiplier output. Tables 1 and 2
	// place their (conceptually WORD_WIDTH-wide) mantissa at the same
	// effective bit position, so the pre-adder sum (1 + m_1 + m_2) is
	// scaled by 2^WORD_WIDTH; the multiplier output is then scaled by
	// 2^(2*WORD_WIDTH).
	localparam int unsigned  NSHIFT = 2 * WORD_WIDTH;

	// DSP58 datapath widths (matches mvu.sv naming for the same primitive).
	localparam int unsigned  A_WIDTH = 27;
	localparam int unsigned  B_WIDTH = 24;
	localparam int unsigned  P_WIDTH = 58;

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
		// Address split: x_0 (top) | x_1 (mid) | x_2 (low) inside fdat[22:0].
		// The three fields sit in contiguous bit positions; remaining LSBs
		// (if any) are simply discarded -- they contribute a residual <
		// 2^-(ADDR_WIDTH_0+ADDR_WIDTH_1+ADDR_WIDTH_2) to f and only show up
		// as quantization error in the downstream approximation.
		//-----------------------------------------------------------------
		uwire [ADDR_WIDTH_0-1:0]  addr_0 = fdat[i][22 -: ADDR_WIDTH_0];
		uwire [ADDR_WIDTH_1-1:0]  addr_1 = fdat[i][22 - ADDR_WIDTH_0 -: ADDR_WIDTH_1];
		uwire [ADDR_WIDTH_2-1:0]  addr_2 = fdat[i][22 - ADDR_WIDTH_0 - ADDR_WIDTH_1 -: ADDR_WIDTH_2];

		//-----------------------------------------------------------------
		// Stage 0: synchronous ROM reads. These three flops are the
		// "packed 3 results" referenced in the spec; each represents the
		// fractional bits (post-decimal) of 2^x_j with the implicit
		// leading 1 to be reintroduced when the factors are combined.
		//-----------------------------------------------------------------
		logic [WORD_WIDTH-1:0]  Lookup0 = '0;
		logic [WW_1-1:0]        Lookup1 = '0;
		logic [WW_2-1:0]        Lookup2 = '0;
		always_ff @(posedge clk) begin
			if(rst) begin
				Lookup0 <= '0;
				Lookup1 <= '0;
				Lookup2 <= '0;
			end
			else if(enable) begin
				Lookup0 <= rom_0[addr_0];
				Lookup1 <= rom_1[addr_1];
				Lookup2 <= rom_2[addr_2];
			end
		end

		//-----------------------------------------------------------------
		// Datapath assembly for the DSP58.
		//
		// Bit layout (B is 24 wide, A/D are 27 wide; all interpreted as
		// signed two's complement by the DSP integer multiplier, but we
		// keep the top bit zero so the value is read as positive):
		//
		//   B = { 1'b0, 1'b1, Lookup0 }                              (WORD_WIDTH + 2 bits)
		//       \____/  \_/   \_____/
		//       sign   impl.  m_0 mantissa
		//       guard  1      fraction          -> value = (1 + m_0) * 2^WORD_WIDTH
		//
		//   D = { 1'b0, 1'b1, {Z_1{1'b0}}, Lookup1 }                 (WORD_WIDTH + 2 bits)
		//       \____/  \_/   \__________/ \_____/
		//       sign   impl.  re-injected   m_1 mantissa
		//       guard  1      leading 0s    LSBs (WW_1 bits)
		//                                   -> value = (1 + m_1) * 2^WORD_WIDTH
		//
		//   A = { 1'b0, {Z_2{1'b0}}, Lookup2 }                       (WORD_WIDTH + 1 bits)
		//       \____/  \__________/ \_____/
		//       sign    re-injected  m_2 mantissa
		//       guard   leading 0s   LSBs (WW_2 bits)
		//                                   -> value = m_2 * 2^WORD_WIDTH
		//
		// Pre-adder: AD = D + A = (1 + m_1 + m_2) * 2^WORD_WIDTH
		//   (We APPROXIMATE (1 + m_1)(1 + m_2) ~= 1 + m_1 + m_2 here:
		//   the dropped m_1 * m_2 term is bounded by ln(2)^2 * 2^(-2*AW0)
		//   which is < 2^-23 for the default geometry (AW0 = 8).)
		//
		// Multiplier: M = AD * B = (1+m_0) * (1+m_1+m_2) * 2^NSHIFT
		//             with NSHIFT = 2 * WORD_WIDTH
		//
		// The true result (1+m_0)(1+m_1+m_2) lies in [1, 2), so the
		// implicit leading 1 of the result sits at bit NSHIFT of M and
		// the 23 mantissa bits we want are bits [NSHIFT-1 : NSHIFT-23].
		// When NSHIFT < 23 we have fewer than 23 fractional bits and
		// pad zeros on the right.
		//-----------------------------------------------------------------

		// B-datapath assembly (B_WIDTH bits). The value (1 + m_0) * 2^WORD_WIDTH
		// occupies bits [WORD_WIDTH : 0] (WORD_WIDTH + 1 bits). Bits
		// [B_WIDTH-1 : WORD_WIDTH+1] are zero -- at least one such bit
		// (bit B_WIDTH-1) is the mandatory sign-guard for the DSP58's
		// signed multiplier.
		uwire [B_WIDTH-1:0]  bb;
		assign  bb = { {(B_WIDTH - 1 - WORD_WIDTH){1'b0}}, 1'b1, Lookup0 };

		// D-datapath assembly (A_WIDTH bits): the value (1 + m_1) * 2^WORD_WIDTH
		// occupies bits [WORD_WIDTH : 0]. The leading-1 sits at bit
		// WORD_WIDTH; below it, Z_1 known-zero mantissa bits are
		// re-injected and then the stored Lookup1 (WW_1 = WORD_WIDTH - Z_1
		// bits) fills the LSBs. Above bit WORD_WIDTH, leading zeros pad
		// out to A_WIDTH (at least 3 bits, with bit A_WIDTH-1 acting as
		// the sign guard).
		uwire [A_WIDTH-1:0]  dd;
		assign  dd = { {(A_WIDTH - 1 - WORD_WIDTH){1'b0}}, 1'b1, {Z_1{1'b0}}, Lookup1 };

		// A-datapath assembly (A_WIDTH bits): m_2 * 2^WORD_WIDTH
		// occupies bits [WORD_WIDTH-1 : 0]. No implicit 1; Z_2 known-zero
		// bits are re-injected, then Lookup2 (WW_2 = WORD_WIDTH - Z_2
		// bits) fills the LSBs. Above bit WORD_WIDTH-1, leading zeros
		// pad out to A_WIDTH.
		uwire [A_WIDTH-1:0]  aa;
		assign  aa = { {(A_WIDTH - WORD_WIDTH){1'b0}}, {Z_2{1'b0}}, Lookup2 };

		//-----------------------------------------------------------------
		// DSP58 instance (or behavioral 3-stage model when
		// FORCE_BEHAVIORAL). Pipeline registers used:
		//   BREG  = 1, ADREG = 1   (stage 1)
		//   MREG  = 1              (stage 2)
		//   PREG  = 1              (stage 3)
		// AREG and DREG are 0 so A and D arrive at the pre-adder in the
		// same cycle and the ADREG captures their sum. INMODE is a
		// constant and not registered; OPMODE is registered but driven
		// from a constant (the desired effective value is realised via
		// IS_OPMODE_INVERTED so it holds from the first clock edge).
		//-----------------------------------------------------------------
		uwire [P_WIDTH-1:0]  pp;

		// Note: Since the product B * AD is computed, with both operands
		//       structurally positive (top bit zero), no signed handling
		//       is required beyond the DSP's intrinsic signed multiply.
		if(FORCE_BEHAVIORAL) begin : genBehav

			// Stage #1: Input Refine
			logic signed [B_WIDTH-1:0]  B1  = 0;
			always_ff @(posedge clk) begin
				if(rst)          B1  <= 0;
				else if(enable)  B1  <= bb;
			end

			logic signed [A_WIDTH-1:0]  AD1 = 0;
			always_ff @(posedge clk) begin
				if(rst)          AD1 <= 0;
				else if(enable)  AD1 <= dd + aa;
			end

			// Stage #2: Multiply
			logic signed [A_WIDTH+B_WIDTH-1:0]  M2 = 0;
			always_ff @(posedge clk) begin
				if(rst)          M2 <= 0;
				else if(enable)  M2 <=
// synthesis translate off
					(B1 === '0) || (AD1 === '0)? 0 :
// synthesis translate on
					B1 * AD1;
			end

			// Stage #3: P register (P = M, no accumulation)
			logic signed [P_WIDTH-1:0]  P3 = 0;
			always_ff @(posedge clk) begin
				if(rst)          P3 <= 0;
				else if(enable)  P3 <= M2;
			end

			assign	pp = P3;
		end : genBehav
`ifndef VERILATOR
		else begin : genDSP
			// OPMODE_INVERSION carries the constant OPMODE we want (P = M):
			// with the OPMODE input pin held at 0 and OPMODEREG=1, the
			// register's output XORed against this mask yields the
			// effective OPMODE = 7'b000_01_01 (Z=0, Y=M, X=M, W=0)
			// = P = M every cycle, including the post-reset warmup.
			localparam logic [6:0]  OPMODE_INVERSION = 7'b000_01_01;
			uwire [6:0]  opmode = '0;
			DSP58 #(
				// Feature Control Attributes: Data Path Selection
				.AMULTSEL("AD"),		// Selects A input to multiplier (A, AD)
				.A_INPUT("DIRECT"),		// Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
				.BMULTSEL("B"),			// Selects B input to multiplier (AD, B)
				.B_INPUT("DIRECT"),		// Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
				.DSP_MODE("INT24"),
				.PREADDINSEL("A"),			// Selects input to pre-adder (A, B)
				.RND('0),					// Rounding Constant
				.USE_MULT("MULTIPLY"),		// Select multiplier usage (DYNAMIC, MULTIPLY, NONE)
				.USE_SIMD("ONE58"),			// SIMD selection (FOUR12, ONE58, TWO24)
				.USE_WIDEXOR("FALSE"),		// Use the Wide XOR function (FALSE, TRUE)
				.XORSIMD("XOR24_34_58_116"),// Mode of operation for the Wide XOR (XOR12_22, XOR24_34_58_116)

				// Pattern Detector Attributes: Pattern Detection Configuration
				.AUTORESET_PATDET("NO_RESET"),		// NO_RESET, RESET_MATCH, RESET_NOT_MATCH
				.AUTORESET_PRIORITY("RESET"),		// Priority of AUTORESET vs. CEP (CEP, RESET).
				.MASK('1),							// 58-bit mask value for pattern detect (1=ignore)
				.PATTERN('0),						// 58-bit pattern match for pattern detect
				.SEL_MASK("MASK"),					// C, MASK, ROUNDING_MODE1, ROUNDING_MODE2
				.SEL_PATTERN("PATTERN"),			// Select pattern value (C, PATTERN)
				.USE_PATTERN_DETECT("NO_PATDET"),	// Enable pattern detect (NO_PATDET, PATDET)

				// Programmable Inversion Attributes: Specifies built-in programmable inversion on specific pins
				.IS_ALUMODE_INVERTED('0),							// Optional inversion for ALUMODE
				.IS_CARRYIN_INVERTED('0),							// Optional inversion for CARRYIN
				.IS_CLK_INVERTED('0),								// Optional inversion for CLK
				.IS_INMODE_INVERTED('0),							// Optional inversion for INMODE
				.IS_NEGATE_INVERTED('0),							// Optional inversion for NEGATE
				.IS_OPMODE_INVERTED({ 2'b00, OPMODE_INVERSION}),	// Optional inversion for OPMODE
				.IS_RSTALLCARRYIN_INVERTED('0),						// Optional inversion for RSTALLCARRYIN
				.IS_RSTALUMODE_INVERTED('0),						// Optional inversion for RSTALUMODE
				.IS_RSTA_INVERTED('0),								// Optional inversion for RSTA
				.IS_RSTB_INVERTED('0),								// Optional inversion for RSTB
				.IS_RSTCTRL_INVERTED('0),							// Optional inversion for STCONJUGATE_A
				.IS_RSTC_INVERTED('0),								// Optional inversion for RSTC
				.IS_RSTD_INVERTED('0),								// Optional inversion for RSTD
				.IS_RSTINMODE_INVERTED('0),							// Optional inversion for RSTINMODE
				.IS_RSTM_INVERTED('0),								// Optional inversion for RSTM
				.IS_RSTP_INVERTED('0),								// Optional inversion for RSTP

				// Register Control Attributes: Pipeline Register Configuration
				.ACASCREG(0),		// Number of pipeline stages between A/ACIN and ACOUT (0-2)
				.ADREG(1),			// Pipeline stages for pre-adder (0-1)
				.ALUMODEREG(0),		// Pipeline stages for ALUMODE (0-1)
				.AREG(0),			// Pipeline stages for A (0-2)
				.BCASCREG(1),		// Number of pipeline stages between B/BCIN and BCOUT (0-2)
				.BREG(1),			// Pipeline stages for B (0-2)
				.CARRYINREG(0),		// Pipeline stages for CARRYIN (0-1)
				.CARRYINSELREG(0),	// Pipeline stages for CARRYINSEL (0-1)
				.CREG(0),			// Pipeline stages for C (0-1)
				.DREG(0),			// Pipeline stages for D (0-1)
				.INMODEREG(0),		// Pipeline stages for INMODE (0-1)
				.MREG(1),			// Multiplier pipeline stages (0-1)
				.OPMODEREG(1),		// Pipeline stages for OPMODE (0-1)
				.PREG(1),			// Number of pipeline stages for P (0-1)
				.RESET_MODE("SYNC")	// Selection of synchronous or asynchronous reset. (ASYNC, SYNC)
			) dsp (
				// Cascade outputs: Cascade Ports
				.ACOUT(),			// 34-bit output: A port cascade
				.BCOUT(),			// 24-bit output: B cascade
				.CARRYCASCOUT(),	// 1-bit output: Cascade carry
				.MULTSIGNOUT(),		// 1-bit output: Multiplier sign cascade
				.PCOUT(),			// 58-bit output: Cascade output

				// Control outputs: Control Inputs/Status Bits
				.OVERFLOW(),		// 1-bit output: Overflow in add/acc
				.PATTERNBDETECT(),	// 1-bit output: Pattern bar detect
				.PATTERNDETECT(),	// 1-bit output: Pattern detect
				.UNDERFLOW(),		// 1-bit output: Underflow in add/acc

				// Data outputs: Data Ports
				.CARRYOUT(),		// 4-bit output: Carry
				.P(pp),				// 58-bit output: Primary data
				.XOROUT(),			// 8-bit output: XOR data

				// Cascade inputs: Cascade Ports
				.ACIN('x),			// 34-bit input: A cascade data
				.BCIN('x),			// 24-bit input: B cascade
				.CARRYCASCIN('x),	// 1-bit input: Cascade carry
				.MULTSIGNIN('x),	// 1-bit input: Multiplier sign cascade
				.PCIN('x),			// 58-bit input: P cascade

				// Control inputs: Control Inputs/Status Bits
				.CLK(clk),					// 1-bit input: Clock
				.ALUMODE(4'h0),				// 4-bit input: ALU control
				.CARRYINSEL('0),			// 3-bit input: Carry select
				.INMODE(5'b00100),			// 5-bit input: INMODE control (pre-adder = D + A)
				.NEGATE('0),				// 3-bit input: Negates the input of the multiplier
				.OPMODE({ 2'b00, opmode }),	// 9-bit input: Operation mode

				// Data inputs: Data Ports
				.A({7'b0, aa}),				// 34-bit input: A data
				.B(bb),						// 24-bit input: B data
				.C('x),						// 58-bit input: C data
				.CARRYIN('0),				// 1-bit input: Carry-in
				.D(dd),						// 27-bit input: D data

				// Reset/Clock Enable inputs: Reset/Clock Enable Inputs
				.ASYNC_RST('0),		// 1-bit input: Asynchronous reset for all registers
				.CEA1('0),			// 1-bit input: Clock enable for 1st stage AREG
				.CEA2('0),			// 1-bit input: Clock enable for 2nd stage AREG
				.CEAD(enable),		// 1-bit input: Clock enable for ADREG
				.CEALUMODE('0),		// 1-bit input: Clock enable for ALUMODE
				.CEB1('0),			// 1-bit input: Clock enable for 1st stage BREG
				.CEB2(enable),		// 1-bit input: Clock enable for 2nd stage BREG
				.CEC('0),			// 1-bit input: Clock enable for CREG
				.CECARRYIN('0),		// 1-bit input: Clock enable for CARRYINREG
				.CECTRL(enable),	// 1-bit input: Clock enable for OPMODEREG and CARRYINSELREG
				.CED('0),			// 1-bit input: Clock enable for DREG
				.CEINMODE('0),		// 1-bit input: Clock enable for INMODEREG
				.CEM(enable),		// 1-bit input: Clock enable for MREG
				.CEP(enable),		// 1-bit input: Clock enable for PREG
				.RSTA('0),			// 1-bit input: Reset for AREG
				.RSTB(rst),			// 1-bit input: Reset for BREG
				.RSTC('0),			// 1-bit input: Reset for CREG
				.RSTD(rst),			// 1-bit input: Reset for DREG and ADREG
				.RSTALLCARRYIN('0),	// 1-bit input: Reset for CARRYINREG
				.RSTALUMODE('0),	// 1-bit input: Reset for ALUMODEREG
				.RSTCTRL('0),		// 1-bit input: Reset for OPMODEREG and CARRYINSELREG
				.RSTINMODE('0),		// 1-bit input: Reset for INMODE register
				.RSTM(rst),			// 1-bit input: Reset for MREG
				.RSTP(rst)			// 1-bit input: Reset for PREG
			);
		end : genDSP
`endif

		//-----------------------------------------------------------------
		// Extract the 23-bit mantissa from the DSP product.
		// The implicit leading 1 of the result sits at bit NSHIFT;
		// the mantissa bits are immediately below it.
		//-----------------------------------------------------------------
		uwire [22:0]  mdat;
		if(NSHIFT >= 23) begin : gMdat_full
			assign  mdat = pp[NSHIFT-1 -: 23];
		end : gMdat_full
		else begin : gMdat_pad
			assign  mdat = { pp[NSHIFT-1:0], {(23 - NSHIFT){1'b0}} };
		end : gMdat_pad

		//-----------------------------------------------------------------
		// kdat must travel alongside fdat through the local pipeline so
		// it lines up with mdat at the module output. Shift register of
		// depth LATENCY = 4. The final stage drives odat straight out of
		// a flop, alongside the registered DSP P output.
		//-----------------------------------------------------------------
		logic [LATENCY-1:0][7:0]  KPipe = '{ default: '0 };
		always_ff @(posedge clk) begin
			if(rst)         KPipe <= '{ default: '0 };
			else if(enable) begin
				KPipe[0] <= kdat[i];
				for(int  s = 1; s < LATENCY; s++)  KPipe[s] <= KPipe[s-1];
			end
		end

		//-----------------------------------------------------------------
		// Assemble result. kdat is straight from the KPipe tail flop;
		// mdat is straight from the DSP's PREG (via the bit slice).
		//-----------------------------------------------------------------
		assign	odat[i] = { 1'b0, KPipe[LATENCY-1], mdat };

	end : gLane

endmodule : exp_splitting
