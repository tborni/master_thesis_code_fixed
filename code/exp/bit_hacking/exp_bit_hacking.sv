module exp_bit_hacking #(
	int unsigned  SIMD,
	shortreal     A = 12102203.0,
	int unsigned  D = 1064866072,
	bit  EXCLUDE_POS = 0,   // 1: assume input in (-inf, 0]
	bit  FORCE_BEHAVIORAL = 0
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

	// Total pipeline depth: 3 cycles in the DSP (AREG + FPMPIPE + FPM_PREG)
	// + cast register + add register.
	localparam int unsigned  TOTAL_LATENCY = 5;

	//-----------------------------------------------------------------
	// Global pipeline enable (skid-free stall).
	// The pipeline advances whenever the final stage (sum_q) is empty or
	// is being drained this cycle.  When stalled, every stage holds.
	//-----------------------------------------------------------------
	logic [SIMD-1:0][31:0]  sum_q;
	logic [TOTAL_LATENCY-1:0]  vld_sr;

	uwire  ovld_i = vld_sr[TOTAL_LATENCY-1];
	uwire  enable = !ovld_i || ordy;

	assign  irdy = enable;
	assign  ovld = ovld_i;
	assign  odat = sum_q;

	//-----------------------------------------------------------------
	// Valid shift register tracking in-flight samples through the
	// fixed-latency datapath.  vld_sr[0] is the freshly-accepted sample.
	//-----------------------------------------------------------------
	always_ff @(posedge clk) begin
		if(rst)  vld_sr <= '0;
		else if(enable) begin
			vld_sr <= {vld_sr[TOTAL_LATENCY-2:0], ivld};
		end
	end

	for(genvar  i = 0; i < SIMD; i++) begin : gLane
		//-----------------------------------------------------------------
		// DSPFP32: prod_fp32 = idat * A    (3-cycle fp32 multiply on FPM_OUT)
		//-----------------------------------------------------------------
		uwire [31:0]  prod_fp32;
		if(FORCE_BEHAVIORAL) begin : genBehav
			// Behavioral reference: emulate the 3-cycle DSP latency with a
			// shift register of shortreal products.
			localparam int unsigned  DSP_LATENCY = 3;
			logic [31:0]  prod_pipe [DSP_LATENCY];
			always_ff @(posedge clk) begin
				if(rst) begin
					for(int  k = 0; k < DSP_LATENCY; k++)  prod_pipe[k] <= 'x;
				end
				else if(enable) begin
					automatic shortreal  fx = $bitstoshortreal(idat[i]);
					prod_pipe[0] <= $shortrealtobits(fx * A);
					for(int  k = 1; k < DSP_LATENCY; k++)  prod_pipe[k] <= prod_pipe[k-1];
				end
			end
			assign  prod_fp32 = prod_pipe[DSP_LATENCY-1];
		end : genBehav
		else begin : genDSP
			// fp32 bit pattern of the multiplicative constant A, driven on the
			// 'B' port; the streaming sample arrives on 'A'.
			localparam logic [31:0]  A_BITS = $shortrealtobits(A);

			uwire [31:0]  a = idat[i];
			uwire [31:0]  b = A_BITS;

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
				.FPINMODE('1),       // Select B path (not D)
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
		end : genDSP

		//-----------------------------------------------------------------
		// Stage: fp32 -> int32 (combinational), then register.
		// Truncating cast with saturation; treat the int32 reinterpretation
		// of the cast as the index argument to Schraudolph's reconstruction.
		//-----------------------------------------------------------------
		uwire signed [31:0]  prod_int;
		fp32_to_int #(.K(32)) u_cast (
			.fval(prod_fp32),
			.ival(prod_int)
		);

		logic [31:0]  prod_int_q;
		always_ff @(posedge clk) begin
			if(rst)         prod_int_q <= 'x;
			else if(enable) prod_int_q <= prod_int;
		end

		//-----------------------------------------------------------------
		// Stage: int32 add with the Schraudolph offset D.
		// The 32-bit sum is reinterpreted bitwise as an fp32 result
		// (treat_as_float is a no-op in hardware).
		//
		// Out-of-range saturation: Schraudolph's reconstruction is only
		// valid while the sum lands in a normal fp32 exponent field
		// [1, 254], i.e. input x ~ [-87.33, +88.72].  Outside that band:
		//   * a negative int32 sum  => underflow  => 0
		//   * exponent field == 255 => overflow   => FLT_MAX (0x7F7FFFFF)
		//
		// When EXCLUDE_POS=1, the caller guarantees x <= 0, so prod_int_q
		// is non-positive and prod_int_q + D <= D < 0x7F800000.  The
		// overflow path is unreachable and the int32 add cannot wrap, so
		// the 33-bit extension collapses to a plain int32 sign check.
		//-----------------------------------------------------------------
		if(EXCLUDE_POS) begin : gNoPos
			uwire [31:0]  sum32 = prod_int_q + D[31:0];
			always_ff @(posedge clk) begin
				if(rst)         sum_q[i] <= 'x;
				else if(enable) sum_q[i] <= sum32[31]? 32'h0000_0000 : sum32;
			end
		end : gNoPos
		else begin : gFull
			uwire signed [32:0]  sum_ext = $signed({prod_int_q[31], prod_int_q}) + $signed({1'b0, D[31:0]});
			always_ff @(posedge clk) begin
				if(rst)  sum_q[i] <= 'x;
				else if(enable) begin
					if(sum_ext[32])                  sum_q[i] <= 32'h0000_0000;
					else if(sum_ext[31] || sum_ext[30:23] == 8'hFF)
					                                 sum_q[i] <= 32'h7F7F_FFFF;
					else                             sum_q[i] <= sum_ext[31:0];
				end
			end
		end : gFull
	end : gLane

endmodule : exp_bit_hacking
