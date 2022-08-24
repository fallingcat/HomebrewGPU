`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Arcade Mode
// Engineer: Owen Wu
// 
// Create Date: 2021/04/15 17:57:11
// Design Name: 
// Module Name: Fixed3_Norm
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
`include "Fixed3.sv"

module FixedNorm_CosSin(
    input clk,
	input FixedNorm d,
	output Fixed o
    );

    logic`FIXED CosSinLut[360];

	initial begin
		$readmemh("E:/MyWork/HomebrewGPU/Prototype/HomebrewGPU/src/CosSinLut.txt", CosSinLut);		
	end

    always_ff @(posedge clk) begin
        o.Value = CosSinLut[d.Value];
    end      
   
endmodule
