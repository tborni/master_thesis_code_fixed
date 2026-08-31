module rsqrt_ip_core(
	input	logic  clk,
	input	logic  rstn,

	input	logic [31:0]  x,
	input	logic  xvld,

	output	logic [31:0]  r,
	output	logic  rvld
	);

	floating_point_0 rsqrt_ip (
		.aclk(clk),
		.aresetn(rstn),
		.s_axis_a_tvalid(xvld),
		.s_axis_a_tdata(x),
		.m_axis_result_tvalid(rvld),
		.m_axis_result_tdata(r)
	);
endmodule : rsqrt_ip_core
