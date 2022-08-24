`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/22 11:12:38
// Design Name: 
// Module Name: Fixed3Inv_Test
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

module Fixed3Inv_Test;    
    logic CLK;
    Fixed3 A, B;
    logic Start;
    State State;
	logic Valid;

    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz
	always #(CLK_PERIOD/2) CLK = ~CLK;		
	
	// Instantiate the Unit Under Test (UUT)
	Fixed3_Inv_V3 Uut(
		.clk(CLK),
		.strobe(Start), 
		.v(A), 
		.ov(B),
		.valid(Valid)
	);	
	
	
	initial begin
	   CLK = 1;
	
	   //#10
	   //A = Fixed_Mul(_Fixed(10), _Fixed(10));
	   A = _Fixed3(_Fixed(8), _Fixed(15), _Fixed(17));
	   Start = 1;	   
	
	   #10
	   $display($time, " Invert Vector3<%d> = (%f, %f, %f)\n", Valid, B.Dim[0].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[1].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[2].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));

	   #10
	   $display($time, " Invert Vector3<%d> = (%f, %f, %f)\n", Valid, B.Dim[0].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[1].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[2].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));

	   #10
	   $display($time, " Invert Vector3<%d> = (%f, %f, %f)\n", Valid, B.Dim[0].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[1].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[2].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));

	   #10
	   $display($time, " Invert Vector3<%d> = (%f, %f, %f)\n", Valid, B.Dim[0].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[1].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[2].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));
	   
	   #10
	   $display($time, " Invert Vector3<%d> = (%f, %f, %f)\n", Valid, B.Dim[0].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[1].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[2].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));

	   #40
	   $display($time, " Invert Vector3 = (%f, %f, %f)\n", B.Dim[0].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[1].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[2].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));
	   Start = 0;
	   //$display($time, " Sqrt(%f) = %f\n", A.Value, B.Value);
	   
	   /*
	   #10
	   A = _Fixed3(_Fixed(4), _Fixed(10), _Fixed(-15));
	   Start = 1;	   
	   
	   #10
	   $display($time, " Invert Vector3 = (%f, %f, %f)\n", B.Dim[0].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), B.Dim[1].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), Fixed_Neg(B.Dim[2]).Value/(-1.0 * (1 << `FIXED_FRAC_WIDTH)));
	   Start = 0;
	   */
					
        #10
	   $finish;
    end	
    
    
endmodule
