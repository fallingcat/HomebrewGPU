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
`include "FixedNorm3.sv"

module Fixed3_NormV2(
    input clk,	
	input logic strobe,
	input Fixed3 v,
	output logic valid,
	output Fixed3 ov,
	output FixedNorm3 ovn
    );
	logic [47:0] D[3];
	logic [47:0] A;
	logic [23:0] B;
	Fixed3 TA;
	Fixed SQRT;
	logic SQRT_Valid;
	logic Valid[3];
    
	//assign valid = (Valid[0] & Valid[1] & Valid[2]);
	assign valid = Valid[2];
	assign ovn.Dim[0].Value = ov.Dim[0].Value[15:0];
	assign ovn.Dim[1].Value = ov.Dim[1].Value[15:0];
	assign ovn.Dim[2].Value = ov.Dim[2].Value[15:0];
	
	always_comb begin
		TA.Dim[0] = (v.Dim[0].Value[`FIXED_WIDTH-1]) ? Fixed_Neg(v.Dim[0]) : v.Dim[0];		
		TA.Dim[1] = (v.Dim[1].Value[`FIXED_WIDTH-1]) ? Fixed_Neg(v.Dim[1]) : v.Dim[1];		
		TA.Dim[2] = (v.Dim[2].Value[`FIXED_WIDTH-1]) ? Fixed_Neg(v.Dim[2]) : v.Dim[2];		
		
		D[0] = TA.Dim[0].Value >> 8;
		D[1] = TA.Dim[1].Value >> 8;
		D[2] = TA.Dim[2].Value >> 8;

		A = (D[0] * D[0]) + (D[1] * D[1]) + (D[2] * D[2]);
	end

	always_comb begin
		SQRT.Value = (B == 0) ? `FIXED_ONE : (B << 8);
	end

	Sqrt SQT(
        //.aclk(clk),
        .s_axis_cartesian_tvalid(strobe),
        .s_axis_cartesian_tdata(A),
        .m_axis_dout_tvalid(SQRT_Valid),
        .m_axis_dout_tdata(B)
    );    

	Fixed_Div_V3 D0(
		.clk(clk),
		.strobe(SQRT_Valid), 
		.a(v.Dim[0]), 
        .b(SQRT), 
        .valid(Valid[0]),
		.q(ov.Dim[0])
	);

	Fixed_Div_V3 D1(
		.clk(clk),
		.strobe(SQRT_Valid), 
		.a(v.Dim[1]), 
        .b(SQRT), 
        .valid(Valid[1]),
		.q(ov.Dim[1])
	);

	Fixed_Div_V3 D2(
		.clk(clk),
		.strobe(SQRT_Valid), 
		.a(v.Dim[2]), 
        .b(SQRT), 
        .valid(Valid[2]),
		.q(ov.Dim[2])
	);
    
endmodule
