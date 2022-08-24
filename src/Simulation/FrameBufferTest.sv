`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/30 16:58:48
// Design Name: 
// Module Name: FrameBufferTest
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
`include "../Math/Fixed.sv"
`include "../Math/Fixed3.sv"

module FrameBufferTest;

    logic CLK, CLK100;
    logic `SCREEN_COORD ix, iy, ox, oy;
    RGB8 Color;

    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz
	always #(CLK_PERIOD / 2) CLK100 = ~CLK100;
    always #(CLK_PERIOD * 2) CLK = ~CLK;

    /*FrameBufferReader FBR(
        .clk(CLK),	
        .clk_fbw(CLK100),
        .clk_mem(CLK),
        .x(x),
        .y(y)        
	);*/

    /*
    FrameBufferWriter FBW(
        .clk(CLK),	
        .clk_fbw(CLK100),
        .clk_mem(CLK),
        .x(x),
        .y(y),
        .color(Color)        
    );
    */    

    FrameBufferController FBC(
        .clk(CLK),	
        .clk_fbw(CLK100),
        .clk_mem(CLK),
        .ix(ix),
        .iy(iy),
        .i_color(Color),
        .ox(ox),
        .oy(oy)       
    );    

    initial begin
        CLK100 = 1;
	    CLK = 1;
	
	    #10
        ix = 0;
        iy = 0;
        ox = 0;
        oy = 0;

	    #160
	    ix = 31;
        iy = 0;
        ox = 16;
        oy = 0;

        #160
	    ix = 0;
        iy = 1;
        ox = 31;
        oy = 0;

        #160
	    ix = 31;
        iy = 1;
        ox = 0;
        oy = 1;
        	
	    #600
	    $finish;
    end   

endmodule
