module exp_wrapper #(
	int unsigned  SIMD,
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

	localparam int unsigned  LATENCY = 1;

	logic [LATENCY-1:0]  Vld = '0;
	uwire  enable = ordy || !Vld[LATENCY-1];
	if(LATENCY == 1) begin : gVld1
		always_ff @(posedge clk) begin
			if(rst)         Vld <= '0;
			else if(enable) Vld <= kfvld;
		end
	end : gVld1
	else begin : gVldN
		always_ff @(posedge clk) begin
			if(rst)         Vld <= '0;
			else if(enable) Vld <= { Vld[LATENCY-2:0], kfvld };
		end
	end : gVldN
	assign	kfrdy = enable;
	assign	ovld  = Vld[LATENCY-1];

	for(genvar  i = 0; i < SIMD; i++) begin : gLane

		//-----------------------------------------------------------------
		// Exponent delay
		//-----------------------------------------------------------------
		logic [LATENCY-1:0][7:0]  KPipe = '{ default: 'x };
		always_ff @(posedge clk) begin
			if(rst)         KPipe <= '{ default: 'x };
			else if(enable) begin
				KPipe[0] <= kdat[i];
				for(int  s = 1; s < LATENCY; s++)  KPipe[s] <= KPipe[s-1];
			end
		end
		uwire [7:0]  kdat_dly = KPipe[LATENCY-1];

		//-----------------------------------------------------------------
		// Mantissa transform -> Replace!
		//-----------------------------------------------------------------
		logic [22:0]  MdatR = 'x;
		always_ff @(posedge clk) begin
			if(rst)         MdatR <= 'x;
			else if(enable) MdatR <= fdat[i];
		end
		uwire [22:0]  mdat = MdatR;

		//-----------------------------------------------------------------
		// Assemble result
		//-----------------------------------------------------------------
		assign	odat[i] = { 1'b0, kdat_dly, mdat };

	end : gLane

endmodule : exp_wrapper
