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

module Fixed3_Mad(
    input clk,
	input Fixed3 c,
    input Fixed a,
    input Fixed3 b,
	output Fixed3 ov
    );

`ifdef USE_MAD_IP
    logic [24:0] A;
    logic [24:0] B[3];
    
    always_comb begin
        A = a.Value >> `FIXED_FRAC_HALF_WIDTH;
        B[0] = b.Dim[0].Value >> `FIXED_FRAC_HALF_WIDTH;
        B[1] = b.Dim[1].Value >> `FIXED_FRAC_HALF_WIDTH;
        B[2] = b.Dim[2].Value >> `FIXED_FRAC_HALF_WIDTH;        
    end

    Vivado_Fixed_Mad MAD0 (
		.A(A), 
		.B(B[0]), 
        .C(c.Dim[0].Value), 
        .SUBTRACT(0),
		.P(ov.Dim[0].Value)
	);
	
	Vivado_Fixed_Mad MAD1 (
		.A(A), 
		.B(B[1]), 
        .C(c.Dim[1].Value), 
        .SUBTRACT(0),
		.P(ov.Dim[1].Value)
	);

    Vivado_Fixed_Mad MAD2 (
		.A(A), 
		.B(B[2]), 
        .C(c.Dim[2].Value), 
        .SUBTRACT(0),
		.P(ov.Dim[2].Value)
	);
`else
    always_ff @(posedge clk) begin
        ov = Fixed3_Add(c, Fixed3_Mul(a, b));
    end
`endif
	
endmodule
