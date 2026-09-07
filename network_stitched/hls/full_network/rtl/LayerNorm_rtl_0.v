/****************************************************************************
 * Copyright (C) 2025, Advanced Micro Devices, Inc.
 * All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 *
 ***************************************************************************/

module LayerNorm_rtl_0(
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

	// ---------------------------------------------------------------------
	// LayerNorm core replaced by the Vitis-HLS implementation (layernorm_top).
	// Parameters baked into the HLS core: N=384, SIMD=4, FP32 in/out.
	// The FINN AXI-Stream payload packs SIMD lanes little-endian (lane 0 in
	// bits [31:0]); this matches the hls::vector<float,4> layout used by the
	// HLS core, so the 128-bit TDATA buses connect directly.
	// layernorm_top takes ap_rst_n (active-low) natively and drives its own
	// internal ap_ctrl_none handshake, so no reset inversion is needed here.
	// ---------------------------------------------------------------------
	layernorm_top impl (
		.ap_clk    (ap_clk),
		.ap_rst_n  (ap_rst_n),
		.src_TDATA (in0_V_TDATA),
		.src_TVALID(in0_V_TVALID),
		.src_TREADY(in0_V_TREADY),
		.dst_TDATA (out0_V_TDATA),
		.dst_TVALID(out0_V_TVALID),
		.dst_TREADY(out0_V_TREADY)
	);

endmodule
