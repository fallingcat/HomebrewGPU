`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/23 16:07:02
// Design Name: 
// Module Name: HomebrewGPU
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
`include "Math/Fixed.sv"
`include "Math/Fixed3.sv"

module FixedALU(    
    input clk,	
    input resetn,
    // controls ...    
    input strobe,  
    // inputs ...  
    input Fixed a,
    input Fixed b,
    // outputs ...
    output Fixed out,
    output logic valid,
    output logic free
    );

endmodule

module Fixed3ALU(
    input clk,	
    input resetn,
    // controls ...    
    input strobe,  
    // inputs ...  
    input Fixed3 a,
    input Fixed3 b,
    // outputs ...
    output Fixed3 out,
    output logic valid,
    output logic free
    );

endmodule
