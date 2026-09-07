/****************************************************************************
 * Copyright (C) 2026, Advanced Micro Devices, Inc.
 * All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 *
 ***************************************************************************/

module HWSoftmax_rtl_0(
//- Global Control ------------------
(* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF in0_V:out0_V, ASSOCIATED_RESET ap_rst_n" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 ap_clk CLK" *)
input   ap_clk,
(* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
input   ap_rst_n,

//- AXI Stream - Input -------------------
output	in0_V_TREADY,
input	in0_V_TVALID,
input	[4*32-1:0]  in0_V_TDATA,

//- AXI Stream - Output ------------------
input	out0_V_TREADY,
output	out0_V_TVALID,
output	[4*32-1:0]  out0_V_TDATA
);

	// flat carrier between input-conv stage and softmaxf core
	wire [4*32-1:0]  idat_flat;

	generate
		if (1) begin : gen_passthrough
			assign  idat_flat = in0_V_TDATA;
		end
		else begin : gen_int_conv
			genvar  i;
			for (i = 0; i < 4; i = i + 1) begin : gen_lane
				int_to_fp32 #(
					.WIDTH(32),
					.SIGNED(1)
				) u_conv (
					.ival(in0_V_TDATA[(i+1)*32-1 -: 32]),
					.fval(idat_flat[(i+1)*32-1 -: 32])
				);
			end
		end
	endgenerate

	softmaxf #(
		.N(128),
		.SIMD(4),
		.NR_ITERS(2),
		.TI_WIDTH(32)
	) impl (
		.clk(ap_clk),
		.rst(!ap_rst_n),
		.idat(idat_flat),
		.ivld(in0_V_TVALID),
		.irdy(in0_V_TREADY),
		.odat(out0_V_TDATA),
		.ovld(out0_V_TVALID),
		.ordy(out0_V_TREADY)
	);

endmodule
