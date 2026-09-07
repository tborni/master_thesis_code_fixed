//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2025.2 (lin64) Build 6299465 Fri Nov 14 12:34:56 MST 2025
//Date        : Thu Sep  3 12:02:59 2026
//Host        : finn_dev_sfleming running 64-bit Ubuntu 22.04.5 LTS
//Command     : generate_target finn_design.bd
//Design      : finn_design
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module ElementwiseAdd_rtl_0_imp_13HFK09
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [127:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [127:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [127:0]ElementwiseAdd_rtl_0_wstrm_m_axis_0_TDATA;
  wire ElementwiseAdd_rtl_0_wstrm_m_axis_0_TREADY;
  wire ElementwiseAdd_rtl_0_wstrm_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [127:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [127:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_ElementwiseAdd_rtl_0_0 ElementwiseAdd_rtl_0
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(ElementwiseAdd_rtl_0_wstrm_m_axis_0_TDATA),
        .in1_V_TREADY(ElementwiseAdd_rtl_0_wstrm_m_axis_0_TREADY),
        .in1_V_TVALID(ElementwiseAdd_rtl_0_wstrm_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_ElementwiseAdd_rtl_0_wstrm_0 ElementwiseAdd_rtl_0_wstrm
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_tdata(ElementwiseAdd_rtl_0_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(ElementwiseAdd_rtl_0_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(ElementwiseAdd_rtl_0_wstrm_m_axis_0_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARPROT({1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWPROT({1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0),
        .s_axis_0_tdata(1'b0),
        .s_axis_0_tvalid(1'b0));
endmodule

module ElementwiseAdd_rtl_10_imp_PZKKR8
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [127:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [127:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [127:0]ElementwiseAdd_rtl_10_wstrm_m_axis_0_TDATA;
  wire ElementwiseAdd_rtl_10_wstrm_m_axis_0_TREADY;
  wire ElementwiseAdd_rtl_10_wstrm_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [127:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [127:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_ElementwiseAdd_rtl_10_0 ElementwiseAdd_rtl_10
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(ElementwiseAdd_rtl_10_wstrm_m_axis_0_TDATA),
        .in1_V_TREADY(ElementwiseAdd_rtl_10_wstrm_m_axis_0_TREADY),
        .in1_V_TVALID(ElementwiseAdd_rtl_10_wstrm_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_ElementwiseAdd_rtl_10_wstrm_0 ElementwiseAdd_rtl_10_wstrm
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_tdata(ElementwiseAdd_rtl_10_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(ElementwiseAdd_rtl_10_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(ElementwiseAdd_rtl_10_wstrm_m_axis_0_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARPROT({1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWPROT({1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0),
        .s_axis_0_tdata(1'b0),
        .s_axis_0_tvalid(1'b0));
endmodule

module ElementwiseAdd_rtl_11_imp_1IY9P4R
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [63:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [63:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [63:0]ElementwiseAdd_rtl_11_wstrm_m_axis_0_TDATA;
  wire ElementwiseAdd_rtl_11_wstrm_m_axis_0_TREADY;
  wire ElementwiseAdd_rtl_11_wstrm_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [63:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [63:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_ElementwiseAdd_rtl_11_0 ElementwiseAdd_rtl_11
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(ElementwiseAdd_rtl_11_wstrm_m_axis_0_TDATA),
        .in1_V_TREADY(ElementwiseAdd_rtl_11_wstrm_m_axis_0_TREADY),
        .in1_V_TVALID(ElementwiseAdd_rtl_11_wstrm_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_ElementwiseAdd_rtl_11_wstrm_0 ElementwiseAdd_rtl_11_wstrm
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_tdata(ElementwiseAdd_rtl_11_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(ElementwiseAdd_rtl_11_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(ElementwiseAdd_rtl_11_wstrm_m_axis_0_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0}),
        .s_axilite_ARPROT({1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0}),
        .s_axilite_AWPROT({1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0),
        .s_axis_0_tdata(1'b0),
        .s_axis_0_tvalid(1'b0));
endmodule

module ElementwiseAdd_rtl_1_imp_62U4IU
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [127:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [127:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [127:0]ElementwiseAdd_rtl_1_wstrm_m_axis_0_TDATA;
  wire ElementwiseAdd_rtl_1_wstrm_m_axis_0_TREADY;
  wire ElementwiseAdd_rtl_1_wstrm_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [127:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [127:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_ElementwiseAdd_rtl_1_0 ElementwiseAdd_rtl_1
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(ElementwiseAdd_rtl_1_wstrm_m_axis_0_TDATA),
        .in1_V_TREADY(ElementwiseAdd_rtl_1_wstrm_m_axis_0_TREADY),
        .in1_V_TVALID(ElementwiseAdd_rtl_1_wstrm_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_ElementwiseAdd_rtl_1_wstrm_0 ElementwiseAdd_rtl_1_wstrm
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_tdata(ElementwiseAdd_rtl_1_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(ElementwiseAdd_rtl_1_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(ElementwiseAdd_rtl_1_wstrm_m_axis_0_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARPROT({1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWPROT({1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0),
        .s_axis_0_tdata(1'b0),
        .s_axis_0_tvalid(1'b0));
endmodule

module ElementwiseAdd_rtl_2_imp_RBIH7A
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [127:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [127:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [127:0]ElementwiseAdd_rtl_2_wstrm_m_axis_0_TDATA;
  wire ElementwiseAdd_rtl_2_wstrm_m_axis_0_TREADY;
  wire ElementwiseAdd_rtl_2_wstrm_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [127:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [127:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_ElementwiseAdd_rtl_2_0 ElementwiseAdd_rtl_2
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(ElementwiseAdd_rtl_2_wstrm_m_axis_0_TDATA),
        .in1_V_TREADY(ElementwiseAdd_rtl_2_wstrm_m_axis_0_TREADY),
        .in1_V_TVALID(ElementwiseAdd_rtl_2_wstrm_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_ElementwiseAdd_rtl_2_wstrm_0 ElementwiseAdd_rtl_2_wstrm
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_tdata(ElementwiseAdd_rtl_2_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(ElementwiseAdd_rtl_2_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(ElementwiseAdd_rtl_2_wstrm_m_axis_0_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARPROT({1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWPROT({1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0),
        .s_axis_0_tdata(1'b0),
        .s_axis_0_tvalid(1'b0));
endmodule

module ElementwiseAdd_rtl_3_imp_1XBFDVD
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [127:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [127:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [127:0]ElementwiseAdd_rtl_3_wstrm_m_axis_0_TDATA;
  wire ElementwiseAdd_rtl_3_wstrm_m_axis_0_TREADY;
  wire ElementwiseAdd_rtl_3_wstrm_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [127:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [127:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_ElementwiseAdd_rtl_3_0 ElementwiseAdd_rtl_3
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(ElementwiseAdd_rtl_3_wstrm_m_axis_0_TDATA),
        .in1_V_TREADY(ElementwiseAdd_rtl_3_wstrm_m_axis_0_TREADY),
        .in1_V_TVALID(ElementwiseAdd_rtl_3_wstrm_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_ElementwiseAdd_rtl_3_wstrm_0 ElementwiseAdd_rtl_3_wstrm
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_tdata(ElementwiseAdd_rtl_3_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(ElementwiseAdd_rtl_3_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(ElementwiseAdd_rtl_3_wstrm_m_axis_0_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARPROT({1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWPROT({1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0),
        .s_axis_0_tdata(1'b0),
        .s_axis_0_tvalid(1'b0));
endmodule

module ElementwiseAdd_rtl_4_imp_137DH86
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    in1_V_tdata,
    in1_V_tready,
    in1_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [127:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  input [127:0]in1_V_tdata;
  output in1_V_tready;
  input in1_V_tvalid;
  output [127:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire ap_clk;
  wire ap_rst_n;
  wire [127:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [127:0]in1_V_tdata;
  wire in1_V_tready;
  wire in1_V_tvalid;
  wire [127:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_ElementwiseAdd_rtl_4_0 ElementwiseAdd_rtl_4
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(in1_V_tdata),
        .in1_V_TREADY(in1_V_tready),
        .in1_V_TVALID(in1_V_tvalid),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
endmodule

module ElementwiseAdd_rtl_5_imp_6D2DQX
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [127:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [127:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [127:0]ElementwiseAdd_rtl_5_wstrm_m_axis_0_TDATA;
  wire ElementwiseAdd_rtl_5_wstrm_m_axis_0_TREADY;
  wire ElementwiseAdd_rtl_5_wstrm_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [127:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [127:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_ElementwiseAdd_rtl_5_0 ElementwiseAdd_rtl_5
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(ElementwiseAdd_rtl_5_wstrm_m_axis_0_TDATA),
        .in1_V_TREADY(ElementwiseAdd_rtl_5_wstrm_m_axis_0_TREADY),
        .in1_V_TVALID(ElementwiseAdd_rtl_5_wstrm_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_ElementwiseAdd_rtl_5_wstrm_0 ElementwiseAdd_rtl_5_wstrm
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_tdata(ElementwiseAdd_rtl_5_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(ElementwiseAdd_rtl_5_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(ElementwiseAdd_rtl_5_wstrm_m_axis_0_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARPROT({1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWPROT({1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0),
        .s_axis_0_tdata(1'b0),
        .s_axis_0_tvalid(1'b0));
endmodule

module ElementwiseAdd_rtl_6_imp_R1AHUX
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [127:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [127:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [127:0]ElementwiseAdd_rtl_6_wstrm_m_axis_0_TDATA;
  wire ElementwiseAdd_rtl_6_wstrm_m_axis_0_TREADY;
  wire ElementwiseAdd_rtl_6_wstrm_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [127:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [127:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_ElementwiseAdd_rtl_6_0 ElementwiseAdd_rtl_6
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(ElementwiseAdd_rtl_6_wstrm_m_axis_0_TDATA),
        .in1_V_TREADY(ElementwiseAdd_rtl_6_wstrm_m_axis_0_TREADY),
        .in1_V_TVALID(ElementwiseAdd_rtl_6_wstrm_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_ElementwiseAdd_rtl_6_wstrm_0 ElementwiseAdd_rtl_6_wstrm
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_tdata(ElementwiseAdd_rtl_6_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(ElementwiseAdd_rtl_6_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(ElementwiseAdd_rtl_6_wstrm_m_axis_0_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARPROT({1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWPROT({1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0),
        .s_axis_0_tdata(1'b0),
        .s_axis_0_tvalid(1'b0));
endmodule

module ElementwiseAdd_rtl_7_imp_1XLHWUE
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [127:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [127:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [127:0]ElementwiseAdd_rtl_7_wstrm_m_axis_0_TDATA;
  wire ElementwiseAdd_rtl_7_wstrm_m_axis_0_TREADY;
  wire ElementwiseAdd_rtl_7_wstrm_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [127:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [127:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_ElementwiseAdd_rtl_7_0 ElementwiseAdd_rtl_7
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(ElementwiseAdd_rtl_7_wstrm_m_axis_0_TDATA),
        .in1_V_TREADY(ElementwiseAdd_rtl_7_wstrm_m_axis_0_TREADY),
        .in1_V_TVALID(ElementwiseAdd_rtl_7_wstrm_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_ElementwiseAdd_rtl_7_wstrm_0 ElementwiseAdd_rtl_7_wstrm
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_tdata(ElementwiseAdd_rtl_7_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(ElementwiseAdd_rtl_7_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(ElementwiseAdd_rtl_7_wstrm_m_axis_0_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARPROT({1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWPROT({1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0),
        .s_axis_0_tdata(1'b0),
        .s_axis_0_tvalid(1'b0));
endmodule

module ElementwiseAdd_rtl_8_imp_11T133R
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    in1_V_tdata,
    in1_V_tready,
    in1_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [127:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  input [127:0]in1_V_tdata;
  output in1_V_tready;
  input in1_V_tvalid;
  output [127:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire ap_clk;
  wire ap_rst_n;
  wire [127:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [127:0]in1_V_tdata;
  wire in1_V_tready;
  wire in1_V_tvalid;
  wire [127:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_ElementwiseAdd_rtl_8_0 ElementwiseAdd_rtl_8
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(in1_V_tdata),
        .in1_V_TREADY(in1_V_tready),
        .in1_V_TVALID(in1_V_tvalid),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
endmodule

module ElementwiseAdd_rtl_9_imp_5IPX94
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [127:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [127:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [127:0]ElementwiseAdd_rtl_9_wstrm_m_axis_0_TDATA;
  wire ElementwiseAdd_rtl_9_wstrm_m_axis_0_TREADY;
  wire ElementwiseAdd_rtl_9_wstrm_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [127:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [127:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_ElementwiseAdd_rtl_9_0 ElementwiseAdd_rtl_9
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(ElementwiseAdd_rtl_9_wstrm_m_axis_0_TDATA),
        .in1_V_TREADY(ElementwiseAdd_rtl_9_wstrm_m_axis_0_TREADY),
        .in1_V_TVALID(ElementwiseAdd_rtl_9_wstrm_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_ElementwiseAdd_rtl_9_wstrm_0 ElementwiseAdd_rtl_9_wstrm
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_tdata(ElementwiseAdd_rtl_9_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(ElementwiseAdd_rtl_9_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(ElementwiseAdd_rtl_9_wstrm_m_axis_0_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARPROT({1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWPROT({1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0),
        .s_axis_0_tdata(1'b0),
        .s_axis_0_tvalid(1'b0));
endmodule

module ElementwiseMul_rtl_0_imp_13JTGOS
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [87:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [127:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [127:0]ElementwiseMul_rtl_0_wstrm_m_axis_0_TDATA;
  wire ElementwiseMul_rtl_0_wstrm_m_axis_0_TREADY;
  wire ElementwiseMul_rtl_0_wstrm_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [87:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [127:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_ElementwiseMul_rtl_0_0 ElementwiseMul_rtl_0
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(ElementwiseMul_rtl_0_wstrm_m_axis_0_TDATA),
        .in1_V_TREADY(ElementwiseMul_rtl_0_wstrm_m_axis_0_TREADY),
        .in1_V_TVALID(ElementwiseMul_rtl_0_wstrm_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_ElementwiseMul_rtl_0_wstrm_0 ElementwiseMul_rtl_0_wstrm
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_tdata(ElementwiseMul_rtl_0_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(ElementwiseMul_rtl_0_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(ElementwiseMul_rtl_0_wstrm_m_axis_0_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARPROT({1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWPROT({1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0),
        .s_axis_0_tdata(1'b0),
        .s_axis_0_tvalid(1'b0));
endmodule

module ElementwiseMul_rtl_10_imp_1RZQEYN
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [47:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [63:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [63:0]ElementwiseMul_rtl_10_wstrm_m_axis_0_TDATA;
  wire ElementwiseMul_rtl_10_wstrm_m_axis_0_TREADY;
  wire ElementwiseMul_rtl_10_wstrm_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [47:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [63:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_ElementwiseMul_rtl_10_0 ElementwiseMul_rtl_10
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata[43:0]),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(ElementwiseMul_rtl_10_wstrm_m_axis_0_TDATA),
        .in1_V_TREADY(ElementwiseMul_rtl_10_wstrm_m_axis_0_TREADY),
        .in1_V_TVALID(ElementwiseMul_rtl_10_wstrm_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_ElementwiseMul_rtl_10_wstrm_0 ElementwiseMul_rtl_10_wstrm
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_tdata(ElementwiseMul_rtl_10_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(ElementwiseMul_rtl_10_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(ElementwiseMul_rtl_10_wstrm_m_axis_0_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0}),
        .s_axilite_ARPROT({1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0}),
        .s_axilite_AWPROT({1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0),
        .s_axis_0_tdata(1'b0),
        .s_axis_0_tvalid(1'b0));
endmodule

module ElementwiseMul_rtl_1_imp_5VMEAB
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [87:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [127:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [127:0]ElementwiseMul_rtl_1_wstrm_m_axis_0_TDATA;
  wire ElementwiseMul_rtl_1_wstrm_m_axis_0_TREADY;
  wire ElementwiseMul_rtl_1_wstrm_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [87:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [127:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_ElementwiseMul_rtl_1_0 ElementwiseMul_rtl_1
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(ElementwiseMul_rtl_1_wstrm_m_axis_0_TDATA),
        .in1_V_TREADY(ElementwiseMul_rtl_1_wstrm_m_axis_0_TREADY),
        .in1_V_TVALID(ElementwiseMul_rtl_1_wstrm_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_ElementwiseMul_rtl_1_wstrm_0 ElementwiseMul_rtl_1_wstrm
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_tdata(ElementwiseMul_rtl_1_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(ElementwiseMul_rtl_1_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(ElementwiseMul_rtl_1_wstrm_m_axis_0_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARPROT({1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWPROT({1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0),
        .s_axis_0_tdata(1'b0),
        .s_axis_0_tvalid(1'b0));
endmodule

module ElementwiseMul_rtl_2_imp_RDTHCZ
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [87:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [127:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [127:0]ElementwiseMul_rtl_2_wstrm_m_axis_0_TDATA;
  wire ElementwiseMul_rtl_2_wstrm_m_axis_0_TREADY;
  wire ElementwiseMul_rtl_2_wstrm_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [87:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [127:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_ElementwiseMul_rtl_2_0 ElementwiseMul_rtl_2
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(ElementwiseMul_rtl_2_wstrm_m_axis_0_TDATA),
        .in1_V_TREADY(ElementwiseMul_rtl_2_wstrm_m_axis_0_TREADY),
        .in1_V_TVALID(ElementwiseMul_rtl_2_wstrm_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_ElementwiseMul_rtl_2_wstrm_0 ElementwiseMul_rtl_2_wstrm
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_tdata(ElementwiseMul_rtl_2_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(ElementwiseMul_rtl_2_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(ElementwiseMul_rtl_2_wstrm_m_axis_0_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARPROT({1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWPROT({1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0),
        .s_axis_0_tdata(1'b0),
        .s_axis_0_tvalid(1'b0));
endmodule

module ElementwiseMul_rtl_3_imp_1X3ZB64
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [31:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [127:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [127:0]ElementwiseMul_rtl_3_wstrm_m_axis_0_TDATA;
  wire ElementwiseMul_rtl_3_wstrm_m_axis_0_TREADY;
  wire ElementwiseMul_rtl_3_wstrm_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [31:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [127:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_ElementwiseMul_rtl_3_0 ElementwiseMul_rtl_3
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(ElementwiseMul_rtl_3_wstrm_m_axis_0_TDATA),
        .in1_V_TREADY(ElementwiseMul_rtl_3_wstrm_m_axis_0_TREADY),
        .in1_V_TVALID(ElementwiseMul_rtl_3_wstrm_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_ElementwiseMul_rtl_3_wstrm_0 ElementwiseMul_rtl_3_wstrm
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_tdata(ElementwiseMul_rtl_3_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(ElementwiseMul_rtl_3_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(ElementwiseMul_rtl_3_wstrm_m_axis_0_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARPROT({1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWPROT({1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0),
        .s_axis_0_tdata(1'b0),
        .s_axis_0_tvalid(1'b0));
endmodule

module ElementwiseMul_rtl_4_imp_139WKAR
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [87:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [127:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [127:0]ElementwiseMul_rtl_4_wstrm_m_axis_0_TDATA;
  wire ElementwiseMul_rtl_4_wstrm_m_axis_0_TREADY;
  wire ElementwiseMul_rtl_4_wstrm_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [87:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [127:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_ElementwiseMul_rtl_4_0 ElementwiseMul_rtl_4
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(ElementwiseMul_rtl_4_wstrm_m_axis_0_TDATA),
        .in1_V_TREADY(ElementwiseMul_rtl_4_wstrm_m_axis_0_TREADY),
        .in1_V_TVALID(ElementwiseMul_rtl_4_wstrm_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_ElementwiseMul_rtl_4_wstrm_0 ElementwiseMul_rtl_4_wstrm
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_tdata(ElementwiseMul_rtl_4_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(ElementwiseMul_rtl_4_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(ElementwiseMul_rtl_4_wstrm_m_axis_0_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARPROT({1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWPROT({1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0),
        .s_axis_0_tdata(1'b0),
        .s_axis_0_tvalid(1'b0));
endmodule

module ElementwiseMul_rtl_5_imp_65DJ8S
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [127:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [127:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [127:0]ElementwiseMul_rtl_5_wstrm_m_axis_0_TDATA;
  wire ElementwiseMul_rtl_5_wstrm_m_axis_0_TREADY;
  wire ElementwiseMul_rtl_5_wstrm_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [127:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [127:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_ElementwiseMul_rtl_5_0 ElementwiseMul_rtl_5
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(ElementwiseMul_rtl_5_wstrm_m_axis_0_TDATA),
        .in1_V_TREADY(ElementwiseMul_rtl_5_wstrm_m_axis_0_TREADY),
        .in1_V_TVALID(ElementwiseMul_rtl_5_wstrm_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_ElementwiseMul_rtl_5_wstrm_0 ElementwiseMul_rtl_5_wstrm
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_tdata(ElementwiseMul_rtl_5_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(ElementwiseMul_rtl_5_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(ElementwiseMul_rtl_5_wstrm_m_axis_0_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARPROT({1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWPROT({1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0),
        .s_axis_0_tdata(1'b0),
        .s_axis_0_tvalid(1'b0));
endmodule

module ElementwiseMul_rtl_6_imp_R423BW
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [87:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [127:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [127:0]ElementwiseMul_rtl_6_wstrm_m_axis_0_TDATA;
  wire ElementwiseMul_rtl_6_wstrm_m_axis_0_TREADY;
  wire ElementwiseMul_rtl_6_wstrm_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [87:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [127:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_ElementwiseMul_rtl_6_0 ElementwiseMul_rtl_6
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(ElementwiseMul_rtl_6_wstrm_m_axis_0_TDATA),
        .in1_V_TREADY(ElementwiseMul_rtl_6_wstrm_m_axis_0_TREADY),
        .in1_V_TVALID(ElementwiseMul_rtl_6_wstrm_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_ElementwiseMul_rtl_6_wstrm_0 ElementwiseMul_rtl_6_wstrm
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_tdata(ElementwiseMul_rtl_6_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(ElementwiseMul_rtl_6_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(ElementwiseMul_rtl_6_wstrm_m_axis_0_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARPROT({1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWPROT({1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0),
        .s_axis_0_tdata(1'b0),
        .s_axis_0_tvalid(1'b0));
endmodule

module ElementwiseMul_rtl_7_imp_1XDVS4Z
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [95:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [127:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [127:0]ElementwiseMul_rtl_7_wstrm_m_axis_0_TDATA;
  wire ElementwiseMul_rtl_7_wstrm_m_axis_0_TREADY;
  wire ElementwiseMul_rtl_7_wstrm_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [95:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [127:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_ElementwiseMul_rtl_7_0 ElementwiseMul_rtl_7
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(ElementwiseMul_rtl_7_wstrm_m_axis_0_TDATA),
        .in1_V_TREADY(ElementwiseMul_rtl_7_wstrm_m_axis_0_TREADY),
        .in1_V_TVALID(ElementwiseMul_rtl_7_wstrm_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_ElementwiseMul_rtl_7_wstrm_0 ElementwiseMul_rtl_7_wstrm
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_tdata(ElementwiseMul_rtl_7_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(ElementwiseMul_rtl_7_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(ElementwiseMul_rtl_7_wstrm_m_axis_0_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARPROT({1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWPROT({1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0),
        .s_axis_0_tdata(1'b0),
        .s_axis_0_tvalid(1'b0));
endmodule

module ElementwiseMul_rtl_8_imp_11VPVEQ
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [127:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [127:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [127:0]ElementwiseMul_rtl_8_wstrm_m_axis_0_TDATA;
  wire ElementwiseMul_rtl_8_wstrm_m_axis_0_TREADY;
  wire ElementwiseMul_rtl_8_wstrm_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [127:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [127:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_ElementwiseMul_rtl_8_0 ElementwiseMul_rtl_8
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(ElementwiseMul_rtl_8_wstrm_m_axis_0_TDATA),
        .in1_V_TREADY(ElementwiseMul_rtl_8_wstrm_m_axis_0_TREADY),
        .in1_V_TVALID(ElementwiseMul_rtl_8_wstrm_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_ElementwiseMul_rtl_8_wstrm_0 ElementwiseMul_rtl_8_wstrm
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_tdata(ElementwiseMul_rtl_8_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(ElementwiseMul_rtl_8_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(ElementwiseMul_rtl_8_wstrm_m_axis_0_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARPROT({1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWPROT({1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0),
        .s_axis_0_tdata(1'b0),
        .s_axis_0_tvalid(1'b0));
endmodule

module ElementwiseMul_rtl_9_imp_5B6LNX
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [87:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [127:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [127:0]ElementwiseMul_rtl_9_wstrm_m_axis_0_TDATA;
  wire ElementwiseMul_rtl_9_wstrm_m_axis_0_TREADY;
  wire ElementwiseMul_rtl_9_wstrm_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [87:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [127:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_ElementwiseMul_rtl_9_0 ElementwiseMul_rtl_9
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(ElementwiseMul_rtl_9_wstrm_m_axis_0_TDATA),
        .in1_V_TREADY(ElementwiseMul_rtl_9_wstrm_m_axis_0_TREADY),
        .in1_V_TVALID(ElementwiseMul_rtl_9_wstrm_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_ElementwiseMul_rtl_9_wstrm_0 ElementwiseMul_rtl_9_wstrm
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_tdata(ElementwiseMul_rtl_9_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(ElementwiseMul_rtl_9_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(ElementwiseMul_rtl_9_wstrm_m_axis_0_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARPROT({1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWPROT({1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0),
        .s_axis_0_tdata(1'b0),
        .s_axis_0_tvalid(1'b0));
endmodule

module MVAU_rtl_0_imp_1DNJB9Y
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [191:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [351:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [3071:0]MVAU_rtl_0_wstrm_m_axis_0_TDATA;
  wire MVAU_rtl_0_wstrm_m_axis_0_TREADY;
  wire MVAU_rtl_0_wstrm_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [191:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [351:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_MVAU_rtl_0_0 MVAU_rtl_0
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(MVAU_rtl_0_wstrm_m_axis_0_TDATA),
        .in1_V_TREADY(MVAU_rtl_0_wstrm_m_axis_0_TREADY),
        .in1_V_TVALID(MVAU_rtl_0_wstrm_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_MVAU_rtl_0_wstrm_0 MVAU_rtl_0_wstrm
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_tdata(MVAU_rtl_0_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(MVAU_rtl_0_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(MVAU_rtl_0_wstrm_m_axis_0_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARPROT({1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWPROT({1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0),
        .s_axis_0_tdata(1'b0),
        .s_axis_0_tvalid(1'b0));
endmodule

module MVAU_rtl_1_imp_BGQB3T
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [191:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [351:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [3071:0]MVAU_rtl_1_wstrm_m_axis_0_TDATA;
  wire MVAU_rtl_1_wstrm_m_axis_0_TREADY;
  wire MVAU_rtl_1_wstrm_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [191:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [351:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_MVAU_rtl_1_0 MVAU_rtl_1
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(MVAU_rtl_1_wstrm_m_axis_0_TDATA),
        .in1_V_TREADY(MVAU_rtl_1_wstrm_m_axis_0_TREADY),
        .in1_V_TVALID(MVAU_rtl_1_wstrm_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_MVAU_rtl_1_wstrm_0 MVAU_rtl_1_wstrm
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_tdata(MVAU_rtl_1_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(MVAU_rtl_1_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(MVAU_rtl_1_wstrm_m_axis_0_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARPROT({1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWPROT({1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0),
        .s_axis_0_tdata(1'b0),
        .s_axis_0_tvalid(1'b0));
endmodule

module MVAU_rtl_2_imp_QB0MDL
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [191:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [351:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [3071:0]MVAU_rtl_2_wstrm_m_axis_0_TDATA;
  wire MVAU_rtl_2_wstrm_m_axis_0_TREADY;
  wire MVAU_rtl_2_wstrm_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [191:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [351:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_MVAU_rtl_2_0 MVAU_rtl_2
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(MVAU_rtl_2_wstrm_m_axis_0_TDATA),
        .in1_V_TREADY(MVAU_rtl_2_wstrm_m_axis_0_TREADY),
        .in1_V_TVALID(MVAU_rtl_2_wstrm_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_MVAU_rtl_2_wstrm_0 MVAU_rtl_2_wstrm
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_tdata(MVAU_rtl_2_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(MVAU_rtl_2_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(MVAU_rtl_2_wstrm_m_axis_0_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARPROT({1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWPROT({1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0),
        .s_axis_0_tdata(1'b0),
        .s_axis_0_tvalid(1'b0));
endmodule

module MVAU_rtl_3_imp_1IRXAUE
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    in1_V_tdata,
    in1_V_tready,
    in1_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [63:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  input [63:0]in1_V_tdata;
  output in1_V_tready;
  input in1_V_tvalid;
  output [167:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [511:0]MVAU_rtl_3_wdynld_m_axis_0_TDATA;
  wire MVAU_rtl_3_wdynld_m_axis_0_TREADY;
  wire MVAU_rtl_3_wdynld_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [63:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [63:0]in1_V_tdata;
  wire in1_V_tready;
  wire in1_V_tvalid;
  wire [167:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_MVAU_rtl_3_0 MVAU_rtl_3
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(MVAU_rtl_3_wdynld_m_axis_0_TDATA),
        .in1_V_TREADY(MVAU_rtl_3_wdynld_m_axis_0_TREADY),
        .in1_V_TVALID(MVAU_rtl_3_wdynld_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_MVAU_rtl_3_wdynld_0 MVAU_rtl_3_wdynld
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_TDATA(MVAU_rtl_3_wdynld_m_axis_0_TDATA),
        .m_axis_0_TREADY(MVAU_rtl_3_wdynld_m_axis_0_TREADY),
        .m_axis_0_TVALID(MVAU_rtl_3_wdynld_m_axis_0_TVALID),
        .s_axis_0_TDATA(in1_V_tdata),
        .s_axis_0_TREADY(in1_V_tready),
        .s_axis_0_TVALID(in1_V_tvalid));
endmodule

module MVAU_rtl_4_imp_1DDGY3T
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    in1_V_tdata,
    in1_V_tready,
    in1_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [63:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  input [63:0]in1_V_tdata;
  output in1_V_tready;
  input in1_V_tvalid;
  output [183:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [511:0]MVAU_rtl_4_wdynld_m_axis_0_TDATA;
  wire MVAU_rtl_4_wdynld_m_axis_0_TREADY;
  wire MVAU_rtl_4_wdynld_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [63:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [63:0]in1_V_tdata;
  wire in1_V_tready;
  wire in1_V_tvalid;
  wire [183:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_MVAU_rtl_4_0 MVAU_rtl_4
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(MVAU_rtl_4_wdynld_m_axis_0_TDATA),
        .in1_V_TREADY(MVAU_rtl_4_wdynld_m_axis_0_TREADY),
        .in1_V_TVALID(MVAU_rtl_4_wdynld_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_MVAU_rtl_4_wdynld_0 MVAU_rtl_4_wdynld
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_TDATA(MVAU_rtl_4_wdynld_m_axis_0_TDATA),
        .m_axis_0_TREADY(MVAU_rtl_4_wdynld_m_axis_0_TREADY),
        .m_axis_0_TVALID(MVAU_rtl_4_wdynld_m_axis_0_TVALID),
        .s_axis_0_TDATA(in1_V_tdata),
        .s_axis_0_TREADY(in1_V_tready),
        .s_axis_0_TVALID(in1_V_tvalid));
endmodule

module MVAU_rtl_5_imp_BQYGG6
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [191:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [351:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [3071:0]MVAU_rtl_5_wstrm_m_axis_0_TDATA;
  wire MVAU_rtl_5_wstrm_m_axis_0_TREADY;
  wire MVAU_rtl_5_wstrm_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [191:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [351:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_MVAU_rtl_5_0 MVAU_rtl_5
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(MVAU_rtl_5_wstrm_m_axis_0_TDATA),
        .in1_V_TREADY(MVAU_rtl_5_wstrm_m_axis_0_TREADY),
        .in1_V_TVALID(MVAU_rtl_5_wstrm_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_MVAU_rtl_5_wstrm_0 MVAU_rtl_5_wstrm
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_tdata(MVAU_rtl_5_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(MVAU_rtl_5_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(MVAU_rtl_5_wstrm_m_axis_0_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARPROT({1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWPROT({1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0),
        .s_axis_0_tdata(1'b0),
        .s_axis_0_tvalid(1'b0));
endmodule

module MVAU_rtl_6_imp_Q0SX86
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [383:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [703:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [12287:0]MVAU_rtl_6_wstrm_m_axis_0_TDATA;
  wire MVAU_rtl_6_wstrm_m_axis_0_TREADY;
  wire MVAU_rtl_6_wstrm_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [383:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [703:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_MVAU_rtl_6_0 MVAU_rtl_6
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(MVAU_rtl_6_wstrm_m_axis_0_TDATA),
        .in1_V_TREADY(MVAU_rtl_6_wstrm_m_axis_0_TREADY),
        .in1_V_TVALID(MVAU_rtl_6_wstrm_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_MVAU_rtl_6_wstrm_0 MVAU_rtl_6_wstrm
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_tdata(MVAU_rtl_6_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(MVAU_rtl_6_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(MVAU_rtl_6_wstrm_m_axis_0_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARPROT({1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWPROT({1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0),
        .s_axis_0_tdata(1'b0),
        .s_axis_0_tvalid(1'b0));
endmodule

module MVAU_rtl_7_imp_1J1ZXW9
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [383:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [767:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [12287:0]MVAU_rtl_7_wstrm_m_axis_0_TDATA;
  wire MVAU_rtl_7_wstrm_m_axis_0_TREADY;
  wire MVAU_rtl_7_wstrm_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [383:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [767:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_MVAU_rtl_7_0 MVAU_rtl_7
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(MVAU_rtl_7_wstrm_m_axis_0_TDATA),
        .in1_V_TREADY(MVAU_rtl_7_wstrm_m_axis_0_TREADY),
        .in1_V_TVALID(MVAU_rtl_7_wstrm_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_MVAU_rtl_7_wstrm_0 MVAU_rtl_7_wstrm
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_tdata(MVAU_rtl_7_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(MVAU_rtl_7_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(MVAU_rtl_7_wstrm_m_axis_0_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARPROT({1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWPROT({1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0),
        .s_axis_0_tdata(1'b0),
        .s_axis_0_tvalid(1'b0));
endmodule

module MVAU_rtl_8_imp_1E7OKDK
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [191:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [175:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [1535:0]MVAU_rtl_8_wstrm_m_axis_0_TDATA;
  wire MVAU_rtl_8_wstrm_m_axis_0_TREADY;
  wire MVAU_rtl_8_wstrm_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [191:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [175:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_MVAU_rtl_8_0 MVAU_rtl_8
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(MVAU_rtl_8_wstrm_m_axis_0_TDATA),
        .in1_V_TREADY(MVAU_rtl_8_wstrm_m_axis_0_TREADY),
        .in1_V_TVALID(MVAU_rtl_8_wstrm_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_MVAU_rtl_8_wstrm_0 MVAU_rtl_8_wstrm
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_tdata(MVAU_rtl_8_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(MVAU_rtl_8_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(MVAU_rtl_8_wstrm_m_axis_0_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARPROT({1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWPROT({1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0),
        .s_axis_0_tdata(1'b0),
        .s_axis_0_tvalid(1'b0));
endmodule

module MVAU_rtl_9_imp_D54FGN
   (ap_clk,
    ap_rst_n,
    in0_V_tdata,
    in0_V_tready,
    in0_V_tvalid,
    out0_V_tdata,
    out0_V_tready,
    out0_V_tvalid);
  input ap_clk;
  input ap_rst_n;
  input [63:0]in0_V_tdata;
  output in0_V_tready;
  input in0_V_tvalid;
  output [47:0]out0_V_tdata;
  input out0_V_tready;
  output out0_V_tvalid;

  wire [127:0]MVAU_rtl_9_wstrm_m_axis_0_TDATA;
  wire MVAU_rtl_9_wstrm_m_axis_0_TREADY;
  wire MVAU_rtl_9_wstrm_m_axis_0_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [63:0]in0_V_tdata;
  wire in0_V_tready;
  wire in0_V_tvalid;
  wire [47:0]out0_V_tdata;
  wire out0_V_tready;
  wire out0_V_tvalid;

  finn_design_MVAU_rtl_9_0 MVAU_rtl_9
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(in0_V_tdata),
        .in0_V_TREADY(in0_V_tready),
        .in0_V_TVALID(in0_V_tvalid),
        .in1_V_TDATA(MVAU_rtl_9_wstrm_m_axis_0_TDATA),
        .in1_V_TREADY(MVAU_rtl_9_wstrm_m_axis_0_TREADY),
        .in1_V_TVALID(MVAU_rtl_9_wstrm_m_axis_0_TVALID),
        .out0_V_TDATA(out0_V_tdata),
        .out0_V_TREADY(out0_V_tready),
        .out0_V_TVALID(out0_V_tvalid));
  finn_design_MVAU_rtl_9_wstrm_0 MVAU_rtl_9_wstrm
       (.ap_clk(ap_clk),
        .ap_clk2x(ap_clk),
        .ap_rst_n(ap_rst_n),
        .m_axis_0_tdata(MVAU_rtl_9_wstrm_m_axis_0_TDATA),
        .m_axis_0_tready(MVAU_rtl_9_wstrm_m_axis_0_TREADY),
        .m_axis_0_tvalid(MVAU_rtl_9_wstrm_m_axis_0_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARPROT({1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWPROT({1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0),
        .s_axis_0_tdata(1'b0),
        .s_axis_0_tvalid(1'b0));
endmodule

(* CORE_GENERATION_INFO = "finn_design,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=finn_design,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=240,numReposBlks=207,numNonXlnxBlks=0,numHierBlks=33,maxHierDepth=1,numSysgenBlks=0,numHlsBlks=7,numHdlrefBlks=200,numPkgbdBlks=0,bdsource=USER,synth_mode=Hierarchical}" *) (* HW_HANDOFF = "finn_design.hwdef" *) 
module finn_design
   (ap_clk,
    ap_rst_n,
    m_axis_0_tdata,
    m_axis_0_tready,
    m_axis_0_tvalid,
    s_axis_0_tdata,
    s_axis_0_tready,
    s_axis_0_tvalid,
    sim_finish);
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.AP_CLK CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.AP_CLK, ASSOCIATED_BUSIF s_axis_0:m_axis_0, ASSOCIATED_RESET ap_rst_n, CLK_DOMAIN finn_design_ap_clk_0, FREQ_HZ 200000000, FREQ_TOLERANCE_HZ 0, INSERT_VIP 0, PHASE 0.0" *) input ap_clk;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.AP_RST_N RST" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.AP_RST_N, INSERT_VIP 0, POLARITY ACTIVE_LOW" *) input ap_rst_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_0 TDATA" *) (* X_INTERFACE_MODE = "Master" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME m_axis_0, CLK_DOMAIN finn_design_ap_clk_0, FREQ_HZ 200000000, HAS_TKEEP 0, HAS_TLAST 0, HAS_TREADY 1, HAS_TSTRB 0, INSERT_VIP 0, LAYERED_METADATA undef, PHASE 0.0, TDATA_NUM_BYTES 8, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0" *) output [63:0]m_axis_0_tdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_0 TREADY" *) input m_axis_0_tready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_0 TVALID" *) output m_axis_0_tvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_0 TDATA" *) (* X_INTERFACE_MODE = "Slave" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_axis_0, CLK_DOMAIN finn_design_ap_clk_0, FREQ_HZ 200000000, HAS_TKEEP 0, HAS_TLAST 0, HAS_TREADY 1, HAS_TSTRB 0, INSERT_VIP 0, LAYERED_METADATA undef, PHASE 0.0, TDATA_NUM_BYTES 32, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0" *) input [255:0]s_axis_0_tdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_0 TREADY" *) output s_axis_0_tready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_0 TVALID" *) input s_axis_0_tvalid;
  input sim_finish;

  wire [255:0]DuplicateStreams_hls_0_out0_V_TDATA;
  wire DuplicateStreams_hls_0_out0_V_TREADY;
  wire DuplicateStreams_hls_0_out0_V_TVALID;
  wire [255:0]DuplicateStreams_hls_0_out1_V_TDATA;
  wire DuplicateStreams_hls_0_out1_V_TREADY;
  wire DuplicateStreams_hls_0_out1_V_TVALID;
  wire [63:0]DuplicateStreams_hls_1_out0_V_TDATA;
  wire DuplicateStreams_hls_1_out0_V_TREADY;
  wire DuplicateStreams_hls_1_out0_V_TVALID;
  wire [63:0]DuplicateStreams_hls_1_out1_V_TDATA;
  wire DuplicateStreams_hls_1_out1_V_TREADY;
  wire DuplicateStreams_hls_1_out1_V_TVALID;
  wire [63:0]DuplicateStreams_hls_1_out2_V_TDATA;
  wire DuplicateStreams_hls_1_out2_V_TREADY;
  wire DuplicateStreams_hls_1_out2_V_TVALID;
  wire [255:0]DuplicateStreams_hls_2_out0_V_TDATA;
  wire DuplicateStreams_hls_2_out0_V_TREADY;
  wire DuplicateStreams_hls_2_out0_V_TVALID;
  wire [255:0]DuplicateStreams_hls_2_out1_V_TDATA;
  wire DuplicateStreams_hls_2_out1_V_TREADY;
  wire DuplicateStreams_hls_2_out1_V_TVALID;
  wire [127:0]ElementwiseAdd_rtl_0_out0_V_TDATA;
  wire ElementwiseAdd_rtl_0_out0_V_TREADY;
  wire ElementwiseAdd_rtl_0_out0_V_TVALID;
  wire [127:0]ElementwiseAdd_rtl_10_out0_V_TDATA;
  wire ElementwiseAdd_rtl_10_out0_V_TREADY;
  wire ElementwiseAdd_rtl_10_out0_V_TVALID;
  wire [63:0]ElementwiseAdd_rtl_11_out0_V_TDATA;
  wire ElementwiseAdd_rtl_11_out0_V_TREADY;
  wire ElementwiseAdd_rtl_11_out0_V_TVALID;
  wire [127:0]ElementwiseAdd_rtl_1_out0_V_TDATA;
  wire ElementwiseAdd_rtl_1_out0_V_TREADY;
  wire ElementwiseAdd_rtl_1_out0_V_TVALID;
  wire [127:0]ElementwiseAdd_rtl_2_out0_V_TDATA;
  wire ElementwiseAdd_rtl_2_out0_V_TREADY;
  wire ElementwiseAdd_rtl_2_out0_V_TVALID;
  wire [127:0]ElementwiseAdd_rtl_3_out0_V_TDATA;
  wire ElementwiseAdd_rtl_3_out0_V_TREADY;
  wire ElementwiseAdd_rtl_3_out0_V_TVALID;
  wire [127:0]ElementwiseAdd_rtl_4_out0_V_TDATA;
  wire ElementwiseAdd_rtl_4_out0_V_TREADY;
  wire ElementwiseAdd_rtl_4_out0_V_TVALID;
  wire [127:0]ElementwiseAdd_rtl_5_out0_V_TDATA;
  wire ElementwiseAdd_rtl_5_out0_V_TREADY;
  wire ElementwiseAdd_rtl_5_out0_V_TVALID;
  wire [127:0]ElementwiseAdd_rtl_6_out0_V_TDATA;
  wire ElementwiseAdd_rtl_6_out0_V_TREADY;
  wire ElementwiseAdd_rtl_6_out0_V_TVALID;
  wire [127:0]ElementwiseAdd_rtl_7_out0_V_TDATA;
  wire ElementwiseAdd_rtl_7_out0_V_TREADY;
  wire ElementwiseAdd_rtl_7_out0_V_TVALID;
  wire [127:0]ElementwiseAdd_rtl_8_out0_V_TDATA;
  wire ElementwiseAdd_rtl_8_out0_V_TREADY;
  wire ElementwiseAdd_rtl_8_out0_V_TVALID;
  wire [127:0]ElementwiseAdd_rtl_9_out0_V_TDATA;
  wire ElementwiseAdd_rtl_9_out0_V_TREADY;
  wire ElementwiseAdd_rtl_9_out0_V_TVALID;
  wire [127:0]ElementwiseMul_rtl_0_out0_V_TDATA;
  wire ElementwiseMul_rtl_0_out0_V_TREADY;
  wire ElementwiseMul_rtl_0_out0_V_TVALID;
  wire [63:0]ElementwiseMul_rtl_10_out0_V_TDATA;
  wire ElementwiseMul_rtl_10_out0_V_TREADY;
  wire ElementwiseMul_rtl_10_out0_V_TVALID;
  wire [127:0]ElementwiseMul_rtl_1_out0_V_TDATA;
  wire ElementwiseMul_rtl_1_out0_V_TREADY;
  wire ElementwiseMul_rtl_1_out0_V_TVALID;
  wire [127:0]ElementwiseMul_rtl_2_out0_V_TDATA;
  wire ElementwiseMul_rtl_2_out0_V_TREADY;
  wire ElementwiseMul_rtl_2_out0_V_TVALID;
  wire [127:0]ElementwiseMul_rtl_3_out0_V_TDATA;
  wire ElementwiseMul_rtl_3_out0_V_TREADY;
  wire ElementwiseMul_rtl_3_out0_V_TVALID;
  wire [127:0]ElementwiseMul_rtl_4_out0_V_TDATA;
  wire ElementwiseMul_rtl_4_out0_V_TREADY;
  wire ElementwiseMul_rtl_4_out0_V_TVALID;
  wire [127:0]ElementwiseMul_rtl_5_out0_V_TDATA;
  wire ElementwiseMul_rtl_5_out0_V_TREADY;
  wire ElementwiseMul_rtl_5_out0_V_TVALID;
  wire [127:0]ElementwiseMul_rtl_6_out0_V_TDATA;
  wire ElementwiseMul_rtl_6_out0_V_TREADY;
  wire ElementwiseMul_rtl_6_out0_V_TVALID;
  wire [127:0]ElementwiseMul_rtl_7_out0_V_TDATA;
  wire ElementwiseMul_rtl_7_out0_V_TREADY;
  wire ElementwiseMul_rtl_7_out0_V_TVALID;
  wire [127:0]ElementwiseMul_rtl_8_out0_V_TDATA;
  wire ElementwiseMul_rtl_8_out0_V_TREADY;
  wire ElementwiseMul_rtl_8_out0_V_TVALID;
  wire [127:0]ElementwiseMul_rtl_9_out0_V_TDATA;
  wire ElementwiseMul_rtl_9_out0_V_TREADY;
  wire ElementwiseMul_rtl_9_out0_V_TVALID;
  wire [127:0]HWSoftmax_rtl_0_out0_V_TDATA;
  wire HWSoftmax_rtl_0_out0_V_TREADY;
  wire HWSoftmax_rtl_0_out0_V_TVALID;
  wire [127:0]InnerShuffle_rtl_0_out0_V_TDATA;
  wire InnerShuffle_rtl_0_out0_V_TREADY;
  wire InnerShuffle_rtl_0_out0_V_TVALID;
  wire [127:0]LayerNorm_rtl_0_out0_V_TDATA;
  wire LayerNorm_rtl_0_out0_V_TREADY;
  wire LayerNorm_rtl_0_out0_V_TVALID;
  wire [127:0]LayerNorm_rtl_1_out0_V_TDATA;
  wire LayerNorm_rtl_1_out0_V_TREADY;
  wire LayerNorm_rtl_1_out0_V_TVALID;
  wire [351:0]MVAU_rtl_0_out0_V_TDATA;
  wire MVAU_rtl_0_out0_V_TREADY;
  wire MVAU_rtl_0_out0_V_TVALID;
  wire [351:0]MVAU_rtl_1_out0_V_TDATA;
  wire MVAU_rtl_1_out0_V_TREADY;
  wire MVAU_rtl_1_out0_V_TVALID;
  wire [351:0]MVAU_rtl_2_out0_V_TDATA;
  wire MVAU_rtl_2_out0_V_TREADY;
  wire MVAU_rtl_2_out0_V_TVALID;
  wire [167:0]MVAU_rtl_3_out0_V_TDATA;
  wire MVAU_rtl_3_out0_V_TREADY;
  wire MVAU_rtl_3_out0_V_TVALID;
  wire [183:0]MVAU_rtl_4_out0_V_TDATA;
  wire MVAU_rtl_4_out0_V_TREADY;
  wire MVAU_rtl_4_out0_V_TVALID;
  wire [351:0]MVAU_rtl_5_out0_V_TDATA;
  wire MVAU_rtl_5_out0_V_TREADY;
  wire MVAU_rtl_5_out0_V_TVALID;
  wire [703:0]MVAU_rtl_6_out0_V_TDATA;
  wire MVAU_rtl_6_out0_V_TREADY;
  wire MVAU_rtl_6_out0_V_TVALID;
  wire [767:0]MVAU_rtl_7_out0_V_TDATA;
  wire MVAU_rtl_7_out0_V_TREADY;
  wire MVAU_rtl_7_out0_V_TVALID;
  wire [175:0]MVAU_rtl_8_out0_V_TDATA;
  wire MVAU_rtl_8_out0_V_TREADY;
  wire MVAU_rtl_8_out0_V_TVALID;
  wire [47:0]MVAU_rtl_9_out0_V_TDATA;
  wire MVAU_rtl_9_out0_V_TREADY;
  wire MVAU_rtl_9_out0_V_TVALID;
  wire [127:0]OuterShuffle_hls_0_out0_V_TDATA;
  wire OuterShuffle_hls_0_out0_V_TREADY;
  wire OuterShuffle_hls_0_out0_V_TVALID;
  wire [127:0]OuterShuffle_hls_1_out0_V_TDATA;
  wire OuterShuffle_hls_1_out0_V_TREADY;
  wire OuterShuffle_hls_1_out0_V_TVALID;
  wire [127:0]OuterShuffle_hls_2_out0_V_TDATA;
  wire OuterShuffle_hls_2_out0_V_TREADY;
  wire OuterShuffle_hls_2_out0_V_TVALID;
  wire [95:0]OuterShuffle_hls_3_out0_V_TDATA;
  wire OuterShuffle_hls_3_out0_V_TREADY;
  wire OuterShuffle_hls_3_out0_V_TVALID;
  wire [127:0]SelectToken_rtl_0_out0_V_TDATA;
  wire SelectToken_rtl_0_out0_V_TREADY;
  wire SelectToken_rtl_0_out0_V_TVALID;
  wire [127:0]StreamingDataWidthConverter_rtl_0_out0_V_TDATA;
  wire StreamingDataWidthConverter_rtl_0_out0_V_TREADY;
  wire StreamingDataWidthConverter_rtl_0_out0_V_TVALID;
  wire [63:0]StreamingDataWidthConverter_rtl_10_out0_V_TDATA;
  wire StreamingDataWidthConverter_rtl_10_out0_V_TREADY;
  wire StreamingDataWidthConverter_rtl_10_out0_V_TVALID;
  wire [63:0]StreamingDataWidthConverter_rtl_11_out0_V_TDATA;
  wire StreamingDataWidthConverter_rtl_11_out0_V_TREADY;
  wire StreamingDataWidthConverter_rtl_11_out0_V_TVALID;
  wire [63:0]StreamingDataWidthConverter_rtl_12_out0_V_TDATA;
  wire StreamingDataWidthConverter_rtl_12_out0_V_TREADY;
  wire StreamingDataWidthConverter_rtl_12_out0_V_TVALID;
  wire [87:0]StreamingDataWidthConverter_rtl_13_out0_V_TDATA;
  wire StreamingDataWidthConverter_rtl_13_out0_V_TREADY;
  wire StreamingDataWidthConverter_rtl_13_out0_V_TVALID;
  wire [63:0]StreamingDataWidthConverter_rtl_14_out0_V_TDATA;
  wire StreamingDataWidthConverter_rtl_14_out0_V_TREADY;
  wire StreamingDataWidthConverter_rtl_14_out0_V_TVALID;
  wire [95:0]StreamingDataWidthConverter_rtl_15_out0_V_TDATA;
  wire StreamingDataWidthConverter_rtl_15_out0_V_TREADY;
  wire StreamingDataWidthConverter_rtl_15_out0_V_TVALID;
  wire [191:0]StreamingDataWidthConverter_rtl_16_out0_V_TDATA;
  wire StreamingDataWidthConverter_rtl_16_out0_V_TREADY;
  wire StreamingDataWidthConverter_rtl_16_out0_V_TVALID;
  wire [87:0]StreamingDataWidthConverter_rtl_17_out0_V_TDATA;
  wire StreamingDataWidthConverter_rtl_17_out0_V_TREADY;
  wire StreamingDataWidthConverter_rtl_17_out0_V_TVALID;
  wire [255:0]StreamingDataWidthConverter_rtl_18_out0_V_TDATA;
  wire StreamingDataWidthConverter_rtl_18_out0_V_TREADY;
  wire StreamingDataWidthConverter_rtl_18_out0_V_TVALID;
  wire [127:0]StreamingDataWidthConverter_rtl_19_out0_V_TDATA;
  wire StreamingDataWidthConverter_rtl_19_out0_V_TREADY;
  wire StreamingDataWidthConverter_rtl_19_out0_V_TVALID;
  wire [127:0]StreamingDataWidthConverter_rtl_1_out0_V_TDATA;
  wire StreamingDataWidthConverter_rtl_1_out0_V_TREADY;
  wire StreamingDataWidthConverter_rtl_1_out0_V_TVALID;
  wire [127:0]StreamingDataWidthConverter_rtl_20_out0_V_TDATA;
  wire StreamingDataWidthConverter_rtl_20_out0_V_TREADY;
  wire StreamingDataWidthConverter_rtl_20_out0_V_TVALID;
  wire [383:0]StreamingDataWidthConverter_rtl_21_out0_V_TDATA;
  wire StreamingDataWidthConverter_rtl_21_out0_V_TREADY;
  wire StreamingDataWidthConverter_rtl_21_out0_V_TVALID;
  wire [87:0]StreamingDataWidthConverter_rtl_22_out0_V_TDATA;
  wire StreamingDataWidthConverter_rtl_22_out0_V_TREADY;
  wire StreamingDataWidthConverter_rtl_22_out0_V_TVALID;
  wire [383:0]StreamingDataWidthConverter_rtl_23_out0_V_TDATA;
  wire StreamingDataWidthConverter_rtl_23_out0_V_TREADY;
  wire StreamingDataWidthConverter_rtl_23_out0_V_TVALID;
  wire [95:0]StreamingDataWidthConverter_rtl_24_out0_V_TDATA;
  wire StreamingDataWidthConverter_rtl_24_out0_V_TREADY;
  wire StreamingDataWidthConverter_rtl_24_out0_V_TVALID;
  wire [191:0]StreamingDataWidthConverter_rtl_25_out0_V_TDATA;
  wire StreamingDataWidthConverter_rtl_25_out0_V_TREADY;
  wire StreamingDataWidthConverter_rtl_25_out0_V_TVALID;
  wire [87:0]StreamingDataWidthConverter_rtl_26_out0_V_TDATA;
  wire StreamingDataWidthConverter_rtl_26_out0_V_TREADY;
  wire StreamingDataWidthConverter_rtl_26_out0_V_TVALID;
  wire [63:0]StreamingDataWidthConverter_rtl_27_out0_V_TDATA;
  wire StreamingDataWidthConverter_rtl_27_out0_V_TREADY;
  wire StreamingDataWidthConverter_rtl_27_out0_V_TVALID;
  wire [63:0]StreamingDataWidthConverter_rtl_2_out0_V_TDATA;
  wire StreamingDataWidthConverter_rtl_2_out0_V_TREADY;
  wire StreamingDataWidthConverter_rtl_2_out0_V_TVALID;
  wire [191:0]StreamingDataWidthConverter_rtl_3_out0_V_TDATA;
  wire StreamingDataWidthConverter_rtl_3_out0_V_TREADY;
  wire StreamingDataWidthConverter_rtl_3_out0_V_TVALID;
  wire [191:0]StreamingDataWidthConverter_rtl_4_out0_V_TDATA;
  wire StreamingDataWidthConverter_rtl_4_out0_V_TREADY;
  wire StreamingDataWidthConverter_rtl_4_out0_V_TVALID;
  wire [191:0]StreamingDataWidthConverter_rtl_5_out0_V_TDATA;
  wire StreamingDataWidthConverter_rtl_5_out0_V_TREADY;
  wire StreamingDataWidthConverter_rtl_5_out0_V_TVALID;
  wire [87:0]StreamingDataWidthConverter_rtl_6_out0_V_TDATA;
  wire StreamingDataWidthConverter_rtl_6_out0_V_TREADY;
  wire StreamingDataWidthConverter_rtl_6_out0_V_TVALID;
  wire [87:0]StreamingDataWidthConverter_rtl_7_out0_V_TDATA;
  wire StreamingDataWidthConverter_rtl_7_out0_V_TREADY;
  wire StreamingDataWidthConverter_rtl_7_out0_V_TVALID;
  wire [87:0]StreamingDataWidthConverter_rtl_8_out0_V_TDATA;
  wire StreamingDataWidthConverter_rtl_8_out0_V_TREADY;
  wire StreamingDataWidthConverter_rtl_8_out0_V_TVALID;
  wire [511:0]StreamingDataWidthConverter_rtl_9_out0_V_TDATA;
  wire StreamingDataWidthConverter_rtl_9_out0_V_TREADY;
  wire StreamingDataWidthConverter_rtl_9_out0_V_TVALID;
  wire [255:0]StreamingFIFO_rtl_0_out0_V_TDATA;
  wire StreamingFIFO_rtl_0_out0_V_TREADY;
  wire StreamingFIFO_rtl_0_out0_V_TVALID;
  wire [191:0]StreamingFIFO_rtl_10_out0_V_TDATA;
  wire StreamingFIFO_rtl_10_out0_V_TREADY;
  wire StreamingFIFO_rtl_10_out0_V_TVALID;
  wire [191:0]StreamingFIFO_rtl_11_out0_V_TDATA;
  wire StreamingFIFO_rtl_11_out0_V_TREADY;
  wire StreamingFIFO_rtl_11_out0_V_TVALID;
  wire [191:0]StreamingFIFO_rtl_12_out0_V_TDATA;
  wire StreamingFIFO_rtl_12_out0_V_TREADY;
  wire StreamingFIFO_rtl_12_out0_V_TVALID;
  wire [351:0]StreamingFIFO_rtl_13_out0_V_TDATA;
  wire StreamingFIFO_rtl_13_out0_V_TREADY;
  wire StreamingFIFO_rtl_13_out0_V_TVALID;
  wire [351:0]StreamingFIFO_rtl_14_out0_V_TDATA;
  wire StreamingFIFO_rtl_14_out0_V_TREADY;
  wire StreamingFIFO_rtl_14_out0_V_TVALID;
  wire [351:0]StreamingFIFO_rtl_15_out0_V_TDATA;
  wire StreamingFIFO_rtl_15_out0_V_TREADY;
  wire StreamingFIFO_rtl_15_out0_V_TVALID;
  wire [87:0]StreamingFIFO_rtl_16_out0_V_TDATA;
  wire StreamingFIFO_rtl_16_out0_V_TREADY;
  wire StreamingFIFO_rtl_16_out0_V_TVALID;
  wire [87:0]StreamingFIFO_rtl_17_out0_V_TDATA;
  wire StreamingFIFO_rtl_17_out0_V_TREADY;
  wire StreamingFIFO_rtl_17_out0_V_TVALID;
  wire [87:0]StreamingFIFO_rtl_18_out0_V_TDATA;
  wire StreamingFIFO_rtl_18_out0_V_TREADY;
  wire StreamingFIFO_rtl_18_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_19_out0_V_TDATA;
  wire StreamingFIFO_rtl_19_out0_V_TREADY;
  wire StreamingFIFO_rtl_19_out0_V_TVALID;
  wire [255:0]StreamingFIFO_rtl_1_out0_V_TDATA;
  wire StreamingFIFO_rtl_1_out0_V_TREADY;
  wire StreamingFIFO_rtl_1_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_20_out0_V_TDATA;
  wire StreamingFIFO_rtl_20_out0_V_TREADY;
  wire StreamingFIFO_rtl_20_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_21_out0_V_TDATA;
  wire StreamingFIFO_rtl_21_out0_V_TREADY;
  wire StreamingFIFO_rtl_21_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_22_out0_V_TDATA;
  wire StreamingFIFO_rtl_22_out0_V_TREADY;
  wire StreamingFIFO_rtl_22_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_23_out0_V_TDATA;
  wire StreamingFIFO_rtl_23_out0_V_TREADY;
  wire StreamingFIFO_rtl_23_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_24_out0_V_TDATA;
  wire StreamingFIFO_rtl_24_out0_V_TREADY;
  wire StreamingFIFO_rtl_24_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_25_out0_V_TDATA;
  wire StreamingFIFO_rtl_25_out0_V_TREADY;
  wire StreamingFIFO_rtl_25_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_26_out0_V_TDATA;
  wire StreamingFIFO_rtl_26_out0_V_TREADY;
  wire StreamingFIFO_rtl_26_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_27_out0_V_TDATA;
  wire StreamingFIFO_rtl_27_out0_V_TREADY;
  wire StreamingFIFO_rtl_27_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_28_out0_V_TDATA;
  wire StreamingFIFO_rtl_28_out0_V_TREADY;
  wire StreamingFIFO_rtl_28_out0_V_TVALID;
  wire [31:0]StreamingFIFO_rtl_29_out0_V_TDATA;
  wire StreamingFIFO_rtl_29_out0_V_TREADY;
  wire StreamingFIFO_rtl_29_out0_V_TVALID;
  wire [255:0]StreamingFIFO_rtl_2_out0_V_TDATA;
  wire StreamingFIFO_rtl_2_out0_V_TREADY;
  wire StreamingFIFO_rtl_2_out0_V_TVALID;
  wire [31:0]StreamingFIFO_rtl_30_out0_V_TDATA;
  wire StreamingFIFO_rtl_30_out0_V_TREADY;
  wire StreamingFIFO_rtl_30_out0_V_TVALID;
  wire [511:0]StreamingFIFO_rtl_31_out0_V_TDATA;
  wire StreamingFIFO_rtl_31_out0_V_TREADY;
  wire StreamingFIFO_rtl_31_out0_V_TVALID;
  wire [63:0]StreamingFIFO_rtl_32_out0_V_TDATA;
  wire StreamingFIFO_rtl_32_out0_V_TREADY;
  wire StreamingFIFO_rtl_32_out0_V_TVALID;
  wire [63:0]StreamingFIFO_rtl_33_out0_V_TDATA;
  wire StreamingFIFO_rtl_33_out0_V_TREADY;
  wire StreamingFIFO_rtl_33_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_34_out0_V_TDATA;
  wire StreamingFIFO_rtl_34_out0_V_TREADY;
  wire StreamingFIFO_rtl_34_out0_V_TVALID;
  wire [63:0]StreamingFIFO_rtl_35_out0_V_TDATA;
  wire StreamingFIFO_rtl_35_out0_V_TREADY;
  wire StreamingFIFO_rtl_35_out0_V_TVALID;
  wire [167:0]StreamingFIFO_rtl_36_out0_V_TDATA;
  wire StreamingFIFO_rtl_36_out0_V_TREADY;
  wire StreamingFIFO_rtl_36_out0_V_TVALID;
  wire [87:0]StreamingFIFO_rtl_37_out0_V_TDATA;
  wire StreamingFIFO_rtl_37_out0_V_TREADY;
  wire StreamingFIFO_rtl_37_out0_V_TVALID;
  wire [31:0]StreamingFIFO_rtl_38_out0_V_TDATA;
  wire StreamingFIFO_rtl_38_out0_V_TREADY;
  wire StreamingFIFO_rtl_38_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_39_out0_V_TDATA;
  wire StreamingFIFO_rtl_39_out0_V_TREADY;
  wire StreamingFIFO_rtl_39_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_3_out0_V_TDATA;
  wire StreamingFIFO_rtl_3_out0_V_TREADY;
  wire StreamingFIFO_rtl_3_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_40_out0_V_TDATA;
  wire StreamingFIFO_rtl_40_out0_V_TREADY;
  wire StreamingFIFO_rtl_40_out0_V_TVALID;
  wire [31:0]StreamingFIFO_rtl_41_out0_V_TDATA;
  wire StreamingFIFO_rtl_41_out0_V_TREADY;
  wire StreamingFIFO_rtl_41_out0_V_TVALID;
  wire [63:0]StreamingFIFO_rtl_42_out0_V_TDATA;
  wire StreamingFIFO_rtl_42_out0_V_TREADY;
  wire StreamingFIFO_rtl_42_out0_V_TVALID;
  wire [183:0]StreamingFIFO_rtl_43_out0_V_TDATA;
  wire StreamingFIFO_rtl_43_out0_V_TREADY;
  wire StreamingFIFO_rtl_43_out0_V_TVALID;
  wire [95:0]StreamingFIFO_rtl_44_out0_V_TDATA;
  wire StreamingFIFO_rtl_44_out0_V_TREADY;
  wire StreamingFIFO_rtl_44_out0_V_TVALID;
  wire [95:0]StreamingFIFO_rtl_45_out0_V_TDATA;
  wire StreamingFIFO_rtl_45_out0_V_TREADY;
  wire StreamingFIFO_rtl_45_out0_V_TVALID;
  wire [31:0]StreamingFIFO_rtl_46_out0_V_TDATA;
  wire StreamingFIFO_rtl_46_out0_V_TREADY;
  wire StreamingFIFO_rtl_46_out0_V_TVALID;
  wire [191:0]StreamingFIFO_rtl_47_out0_V_TDATA;
  wire StreamingFIFO_rtl_47_out0_V_TREADY;
  wire StreamingFIFO_rtl_47_out0_V_TVALID;
  wire [351:0]StreamingFIFO_rtl_48_out0_V_TDATA;
  wire StreamingFIFO_rtl_48_out0_V_TREADY;
  wire StreamingFIFO_rtl_48_out0_V_TVALID;
  wire [87:0]StreamingFIFO_rtl_49_out0_V_TDATA;
  wire StreamingFIFO_rtl_49_out0_V_TREADY;
  wire StreamingFIFO_rtl_49_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_4_out0_V_TDATA;
  wire StreamingFIFO_rtl_4_out0_V_TREADY;
  wire StreamingFIFO_rtl_4_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_50_out0_V_TDATA;
  wire StreamingFIFO_rtl_50_out0_V_TREADY;
  wire StreamingFIFO_rtl_50_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_51_out0_V_TDATA;
  wire StreamingFIFO_rtl_51_out0_V_TREADY;
  wire StreamingFIFO_rtl_51_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_52_out0_V_TDATA;
  wire StreamingFIFO_rtl_52_out0_V_TREADY;
  wire StreamingFIFO_rtl_52_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_53_out0_V_TDATA;
  wire StreamingFIFO_rtl_53_out0_V_TREADY;
  wire StreamingFIFO_rtl_53_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_54_out0_V_TDATA;
  wire StreamingFIFO_rtl_54_out0_V_TREADY;
  wire StreamingFIFO_rtl_54_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_55_out0_V_TDATA;
  wire StreamingFIFO_rtl_55_out0_V_TREADY;
  wire StreamingFIFO_rtl_55_out0_V_TVALID;
  wire [255:0]StreamingFIFO_rtl_56_out0_V_TDATA;
  wire StreamingFIFO_rtl_56_out0_V_TREADY;
  wire StreamingFIFO_rtl_56_out0_V_TVALID;
  wire [255:0]StreamingFIFO_rtl_57_out0_V_TDATA;
  wire StreamingFIFO_rtl_57_out0_V_TREADY;
  wire StreamingFIFO_rtl_57_out0_V_TVALID;
  wire [255:0]StreamingFIFO_rtl_58_out0_V_TDATA;
  wire StreamingFIFO_rtl_58_out0_V_TREADY;
  wire StreamingFIFO_rtl_58_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_59_out0_V_TDATA;
  wire StreamingFIFO_rtl_59_out0_V_TREADY;
  wire StreamingFIFO_rtl_59_out0_V_TVALID;
  wire [31:0]StreamingFIFO_rtl_5_out0_V_TDATA;
  wire StreamingFIFO_rtl_5_out0_V_TREADY;
  wire StreamingFIFO_rtl_5_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_60_out0_V_TDATA;
  wire StreamingFIFO_rtl_60_out0_V_TREADY;
  wire StreamingFIFO_rtl_60_out0_V_TVALID;
  wire [31:0]StreamingFIFO_rtl_61_out0_V_TDATA;
  wire StreamingFIFO_rtl_61_out0_V_TREADY;
  wire StreamingFIFO_rtl_61_out0_V_TVALID;
  wire [383:0]StreamingFIFO_rtl_62_out0_V_TDATA;
  wire StreamingFIFO_rtl_62_out0_V_TREADY;
  wire StreamingFIFO_rtl_62_out0_V_TVALID;
  wire [703:0]StreamingFIFO_rtl_63_out0_V_TDATA;
  wire StreamingFIFO_rtl_63_out0_V_TREADY;
  wire StreamingFIFO_rtl_63_out0_V_TVALID;
  wire [87:0]StreamingFIFO_rtl_64_out0_V_TDATA;
  wire StreamingFIFO_rtl_64_out0_V_TREADY;
  wire StreamingFIFO_rtl_64_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_65_out0_V_TDATA;
  wire StreamingFIFO_rtl_65_out0_V_TREADY;
  wire StreamingFIFO_rtl_65_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_66_out0_V_TDATA;
  wire StreamingFIFO_rtl_66_out0_V_TREADY;
  wire StreamingFIFO_rtl_66_out0_V_TVALID;
  wire [31:0]StreamingFIFO_rtl_67_out0_V_TDATA;
  wire StreamingFIFO_rtl_67_out0_V_TREADY;
  wire StreamingFIFO_rtl_67_out0_V_TVALID;
  wire [383:0]StreamingFIFO_rtl_68_out0_V_TDATA;
  wire StreamingFIFO_rtl_68_out0_V_TREADY;
  wire StreamingFIFO_rtl_68_out0_V_TVALID;
  wire [767:0]StreamingFIFO_rtl_69_out0_V_TDATA;
  wire StreamingFIFO_rtl_69_out0_V_TREADY;
  wire StreamingFIFO_rtl_69_out0_V_TVALID;
  wire [63:0]StreamingFIFO_rtl_6_out0_V_TDATA;
  wire StreamingFIFO_rtl_6_out0_V_TREADY;
  wire StreamingFIFO_rtl_6_out0_V_TVALID;
  wire [95:0]StreamingFIFO_rtl_70_out0_V_TDATA;
  wire StreamingFIFO_rtl_70_out0_V_TREADY;
  wire StreamingFIFO_rtl_70_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_71_out0_V_TDATA;
  wire StreamingFIFO_rtl_71_out0_V_TREADY;
  wire StreamingFIFO_rtl_71_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_72_out0_V_TDATA;
  wire StreamingFIFO_rtl_72_out0_V_TREADY;
  wire StreamingFIFO_rtl_72_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_73_out0_V_TDATA;
  wire StreamingFIFO_rtl_73_out0_V_TREADY;
  wire StreamingFIFO_rtl_73_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_74_out0_V_TDATA;
  wire StreamingFIFO_rtl_74_out0_V_TREADY;
  wire StreamingFIFO_rtl_74_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_75_out0_V_TDATA;
  wire StreamingFIFO_rtl_75_out0_V_TREADY;
  wire StreamingFIFO_rtl_75_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_76_out0_V_TDATA;
  wire StreamingFIFO_rtl_76_out0_V_TREADY;
  wire StreamingFIFO_rtl_76_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_77_out0_V_TDATA;
  wire StreamingFIFO_rtl_77_out0_V_TREADY;
  wire StreamingFIFO_rtl_77_out0_V_TVALID;
  wire [31:0]StreamingFIFO_rtl_78_out0_V_TDATA;
  wire StreamingFIFO_rtl_78_out0_V_TREADY;
  wire StreamingFIFO_rtl_78_out0_V_TVALID;
  wire [191:0]StreamingFIFO_rtl_79_out0_V_TDATA;
  wire StreamingFIFO_rtl_79_out0_V_TREADY;
  wire StreamingFIFO_rtl_79_out0_V_TVALID;
  wire [63:0]StreamingFIFO_rtl_7_out0_V_TDATA;
  wire StreamingFIFO_rtl_7_out0_V_TREADY;
  wire StreamingFIFO_rtl_7_out0_V_TVALID;
  wire [175:0]StreamingFIFO_rtl_80_out0_V_TDATA;
  wire StreamingFIFO_rtl_80_out0_V_TREADY;
  wire StreamingFIFO_rtl_80_out0_V_TVALID;
  wire [87:0]StreamingFIFO_rtl_81_out0_V_TDATA;
  wire StreamingFIFO_rtl_81_out0_V_TREADY;
  wire StreamingFIFO_rtl_81_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_82_out0_V_TDATA;
  wire StreamingFIFO_rtl_82_out0_V_TREADY;
  wire StreamingFIFO_rtl_82_out0_V_TVALID;
  wire [127:0]StreamingFIFO_rtl_83_out0_V_TDATA;
  wire StreamingFIFO_rtl_83_out0_V_TREADY;
  wire StreamingFIFO_rtl_83_out0_V_TVALID;
  wire [31:0]StreamingFIFO_rtl_84_out0_V_TDATA;
  wire StreamingFIFO_rtl_84_out0_V_TREADY;
  wire StreamingFIFO_rtl_84_out0_V_TVALID;
  wire [31:0]StreamingFIFO_rtl_85_out0_V_TDATA;
  wire StreamingFIFO_rtl_85_out0_V_TREADY;
  wire StreamingFIFO_rtl_85_out0_V_TVALID;
  wire [63:0]StreamingFIFO_rtl_86_out0_V_TDATA;
  wire StreamingFIFO_rtl_86_out0_V_TREADY;
  wire StreamingFIFO_rtl_86_out0_V_TVALID;
  wire [47:0]StreamingFIFO_rtl_87_out0_V_TDATA;
  wire StreamingFIFO_rtl_87_out0_V_TREADY;
  wire StreamingFIFO_rtl_87_out0_V_TVALID;
  wire [63:0]StreamingFIFO_rtl_88_out0_V_TDATA;
  wire StreamingFIFO_rtl_88_out0_V_TREADY;
  wire StreamingFIFO_rtl_88_out0_V_TVALID;
  wire [63:0]StreamingFIFO_rtl_8_out0_V_TDATA;
  wire StreamingFIFO_rtl_8_out0_V_TREADY;
  wire StreamingFIFO_rtl_8_out0_V_TVALID;
  wire [63:0]StreamingFIFO_rtl_9_out0_V_TDATA;
  wire StreamingFIFO_rtl_9_out0_V_TREADY;
  wire StreamingFIFO_rtl_9_out0_V_TVALID;
  wire [31:0]Thresholding_rtl_0_out0_V_TDATA;
  wire Thresholding_rtl_0_out0_V_TREADY;
  wire Thresholding_rtl_0_out0_V_TVALID;
  wire [31:0]Thresholding_rtl_10_out0_V_TDATA;
  wire Thresholding_rtl_10_out0_V_TREADY;
  wire Thresholding_rtl_10_out0_V_TVALID;
  wire [31:0]Thresholding_rtl_11_out0_V_TDATA;
  wire Thresholding_rtl_11_out0_V_TREADY;
  wire Thresholding_rtl_11_out0_V_TVALID;
  wire [31:0]Thresholding_rtl_1_out0_V_TDATA;
  wire Thresholding_rtl_1_out0_V_TREADY;
  wire Thresholding_rtl_1_out0_V_TVALID;
  wire [31:0]Thresholding_rtl_2_out0_V_TDATA;
  wire Thresholding_rtl_2_out0_V_TREADY;
  wire Thresholding_rtl_2_out0_V_TVALID;
  wire [127:0]Thresholding_rtl_3_out0_V_TDATA;
  wire Thresholding_rtl_3_out0_V_TREADY;
  wire Thresholding_rtl_3_out0_V_TVALID;
  wire [31:0]Thresholding_rtl_4_out0_V_TDATA;
  wire Thresholding_rtl_4_out0_V_TREADY;
  wire Thresholding_rtl_4_out0_V_TVALID;
  wire [31:0]Thresholding_rtl_5_out0_V_TDATA;
  wire Thresholding_rtl_5_out0_V_TREADY;
  wire Thresholding_rtl_5_out0_V_TVALID;
  wire [31:0]Thresholding_rtl_6_out0_V_TDATA;
  wire Thresholding_rtl_6_out0_V_TREADY;
  wire Thresholding_rtl_6_out0_V_TVALID;
  wire [31:0]Thresholding_rtl_7_out0_V_TDATA;
  wire Thresholding_rtl_7_out0_V_TREADY;
  wire Thresholding_rtl_7_out0_V_TVALID;
  wire [31:0]Thresholding_rtl_8_out0_V_TDATA;
  wire Thresholding_rtl_8_out0_V_TREADY;
  wire Thresholding_rtl_8_out0_V_TVALID;
  wire [31:0]Thresholding_rtl_9_out0_V_TDATA;
  wire Thresholding_rtl_9_out0_V_TREADY;
  wire Thresholding_rtl_9_out0_V_TVALID;
  wire ap_clk;
  wire ap_rst_n;
  wire [63:0]m_axis_0_tdata;
  wire m_axis_0_tready;
  wire m_axis_0_tvalid;
  wire [255:0]s_axis_0_tdata;
  wire s_axis_0_tready;
  wire s_axis_0_tvalid;
  wire sim_finish;

  finn_design_DuplicateStreams_hls_0_0 DuplicateStreams_hls_0
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_0_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_0_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_0_out0_V_TVALID),
        .out0_V_TDATA(DuplicateStreams_hls_0_out0_V_TDATA),
        .out0_V_TREADY(DuplicateStreams_hls_0_out0_V_TREADY),
        .out0_V_TVALID(DuplicateStreams_hls_0_out0_V_TVALID),
        .out1_V_TDATA(DuplicateStreams_hls_0_out1_V_TDATA),
        .out1_V_TREADY(DuplicateStreams_hls_0_out1_V_TREADY),
        .out1_V_TVALID(DuplicateStreams_hls_0_out1_V_TVALID));
  finn_design_DuplicateStreams_hls_1_0 DuplicateStreams_hls_1
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_6_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_6_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_6_out0_V_TVALID),
        .out0_V_TDATA(DuplicateStreams_hls_1_out0_V_TDATA),
        .out0_V_TREADY(DuplicateStreams_hls_1_out0_V_TREADY),
        .out0_V_TVALID(DuplicateStreams_hls_1_out0_V_TVALID),
        .out1_V_TDATA(DuplicateStreams_hls_1_out1_V_TDATA),
        .out1_V_TREADY(DuplicateStreams_hls_1_out1_V_TREADY),
        .out1_V_TVALID(DuplicateStreams_hls_1_out1_V_TVALID),
        .out2_V_TDATA(DuplicateStreams_hls_1_out2_V_TDATA),
        .out2_V_TREADY(DuplicateStreams_hls_1_out2_V_TREADY),
        .out2_V_TVALID(DuplicateStreams_hls_1_out2_V_TVALID));
  finn_design_DuplicateStreams_hls_2_0 DuplicateStreams_hls_2
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_56_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_56_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_56_out0_V_TVALID),
        .out0_V_TDATA(DuplicateStreams_hls_2_out0_V_TDATA),
        .out0_V_TREADY(DuplicateStreams_hls_2_out0_V_TREADY),
        .out0_V_TVALID(DuplicateStreams_hls_2_out0_V_TVALID),
        .out1_V_TDATA(DuplicateStreams_hls_2_out1_V_TDATA),
        .out1_V_TREADY(DuplicateStreams_hls_2_out1_V_TREADY),
        .out1_V_TVALID(DuplicateStreams_hls_2_out1_V_TVALID));
  ElementwiseAdd_rtl_0_imp_13HFK09 ElementwiseAdd_rtl_0
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_21_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_21_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_21_out0_V_TVALID),
        .out0_V_tdata(ElementwiseAdd_rtl_0_out0_V_TDATA),
        .out0_V_tready(ElementwiseAdd_rtl_0_out0_V_TREADY),
        .out0_V_tvalid(ElementwiseAdd_rtl_0_out0_V_TVALID));
  ElementwiseAdd_rtl_1_imp_62U4IU ElementwiseAdd_rtl_1
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_20_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_20_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_20_out0_V_TVALID),
        .out0_V_tdata(ElementwiseAdd_rtl_1_out0_V_TDATA),
        .out0_V_tready(ElementwiseAdd_rtl_1_out0_V_TREADY),
        .out0_V_tvalid(ElementwiseAdd_rtl_1_out0_V_TVALID));
  ElementwiseAdd_rtl_10_imp_PZKKR8 ElementwiseAdd_rtl_10
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_82_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_82_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_82_out0_V_TVALID),
        .out0_V_tdata(ElementwiseAdd_rtl_10_out0_V_TDATA),
        .out0_V_tready(ElementwiseAdd_rtl_10_out0_V_TREADY),
        .out0_V_tvalid(ElementwiseAdd_rtl_10_out0_V_TVALID));
  ElementwiseAdd_rtl_11_imp_1IY9P4R ElementwiseAdd_rtl_11
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_88_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_88_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_88_out0_V_TVALID),
        .out0_V_tdata(ElementwiseAdd_rtl_11_out0_V_TDATA),
        .out0_V_tready(ElementwiseAdd_rtl_11_out0_V_TREADY),
        .out0_V_tvalid(ElementwiseAdd_rtl_11_out0_V_TVALID));
  ElementwiseAdd_rtl_2_imp_RBIH7A ElementwiseAdd_rtl_2
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_19_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_19_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_19_out0_V_TVALID),
        .out0_V_tdata(ElementwiseAdd_rtl_2_out0_V_TDATA),
        .out0_V_tready(ElementwiseAdd_rtl_2_out0_V_TREADY),
        .out0_V_tvalid(ElementwiseAdd_rtl_2_out0_V_TVALID));
  ElementwiseAdd_rtl_3_imp_1XBFDVD ElementwiseAdd_rtl_3
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_50_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_50_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_50_out0_V_TVALID),
        .out0_V_tdata(ElementwiseAdd_rtl_3_out0_V_TDATA),
        .out0_V_tready(ElementwiseAdd_rtl_3_out0_V_TREADY),
        .out0_V_tvalid(ElementwiseAdd_rtl_3_out0_V_TVALID));
  ElementwiseAdd_rtl_4_imp_137DH86 ElementwiseAdd_rtl_4
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_51_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_51_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_51_out0_V_TVALID),
        .in1_V_tdata(StreamingFIFO_rtl_3_out0_V_TDATA),
        .in1_V_tready(StreamingFIFO_rtl_3_out0_V_TREADY),
        .in1_V_tvalid(StreamingFIFO_rtl_3_out0_V_TVALID),
        .out0_V_tdata(ElementwiseAdd_rtl_4_out0_V_TDATA),
        .out0_V_tready(ElementwiseAdd_rtl_4_out0_V_TREADY),
        .out0_V_tvalid(ElementwiseAdd_rtl_4_out0_V_TVALID));
  ElementwiseAdd_rtl_5_imp_6D2DQX ElementwiseAdd_rtl_5
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_54_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_54_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_54_out0_V_TVALID),
        .out0_V_tdata(ElementwiseAdd_rtl_5_out0_V_TDATA),
        .out0_V_tready(ElementwiseAdd_rtl_5_out0_V_TREADY),
        .out0_V_tvalid(ElementwiseAdd_rtl_5_out0_V_TVALID));
  ElementwiseAdd_rtl_6_imp_R1AHUX ElementwiseAdd_rtl_6
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_65_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_65_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_65_out0_V_TVALID),
        .out0_V_tdata(ElementwiseAdd_rtl_6_out0_V_TDATA),
        .out0_V_tready(ElementwiseAdd_rtl_6_out0_V_TREADY),
        .out0_V_tvalid(ElementwiseAdd_rtl_6_out0_V_TVALID));
  ElementwiseAdd_rtl_7_imp_1XLHWUE ElementwiseAdd_rtl_7
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_71_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_71_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_71_out0_V_TVALID),
        .out0_V_tdata(ElementwiseAdd_rtl_7_out0_V_TDATA),
        .out0_V_tready(ElementwiseAdd_rtl_7_out0_V_TREADY),
        .out0_V_tvalid(ElementwiseAdd_rtl_7_out0_V_TVALID));
  ElementwiseAdd_rtl_8_imp_11T133R ElementwiseAdd_rtl_8
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_72_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_72_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_72_out0_V_TVALID),
        .in1_V_tdata(StreamingFIFO_rtl_59_out0_V_TDATA),
        .in1_V_tready(StreamingFIFO_rtl_59_out0_V_TREADY),
        .in1_V_tvalid(StreamingFIFO_rtl_59_out0_V_TVALID),
        .out0_V_tdata(ElementwiseAdd_rtl_8_out0_V_TDATA),
        .out0_V_tready(ElementwiseAdd_rtl_8_out0_V_TREADY),
        .out0_V_tvalid(ElementwiseAdd_rtl_8_out0_V_TVALID));
  ElementwiseAdd_rtl_9_imp_5IPX94 ElementwiseAdd_rtl_9
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_75_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_75_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_75_out0_V_TVALID),
        .out0_V_tdata(ElementwiseAdd_rtl_9_out0_V_TDATA),
        .out0_V_tready(ElementwiseAdd_rtl_9_out0_V_TREADY),
        .out0_V_tvalid(ElementwiseAdd_rtl_9_out0_V_TVALID));
  ElementwiseMul_rtl_0_imp_13JTGOS ElementwiseMul_rtl_0
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_16_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_16_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_16_out0_V_TVALID),
        .out0_V_tdata(ElementwiseMul_rtl_0_out0_V_TDATA),
        .out0_V_tready(ElementwiseMul_rtl_0_out0_V_TREADY),
        .out0_V_tvalid(ElementwiseMul_rtl_0_out0_V_TVALID));
  ElementwiseMul_rtl_1_imp_5VMEAB ElementwiseMul_rtl_1
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_17_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_17_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_17_out0_V_TVALID),
        .out0_V_tdata(ElementwiseMul_rtl_1_out0_V_TDATA),
        .out0_V_tready(ElementwiseMul_rtl_1_out0_V_TREADY),
        .out0_V_tvalid(ElementwiseMul_rtl_1_out0_V_TVALID));
  ElementwiseMul_rtl_10_imp_1RZQEYN ElementwiseMul_rtl_10
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_87_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_87_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_87_out0_V_TVALID),
        .out0_V_tdata(ElementwiseMul_rtl_10_out0_V_TDATA),
        .out0_V_tready(ElementwiseMul_rtl_10_out0_V_TREADY),
        .out0_V_tvalid(ElementwiseMul_rtl_10_out0_V_TVALID));
  ElementwiseMul_rtl_2_imp_RDTHCZ ElementwiseMul_rtl_2
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_18_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_18_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_18_out0_V_TVALID),
        .out0_V_tdata(ElementwiseMul_rtl_2_out0_V_TDATA),
        .out0_V_tready(ElementwiseMul_rtl_2_out0_V_TREADY),
        .out0_V_tvalid(ElementwiseMul_rtl_2_out0_V_TVALID));
  ElementwiseMul_rtl_3_imp_1X3ZB64 ElementwiseMul_rtl_3
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_38_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_38_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_38_out0_V_TVALID),
        .out0_V_tdata(ElementwiseMul_rtl_3_out0_V_TDATA),
        .out0_V_tready(ElementwiseMul_rtl_3_out0_V_TREADY),
        .out0_V_tvalid(ElementwiseMul_rtl_3_out0_V_TVALID));
  ElementwiseMul_rtl_4_imp_139WKAR ElementwiseMul_rtl_4
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_49_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_49_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_49_out0_V_TVALID),
        .out0_V_tdata(ElementwiseMul_rtl_4_out0_V_TDATA),
        .out0_V_tready(ElementwiseMul_rtl_4_out0_V_TREADY),
        .out0_V_tvalid(ElementwiseMul_rtl_4_out0_V_TVALID));
  ElementwiseMul_rtl_5_imp_65DJ8S ElementwiseMul_rtl_5
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_53_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_53_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_53_out0_V_TVALID),
        .out0_V_tdata(ElementwiseMul_rtl_5_out0_V_TDATA),
        .out0_V_tready(ElementwiseMul_rtl_5_out0_V_TREADY),
        .out0_V_tvalid(ElementwiseMul_rtl_5_out0_V_TVALID));
  ElementwiseMul_rtl_6_imp_R423BW ElementwiseMul_rtl_6
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_64_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_64_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_64_out0_V_TVALID),
        .out0_V_tdata(ElementwiseMul_rtl_6_out0_V_TDATA),
        .out0_V_tready(ElementwiseMul_rtl_6_out0_V_TREADY),
        .out0_V_tvalid(ElementwiseMul_rtl_6_out0_V_TVALID));
  ElementwiseMul_rtl_7_imp_1XDVS4Z ElementwiseMul_rtl_7
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_70_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_70_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_70_out0_V_TVALID),
        .out0_V_tdata(ElementwiseMul_rtl_7_out0_V_TDATA),
        .out0_V_tready(ElementwiseMul_rtl_7_out0_V_TREADY),
        .out0_V_tvalid(ElementwiseMul_rtl_7_out0_V_TVALID));
  ElementwiseMul_rtl_8_imp_11VPVEQ ElementwiseMul_rtl_8
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_74_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_74_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_74_out0_V_TVALID),
        .out0_V_tdata(ElementwiseMul_rtl_8_out0_V_TDATA),
        .out0_V_tready(ElementwiseMul_rtl_8_out0_V_TREADY),
        .out0_V_tvalid(ElementwiseMul_rtl_8_out0_V_TVALID));
  ElementwiseMul_rtl_9_imp_5B6LNX ElementwiseMul_rtl_9
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_81_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_81_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_81_out0_V_TVALID),
        .out0_V_tdata(ElementwiseMul_rtl_9_out0_V_TDATA),
        .out0_V_tready(ElementwiseMul_rtl_9_out0_V_TREADY),
        .out0_V_tvalid(ElementwiseMul_rtl_9_out0_V_TVALID));
  finn_design_HWSoftmax_rtl_0_0 HWSoftmax_rtl_0
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_39_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_39_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_39_out0_V_TVALID),
        .out0_V_TDATA(HWSoftmax_rtl_0_out0_V_TDATA),
        .out0_V_TREADY(HWSoftmax_rtl_0_out0_V_TREADY),
        .out0_V_TVALID(HWSoftmax_rtl_0_out0_V_TVALID));
  finn_design_InnerShuffle_rtl_0_0 InnerShuffle_rtl_0
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_27_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_27_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_27_out0_V_TVALID),
        .out0_V_TDATA(InnerShuffle_rtl_0_out0_V_TDATA),
        .out0_V_TREADY(InnerShuffle_rtl_0_out0_V_TREADY),
        .out0_V_TVALID(InnerShuffle_rtl_0_out0_V_TVALID));
  finn_design_LayerNorm_rtl_0_0 LayerNorm_rtl_0
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_52_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_52_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_52_out0_V_TVALID),
        .out0_V_TDATA(LayerNorm_rtl_0_out0_V_TDATA),
        .out0_V_TREADY(LayerNorm_rtl_0_out0_V_TREADY),
        .out0_V_TVALID(LayerNorm_rtl_0_out0_V_TVALID));
  finn_design_LayerNorm_rtl_1_0 LayerNorm_rtl_1
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_73_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_73_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_73_out0_V_TVALID),
        .out0_V_TDATA(LayerNorm_rtl_1_out0_V_TDATA),
        .out0_V_TREADY(LayerNorm_rtl_1_out0_V_TREADY),
        .out0_V_TVALID(LayerNorm_rtl_1_out0_V_TVALID));
  MVAU_rtl_0_imp_1DNJB9Y MVAU_rtl_0
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_12_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_12_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_12_out0_V_TVALID),
        .out0_V_tdata(MVAU_rtl_0_out0_V_TDATA),
        .out0_V_tready(MVAU_rtl_0_out0_V_TREADY),
        .out0_V_tvalid(MVAU_rtl_0_out0_V_TVALID));
  MVAU_rtl_1_imp_BGQB3T MVAU_rtl_1
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_11_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_11_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_11_out0_V_TVALID),
        .out0_V_tdata(MVAU_rtl_1_out0_V_TDATA),
        .out0_V_tready(MVAU_rtl_1_out0_V_TREADY),
        .out0_V_tvalid(MVAU_rtl_1_out0_V_TVALID));
  MVAU_rtl_2_imp_QB0MDL MVAU_rtl_2
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_10_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_10_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_10_out0_V_TVALID),
        .out0_V_tdata(MVAU_rtl_2_out0_V_TDATA),
        .out0_V_tready(MVAU_rtl_2_out0_V_TREADY),
        .out0_V_tvalid(MVAU_rtl_2_out0_V_TVALID));
  MVAU_rtl_3_imp_1IRXAUE MVAU_rtl_3
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_33_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_33_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_33_out0_V_TVALID),
        .in1_V_tdata(StreamingFIFO_rtl_35_out0_V_TDATA),
        .in1_V_tready(StreamingFIFO_rtl_35_out0_V_TREADY),
        .in1_V_tvalid(StreamingFIFO_rtl_35_out0_V_TVALID),
        .out0_V_tdata(MVAU_rtl_3_out0_V_TDATA),
        .out0_V_tready(MVAU_rtl_3_out0_V_TREADY),
        .out0_V_tvalid(MVAU_rtl_3_out0_V_TVALID));
  MVAU_rtl_4_imp_1DDGY3T MVAU_rtl_4
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_42_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_42_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_42_out0_V_TVALID),
        .in1_V_tdata(StreamingFIFO_rtl_32_out0_V_TDATA),
        .in1_V_tready(StreamingFIFO_rtl_32_out0_V_TREADY),
        .in1_V_tvalid(StreamingFIFO_rtl_32_out0_V_TVALID),
        .out0_V_tdata(MVAU_rtl_4_out0_V_TDATA),
        .out0_V_tready(MVAU_rtl_4_out0_V_TREADY),
        .out0_V_tvalid(MVAU_rtl_4_out0_V_TVALID));
  MVAU_rtl_5_imp_BQYGG6 MVAU_rtl_5
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_47_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_47_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_47_out0_V_TVALID),
        .out0_V_tdata(MVAU_rtl_5_out0_V_TDATA),
        .out0_V_tready(MVAU_rtl_5_out0_V_TREADY),
        .out0_V_tvalid(MVAU_rtl_5_out0_V_TVALID));
  MVAU_rtl_6_imp_Q0SX86 MVAU_rtl_6
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_62_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_62_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_62_out0_V_TVALID),
        .out0_V_tdata(MVAU_rtl_6_out0_V_TDATA),
        .out0_V_tready(MVAU_rtl_6_out0_V_TREADY),
        .out0_V_tvalid(MVAU_rtl_6_out0_V_TVALID));
  MVAU_rtl_7_imp_1J1ZXW9 MVAU_rtl_7
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_68_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_68_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_68_out0_V_TVALID),
        .out0_V_tdata(MVAU_rtl_7_out0_V_TDATA),
        .out0_V_tready(MVAU_rtl_7_out0_V_TREADY),
        .out0_V_tvalid(MVAU_rtl_7_out0_V_TVALID));
  MVAU_rtl_8_imp_1E7OKDK MVAU_rtl_8
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_79_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_79_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_79_out0_V_TVALID),
        .out0_V_tdata(MVAU_rtl_8_out0_V_TDATA),
        .out0_V_tready(MVAU_rtl_8_out0_V_TREADY),
        .out0_V_tvalid(MVAU_rtl_8_out0_V_TVALID));
  MVAU_rtl_9_imp_D54FGN MVAU_rtl_9
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_tdata(StreamingFIFO_rtl_86_out0_V_TDATA),
        .in0_V_tready(StreamingFIFO_rtl_86_out0_V_TREADY),
        .in0_V_tvalid(StreamingFIFO_rtl_86_out0_V_TVALID),
        .out0_V_tdata(MVAU_rtl_9_out0_V_TDATA),
        .out0_V_tready(MVAU_rtl_9_out0_V_TREADY),
        .out0_V_tvalid(MVAU_rtl_9_out0_V_TVALID));
  finn_design_OuterShuffle_hls_0_0 OuterShuffle_hls_0
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_22_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_22_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_22_out0_V_TVALID),
        .out0_V_TDATA(OuterShuffle_hls_0_out0_V_TDATA),
        .out0_V_TREADY(OuterShuffle_hls_0_out0_V_TREADY),
        .out0_V_TVALID(OuterShuffle_hls_0_out0_V_TVALID));
  finn_design_OuterShuffle_hls_1_0 OuterShuffle_hls_1
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_24_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_24_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_24_out0_V_TVALID),
        .out0_V_TDATA(OuterShuffle_hls_1_out0_V_TDATA),
        .out0_V_TREADY(OuterShuffle_hls_1_out0_V_TREADY),
        .out0_V_TVALID(OuterShuffle_hls_1_out0_V_TVALID));
  finn_design_OuterShuffle_hls_2_0 OuterShuffle_hls_2
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_23_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_23_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_23_out0_V_TVALID),
        .out0_V_TDATA(OuterShuffle_hls_2_out0_V_TDATA),
        .out0_V_TREADY(OuterShuffle_hls_2_out0_V_TREADY),
        .out0_V_TVALID(OuterShuffle_hls_2_out0_V_TVALID));
  finn_design_OuterShuffle_hls_3_0 OuterShuffle_hls_3
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_44_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_44_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_44_out0_V_TVALID),
        .out0_V_TDATA(OuterShuffle_hls_3_out0_V_TDATA),
        .out0_V_TREADY(OuterShuffle_hls_3_out0_V_TREADY),
        .out0_V_TVALID(OuterShuffle_hls_3_out0_V_TVALID));
  finn_design_SelectToken_rtl_0_0 SelectToken_rtl_0
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_76_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_76_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_76_out0_V_TVALID),
        .out0_V_TDATA(SelectToken_rtl_0_out0_V_TDATA),
        .out0_V_TREADY(SelectToken_rtl_0_out0_V_TREADY),
        .out0_V_TVALID(SelectToken_rtl_0_out0_V_TVALID));
  finn_design_StreamingDataWidthConverter_rtl_0_0 StreamingDataWidthConverter_rtl_0
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_1_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_1_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_1_out0_V_TVALID),
        .out0_V_TDATA(StreamingDataWidthConverter_rtl_0_out0_V_TDATA),
        .out0_V_TREADY(StreamingDataWidthConverter_rtl_0_out0_V_TREADY),
        .out0_V_TVALID(StreamingDataWidthConverter_rtl_0_out0_V_TVALID));
  finn_design_StreamingDataWidthConverter_rtl_1_0 StreamingDataWidthConverter_rtl_1
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_2_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_2_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_2_out0_V_TVALID),
        .out0_V_TDATA(StreamingDataWidthConverter_rtl_1_out0_V_TDATA),
        .out0_V_TREADY(StreamingDataWidthConverter_rtl_1_out0_V_TREADY),
        .out0_V_TVALID(StreamingDataWidthConverter_rtl_1_out0_V_TVALID));
  finn_design_StreamingDataWidthConverter_rtl_10_0 StreamingDataWidthConverter_rtl_10
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_29_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_29_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_29_out0_V_TVALID),
        .out0_V_TDATA(StreamingDataWidthConverter_rtl_10_out0_V_TDATA),
        .out0_V_TREADY(StreamingDataWidthConverter_rtl_10_out0_V_TREADY),
        .out0_V_TVALID(StreamingDataWidthConverter_rtl_10_out0_V_TVALID));
  finn_design_StreamingDataWidthConverter_rtl_11_0 StreamingDataWidthConverter_rtl_11
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_30_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_30_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_30_out0_V_TVALID),
        .out0_V_TDATA(StreamingDataWidthConverter_rtl_11_out0_V_TDATA),
        .out0_V_TREADY(StreamingDataWidthConverter_rtl_11_out0_V_TREADY),
        .out0_V_TVALID(StreamingDataWidthConverter_rtl_11_out0_V_TVALID));
  finn_design_StreamingDataWidthConverter_rtl_12_0 StreamingDataWidthConverter_rtl_12
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_34_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_34_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_34_out0_V_TVALID),
        .out0_V_TDATA(StreamingDataWidthConverter_rtl_12_out0_V_TDATA),
        .out0_V_TREADY(StreamingDataWidthConverter_rtl_12_out0_V_TREADY),
        .out0_V_TVALID(StreamingDataWidthConverter_rtl_12_out0_V_TVALID));
  finn_design_StreamingDataWidthConverter_rtl_13_0 StreamingDataWidthConverter_rtl_13
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_36_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_36_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_36_out0_V_TVALID),
        .out0_V_TDATA(StreamingDataWidthConverter_rtl_13_out0_V_TDATA),
        .out0_V_TREADY(StreamingDataWidthConverter_rtl_13_out0_V_TREADY),
        .out0_V_TVALID(StreamingDataWidthConverter_rtl_13_out0_V_TVALID));
  finn_design_StreamingDataWidthConverter_rtl_14_0 StreamingDataWidthConverter_rtl_14
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_41_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_41_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_41_out0_V_TVALID),
        .out0_V_TDATA(StreamingDataWidthConverter_rtl_14_out0_V_TDATA),
        .out0_V_TREADY(StreamingDataWidthConverter_rtl_14_out0_V_TREADY),
        .out0_V_TVALID(StreamingDataWidthConverter_rtl_14_out0_V_TVALID));
  finn_design_StreamingDataWidthConverter_rtl_15_0 StreamingDataWidthConverter_rtl_15
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_43_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_43_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_43_out0_V_TVALID),
        .out0_V_TDATA(StreamingDataWidthConverter_rtl_15_out0_V_TDATA),
        .out0_V_TREADY(StreamingDataWidthConverter_rtl_15_out0_V_TREADY),
        .out0_V_TVALID(StreamingDataWidthConverter_rtl_15_out0_V_TVALID));
  finn_design_StreamingDataWidthConverter_rtl_16_0 StreamingDataWidthConverter_rtl_16
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_46_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_46_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_46_out0_V_TVALID),
        .out0_V_TDATA(StreamingDataWidthConverter_rtl_16_out0_V_TDATA),
        .out0_V_TREADY(StreamingDataWidthConverter_rtl_16_out0_V_TREADY),
        .out0_V_TVALID(StreamingDataWidthConverter_rtl_16_out0_V_TVALID));
  finn_design_StreamingDataWidthConverter_rtl_17_0 StreamingDataWidthConverter_rtl_17
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_48_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_48_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_48_out0_V_TVALID),
        .out0_V_TDATA(StreamingDataWidthConverter_rtl_17_out0_V_TDATA),
        .out0_V_TREADY(StreamingDataWidthConverter_rtl_17_out0_V_TREADY),
        .out0_V_TVALID(StreamingDataWidthConverter_rtl_17_out0_V_TVALID));
  finn_design_StreamingDataWidthConverter_rtl_18_0 StreamingDataWidthConverter_rtl_18
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_55_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_55_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_55_out0_V_TVALID),
        .out0_V_TDATA(StreamingDataWidthConverter_rtl_18_out0_V_TDATA),
        .out0_V_TREADY(StreamingDataWidthConverter_rtl_18_out0_V_TREADY),
        .out0_V_TVALID(StreamingDataWidthConverter_rtl_18_out0_V_TVALID));
  finn_design_StreamingDataWidthConverter_rtl_19_0 StreamingDataWidthConverter_rtl_19
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_57_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_57_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_57_out0_V_TVALID),
        .out0_V_TDATA(StreamingDataWidthConverter_rtl_19_out0_V_TDATA),
        .out0_V_TREADY(StreamingDataWidthConverter_rtl_19_out0_V_TREADY),
        .out0_V_TVALID(StreamingDataWidthConverter_rtl_19_out0_V_TVALID));
  finn_design_StreamingDataWidthConverter_rtl_2_0 StreamingDataWidthConverter_rtl_2
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_5_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_5_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_5_out0_V_TVALID),
        .out0_V_TDATA(StreamingDataWidthConverter_rtl_2_out0_V_TDATA),
        .out0_V_TREADY(StreamingDataWidthConverter_rtl_2_out0_V_TREADY),
        .out0_V_TVALID(StreamingDataWidthConverter_rtl_2_out0_V_TVALID));
  finn_design_StreamingDataWidthConverter_rtl_20_0 StreamingDataWidthConverter_rtl_20
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_58_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_58_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_58_out0_V_TVALID),
        .out0_V_TDATA(StreamingDataWidthConverter_rtl_20_out0_V_TDATA),
        .out0_V_TREADY(StreamingDataWidthConverter_rtl_20_out0_V_TREADY),
        .out0_V_TVALID(StreamingDataWidthConverter_rtl_20_out0_V_TVALID));
  finn_design_StreamingDataWidthConverter_rtl_21_0 StreamingDataWidthConverter_rtl_21
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_61_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_61_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_61_out0_V_TVALID),
        .out0_V_TDATA(StreamingDataWidthConverter_rtl_21_out0_V_TDATA),
        .out0_V_TREADY(StreamingDataWidthConverter_rtl_21_out0_V_TREADY),
        .out0_V_TVALID(StreamingDataWidthConverter_rtl_21_out0_V_TVALID));
  finn_design_StreamingDataWidthConverter_rtl_22_0 StreamingDataWidthConverter_rtl_22
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_63_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_63_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_63_out0_V_TVALID),
        .out0_V_TDATA(StreamingDataWidthConverter_rtl_22_out0_V_TDATA),
        .out0_V_TREADY(StreamingDataWidthConverter_rtl_22_out0_V_TREADY),
        .out0_V_TVALID(StreamingDataWidthConverter_rtl_22_out0_V_TVALID));
  finn_design_StreamingDataWidthConverter_rtl_23_0 StreamingDataWidthConverter_rtl_23
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_67_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_67_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_67_out0_V_TVALID),
        .out0_V_TDATA(StreamingDataWidthConverter_rtl_23_out0_V_TDATA),
        .out0_V_TREADY(StreamingDataWidthConverter_rtl_23_out0_V_TREADY),
        .out0_V_TVALID(StreamingDataWidthConverter_rtl_23_out0_V_TVALID));
  finn_design_StreamingDataWidthConverter_rtl_24_0 StreamingDataWidthConverter_rtl_24
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_69_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_69_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_69_out0_V_TVALID),
        .out0_V_TDATA(StreamingDataWidthConverter_rtl_24_out0_V_TDATA),
        .out0_V_TREADY(StreamingDataWidthConverter_rtl_24_out0_V_TREADY),
        .out0_V_TVALID(StreamingDataWidthConverter_rtl_24_out0_V_TVALID));
  finn_design_StreamingDataWidthConverter_rtl_25_0 StreamingDataWidthConverter_rtl_25
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_78_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_78_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_78_out0_V_TVALID),
        .out0_V_TDATA(StreamingDataWidthConverter_rtl_25_out0_V_TDATA),
        .out0_V_TREADY(StreamingDataWidthConverter_rtl_25_out0_V_TREADY),
        .out0_V_TVALID(StreamingDataWidthConverter_rtl_25_out0_V_TVALID));
  finn_design_StreamingDataWidthConverter_rtl_26_0 StreamingDataWidthConverter_rtl_26
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_80_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_80_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_80_out0_V_TVALID),
        .out0_V_TDATA(StreamingDataWidthConverter_rtl_26_out0_V_TDATA),
        .out0_V_TREADY(StreamingDataWidthConverter_rtl_26_out0_V_TREADY),
        .out0_V_TVALID(StreamingDataWidthConverter_rtl_26_out0_V_TVALID));
  finn_design_StreamingDataWidthConverter_rtl_27_0 StreamingDataWidthConverter_rtl_27
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_85_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_85_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_85_out0_V_TVALID),
        .out0_V_TDATA(StreamingDataWidthConverter_rtl_27_out0_V_TDATA),
        .out0_V_TREADY(StreamingDataWidthConverter_rtl_27_out0_V_TREADY),
        .out0_V_TVALID(StreamingDataWidthConverter_rtl_27_out0_V_TVALID));
  finn_design_StreamingDataWidthConverter_rtl_3_0 StreamingDataWidthConverter_rtl_3
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_7_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_7_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_7_out0_V_TVALID),
        .out0_V_TDATA(StreamingDataWidthConverter_rtl_3_out0_V_TDATA),
        .out0_V_TREADY(StreamingDataWidthConverter_rtl_3_out0_V_TREADY),
        .out0_V_TVALID(StreamingDataWidthConverter_rtl_3_out0_V_TVALID));
  finn_design_StreamingDataWidthConverter_rtl_4_0 StreamingDataWidthConverter_rtl_4
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_8_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_8_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_8_out0_V_TVALID),
        .out0_V_TDATA(StreamingDataWidthConverter_rtl_4_out0_V_TDATA),
        .out0_V_TREADY(StreamingDataWidthConverter_rtl_4_out0_V_TREADY),
        .out0_V_TVALID(StreamingDataWidthConverter_rtl_4_out0_V_TVALID));
  finn_design_StreamingDataWidthConverter_rtl_5_0 StreamingDataWidthConverter_rtl_5
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_9_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_9_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_9_out0_V_TVALID),
        .out0_V_TDATA(StreamingDataWidthConverter_rtl_5_out0_V_TDATA),
        .out0_V_TREADY(StreamingDataWidthConverter_rtl_5_out0_V_TREADY),
        .out0_V_TVALID(StreamingDataWidthConverter_rtl_5_out0_V_TVALID));
  finn_design_StreamingDataWidthConverter_rtl_6_0 StreamingDataWidthConverter_rtl_6
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_13_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_13_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_13_out0_V_TVALID),
        .out0_V_TDATA(StreamingDataWidthConverter_rtl_6_out0_V_TDATA),
        .out0_V_TREADY(StreamingDataWidthConverter_rtl_6_out0_V_TREADY),
        .out0_V_TVALID(StreamingDataWidthConverter_rtl_6_out0_V_TVALID));
  finn_design_StreamingDataWidthConverter_rtl_7_0 StreamingDataWidthConverter_rtl_7
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_14_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_14_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_14_out0_V_TVALID),
        .out0_V_TDATA(StreamingDataWidthConverter_rtl_7_out0_V_TDATA),
        .out0_V_TREADY(StreamingDataWidthConverter_rtl_7_out0_V_TREADY),
        .out0_V_TVALID(StreamingDataWidthConverter_rtl_7_out0_V_TVALID));
  finn_design_StreamingDataWidthConverter_rtl_8_0 StreamingDataWidthConverter_rtl_8
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_15_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_15_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_15_out0_V_TVALID),
        .out0_V_TDATA(StreamingDataWidthConverter_rtl_8_out0_V_TDATA),
        .out0_V_TREADY(StreamingDataWidthConverter_rtl_8_out0_V_TREADY),
        .out0_V_TVALID(StreamingDataWidthConverter_rtl_8_out0_V_TVALID));
  finn_design_StreamingDataWidthConverter_rtl_9_0 StreamingDataWidthConverter_rtl_9
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_28_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_28_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_28_out0_V_TVALID),
        .out0_V_TDATA(StreamingDataWidthConverter_rtl_9_out0_V_TDATA),
        .out0_V_TREADY(StreamingDataWidthConverter_rtl_9_out0_V_TREADY),
        .out0_V_TVALID(StreamingDataWidthConverter_rtl_9_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_0_0 StreamingFIFO_rtl_0
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(s_axis_0_tdata),
        .in0_V_TREADY(s_axis_0_tready),
        .in0_V_TVALID(s_axis_0_tvalid),
        .out0_V_TDATA(StreamingFIFO_rtl_0_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_0_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_0_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_1_0 StreamingFIFO_rtl_1
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(DuplicateStreams_hls_0_out1_V_TDATA),
        .in0_V_TREADY(DuplicateStreams_hls_0_out1_V_TREADY),
        .in0_V_TVALID(DuplicateStreams_hls_0_out1_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_1_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_1_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_1_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_10_0 StreamingFIFO_rtl_10
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingDataWidthConverter_rtl_3_out0_V_TDATA),
        .in0_V_TREADY(StreamingDataWidthConverter_rtl_3_out0_V_TREADY),
        .in0_V_TVALID(StreamingDataWidthConverter_rtl_3_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_10_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_10_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_10_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_11_0 StreamingFIFO_rtl_11
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingDataWidthConverter_rtl_4_out0_V_TDATA),
        .in0_V_TREADY(StreamingDataWidthConverter_rtl_4_out0_V_TREADY),
        .in0_V_TVALID(StreamingDataWidthConverter_rtl_4_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_11_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_11_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_11_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_12_0 StreamingFIFO_rtl_12
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingDataWidthConverter_rtl_5_out0_V_TDATA),
        .in0_V_TREADY(StreamingDataWidthConverter_rtl_5_out0_V_TREADY),
        .in0_V_TVALID(StreamingDataWidthConverter_rtl_5_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_12_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_12_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_12_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_13_0 StreamingFIFO_rtl_13
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(MVAU_rtl_0_out0_V_TDATA),
        .in0_V_TREADY(MVAU_rtl_0_out0_V_TREADY),
        .in0_V_TVALID(MVAU_rtl_0_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_13_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_13_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_13_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_14_0 StreamingFIFO_rtl_14
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(MVAU_rtl_1_out0_V_TDATA),
        .in0_V_TREADY(MVAU_rtl_1_out0_V_TREADY),
        .in0_V_TVALID(MVAU_rtl_1_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_14_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_14_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_14_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_15_0 StreamingFIFO_rtl_15
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(MVAU_rtl_2_out0_V_TDATA),
        .in0_V_TREADY(MVAU_rtl_2_out0_V_TREADY),
        .in0_V_TVALID(MVAU_rtl_2_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_15_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_15_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_15_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_16_0 StreamingFIFO_rtl_16
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingDataWidthConverter_rtl_6_out0_V_TDATA),
        .in0_V_TREADY(StreamingDataWidthConverter_rtl_6_out0_V_TREADY),
        .in0_V_TVALID(StreamingDataWidthConverter_rtl_6_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_16_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_16_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_16_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_17_0 StreamingFIFO_rtl_17
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingDataWidthConverter_rtl_7_out0_V_TDATA),
        .in0_V_TREADY(StreamingDataWidthConverter_rtl_7_out0_V_TREADY),
        .in0_V_TVALID(StreamingDataWidthConverter_rtl_7_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_17_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_17_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_17_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_18_0 StreamingFIFO_rtl_18
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingDataWidthConverter_rtl_8_out0_V_TDATA),
        .in0_V_TREADY(StreamingDataWidthConverter_rtl_8_out0_V_TREADY),
        .in0_V_TVALID(StreamingDataWidthConverter_rtl_8_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_18_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_18_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_18_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_19_0 StreamingFIFO_rtl_19
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(ElementwiseMul_rtl_0_out0_V_TDATA),
        .in0_V_TREADY(ElementwiseMul_rtl_0_out0_V_TREADY),
        .in0_V_TVALID(ElementwiseMul_rtl_0_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_19_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_19_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_19_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_2_0 StreamingFIFO_rtl_2
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(DuplicateStreams_hls_0_out0_V_TDATA),
        .in0_V_TREADY(DuplicateStreams_hls_0_out0_V_TREADY),
        .in0_V_TVALID(DuplicateStreams_hls_0_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_2_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_2_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_2_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_20_0 StreamingFIFO_rtl_20
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(ElementwiseMul_rtl_1_out0_V_TDATA),
        .in0_V_TREADY(ElementwiseMul_rtl_1_out0_V_TREADY),
        .in0_V_TVALID(ElementwiseMul_rtl_1_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_20_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_20_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_20_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_21_0 StreamingFIFO_rtl_21
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(ElementwiseMul_rtl_2_out0_V_TDATA),
        .in0_V_TREADY(ElementwiseMul_rtl_2_out0_V_TREADY),
        .in0_V_TVALID(ElementwiseMul_rtl_2_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_21_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_21_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_21_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_22_0 StreamingFIFO_rtl_22
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(ElementwiseAdd_rtl_0_out0_V_TDATA),
        .in0_V_TREADY(ElementwiseAdd_rtl_0_out0_V_TREADY),
        .in0_V_TVALID(ElementwiseAdd_rtl_0_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_22_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_22_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_22_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_23_0 StreamingFIFO_rtl_23
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(ElementwiseAdd_rtl_1_out0_V_TDATA),
        .in0_V_TREADY(ElementwiseAdd_rtl_1_out0_V_TREADY),
        .in0_V_TVALID(ElementwiseAdd_rtl_1_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_23_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_23_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_23_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_24_0 StreamingFIFO_rtl_24
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(ElementwiseAdd_rtl_2_out0_V_TDATA),
        .in0_V_TREADY(ElementwiseAdd_rtl_2_out0_V_TREADY),
        .in0_V_TVALID(ElementwiseAdd_rtl_2_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_24_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_24_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_24_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_25_0 StreamingFIFO_rtl_25
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(OuterShuffle_hls_0_out0_V_TDATA),
        .in0_V_TREADY(OuterShuffle_hls_0_out0_V_TREADY),
        .in0_V_TVALID(OuterShuffle_hls_0_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_25_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_25_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_25_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_26_0 StreamingFIFO_rtl_26
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(OuterShuffle_hls_1_out0_V_TDATA),
        .in0_V_TREADY(OuterShuffle_hls_1_out0_V_TREADY),
        .in0_V_TVALID(OuterShuffle_hls_1_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_26_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_26_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_26_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_27_0 StreamingFIFO_rtl_27
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(OuterShuffle_hls_2_out0_V_TDATA),
        .in0_V_TREADY(OuterShuffle_hls_2_out0_V_TREADY),
        .in0_V_TVALID(OuterShuffle_hls_2_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_27_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_27_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_27_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_28_0 StreamingFIFO_rtl_28
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(InnerShuffle_rtl_0_out0_V_TDATA),
        .in0_V_TREADY(InnerShuffle_rtl_0_out0_V_TREADY),
        .in0_V_TVALID(InnerShuffle_rtl_0_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_28_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_28_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_28_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_29_0 StreamingFIFO_rtl_29
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(Thresholding_rtl_1_out0_V_TDATA),
        .in0_V_TREADY(Thresholding_rtl_1_out0_V_TREADY),
        .in0_V_TVALID(Thresholding_rtl_1_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_29_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_29_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_29_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_3_0 StreamingFIFO_rtl_3
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingDataWidthConverter_rtl_0_out0_V_TDATA),
        .in0_V_TREADY(StreamingDataWidthConverter_rtl_0_out0_V_TREADY),
        .in0_V_TVALID(StreamingDataWidthConverter_rtl_0_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_3_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_3_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_3_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_30_0 StreamingFIFO_rtl_30
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(Thresholding_rtl_2_out0_V_TDATA),
        .in0_V_TREADY(Thresholding_rtl_2_out0_V_TREADY),
        .in0_V_TVALID(Thresholding_rtl_2_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_30_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_30_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_30_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_31_0 StreamingFIFO_rtl_31
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingDataWidthConverter_rtl_9_out0_V_TDATA),
        .in0_V_TREADY(StreamingDataWidthConverter_rtl_9_out0_V_TREADY),
        .in0_V_TVALID(StreamingDataWidthConverter_rtl_9_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_31_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_31_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_31_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_32_0 StreamingFIFO_rtl_32
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingDataWidthConverter_rtl_10_out0_V_TDATA),
        .in0_V_TREADY(StreamingDataWidthConverter_rtl_10_out0_V_TREADY),
        .in0_V_TVALID(StreamingDataWidthConverter_rtl_10_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_32_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_32_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_32_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_33_0 StreamingFIFO_rtl_33
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingDataWidthConverter_rtl_11_out0_V_TDATA),
        .in0_V_TREADY(StreamingDataWidthConverter_rtl_11_out0_V_TREADY),
        .in0_V_TVALID(StreamingDataWidthConverter_rtl_11_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_33_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_33_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_33_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_34_0 StreamingFIFO_rtl_34
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(Thresholding_rtl_3_out0_V_TDATA),
        .in0_V_TREADY(Thresholding_rtl_3_out0_V_TREADY),
        .in0_V_TVALID(Thresholding_rtl_3_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_34_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_34_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_34_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_35_0 StreamingFIFO_rtl_35
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingDataWidthConverter_rtl_12_out0_V_TDATA),
        .in0_V_TREADY(StreamingDataWidthConverter_rtl_12_out0_V_TREADY),
        .in0_V_TVALID(StreamingDataWidthConverter_rtl_12_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_35_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_35_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_35_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_36_0 StreamingFIFO_rtl_36
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(MVAU_rtl_3_out0_V_TDATA),
        .in0_V_TREADY(MVAU_rtl_3_out0_V_TREADY),
        .in0_V_TVALID(MVAU_rtl_3_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_36_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_36_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_36_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_37_0 StreamingFIFO_rtl_37
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingDataWidthConverter_rtl_13_out0_V_TDATA),
        .in0_V_TREADY(StreamingDataWidthConverter_rtl_13_out0_V_TREADY),
        .in0_V_TVALID(StreamingDataWidthConverter_rtl_13_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_37_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_37_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_37_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_38_0 StreamingFIFO_rtl_38
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(Thresholding_rtl_4_out0_V_TDATA),
        .in0_V_TREADY(Thresholding_rtl_4_out0_V_TREADY),
        .in0_V_TVALID(Thresholding_rtl_4_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_38_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_38_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_38_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_39_0 StreamingFIFO_rtl_39
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(ElementwiseMul_rtl_3_out0_V_TDATA),
        .in0_V_TREADY(ElementwiseMul_rtl_3_out0_V_TREADY),
        .in0_V_TVALID(ElementwiseMul_rtl_3_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_39_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_39_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_39_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_4_0 StreamingFIFO_rtl_4
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingDataWidthConverter_rtl_1_out0_V_TDATA),
        .in0_V_TREADY(StreamingDataWidthConverter_rtl_1_out0_V_TREADY),
        .in0_V_TVALID(StreamingDataWidthConverter_rtl_1_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_4_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_4_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_4_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_40_0 StreamingFIFO_rtl_40
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(HWSoftmax_rtl_0_out0_V_TDATA),
        .in0_V_TREADY(HWSoftmax_rtl_0_out0_V_TREADY),
        .in0_V_TVALID(HWSoftmax_rtl_0_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_40_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_40_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_40_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_41_0 StreamingFIFO_rtl_41
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(Thresholding_rtl_5_out0_V_TDATA),
        .in0_V_TREADY(Thresholding_rtl_5_out0_V_TREADY),
        .in0_V_TVALID(Thresholding_rtl_5_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_41_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_41_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_41_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_42_0 StreamingFIFO_rtl_42
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingDataWidthConverter_rtl_14_out0_V_TDATA),
        .in0_V_TREADY(StreamingDataWidthConverter_rtl_14_out0_V_TREADY),
        .in0_V_TVALID(StreamingDataWidthConverter_rtl_14_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_42_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_42_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_42_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_43_0 StreamingFIFO_rtl_43
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(MVAU_rtl_4_out0_V_TDATA),
        .in0_V_TREADY(MVAU_rtl_4_out0_V_TREADY),
        .in0_V_TVALID(MVAU_rtl_4_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_43_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_43_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_43_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_44_0 StreamingFIFO_rtl_44
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingDataWidthConverter_rtl_15_out0_V_TDATA),
        .in0_V_TREADY(StreamingDataWidthConverter_rtl_15_out0_V_TREADY),
        .in0_V_TVALID(StreamingDataWidthConverter_rtl_15_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_44_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_44_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_44_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_45_0 StreamingFIFO_rtl_45
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(OuterShuffle_hls_3_out0_V_TDATA),
        .in0_V_TREADY(OuterShuffle_hls_3_out0_V_TREADY),
        .in0_V_TVALID(OuterShuffle_hls_3_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_45_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_45_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_45_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_46_0 StreamingFIFO_rtl_46
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(Thresholding_rtl_6_out0_V_TDATA),
        .in0_V_TREADY(Thresholding_rtl_6_out0_V_TREADY),
        .in0_V_TVALID(Thresholding_rtl_6_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_46_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_46_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_46_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_47_0 StreamingFIFO_rtl_47
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingDataWidthConverter_rtl_16_out0_V_TDATA),
        .in0_V_TREADY(StreamingDataWidthConverter_rtl_16_out0_V_TREADY),
        .in0_V_TVALID(StreamingDataWidthConverter_rtl_16_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_47_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_47_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_47_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_48_0 StreamingFIFO_rtl_48
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(MVAU_rtl_5_out0_V_TDATA),
        .in0_V_TREADY(MVAU_rtl_5_out0_V_TREADY),
        .in0_V_TVALID(MVAU_rtl_5_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_48_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_48_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_48_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_49_0 StreamingFIFO_rtl_49
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingDataWidthConverter_rtl_17_out0_V_TDATA),
        .in0_V_TREADY(StreamingDataWidthConverter_rtl_17_out0_V_TREADY),
        .in0_V_TVALID(StreamingDataWidthConverter_rtl_17_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_49_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_49_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_49_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_5_0 StreamingFIFO_rtl_5
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(Thresholding_rtl_0_out0_V_TDATA),
        .in0_V_TREADY(Thresholding_rtl_0_out0_V_TREADY),
        .in0_V_TVALID(Thresholding_rtl_0_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_5_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_5_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_5_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_50_0 StreamingFIFO_rtl_50
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(ElementwiseMul_rtl_4_out0_V_TDATA),
        .in0_V_TREADY(ElementwiseMul_rtl_4_out0_V_TREADY),
        .in0_V_TVALID(ElementwiseMul_rtl_4_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_50_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_50_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_50_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_51_0 StreamingFIFO_rtl_51
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(ElementwiseAdd_rtl_3_out0_V_TDATA),
        .in0_V_TREADY(ElementwiseAdd_rtl_3_out0_V_TREADY),
        .in0_V_TVALID(ElementwiseAdd_rtl_3_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_51_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_51_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_51_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_52_0 StreamingFIFO_rtl_52
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(ElementwiseAdd_rtl_4_out0_V_TDATA),
        .in0_V_TREADY(ElementwiseAdd_rtl_4_out0_V_TREADY),
        .in0_V_TVALID(ElementwiseAdd_rtl_4_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_52_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_52_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_52_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_53_0 StreamingFIFO_rtl_53
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(LayerNorm_rtl_0_out0_V_TDATA),
        .in0_V_TREADY(LayerNorm_rtl_0_out0_V_TREADY),
        .in0_V_TVALID(LayerNorm_rtl_0_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_53_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_53_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_53_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_54_0 StreamingFIFO_rtl_54
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(ElementwiseMul_rtl_5_out0_V_TDATA),
        .in0_V_TREADY(ElementwiseMul_rtl_5_out0_V_TREADY),
        .in0_V_TVALID(ElementwiseMul_rtl_5_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_54_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_54_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_54_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_55_0 StreamingFIFO_rtl_55
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(ElementwiseAdd_rtl_5_out0_V_TDATA),
        .in0_V_TREADY(ElementwiseAdd_rtl_5_out0_V_TREADY),
        .in0_V_TVALID(ElementwiseAdd_rtl_5_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_55_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_55_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_55_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_56_0 StreamingFIFO_rtl_56
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingDataWidthConverter_rtl_18_out0_V_TDATA),
        .in0_V_TREADY(StreamingDataWidthConverter_rtl_18_out0_V_TREADY),
        .in0_V_TVALID(StreamingDataWidthConverter_rtl_18_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_56_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_56_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_56_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_57_0 StreamingFIFO_rtl_57
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(DuplicateStreams_hls_2_out1_V_TDATA),
        .in0_V_TREADY(DuplicateStreams_hls_2_out1_V_TREADY),
        .in0_V_TVALID(DuplicateStreams_hls_2_out1_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_57_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_57_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_57_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_58_0 StreamingFIFO_rtl_58
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(DuplicateStreams_hls_2_out0_V_TDATA),
        .in0_V_TREADY(DuplicateStreams_hls_2_out0_V_TREADY),
        .in0_V_TVALID(DuplicateStreams_hls_2_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_58_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_58_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_58_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_59_0 StreamingFIFO_rtl_59
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingDataWidthConverter_rtl_19_out0_V_TDATA),
        .in0_V_TREADY(StreamingDataWidthConverter_rtl_19_out0_V_TREADY),
        .in0_V_TVALID(StreamingDataWidthConverter_rtl_19_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_59_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_59_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_59_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_6_0 StreamingFIFO_rtl_6
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingDataWidthConverter_rtl_2_out0_V_TDATA),
        .in0_V_TREADY(StreamingDataWidthConverter_rtl_2_out0_V_TREADY),
        .in0_V_TVALID(StreamingDataWidthConverter_rtl_2_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_6_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_6_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_6_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_60_0 StreamingFIFO_rtl_60
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingDataWidthConverter_rtl_20_out0_V_TDATA),
        .in0_V_TREADY(StreamingDataWidthConverter_rtl_20_out0_V_TREADY),
        .in0_V_TVALID(StreamingDataWidthConverter_rtl_20_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_60_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_60_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_60_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_61_0 StreamingFIFO_rtl_61
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(Thresholding_rtl_7_out0_V_TDATA),
        .in0_V_TREADY(Thresholding_rtl_7_out0_V_TREADY),
        .in0_V_TVALID(Thresholding_rtl_7_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_61_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_61_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_61_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_62_0 StreamingFIFO_rtl_62
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingDataWidthConverter_rtl_21_out0_V_TDATA),
        .in0_V_TREADY(StreamingDataWidthConverter_rtl_21_out0_V_TREADY),
        .in0_V_TVALID(StreamingDataWidthConverter_rtl_21_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_62_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_62_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_62_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_63_0 StreamingFIFO_rtl_63
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(MVAU_rtl_6_out0_V_TDATA),
        .in0_V_TREADY(MVAU_rtl_6_out0_V_TREADY),
        .in0_V_TVALID(MVAU_rtl_6_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_63_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_63_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_63_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_64_0 StreamingFIFO_rtl_64
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingDataWidthConverter_rtl_22_out0_V_TDATA),
        .in0_V_TREADY(StreamingDataWidthConverter_rtl_22_out0_V_TREADY),
        .in0_V_TVALID(StreamingDataWidthConverter_rtl_22_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_64_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_64_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_64_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_65_0 StreamingFIFO_rtl_65
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(ElementwiseMul_rtl_6_out0_V_TDATA),
        .in0_V_TREADY(ElementwiseMul_rtl_6_out0_V_TREADY),
        .in0_V_TVALID(ElementwiseMul_rtl_6_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_65_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_65_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_65_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_66_0 StreamingFIFO_rtl_66
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(ElementwiseAdd_rtl_6_out0_V_TDATA),
        .in0_V_TREADY(ElementwiseAdd_rtl_6_out0_V_TREADY),
        .in0_V_TVALID(ElementwiseAdd_rtl_6_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_66_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_66_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_66_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_67_0 StreamingFIFO_rtl_67
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(Thresholding_rtl_8_out0_V_TDATA),
        .in0_V_TREADY(Thresholding_rtl_8_out0_V_TREADY),
        .in0_V_TVALID(Thresholding_rtl_8_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_67_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_67_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_67_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_68_0 StreamingFIFO_rtl_68
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingDataWidthConverter_rtl_23_out0_V_TDATA),
        .in0_V_TREADY(StreamingDataWidthConverter_rtl_23_out0_V_TREADY),
        .in0_V_TVALID(StreamingDataWidthConverter_rtl_23_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_68_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_68_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_68_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_69_0 StreamingFIFO_rtl_69
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(MVAU_rtl_7_out0_V_TDATA),
        .in0_V_TREADY(MVAU_rtl_7_out0_V_TREADY),
        .in0_V_TVALID(MVAU_rtl_7_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_69_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_69_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_69_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_7_0 StreamingFIFO_rtl_7
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(DuplicateStreams_hls_1_out2_V_TDATA),
        .in0_V_TREADY(DuplicateStreams_hls_1_out2_V_TREADY),
        .in0_V_TVALID(DuplicateStreams_hls_1_out2_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_7_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_7_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_7_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_70_0 StreamingFIFO_rtl_70
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingDataWidthConverter_rtl_24_out0_V_TDATA),
        .in0_V_TREADY(StreamingDataWidthConverter_rtl_24_out0_V_TREADY),
        .in0_V_TVALID(StreamingDataWidthConverter_rtl_24_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_70_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_70_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_70_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_71_0 StreamingFIFO_rtl_71
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(ElementwiseMul_rtl_7_out0_V_TDATA),
        .in0_V_TREADY(ElementwiseMul_rtl_7_out0_V_TREADY),
        .in0_V_TVALID(ElementwiseMul_rtl_7_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_71_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_71_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_71_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_72_0 StreamingFIFO_rtl_72
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(ElementwiseAdd_rtl_7_out0_V_TDATA),
        .in0_V_TREADY(ElementwiseAdd_rtl_7_out0_V_TREADY),
        .in0_V_TVALID(ElementwiseAdd_rtl_7_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_72_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_72_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_72_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_73_0 StreamingFIFO_rtl_73
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(ElementwiseAdd_rtl_8_out0_V_TDATA),
        .in0_V_TREADY(ElementwiseAdd_rtl_8_out0_V_TREADY),
        .in0_V_TVALID(ElementwiseAdd_rtl_8_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_73_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_73_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_73_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_74_0 StreamingFIFO_rtl_74
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(LayerNorm_rtl_1_out0_V_TDATA),
        .in0_V_TREADY(LayerNorm_rtl_1_out0_V_TREADY),
        .in0_V_TVALID(LayerNorm_rtl_1_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_74_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_74_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_74_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_75_0 StreamingFIFO_rtl_75
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(ElementwiseMul_rtl_8_out0_V_TDATA),
        .in0_V_TREADY(ElementwiseMul_rtl_8_out0_V_TREADY),
        .in0_V_TVALID(ElementwiseMul_rtl_8_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_75_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_75_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_75_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_76_0 StreamingFIFO_rtl_76
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(ElementwiseAdd_rtl_9_out0_V_TDATA),
        .in0_V_TREADY(ElementwiseAdd_rtl_9_out0_V_TREADY),
        .in0_V_TVALID(ElementwiseAdd_rtl_9_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_76_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_76_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_76_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_77_0 StreamingFIFO_rtl_77
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(SelectToken_rtl_0_out0_V_TDATA),
        .in0_V_TREADY(SelectToken_rtl_0_out0_V_TREADY),
        .in0_V_TVALID(SelectToken_rtl_0_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_77_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_77_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_77_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_78_0 StreamingFIFO_rtl_78
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(Thresholding_rtl_9_out0_V_TDATA),
        .in0_V_TREADY(Thresholding_rtl_9_out0_V_TREADY),
        .in0_V_TVALID(Thresholding_rtl_9_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_78_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_78_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_78_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_79_0 StreamingFIFO_rtl_79
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingDataWidthConverter_rtl_25_out0_V_TDATA),
        .in0_V_TREADY(StreamingDataWidthConverter_rtl_25_out0_V_TREADY),
        .in0_V_TVALID(StreamingDataWidthConverter_rtl_25_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_79_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_79_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_79_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_8_0 StreamingFIFO_rtl_8
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(DuplicateStreams_hls_1_out1_V_TDATA),
        .in0_V_TREADY(DuplicateStreams_hls_1_out1_V_TREADY),
        .in0_V_TVALID(DuplicateStreams_hls_1_out1_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_8_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_8_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_8_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_80_0 StreamingFIFO_rtl_80
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(MVAU_rtl_8_out0_V_TDATA),
        .in0_V_TREADY(MVAU_rtl_8_out0_V_TREADY),
        .in0_V_TVALID(MVAU_rtl_8_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_80_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_80_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_80_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_81_0 StreamingFIFO_rtl_81
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingDataWidthConverter_rtl_26_out0_V_TDATA),
        .in0_V_TREADY(StreamingDataWidthConverter_rtl_26_out0_V_TREADY),
        .in0_V_TVALID(StreamingDataWidthConverter_rtl_26_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_81_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_81_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_81_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_82_0 StreamingFIFO_rtl_82
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(ElementwiseMul_rtl_9_out0_V_TDATA),
        .in0_V_TREADY(ElementwiseMul_rtl_9_out0_V_TREADY),
        .in0_V_TVALID(ElementwiseMul_rtl_9_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_82_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_82_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_82_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_83_0 StreamingFIFO_rtl_83
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(ElementwiseAdd_rtl_10_out0_V_TDATA),
        .in0_V_TREADY(ElementwiseAdd_rtl_10_out0_V_TREADY),
        .in0_V_TVALID(ElementwiseAdd_rtl_10_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_83_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_83_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_83_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_84_0 StreamingFIFO_rtl_84
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(Thresholding_rtl_10_out0_V_TDATA),
        .in0_V_TREADY(Thresholding_rtl_10_out0_V_TREADY),
        .in0_V_TVALID(Thresholding_rtl_10_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_84_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_84_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_84_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_85_0 StreamingFIFO_rtl_85
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(Thresholding_rtl_11_out0_V_TDATA),
        .in0_V_TREADY(Thresholding_rtl_11_out0_V_TREADY),
        .in0_V_TVALID(Thresholding_rtl_11_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_85_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_85_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_85_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_86_0 StreamingFIFO_rtl_86
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingDataWidthConverter_rtl_27_out0_V_TDATA),
        .in0_V_TREADY(StreamingDataWidthConverter_rtl_27_out0_V_TREADY),
        .in0_V_TVALID(StreamingDataWidthConverter_rtl_27_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_86_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_86_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_86_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_87_0 StreamingFIFO_rtl_87
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(MVAU_rtl_9_out0_V_TDATA),
        .in0_V_TREADY(MVAU_rtl_9_out0_V_TREADY),
        .in0_V_TVALID(MVAU_rtl_9_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_87_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_87_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_87_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_88_0 StreamingFIFO_rtl_88
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(ElementwiseMul_rtl_10_out0_V_TDATA),
        .in0_V_TREADY(ElementwiseMul_rtl_10_out0_V_TREADY),
        .in0_V_TVALID(ElementwiseMul_rtl_10_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_88_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_88_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_88_out0_V_TVALID));
  finn_design_StreamingFIFO_rtl_89_0 StreamingFIFO_rtl_89
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(ElementwiseAdd_rtl_11_out0_V_TDATA),
        .in0_V_TREADY(ElementwiseAdd_rtl_11_out0_V_TREADY),
        .in0_V_TVALID(ElementwiseAdd_rtl_11_out0_V_TVALID),
        .out0_V_TDATA(m_axis_0_tdata),
        .out0_V_TREADY(m_axis_0_tready),
        .out0_V_TVALID(m_axis_0_tvalid));
  finn_design_StreamingFIFO_rtl_9_0 StreamingFIFO_rtl_9
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(DuplicateStreams_hls_1_out0_V_TDATA),
        .in0_V_TREADY(DuplicateStreams_hls_1_out0_V_TREADY),
        .in0_V_TVALID(DuplicateStreams_hls_1_out0_V_TVALID),
        .out0_V_TDATA(StreamingFIFO_rtl_9_out0_V_TDATA),
        .out0_V_TREADY(StreamingFIFO_rtl_9_out0_V_TREADY),
        .out0_V_TVALID(StreamingFIFO_rtl_9_out0_V_TVALID));
  finn_design_Thresholding_rtl_0_0 Thresholding_rtl_0
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_4_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_4_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_4_out0_V_TVALID),
        .in1_V_TDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .in1_V_TVALID(1'b0),
        .out0_V_TDATA(Thresholding_rtl_0_out0_V_TDATA),
        .out0_V_TREADY(Thresholding_rtl_0_out0_V_TREADY),
        .out0_V_TVALID(Thresholding_rtl_0_out0_V_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0));
  finn_design_Thresholding_rtl_1_0 Thresholding_rtl_1
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_25_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_25_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_25_out0_V_TVALID),
        .in1_V_TDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .in1_V_TVALID(1'b0),
        .out0_V_TDATA(Thresholding_rtl_1_out0_V_TDATA),
        .out0_V_TREADY(Thresholding_rtl_1_out0_V_TREADY),
        .out0_V_TVALID(Thresholding_rtl_1_out0_V_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0));
  finn_design_Thresholding_rtl_10_0 Thresholding_rtl_10
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_83_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_83_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_83_out0_V_TVALID),
        .in1_V_TDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .in1_V_TVALID(1'b0),
        .out0_V_TDATA(Thresholding_rtl_10_out0_V_TDATA),
        .out0_V_TREADY(Thresholding_rtl_10_out0_V_TREADY),
        .out0_V_TVALID(Thresholding_rtl_10_out0_V_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0));
  finn_design_Thresholding_rtl_11_0 Thresholding_rtl_11
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_84_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_84_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_84_out0_V_TVALID),
        .in1_V_TDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .in1_V_TVALID(1'b0),
        .out0_V_TDATA(Thresholding_rtl_11_out0_V_TDATA),
        .out0_V_TREADY(Thresholding_rtl_11_out0_V_TREADY),
        .out0_V_TVALID(Thresholding_rtl_11_out0_V_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0));
  finn_design_Thresholding_rtl_2_0 Thresholding_rtl_2
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_26_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_26_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_26_out0_V_TVALID),
        .in1_V_TDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .in1_V_TVALID(1'b0),
        .out0_V_TDATA(Thresholding_rtl_2_out0_V_TDATA),
        .out0_V_TREADY(Thresholding_rtl_2_out0_V_TREADY),
        .out0_V_TVALID(Thresholding_rtl_2_out0_V_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0));
  finn_design_Thresholding_rtl_3_0 Thresholding_rtl_3
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_31_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_31_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_31_out0_V_TVALID),
        .in1_V_TDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .in1_V_TVALID(1'b0),
        .out0_V_TDATA(Thresholding_rtl_3_out0_V_TDATA),
        .out0_V_TREADY(Thresholding_rtl_3_out0_V_TREADY),
        .out0_V_TVALID(Thresholding_rtl_3_out0_V_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0));
  finn_design_Thresholding_rtl_4_0 Thresholding_rtl_4
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_37_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_37_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_37_out0_V_TVALID),
        .in1_V_TDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .in1_V_TVALID(1'b0),
        .out0_V_TDATA(Thresholding_rtl_4_out0_V_TDATA),
        .out0_V_TREADY(Thresholding_rtl_4_out0_V_TREADY),
        .out0_V_TVALID(Thresholding_rtl_4_out0_V_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0));
  finn_design_Thresholding_rtl_5_0 Thresholding_rtl_5
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_40_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_40_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_40_out0_V_TVALID),
        .in1_V_TDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .in1_V_TVALID(1'b0),
        .out0_V_TDATA(Thresholding_rtl_5_out0_V_TDATA),
        .out0_V_TREADY(Thresholding_rtl_5_out0_V_TREADY),
        .out0_V_TVALID(Thresholding_rtl_5_out0_V_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0));
  finn_design_Thresholding_rtl_6_0 Thresholding_rtl_6
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_45_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_45_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_45_out0_V_TVALID),
        .in1_V_TDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .in1_V_TVALID(1'b0),
        .out0_V_TDATA(Thresholding_rtl_6_out0_V_TDATA),
        .out0_V_TREADY(Thresholding_rtl_6_out0_V_TREADY),
        .out0_V_TVALID(Thresholding_rtl_6_out0_V_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0));
  finn_design_Thresholding_rtl_7_0 Thresholding_rtl_7
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_60_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_60_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_60_out0_V_TVALID),
        .in1_V_TDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .in1_V_TVALID(1'b0),
        .out0_V_TDATA(Thresholding_rtl_7_out0_V_TDATA),
        .out0_V_TREADY(Thresholding_rtl_7_out0_V_TREADY),
        .out0_V_TVALID(Thresholding_rtl_7_out0_V_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0));
  finn_design_Thresholding_rtl_8_0 Thresholding_rtl_8
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_66_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_66_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_66_out0_V_TVALID),
        .in1_V_TDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .in1_V_TVALID(1'b0),
        .out0_V_TDATA(Thresholding_rtl_8_out0_V_TDATA),
        .out0_V_TREADY(Thresholding_rtl_8_out0_V_TREADY),
        .out0_V_TVALID(Thresholding_rtl_8_out0_V_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0));
  finn_design_Thresholding_rtl_9_0 Thresholding_rtl_9
       (.ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),
        .in0_V_TDATA(StreamingFIFO_rtl_77_out0_V_TDATA),
        .in0_V_TREADY(StreamingFIFO_rtl_77_out0_V_TREADY),
        .in0_V_TVALID(StreamingFIFO_rtl_77_out0_V_TVALID),
        .in1_V_TDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .in1_V_TVALID(1'b0),
        .out0_V_TDATA(Thresholding_rtl_9_out0_V_TDATA),
        .out0_V_TREADY(Thresholding_rtl_9_out0_V_TREADY),
        .out0_V_TVALID(Thresholding_rtl_9_out0_V_TVALID),
        .s_axilite_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_ARVALID(1'b0),
        .s_axilite_AWADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_AWVALID(1'b0),
        .s_axilite_BREADY(1'b0),
        .s_axilite_RREADY(1'b0),
        .s_axilite_WDATA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axilite_WSTRB({1'b1,1'b1,1'b1,1'b1}),
        .s_axilite_WVALID(1'b0));
  finn_design_sim_ctrl_0_0 sim_ctrl_0
       (.ap_clk(ap_clk),
        .sim_finish(sim_finish));
endmodule
