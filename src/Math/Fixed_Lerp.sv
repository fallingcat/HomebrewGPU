`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/14 18:23:25
// Design Name: 
// Module Name: Fixed_Div
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
`include "Fixed.sv"

module Fixed_Lerp (
    input clk,    
	input resetn, 
	input strobe,
    input Fixed a0,
    input Fixed a1,
	input Fixed r,
	output Fixed o
    );    

    always_comb begin        
    end
	
    Div DIV(
		.aclk(clk),
		.aresetn(resetn),
		.s_axis_divisor_tvalid(strobe),
		.s_axis_divisor_tdata((b.Value == `FIXED_ZERO) ? `FIXED_WIDTH'b1 : b.Value),
		.s_axis_dividend_tvalid(strobe),
		.s_axis_dividend_tdata({{2{1'b0}}, a.Value, {`FIXED_FRAC_WIDTH{1'b0}}}),
		.m_axis_dout_tvalid(valid),
		.m_axis_dout_tdata(OutData)
	);	
endmodule
