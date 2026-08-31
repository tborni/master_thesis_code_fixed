module exp_lookup #(
	int unsigned  SIMD,
	int unsigned  ADDR_WIDTH = 10,
	int unsigned  WORD_WIDTH = 10,
	bit  EXCLUDE_POS = 0,   // 1: assume input in (-inf, 0]
	bit  FORCE_BEHAVIORAL = 0,

	parameter  RAM_STYLE = "distributed"	// Allowed: "heuristic", "auto", "block", "distributed", "registers", "ultra", "mixed"
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
		if(ADDR_WIDTH == 0 || ADDR_WIDTH > 23) begin
			$error("ADDR_WIDTH (%0d) must be in [1, 23].", ADDR_WIDTH);
			$finish;
		end
		if(WORD_WIDTH == 0 || WORD_WIDTH > 23) begin
			$error("WORD_WIDTH (%0d) must be in [1, 23].", WORD_WIDTH);
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

			// RMSRE-optimal lookup value for f(x) = 2^x over the subinterval
			// [x_lo, x_lo + d] with x_lo = value_min and d = value_range, using
			// the closed form c* = 2^{x_lo + 1} / (1 + 2^{-d}) (see thesis
			// Sec. 4.1.1). The exponential is tabulated in base two after range
			// reduction, so no additional scaling factor is needed here.
			automatic shortreal  lookup_value = shortreal'((2.0 ** (value_min + 1.0)) / (1.0 + 2.0 ** (-value_range)));
			//automatic shortreal  lookup_value = shortreal'(2.0 ** value_max - 2.0 ** value_min) / ($ln(2) * value_range);
			//automatic shortreal  lookup_value = shortreal'(2.0 ** (value_min + 0.5*value_range));
			automatic logic [31:0]  lookup_bits = $shortrealtobits(lookup_value);

			// round_nearest
			if(WORD_WIDTH == 23) begin
				rom[i] = lookup_bits[22 -: WORD_WIDTH];
			end
			else begin
				automatic logic [23:0]  rounded = {1'b0, lookup_bits[22:0]} + (24'd1 << (22 - WORD_WIDTH));
				rom[i] = rounded[23] ? '1 : rounded[22 -: WORD_WIDTH];
			end
		end
	end

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
		// Mantissa transform
		//-----------------------------------------------------------------
		uwire [ADDR_WIDTH-1:0]  addr = fdat[i][22 -: ADDR_WIDTH];
		logic [WORD_WIDTH-1:0]  RomQ = 'x;
		always_ff @(posedge clk) begin
			if(rst)         RomQ <= 'x;
			else if(enable) RomQ <= rom[addr];
		end
		uwire [22:0]  mdat = (WORD_WIDTH == 23) ? RomQ : { RomQ, {(23 - WORD_WIDTH){1'b0}} };

		//-----------------------------------------------------------------
		// Assemble result
		//-----------------------------------------------------------------
		assign	odat[i] = { 1'b0, kdat_dly, mdat };

	end : gLane

endmodule : exp_lookup
