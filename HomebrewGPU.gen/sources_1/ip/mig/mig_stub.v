// Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2021.2 (win64) Build 3367213 Tue Oct 19 02:48:09 MDT 2021
// Date        : Sat Oct  1 19:17:05 2022
// Host        : TIGER running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub e:/MyWork/HomebrewGPU/HomebrewGPU.gen/sources_1/ip/mig/mig_stub.v
// Design      : mig
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module mig(ddr2_dq, ddr2_dqs_n, ddr2_dqs_p, ddr2_addr, 
  ddr2_ba, ddr2_ras_n, ddr2_cas_n, ddr2_we_n, ddr2_ck_p, ddr2_ck_n, ddr2_cke, ddr2_cs_n, ddr2_dm, 
  ddr2_odt, sys_clk_i, app_addr, app_cmd, app_en, app_wdf_data, app_wdf_end, app_wdf_mask, 
  app_wdf_wren, app_rd_data, app_rd_data_end, app_rd_data_valid, app_rdy, app_wdf_rdy, 
  app_sr_req, app_ref_req, app_zq_req, app_sr_active, app_ref_ack, app_zq_ack, ui_clk, 
  ui_clk_sync_rst, init_calib_complete, sys_rst)
/* synthesis syn_black_box black_box_pad_pin="ddr2_dq[15:0],ddr2_dqs_n[1:0],ddr2_dqs_p[1:0],ddr2_addr[12:0],ddr2_ba[2:0],ddr2_ras_n,ddr2_cas_n,ddr2_we_n,ddr2_ck_p[0:0],ddr2_ck_n[0:0],ddr2_cke[0:0],ddr2_cs_n[0:0],ddr2_dm[1:0],ddr2_odt[0:0],sys_clk_i,app_addr[26:0],app_cmd[2:0],app_en,app_wdf_data[127:0],app_wdf_end,app_wdf_mask[15:0],app_wdf_wren,app_rd_data[127:0],app_rd_data_end,app_rd_data_valid,app_rdy,app_wdf_rdy,app_sr_req,app_ref_req,app_zq_req,app_sr_active,app_ref_ack,app_zq_ack,ui_clk,ui_clk_sync_rst,init_calib_complete,sys_rst" */;
  inout [15:0]ddr2_dq;
  inout [1:0]ddr2_dqs_n;
  inout [1:0]ddr2_dqs_p;
  output [12:0]ddr2_addr;
  output [2:0]ddr2_ba;
  output ddr2_ras_n;
  output ddr2_cas_n;
  output ddr2_we_n;
  output [0:0]ddr2_ck_p;
  output [0:0]ddr2_ck_n;
  output [0:0]ddr2_cke;
  output [0:0]ddr2_cs_n;
  output [1:0]ddr2_dm;
  output [0:0]ddr2_odt;
  input sys_clk_i;
  input [26:0]app_addr;
  input [2:0]app_cmd;
  input app_en;
  input [127:0]app_wdf_data;
  input app_wdf_end;
  input [15:0]app_wdf_mask;
  input app_wdf_wren;
  output [127:0]app_rd_data;
  output app_rd_data_end;
  output app_rd_data_valid;
  output app_rdy;
  output app_wdf_rdy;
  input app_sr_req;
  input app_ref_req;
  input app_zq_req;
  output app_sr_active;
  output app_ref_ack;
  output app_zq_ack;
  output ui_clk;
  output ui_clk_sync_rst;
  output init_calib_complete;
  input sys_rst;
endmodule
