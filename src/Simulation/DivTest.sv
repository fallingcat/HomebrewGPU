`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/10 11:25:28
// Design Name: 
// Module Name: DivTest
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


module DivTest;

    logic CLK;
    Fixed A, B;
    Fixed Q;
    logic Strobe;
    logic QValid;
	
    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz
	always #(CLK_PERIOD/2) CLK = ~CLK;	

    // Instantiate the Unit Under Test (UUT)
	Fixed_Div_V3 D(
		.clk(CLK),
		.strobe(Strobe), 
		.a(A), 
        .b(B), 
        .valid(QValid),
		.q(Q)
	);	
	
	initial begin
	   CLK = 1;
	
	   #10
	   Strobe = 1;       
       A = _Fixed(2057);
       B = _Fixed(7);

       #10
	   //Strobe = 0;       

	   //#10
	   //Strobe = 0;       
       
	   #40
	   $display($time, "(%d) : %d / %d = %f\n", QValid, A.Value>>14, B.Value>>14, Q.Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));

	   #40
	   $display($time, "(%d) : %d / %d = %f\n", QValid, A.Value>>14, B.Value>>14, Q.Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));

	   #40
	   $display($time, "(%d) : %d / %d = %f\n", QValid, A.Value>>14, B.Value>>14, Q.Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));

	   #40
	   $display($time, "(%d) : %d / %d = %f\n", QValid, A.Value>>14, B.Value>>14, Q.Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));

	   #10
	   Strobe = 0;       

	   #10
	   Strobe = 1;       	   
	   A = _Fixed(157);
       B = _Fixed(7);

       #40
	   $display($time, "(%d) : %d / %d = %f\n", QValid, A.Value>>14, B.Value>>14, Q.Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));

       #40
	   $display($time, "(%d) : %d / %d = %f\n", QValid, A.Value>>14, B.Value>>14, Q.Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));

       #40
	   $display($time, "(%d) : %d / %d = %d\n", QValid, A.Value>>14, B.Value>>14, Q.Value>>14);

       #40
	   $display($time, "(%d) : %d / %d = %d\n", QValid, A.Value>>14, B.Value>>14, Q.Value>>14);

       #40
	   $display($time, "(%d) : %d / %d = %d\n", QValid, A.Value>>14, B.Value>>14, Q.Value>>14);

       #40
	   $display($time, "(%d) : %d / %d = %d\n", QValid, A.Value>>14, B.Value>>14, Q.Value>>14);

       #40
	   $display($time, "(%d) : %d / %d = %d\n", QValid, A.Value>>14, B.Value>>14, Q.Value>>14);

       #40
	   $display($time, "(%d) : %d / %d = %d\n", QValid, A.Value>>14, B.Value>>14, Q.Value>>14);

       #40
	   $display($time, "(%d) : %d / %d = %d\n", QValid, A.Value>>14, B.Value>>14, Q.Value>>14);
	   			
        #40
	   $finish;
    end
	

endmodule
