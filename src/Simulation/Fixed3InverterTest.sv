`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/14 19:14:24
// Design Name: 
// Module Name: Fixed3InverterTest
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
`include "..\Types.sv"

module Fixed3InverterTest;
    // Inputs
	logic CLK;
    Fixed3 Dir;
    Fixed3 InvDir;	
	
    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz
	always #(CLK_PERIOD/2) CLK = ~CLK;	
	
	// Instantiate the Unit Under Test (UUT)
	Fixed3Inverter Inv (
		.clk(CLK), 
		.v(Dir),
		.ov(InvDir)		
	);	  
	
	initial begin
		// Initialize Inputs		
		#10
		CLK = 1;				
		Dir.Dim[0].Value = 32'd32 << Fixed_FRAC_WIDTH;
		Dir.Dim[1].Value = 32'd128 << Fixed_FRAC_WIDTH;
		Dir.Dim[2].Value = 32'd1024 << Fixed_FRAC_WIDTH;
		
		#50
		$display($time, " InvDir = (%d, %d, %d)\n", Dir.Dim[0].Value, Dir.Dim[1].Value, Dir.Dim[2].Value);
		$display($time, " InvDir = (%d, %d, %d)\n", InvDir.Dim[0].Value, InvDir.Dim[1].Value, InvDir.Dim[2].Value);
		
		#10
		Dir.Dim[0].Value = 32'd10 << Fixed_FRAC_WIDTH;
		Dir.Dim[1].Value = 32'd20 << Fixed_FRAC_WIDTH;
		Dir.Dim[2].Value = 32'd0 << Fixed_FRAC_WIDTH;
		
		#50
		$display($time, " InvDir = (%d, %d, %d)\n", Dir.Dim[0].Value, Dir.Dim[1].Value, Dir.Dim[2].Value);
		$display($time, " InvDir = (%d, %d, %d)\n", InvDir.Dim[0].Value, InvDir.Dim[1].Value, InvDir.Dim[2].Value);
					
		#10
		$finish;		
			
	end
	
    
endmodule
