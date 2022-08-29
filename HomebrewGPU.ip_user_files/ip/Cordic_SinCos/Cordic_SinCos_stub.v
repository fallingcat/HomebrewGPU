// Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2.2 (win64) Build 3118627 Tue Feb  9 05:14:06 MST 2021
// Date        : Tue Apr 27 00:53:43 2021
// Host        : TigerPC running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub -rename_top Cordic_SinCos -prefix
//               Cordic_SinCos_ Cordic_SinCos_stub.v
// Design      : Cordic_SinCos
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "cordic_v6_0_16,Vivado 2020.2.2" *)
module Cordic_SinCos(s_axis_phase_tvalid, s_axis_phase_tdata, 
  m_axis_dout_tvalid, m_axis_dout_tdata)
/* synthesis syn_black_box black_box_pad_pin="s_axis_phase_tvalid,s_axis_phase_tdata[15:0],m_axis_dout_tvalid,m_axis_dout_tdata[31:0]" */;
  input s_axis_phase_tvalid;
  input [15:0]s_axis_phase_tdata;
  output m_axis_dout_tvalid;
  output [31:0]m_axis_dout_tdata;
endmodule
