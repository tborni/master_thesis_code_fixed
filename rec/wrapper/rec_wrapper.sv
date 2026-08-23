module rec_wrapper #(
	bit  FORCE_BEHAVIORAL = 0
)(
	input	logic  clk,
	input	logic  rst,

	input	logic [31:0]  idat,
	input	logic  ivld,
	output	logic  irdy,

	output	logic [31:0]  odat,
	output	logic  ovld,
	input	logic  ordy
);
	localparam int unsigned  LATENCY = 1;

	uwire [ 7:0]  e_in = idat[30:23];
	uwire [22:0]  m_in = idat[22: 0];	

	logic [LATENCY-1:0]  Vld = '0;
	uwire  enable = ordy || !Vld[LATENCY-1];
	if(LATENCY == 1) begin : gVld1
		always_ff @(posedge clk) begin
			if(rst)         Vld <= '0;
			else if(enable) Vld <= ivld;
		end
	end : gVld1
	else begin : gVldN
		always_ff @(posedge clk) begin
			if(rst)         Vld <= '0;
			else if(enable) Vld <= { Vld[LATENCY-2:0], ivld };
		end
	end : gVldN
	assign	irdy = enable;
	assign	ovld = Vld[LATENCY-1];

	//-----------------------------------------------------------------
	// Exponent
	//-----------------------------------------------------------------
	uwire [ 7:0]  e_out = 8'd253 - e_in;	// e_in in {1, ..., 126}, result in {127, ..., 252}
	logic [LATENCY-1:0][7:0]  EPipe = '{ default: 'x };
	always_ff @(posedge clk) begin
		if(rst)         EPipe <= '{ default: 'x };
		else if(enable) begin
			EPipe[0] <= e_out;
			for(int  s = 1; s < LATENCY; s++)  EPipe[s] <= EPipe[s-1];
		end
	end
	uwire [7:0]  e_dly = EPipe[LATENCY-1];

	//-----------------------------------------------------------------
	// Mantissa transform -> Replace!
	//-----------------------------------------------------------------
	logic [22:0]  MdatR = 'x;
	always_ff @(posedge clk) begin
		if(rst)         MdatR <= 'x;
		else if(enable) MdatR <= m_in;
	end
	uwire [22:0]  mdat = MdatR;

	//-----------------------------------------------------------------
	// Assemble result, sign = 0 for softmax reciprocal
	//-----------------------------------------------------------------
	assign	odat = { 1'b0, e_dly, mdat };

endmodule : rec_wrapper
