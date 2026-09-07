/****************************************************************************
 * Range reduction for fp32 exp(x):
 *   prod = x * log2(e)
 *   k    = floor(prod)    -> integer, becomes biased exponent
 *   f    = (prod - k)       -> fraction, becomes mantissa input to subsequent stage, in [0,1)
 *
 * Outputs:
 *   kdat = (k + 127)  (biased exponent field, in {0,...,254})
 *   fdat = f          (only the 23 bit mantissa part)
 *
 * Pipeline stages (latency = 6):
 *   0   1   2     3        4     5
 *  mul mul mul ProdFP32  ShiftR out (KDat/FDat)
 ***************************************************************************/

module range_reduction #(
	int unsigned  SIMD,
	bit  EXCLUDE_POS = 0,	// 1: assume input in (-inf, 0]
	bit  FORCE_BEHAVIORAL = 0
)(
	input	logic  clk,
	input	logic  rst,

	input	logic [SIMD-1:0][31:0]  idat,
	input	logic  ivld,
	output	logic  irdy,

	output	logic [SIMD-1:0][ 7:0]  kdat,
	output	logic [SIMD-1:0][22:0]  fdat,
	output	logic  kfvld,
	input	logic  kfrdy
);

	/**
	 * AXI-handshake
	 *	- Vld[s] = 1 means stage s currently holds a valid sample
	 *	- The whole pipeline advances exactly when enable is asserted
	 */
	localparam int unsigned  LATENCY = 6;
	logic [LATENCY-1:0]  Vld = '0;
	uwire  enable = kfrdy || !Vld[LATENCY-1];
	always_ff @(posedge clk) begin
		if(rst)         Vld <= '0;
		else if(enable) Vld <= { Vld[LATENCY-2:0], ivld };
	end
	assign	irdy  = enable;
	assign	kfvld = Vld[LATENCY-1];

	localparam shortreal  LOG2E = 1.4426950408889634;

	for(genvar  i = 0; i < SIMD; i++) begin : gLane

		//-----------------------------------------------------------------
		// Stages 0-2: multiplication: prod_fp32 = idat * LOG2E
		//-----------------------------------------------------------------
		uwire [31:0]  prod_fp32;
		if(FORCE_BEHAVIORAL) begin : genBehavMul
			localparam int unsigned  DSP_LATENCY = 3;
			logic [31:0]  ProdPipe[DSP_LATENCY] = '{ default: 'x };
			always_ff @(posedge clk) begin
				if(rst) begin
					for(int  k = 0; k < DSP_LATENCY; k++)  ProdPipe[k] <= 'x;
				end
				else if(enable) begin
					automatic shortreal  fx = $bitstoshortreal(idat[i]);
					ProdPipe[0] <= $shortrealtobits(fx * LOG2E);
					for(int  k = 1; k < DSP_LATENCY; k++)  ProdPipe[k] <= ProdPipe[k-1];
				end
			end
			assign	prod_fp32 = ProdPipe[DSP_LATENCY-1];
		end : genBehavMul
		else begin : genDSPMul
			uwire [31:0]  a = idat[i];
			uwire [31:0]  b = $shortrealtobits(LOG2E);

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
				.FPA_PREG(0),
				.FPBREG(1),
				.FPCREG(0),
				.FPDREG(0),
				.FPMPIPEREG(1),
				.FPM_PREG(1),
				.FPOPMREG(0),
				.INMODEREG(0),
				.RESET_MODE("SYNC")
			) DSPFP32_inst (
				.ACOUT_EXP(), .ACOUT_MAN(), .ACOUT_SIGN(),
				.BCOUT_EXP(), .BCOUT_MAN(), .BCOUT_SIGN(),
				.PCOUT(),
				.FPM_INVALID(), .FPM_OVERFLOW(), .FPM_UNDERFLOW(), .FPM_OUT(prod_fp32),
				.FPA_INVALID(), .FPA_OVERFLOW(), .FPA_UNDERFLOW(), .FPA_OUT(),
				.ACIN_EXP('x), .ACIN_MAN('x), .ACIN_SIGN('x),
				.BCIN_EXP('x), .BCIN_MAN('x), .BCIN_SIGN('x),
				.PCIN('x),
				.CLK(clk),
				.FPINMODE('1),
				.FPOPMODE(7'b000_0000),
				.A_SIGN(a[31]), .A_EXP(a[30:23]), .A_MAN(a[22:0]),
				.B_SIGN(b[31]), .B_EXP(b[30:23]), .B_MAN(b[22:0]),
				.C('x),
				.D_SIGN('x), .D_EXP('x), .D_MAN('x),
				.ASYNC_RST('0),
				.CEA1('0), .CEA2(enable),
				.CEB(enable), .CEC('0), .CED('0),
				.CEFPA('0), .CEFPINMODE('0), .CEFPM(enable), .CEFPMPIPE(enable), .CEFPOPMODE('0),
				.RSTA(rst), .RSTB(rst), .RSTC('0), .RSTD('0),
				.RSTFPA('0), .RSTFPINMODE('0), .RSTFPM(rst), .RSTFPMPIPE(rst), .RSTFPOPMODE('0)
			);
		end : genDSPMul

		//-----------------------------------------------------------------
		// Stage 3: register prod_fp32
		//-----------------------------------------------------------------
		logic [31:0]  ProdFP32 = 'x;
		always_ff @(posedge clk) begin
			if(rst)         ProdFP32 <= 'x;
			else if(enable) ProdFP32 <= prod_fp32;
		end

		uwire [ 7:0]  exp = ProdFP32[30:23];
		uwire [22:0]  man = ProdFP32[22:0];
		uwire [23:0]  full_man = { 1'b1, man };	// 1.man

		uwire  neg = EXCLUDE_POS? 1'b1 : ProdFP32[31];

		// Shifting logic to split input into integer and fractional part
		uwire  sat_hi = (exp >= 8'd134);	// |prod| >= 128 -> saturate high
		logic [ 6:0]  int_part;
		logic [22:0]  fr_part;
		always_comb begin
			automatic logic [ 4:0]  shamt = (exp < 8'd103)? 5'd30 : 5'(8'd133 - exp);
			automatic logic [29:0]  base  = { full_man, 6'd0 };
			automatic logic [29:0]  z     = base >> shamt;

			int_part = z[29:23];	// floor(|prod|), 0..127
			fr_part  = z[22: 0];	// top 23 fraction bits
		end

		//-----------------------------------------------------------------
		// Stage 4: register the barrel-shift outputs
		//-----------------------------------------------------------------
		logic         SatHi   = 'x;
		logic         Neg     = 'x;
		logic [ 6:0]  IntPart = 'x;
		logic [22:0]  FrPart  = 'x;
		always_ff @(posedge clk) begin
			if(rst) begin
				SatHi   <= 'x;
				Neg     <= 'x;
				IntPart <= 'x;
				FrPart  <= 'x;
			end
			else if(enable) begin
				SatHi   <= sat_hi;
				Neg     <= neg;
				IntPart <= int_part;
				FrPart  <= fr_part;
			end
		end

		//-----------------------------------------------------------------
		// Determine k and f based on the shifter outputs
		//-----------------------------------------------------------------
		logic [ 7:0]  kdat_pre;
		logic [22:0]  fdat_pre;
		always_comb begin
			if(SatHi) begin
				// |prod| >= 128: saturate
				// Negative: underflow-to-zero for [<= 2^(-128)] (kdat 0)
				// Positive: max-normal value (kdat 254)
				kdat_pre = Neg? 8'd0 : 8'd254;
				fdat_pre = 23'd0;
			end
			else if(!Neg) begin
				// prod >= 0: simple truncation
				// Add 127 to k to account for the bias
				kdat_pre = 8'd127 + 8'(IntPart);
				fdat_pre = FrPart;
			end
			else begin
				// prod < 0: floor is more complicated
				// k: truncate but subtract one if mantissa is not 0
				// f = 1 - truncated_frac
				automatic logic [7:0]  ceil_m = 8'(IntPart) + 8'(FrPart != 0);	// ceil(|prod|), negate later
				if(ceil_m > 8'd127) begin
					// ceil(|prod|) == 128: underflow-to-zero for [< 2^(-127)] (kdat 0)
					kdat_pre = 8'd0;
					fdat_pre = 23'd0;
				end
				else begin
					kdat_pre = 8'd127 - ceil_m;	// Add bias of 127
					fdat_pre = 23'(-FrPart);	// f = 1 - truncated_frac
				end
			end
		end

		//-----------------------------------------------------------------
		// Stage 5: output register
		//-----------------------------------------------------------------
		logic [ 7:0]  KDat = 'x;
		logic [22:0]  FDat = 'x;
		always_ff @(posedge clk) begin
			if(rst) begin
				KDat <= 'x;
				FDat <= 'x;
			end
			else if(enable) begin
				KDat <= kdat_pre;
				FDat <= fdat_pre;
			end
		end

		assign	kdat[i] = KDat;
		assign	fdat[i] = FDat;

	end : gLane

endmodule : range_reduction
