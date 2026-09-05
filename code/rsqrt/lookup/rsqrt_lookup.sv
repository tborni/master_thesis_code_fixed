module rsqrt_lookup #(
	int unsigned  ADDR_WIDTH = 10,
	int unsigned  WORD_WIDTH = 10,
	int unsigned  NUM_NEWTON_STEPS = 0,	// Allowed values: 0, 1 or 2 (only for II = 1)
	int unsigned  SUSTAINABLE_INTERVAL = 1,	// Average II sustained over 12 Cycles
	// Guarantee readiness at II, do not expose delays of arbitrating between iterations:
	//  - by intermittent input delays or
	//  - by revoking readiness.
	bit  STABLE_READINESS = 1,
	bit  FORCE_BEHAVIORAL = 0,

	parameter  RAM_STYLE = "heuristic"	// Allowed: "heuristic", "auto", "block", "distributed", "registers", "ultra", "mixed"
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
	if(ADDR_WIDTH >= 25) begin
		$error("ADDR_WIDTH (%0d) must be less than 25.", ADDR_WIDTH);
		$finish;
	end
	if(WORD_WIDTH >= 24) begin
		$error("WORD_WIDTH (%0d) must be less than 24.", WORD_WIDTH);
		$finish;
	end
	if (NUM_NEWTON_STEPS >= 3) begin
		$error("NUM_NEWTON_STEPS (%0d) must be 0, 1 or 2.", NUM_NEWTON_STEPS);
		$finish;
	end
	if (NUM_NEWTON_STEPS == 2 && SUSTAINABLE_INTERVAL != 1) begin
		$error("SUSTAINABLE_INTERVAL (%0d) must be 1 for NUM_NEWTON_STEPS = 2", SUSTAINABLE_INTERVAL);
		$finish;
	end
	if(SUSTAINABLE_INTERVAL == 0) begin
		$error("SUSTAINABLE_INTERVAL (%0d) must be positive.", SUSTAINABLE_INTERVAL);
		$finish;
	end
	if (!(RAM_STYLE == "heuristic" || RAM_STYLE == "auto" || RAM_STYLE == "block" || RAM_STYLE == "distributed"
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
		// Determine the RMSRE-optimal lookup value for the subinterval addressed
		// by the high part bits, using the closed form c* = 4[(x_lo+d)^{3/2} -
		// x_lo^{3/2}] / (3 d (2 x_lo + d)) for f(x) = x^{-1/2} (see thesis
		// Sec. 4.1.1). value_min is the subinterval start x_lo and value_range
		// its width d; the leading 2.0 factor is the range-reduction scaling
		// that maps the result into (1,2].
		automatic real  factor_from_lsb_exp = 1.0 + 1.0*((i & (1 << (ADDR_WIDTH - 1))) == 0);
		automatic int unsigned  man         = i & ((1 << (ADDR_WIDTH - 1)) - 1);
		automatic real  value_min           = factor_from_lsb_exp * (1.0 + real'(man) / (1 << (ADDR_WIDTH - 1)));
		automatic real  value_range         = factor_from_lsb_exp * (1.0 / (1 << (ADDR_WIDTH - 1)) - 1.0 / (1 << 23));
		automatic real  value_max           = value_min + value_range;
		automatic shortreal  lookup_value   = shortreal'(2.0 * (4.0 * (value_max*$sqrt(value_max) - value_min*$sqrt(value_min))
		                                                         / (3.0 * value_range * (2.0*value_min + value_range))));
		automatic logic [31:0]  lookup_bits = $shortrealtobits(lookup_value);

		rom[i] = lookup_bits[22 -: WORD_WIDTH];	// Truncate lsb bits and reconstruct later using mid point of possible value range
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

uwire [ADDR_WIDTH-1:0]  addr = xx[23 -: ADDR_WIDTH];
uwire [ 8:0]  exp_plus_one = { 1'b0, xx[30:23] } + 9'd1;	// Use 9 bits to handle infinity input properly
uwire [ 7:0]  exp_lookup = 8'd190 - exp_plus_one[8:1];	// No negative exp_lookup value possible, since exp_plus_one[8:1] <= 127
// Full reconstruction for (WORD_WIDTH == 23), otherwise reconstruct using mid point of possible output value range
uwire [22:0]  man_lookup = (WORD_WIDTH == 23) ? rom[addr] : { rom[addr], 1'b1, {(23 - WORD_WIDTH - 1){1'b0}} };
uwire [31:0]  float_lookup = { 1'b0, exp_lookup, man_lookup };

if(NUM_NEWTON_STEPS == 0) begin : genPureLookup
	logic [31:0]  R = 'x;
	logic Vld = 0;
	always_ff @(posedge clk) begin
		if(rst) R <= 'x;
		else    R <= float_lookup;
	end
	always_ff @(posedge clk) begin
		if(rst) Vld <= 0;
		else    Vld <= xxvld;
	end

	assign	r = R;
	assign	rvld = Vld;
	assign	xxrdy = 1;
end : genPureLookup
else begin : genLookupWithNewton
	uwire  xsel;  // Feed new input vs. re-feed for interleaving
	uwire [31:0]  afb;
	uwire [31:0]  a = xsel ? float_lookup : afb;
	uwire [31:0]  b = { xx[31], xx[30:23]-1, xx[22:0]}; // 0.5*x
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
					Vld <= { xxvld, Vld[0:LAT-2] };
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
					Vld <= { xxvld, Vld[0:LAT-2] };
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
			else     Vld <= { xxrdy && xxvld, Vld[0:10] };
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
					IDLE:   Maturity[0] <= xxvld? ITER1 : IDLE;
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
					Cnt <= Cnt + (!cnt8? 1 : xxvld? 8 : 0);
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
					Cnt <= Cnt + (cnt10? 'b101 : xxvld || !bsel);
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

endmodule : rsqrt_lookup


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
