// Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2021.2 (win64) Build 3367213 Tue Oct 19 02:48:09 MDT 2021
// Date        : Fri Nov  5 16:30:55 2021
// Host        : TIGER running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               E:/MyWork/HomebrewGPU/Prototype/HomebrewGPU/HomebrewGPU.runs/ClockWizard_synth_1/ClockWizard_stub.v
// Design      : ClockWizard
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module ClockWizard(clk_200, clk_40, clk_80, resetn, locked, clk_in1)
/* synthesis syn_black_box black_box_pad_pin="clk_200,clk_40,clk_80,resetn,locked,clk_in1" */;
  output clk_200;
  output clk_40;
  output clk_80;
  input resetn;
  output locked;
  input clk_in1;
endmodule
