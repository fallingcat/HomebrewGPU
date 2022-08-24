`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/16 12:13:39
// Design Name: 
// Module Name: RayCoreTest
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "Types.sv"

module HomebrewGPUTop(
    input CLK100MHZ,
	input CPU_RESETN,
	input BTNU,
    input BTND,
    input BTNL,
    input BTNR,
    // VGA outputs
    output VGA_HS,    
    output VGA_VS,
    output [3:0] VGA_R,
    output [3:0] VGA_G,
    output [3:0] VGA_B,
    // LED outputs
	output [15:0] LED,
    // 7-Segments
    output CA,
    output CB,
    output CC,
    output CD,
    output CE,
    output CF,
    output CG,
    output DP,
    output [7:0] AN,
	// DDR2 chip signals
    inout [15:0] ddr2_dq,
    inout [1:0] ddr2_dqs_n,
    inout [1:0] ddr2_dqs_p,
    output [12:0] ddr2_addr,
    output [2:0] ddr2_ba,
    output ddr2_ras_n,
    output ddr2_cas_n,
    output ddr2_we_n,
    output [0:0] ddr2_ck_p,
    output [0:0] ddr2_ck_n,
    output [0:0] ddr2_cke,
    output [0:0] ddr2_cs_n,
    output [1:0] ddr2_dm,
    output [0:0] ddr2_odt	
    );
	
	logic CLK200MHZ, CLK33MHZ, CLK50MHZ, CLK25MHZ, CLK12MHZ, CLK6MHZ, CLK3MHZ, CLK1MHZ;
	logic Blank;	
	logic `SCREEN_COORD x, y;		
	RGB8 FinalColor;	
    logic [15:0] KCyclePerFrame;    
    logic [7:0] Seg;	   
    logic [7:0] Digit;
	
	
	// Output Color
    assign VGA_R = Blank ? 0 : (FinalColor.Channel[0] >> 4);
	assign VGA_G = Blank ? 0 : (FinalColor.Channel[1] >> 4);
	assign VGA_B = Blank ? 0 : (FinalColor.Channel[2] >> 4);

    assign CA = Seg[7];
    assign CB = Seg[6];
    assign CC = Seg[5];
    assign CD = Seg[4];
    assign CE = Seg[3];
    assign CF = Seg[2];
    assign CG = Seg[1];
    assign DP = Seg[0];    
    assign AN = Digit;

	//assign VGA_R = Blank ? 0 : (FinalColor.Channel[0] * 15) >> 8;
	//assign VGA_G = Blank ? 0 : (FinalColor.Channel[1] * 15) >> 8;
	//assign VGA_B = Blank ? 0 : (FinalColor.Channel[2] * 15) >> 8;		
	
    ClockWizard ClkWiz (
        .clk_in1(CLK100MHZ),
        .resetn(CPU_RESETN),        
        .clk_200(CLK200MHZ)
    );

    /*
    ClockDividedBy3 Div33M(
        .clk(CLK100MHZ),
        .clk2(CLK100MHZ),
        .o_clk(CLK33MHZ)
    );*/
    
    ClockDivider Div50M(
        .clk(CLK100MHZ),
        .o_clk(CLK50MHZ)
    );

    ClockDivider Div25M(
        .clk(CLK50MHZ),
        .o_clk(CLK25MHZ)
    );

    ClockDivider Div12M(
        .clk(CLK25MHZ),
        .o_clk(CLK12MHZ)
    );

    /*
    ClockDivider Div6M(
        .clk(CLK12MHZ),
        .o_clk(CLK6MHZ)
    );

    ClockDivider Div3M(
        .clk(CLK6MHZ),
        .o_clk(CLK3MHZ)
    );

    ClockDivider Div1M(
        .clk(CLK3MHZ),
        .o_clk(CLK1MHZ)
    );    
    */

    VGA_640x480_25M_Clk VGA_SYNC(
	    .clk(CLK25MHZ), 
	    .hs(VGA_HS), 
	    .vs(VGA_VS), 
	    .current_x(x), 
	    .current_y(y), 
	    .blank(Blank)
	);	    

	HomebrewGPU GPU(
		.clk(CLK25MHZ),        
        .clk_vga(CLK50MHZ),	
        .clk_mc(CLK50MHZ),	
		.clk_mem(CLK200MHZ),        
        .resetn(CPU_RESETN),
        .hsync(VGA_HS),
		.vsync(VGA_VS),		
        .blank(Blank),
		.x(x), 
		.y(y), 
		.color(FinalColor),		
        .kcycle_per_frame(KCyclePerFrame),    
        .LED(LED),
		.ddr2_cs_n(ddr2_cs_n),
        .ddr2_addr(ddr2_addr),
        .ddr2_ba(ddr2_ba),
        .ddr2_we_n(ddr2_we_n),
        .ddr2_ras_n(ddr2_ras_n),
        .ddr2_cas_n(ddr2_cas_n),
        .ddr2_ck_n(ddr2_ck_n),
        .ddr2_ck_p(ddr2_ck_p),
        .ddr2_cke(ddr2_cke),
        .ddr2_dq(ddr2_dq),
        .ddr2_dqs_n(ddr2_dqs_n),
        .ddr2_dqs_p(ddr2_dqs_p),
        .ddr2_dm(ddr2_dm),
        .ddr2_odt(ddr2_odt)
	);	    

    HexDisplay_7_Seg DISPLAY_SEG(
        .clk(CLK12MHZ),
        .number(KCyclePerFrame),        
        .seg(Seg),
        .digit(Digit)
    );
	
endmodule
