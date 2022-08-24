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


module RendererTest;
	logic CLK;
    logic Flip;
    //MemoryControllerRequest mem_request;
	
    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz
	always #(CLK_PERIOD/2) CLK = ~CLK;	

    initial begin
	    CLK = 1;
	
	    #4000
	    $finish;
    end	

    RendererV3 Renderer(
		.clk(CLK),		
        .resetn(1),
		.vsync(1),	
        .flip(Flip)
        );    

    
endmodule
