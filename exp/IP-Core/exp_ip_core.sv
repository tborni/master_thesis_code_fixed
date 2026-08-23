module exp_ip_core(
	input	logic  clk,
	input	logic  rstn,

	input	logic [31:0]  idat,
	input	logic  ivld,
	output	logic  irdy,

	output	logic [31:0]  odat,
	output	logic  ovld,
	input	logic  ordy
);

floating_point_0 exp_ip (
	.aclk(clk),
	.aresetn(rstn),
	.s_axis_a_tvalid(ivld),
	.s_axis_a_tready(irdy),
	.s_axis_a_tdata(idat),
	.m_axis_result_tvalid(ovld),
	.m_axis_result_tready(ordy),
	.m_axis_result_tdata(odat)
);

endmodule : exp_ip_core
