// Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2021.2 (win64) Build 3367213 Tue Oct 19 02:48:09 MDT 2021
// Date        : Wed Nov 17 11:48:38 2021
// Host        : TIGER running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub -rename_top Sqrt -prefix
//               Sqrt_ Sqrt_stub.v
// Design      : Sqrt
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "cordic_v6_0_17,Vivado 2021.2" *)
module Sqrt(s_axis_cartesian_tvalid, 
  s_axis_cartesian_tdata, m_axis_dout_tvalid, m_axis_dout_tdata)
/* synthesis syn_black_box black_box_pad_pin="s_axis_cartesian_tvalid,s_axis_cartesian_tdata[47:0],m_axis_dout_tvalid,m_axis_dout_tdata[23:0]" */;
  input s_axis_cartesian_tvalid;
  input [47:0]s_axis_cartesian_tdata;
  output m_axis_dout_tvalid;
  output [23:0]m_axis_dout_tdata;
endmodule
