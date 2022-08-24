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

module Fixed3NormalizeInvTest;

    logic CLK;
    Fixed3 A, T;
	Fixed3 B;   	 	
	//FixedNorm3 B;
	FixedNorm LightRad;
	Fixed SinCos;
	Fixed SinCos2;
	Fixed Cos;
	Fixed Sin;
	
    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz
	always #(CLK_PERIOD/2) CLK = ~CLK;	
	
	logic Strobe, Valid, Norm_Valid;
	
	Fixed3_NormV2 FNorm_0(
		.clk(CLK), 
		.strobe(Strobe),
		.v(A),
		.ov(T),
		.valid(Norm_Valid)
	);	   	    

    Fixed3_Inv_V3 DIR_INV(
		.clk(CLK),        
		.strobe(Norm_Valid),		
        .v(T), 
		.valid(Valid),
		.ov(B)
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
	   A = _Fixed3(_Fixed(0), _Fixed(1), _Fixed(1));	   
       Strobe = 1;
	   
	   #10
	   Strobe = 0;
	   $display($time, " Normalized Vector3<%d, %d> = (%f, %f, %f)\n", Norm_Valid, Valid, B.Dim[0].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[1].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[2].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));	   
	   
	   #10	
	   $display($time, " Normalized Vector3<%d, %d> = (%f, %f, %f)\n", Norm_Valid, Valid, B.Dim[0].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[1].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[2].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));	   

	   #10	
	   $display($time, " Normalized Vector3<%d, %d> = (%f, %f, %f)\n", Norm_Valid, Valid, B.Dim[0].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[1].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[2].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));	   

       #10	
	   $display($time, " Normalized Vector3<%d, %d> = (%f, %f, %f)\n", Norm_Valid, Valid, B.Dim[0].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[1].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[2].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));	   

       #10	
	   $display($time, " Normalized Vector3<%d, %d> = (%f, %f, %f)\n", Norm_Valid, Valid, B.Dim[0].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[1].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[2].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));	   

       #10	
	   $display($time, " Normalized Vector3<%d, %d> = (%f, %f, %f)\n", Norm_Valid, Valid, B.Dim[0].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[1].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[2].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));	   

       #10	
	   $display($time, " Normalized Vector3<%d, %d> = (%f, %f, %f)\n", Norm_Valid, Valid, B.Dim[0].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[1].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[2].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));	   

       #10	
	   $display($time, " Normalized Vector3<%d, %d> = (%f, %f, %f)\n", Norm_Valid, Valid, B.Dim[0].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[1].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[2].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));	   

       #10	
	   $display($time, " Normalized Vector3<%d, %d> = (%f, %f, %f)\n", Norm_Valid, Valid, B.Dim[0].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[1].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[2].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));	   

       #10	
	   $display($time, " Normalized Vector3<%d, %d> = (%f, %f, %f)\n", Norm_Valid, Valid, B.Dim[0].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[1].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[2].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));	   

       #10	
	   $display($time, " Normalized Vector3<%d, %d> = (%f, %f, %f)\n", Norm_Valid, Valid, B.Dim[0].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[1].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[2].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));	   

       #10	
	   $display($time, " Normalized Vector3<%d, %d> = (%f, %f, %f)\n", Norm_Valid, Valid, B.Dim[0].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[1].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[2].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));	   

       #100	
	   $display($time, " Normalized Vector3<%d, %d> = (%f, %f, %f)\n", Norm_Valid, Valid, B.Dim[0].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[1].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[2].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));	   
       #10
	   $finish;
    end   
	   
endmodule
