`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/15 18:37:22
// Design Name: 
// Module Name: Fixed3NormalizeTest
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
`include "..\Math\Fixed3.sv"
`include "..\Math\FixedNorm3.sv"

module Fixed3NormalizeTest;

    logic CLK;
    Fixed3 A;
	Fixed3 B;   	 	
	//FixedNorm3 B;
	FixedNorm LightRad;
	Fixed SinCos;
	Fixed SinCos2;
	Fixed Cos;
	Fixed Sin;
	
    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz
	always #(CLK_PERIOD/2) CLK = ~CLK;	
	
	logic Strobe, Valid;

	// Instantiate the Unit Under Test (UUT)
	Fixed3_NormV2 Uut (
		.clk(CLK), 
		.strobe(Strobe),
		.v(A),
		.ov(B),
		//.ovn(B),
		.valid(Valid)
	);

	/*Cordic_SinCos SinCosGen(			 
    	.s_axis_phase_tdata(LightRad.Value),
    	.m_axis_dout_tdata(SinCos.Value)
		);
	  
	always @(SinCos.Value) begin 
		Cos.Value = SinCos.Value[15:0];
	   	Sin.Value = {{16{1'b0}}, SinCos.Value[31:16]};
	   	SinCos2.Value <= SinCos.Value;
		$display($time, " Sin, Cos = (%f, %f)\n", Sin.Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), Cos.Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));	   
	end
	*/

	initial begin
	   CLK = 1;	

	   #10
	   A = _Fixed3(_Fixed(8), _Fixed(5), _Fixed(6));	   
	   Strobe = 1;
	   
	   #10
	   Strobe = 0;
	   $display($time, " Normalized Vector3<%d> = (%f, %f, %f)\n", Valid, B.Dim[0].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[1].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[2].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));	   
	   
	   #10	
	   $display($time, " Normalized Vector3<%d> = (%f, %f, %f)\n", Valid, B.Dim[0].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[1].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[2].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));	   

	   #10		   
	   $display($time, " Normalized Vector3<%d> = (%f, %f, %f)\n", Valid, B.Dim[0].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[1].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[2].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));	   

	   #10	
	   $display($time, " Normalized Vector3<%d> = (%f, %f, %f)\n", Valid, B.Dim[0].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[1].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[2].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));	   

	   #10	
	   $display($time, " Normalized Vector3<%d> = (%f, %f, %f)\n", Valid, B.Dim[0].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[1].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[2].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));	   

	   #10	
	   $display($time, " Normalized Vector3<%d> = (%f, %f, %f)\n", Valid, B.Dim[0].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[1].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[2].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));	   

	   #10	
	   $display($time, " Normalized Vector3<%d> = (%f, %f, %f)\n", Valid, B.Dim[0].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[1].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[2].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));	   

	   #10	
	   $display($time, " Normalized Vector3<%d> = (%f, %f, %f)\n", Valid, B.Dim[0].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[1].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[2].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));	   

       #10
	   $finish;
    end   
	   
endmodule
