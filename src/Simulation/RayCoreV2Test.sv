`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/10 20:36:45
// Design Name: 
// Module Name: RendererTest
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
`include "../Math/FixedNorm.sv"
`include "../Math/FixedNorm3.sv"

module RayCoreV2Test;
	logic CLK;
    logic Flip;
    //MemoryControllerRequest mem_request;
	
    parameter CLK_PERIOD = 20;  // 10 ns == 100 MHz
	always #(CLK_PERIOD/2) CLK = ~CLK;	

    RenderState RenderState;	
    logic `SCREEN_COORD x, y;	    

    initial begin
	    CLK = 1;
        x = 160;
        y = 120;
	
	    #1000
	    $finish;
    end	

    RayCoreV2 RC(
        .clk(CLK),
        .resetn(1),		
        .strobe(1),
        .rs(RenderState),	
        .x(x),
        .y(y)
        );      

    
endmodule
