`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/14 18:11:47
// Design Name: 
// Module Name: Fixed3Inverter
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

module Fixed3_Inv_V2(
    input clk,  
	input resetn, 
	input logic strobe,  
    input Fixed3 v,
	output logic valid,
	output Fixed3 ov		
    );
    
	logic [1:0] Counter;    
    logic Valid[3];
	Fixed3 Out;	
	
	assign ov.Dim[0] = (IsFixedInf(Out.Dim[0])) ? _Fixed(0) : Out.Dim[0];
	assign ov.Dim[1] = (IsFixedInf(Out.Dim[1])) ? _Fixed(0) : Out.Dim[1];
	assign ov.Dim[2] = (IsFixedInf(Out.Dim[2])) ? _Fixed(0) : Out.Dim[2];	

	always_ff @(posedge clk) begin
		if (strobe || Counter == 3) begin	
			valid <= 0;		
			Counter = 0;
		end		

		if (Valid[0]) begin
			Counter = Counter + 1;
		end
		if (Valid[1]) begin
			Counter = Counter + 1;
		end
		if (Valid[2]) begin
			Counter = Counter + 1;
		end
		if (Counter == 3) begin
			valid <= 1;
		end
		else begin
			valid <= 0;
		end
	end
	
		
	Fixed_Div_V2#(`FIXED_DIV_STEP) FD0 (
		.clk(clk),
		.resetn(resetn),
		.strobe(strobe),
		.a(_Fixed(1)), 
		.b(v.Dim[0]), 
		.valid(Valid[0]),
		.q(Out.Dim[0])		
	);
	
	Fixed_Div_V2#(`FIXED_DIV_STEP) FD1 (
		.clk(clk), 
		.resetn(resetn),
		.strobe(strobe),
		.a(_Fixed(1)),
		.b(v.Dim[1]), 
		.valid(Valid[1]),
		.q(Out.Dim[1])		
	);
		
	Fixed_Div_V2#(`FIXED_DIV_STEP) FD2 (
		.clk(clk),
		.resetn(resetn),
		.strobe(strobe),
		.a(_Fixed(1)),
		.b(v.Dim[2]), 
		.valid(Valid[2]),
		.q(Out.Dim[2])
	);		
	
endmodule

module Fixed3_Inv_V3(
    input clk,  
	input resetn, 
	input logic strobe,  
    input Fixed3 v,
	output logic valid,
	output Fixed3 ov		
    );    
	logic Valid[3];
	Fixed3 Out;
	
	assign valid = (Valid[0] & Valid[1] & Valid[2]);	
	assign ov.Dim[0] = (IsFixedInf(Out.Dim[0])) ? _Fixed(0) : Out.Dim[0];
	assign ov.Dim[1] = (IsFixedInf(Out.Dim[1])) ? _Fixed(0) : Out.Dim[1];
	assign ov.Dim[2] = (IsFixedInf(Out.Dim[2])) ? _Fixed(0) : Out.Dim[2];	
		
	Fixed_Div_V3 FD0 (
		.clk(clk),
		.resetn(resetn),
		.strobe(strobe),
		.a(_Fixed(1)), 
		.b(v.Dim[0]), 
		.valid(Valid[0]),
		.q(Out.Dim[0])		
	);
	
	Fixed_Div_V3 FD1 (
		.clk(clk), 
		.resetn(resetn),
		.strobe(strobe),
		.a(_Fixed(1)),
		.b(v.Dim[1]), 
		.valid(Valid[1]),
		.q(Out.Dim[1])		
	);
		
	Fixed_Div_V3 FD2 (
		.clk(clk),
		.resetn(resetn),
		.strobe(strobe),
		.a(_Fixed(1)),
		.b(v.Dim[2]), 
		.valid(Valid[2]),
		.q(Out.Dim[2])
	);		
	
endmodule