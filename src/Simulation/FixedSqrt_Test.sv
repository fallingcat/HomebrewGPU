`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/15 12:31:25
// Design Name: 
// Module Name: FixedSqrt_Test
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

module FixedSqrt_Test;
// Inputs
	logic CLK;
    Fixed A, B;    	
	logic Strobe, Valid;
	
    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz
	always #(CLK_PERIOD/2) CLK = ~CLK;	
	
	// Instantiate the Unit Under Test (UUT)
	Fixed_SqrtV2 Uut (
		.clk(CLK), 
		.strobe(Strobe),
		.rad(A),
		.root(B),
		.valid(Valid)
	);	  
	
	initial begin
	   CLK = 1;	   
	
	   #10	   
	   Strobe = 1;
	   A = _Fixed(3);	
	   $display($time, " (%d) Sqrt of (%d) = %f\n", Valid, A.Value >> 14, B.Value/(1.0 * (1 << 14)));

	   #10
	   Strobe = 0;		   	   
	   $display($time, " (%d) Sqrt of (%d) = %f\n", Valid, A.Value >> 14, B.Value/(1.0 * (1 << 14)));

	   #10	   
	   $display($time, " (%d) Sqrt of (%d) = %f\n", Valid, A.Value >> 14, B.Value/(1.0 * (1 << 14)));

	   #10	   
	   $display($time, " (%d) Sqrt of (%d) = %f\n", Valid, A.Value >> 14, B.Value/(1.0 * (1 << 14)));

	   #10	   
	   $display($time, " (%d) Sqrt of (%d) = %f\n", Valid, A.Value >> 14, B.Value/(1.0 * (1 << 14)));	   

	   #10	   
	   $display($time, " (%d) Sqrt of (%d) = %f\n", Valid, A.Value >> 14, B.Value/(1.0 * (1 << 14)));
	   
		#10
		Strobe = 1;
		A = _Fixed(1947);	   

	   #40	   
	   $display($time, " (%d) Sqrt of (%d) = %f\n", Valid, A.Value >> 14, B.Value/(1.0 * (1 << 14)));

	   #40	   
	   $display($time, " (%d) Sqrt of (%d) = %f\n", Valid, A.Value >> 14, B.Value/(1.0 * (1 << 14)));

	   #40	   
	   $display($time, " (%d) Sqrt of (%d) = %f\n", Valid, A.Value >> 14, B.Value/(1.0 * (1 << 14)));

	   #40	   
	   $display($time, " (%d) Sqrt of (%d) = %f\n", Valid, A.Value >> 14, B.Value/(1.0 * (1 << 14)));

	   #40	   
	   $display($time, " (%d) Sqrt of (%d) = %f\n", Valid, A.Value >> 14, B.Value/(1.0 * (1 << 14)));

	   #40	   
	   $display($time, " (%d) Sqrt of (%d) = %f\n", Valid, A.Value >> 14, B.Value/(1.0 * (1 << 14)));
	   
	   			
        #10
	   $finish;
			
	
	end
	

endmodule
