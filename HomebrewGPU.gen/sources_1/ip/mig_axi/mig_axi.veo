//*****************************************************************************
// (c) Copyright 2009 - 2011 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /   Vendor             : Xilinx
// \   \   \/    Version            : 4.2
//  \   \        Application        : MIG
//  /   /        Filename           : mig_axi.veo
// /___/   /\    Date Last Modified : $Date: 2011/06/02 08:34:47 $
// \   \  /  \   Date Created       : Fri Oct 14 2011
//  \___\/\___\
//
// Device           : 7 Series
// Design Name      : DDR2 SDRAM
// Purpose          : Template file containing code that can be used as a model
//                    for instantiating a CORE Generator module in a HDL design.
// Revision History :
//*****************************************************************************

// The following must be inserted into your Verilog file for this
// core to be instantiated. Change the instance name and port connections
// (in parentheses) to your own signal names.

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG

  mig_axi u_mig_axi (

    // Memory interface ports
    .ddr2_addr                      (ddr2_addr),  // output [12:0]                       ddr2_addr
    .ddr2_ba                        (ddr2_ba),  // output [2:0]                      ddr2_ba
    .ddr2_cas_n                     (ddr2_cas_n),  // output                                       ddr2_cas_n
    .ddr2_ck_n                      (ddr2_ck_n),  // output [0:0]                        ddr2_ck_n
    .ddr2_ck_p                      (ddr2_ck_p),  // output [0:0]                        ddr2_ck_p
    .ddr2_cke                       (ddr2_cke),  // output [0:0]                       ddr2_cke
    .ddr2_ras_n                     (ddr2_ras_n),  // output                                       ddr2_ras_n
    .ddr2_we_n                      (ddr2_we_n),  // output                                       ddr2_we_n
    .ddr2_dq                        (ddr2_dq),  // inout [15:0]                         ddr2_dq
    .ddr2_dqs_n                     (ddr2_dqs_n),  // inout [1:0]                        ddr2_dqs_n
    .ddr2_dqs_p                     (ddr2_dqs_p),  // inout [1:0]                        ddr2_dqs_p
    .init_calib_complete            (init_calib_complete),  // output                                       init_calib_complete
      
	.ddr2_cs_n                      (ddr2_cs_n),  // output [0:0]           ddr2_cs_n
    .ddr2_dm                        (ddr2_dm),  // output [1:0]                        ddr2_dm
    .ddr2_odt                       (ddr2_odt),  // output [0:0]                       ddr2_odt
    // Application interface ports
    .ui_clk                         (ui_clk),  // output                                       ui_clk
    .ui_clk_sync_rst                (ui_clk_sync_rst),  // output                                       ui_clk_sync_rst
    .mmcm_locked                    (mmcm_locked),  // 
    .aresetn                        (aresetn),  // 
    .app_sr_req                     (app_sr_req),  // input                                        app_sr_req
    .app_ref_req                    (app_ref_req),  // input                                        app_ref_req
    .app_zq_req                     (app_zq_req),  // input                                        app_zq_req
    .app_sr_active                  (app_sr_active),  // output                                       app_sr_active
    .app_ref_ack                    (app_ref_ack),  // output                                       app_ref_ack
    .app_zq_ack                     (app_zq_ack),  // output                                       app_zq_ack
    // Slave Interface Write Address Ports
    .s_axi_awid                     (s_axi_awid),  // input  [3:0]                s_axi_awid
    .s_axi_awaddr                   (s_axi_awaddr),  // input  [26:0]              s_axi_awaddr
    .s_axi_awlen                    (s_axi_awlen),  // input  [7:0]                                 s_axi_awlen
    .s_axi_awsize                   (s_axi_awsize),  // input  [2:0]                                 s_axi_awsize
    .s_axi_awburst                  (s_axi_awburst),  // input  [1:0]                                 s_axi_awburst
    .s_axi_awlock                   (s_axi_awlock),  // input  [0:0]                                 s_axi_awlock
    .s_axi_awcache                  (s_axi_awcache),  // input  [3:0]                                 s_axi_awcache
    .s_axi_awprot                   (s_axi_awprot),  // input  [2:0]                                 s_axi_awprot
    .s_axi_awqos                    (s_axi_awqos),  // input  [3:0]                                 s_axi_awqos
    .s_axi_awvalid                  (s_axi_awvalid),  // input                                        s_axi_awvalid
    .s_axi_awready                  (s_axi_awready),  // output                                       s_axi_awready
    // Slave Interface Write Data Ports
    .s_axi_wdata                    (s_axi_wdata),  // input  [127:0]              s_axi_wdata
    .s_axi_wstrb                    (s_axi_wstrb),  // input  [15:0]            s_axi_wstrb
    .s_axi_wlast                    (s_axi_wlast),  // input                                        s_axi_wlast
    .s_axi_wvalid                   (s_axi_wvalid),  // input                                        s_axi_wvalid
    .s_axi_wready                   (s_axi_wready),  // output                                       s_axi_wready
    // Slave Interface Write Response Ports
    .s_axi_bid                      (s_axi_bid),  // output [3:0]                s_axi_bid
    .s_axi_bresp                    (s_axi_bresp),  // output [1:0]                                 s_axi_bresp
    .s_axi_bvalid                   (s_axi_bvalid),  // output                                       s_axi_bvalid
    .s_axi_bready                   (s_axi_bready),  // input                                        s_axi_bready
    // Slave Interface Read Address Ports
    .s_axi_arid                     (s_axi_arid),  // input  [3:0]                s_axi_arid
    .s_axi_araddr                   (s_axi_araddr),  // input  [26:0]              s_axi_araddr
    .s_axi_arlen                    (s_axi_arlen),  // input  [7:0]                                 s_axi_arlen
    .s_axi_arsize                   (s_axi_arsize),  // input  [2:0]                                 s_axi_arsize
    .s_axi_arburst                  (s_axi_arburst),  // input  [1:0]                                 s_axi_arburst
    .s_axi_arlock                   (s_axi_arlock),  // input  [0:0]                                 s_axi_arlock
    .s_axi_arcache                  (s_axi_arcache),  // input  [3:0]                                 s_axi_arcache
    .s_axi_arprot                   (s_axi_arprot),  // input  [2:0]                                 s_axi_arprot
    .s_axi_arqos                    (s_axi_arqos),  // input  [3:0]                                 s_axi_arqos
    .s_axi_arvalid                  (s_axi_arvalid),  // input                                        s_axi_arvalid
    .s_axi_arready                  (s_axi_arready),  // output                                       s_axi_arready
    // Slave Interface Read Data Ports
    .s_axi_rid                      (s_axi_rid),  // output [3:0]                s_axi_rid
    .s_axi_rdata                    (s_axi_rdata),  // output [127:0]              s_axi_rdata
    .s_axi_rresp                    (s_axi_rresp),  // output [1:0]                                 s_axi_rresp
    .s_axi_rlast                    (s_axi_rlast),  // output                                       s_axi_rlast
    .s_axi_rvalid                   (s_axi_rvalid),  // output                                       s_axi_rvalid
    .s_axi_rready                   (s_axi_rready),  // input                                        s_axi_rready
    // System Clock Ports
    .sys_clk_i                       (sys_clk_i),
    .sys_rst                        (sys_rst) // input  sys_rst
    );

// INST_TAG_END ------ End INSTANTIATION Template ---------

// You must compile the wrapper file mig_axi.v when simulating
// the core, mig_axi. When compiling the wrapper file, be sure to
// reference the XilinxCoreLib Verilog simulation library. For detailed
// instructions, please refer to the "CORE Generator Help".


