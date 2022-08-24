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

module Refraction_Test;    
    logic CLK;
    Fixed3 I, R;
    FixedNorm3 N;
    Fixed ETA;
    logic Strobe;
    logic Valid;

    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz
	always #(CLK_PERIOD/2) CLK = ~CLK;		
	
	RefractionDir REFRACTION(
        .clk(CLK),    
        .resetn(1),  
        .strobe(Strobe),  
        .n(N),
        .i(I),    
        .eta(ETA),            
        .r(R),
        .valid(Valid)
    );
	
	
	initial begin
	   CLK = 1;
	
	   N = _FixedNorm3u(0, 1, 0);
       I = _Fixed3s(4294758429, 4294876638, 4294571145);
       ETA.Value = 15728;
	   Strobe = 1;	   
	
	   #10       	   
	   $display($time, " Refrraction Dir <Valid = %d> = (%d, %d, %d)\n", Valid, R.Dim[0].Value, R.Dim[1].Value, R.Dim[2].Value);

	   #10
       Strobe = 0;
	   $display($time, " Refrraction Dir <Valid = %d> = (%d, %d, %d)\n", Valid, R.Dim[0].Value, R.Dim[1].Value, R.Dim[2].Value);

	   #10
	   $display($time, " Refrraction Dir <Valid = %d> = (%d, %d, %d)\n", Valid, R.Dim[0].Value, R.Dim[1].Value, R.Dim[2].Value);

       #10
	   $display($time, " Refrraction Dir <Valid = %d> = (%d, %d, %d)\n", Valid, R.Dim[0].Value, R.Dim[1].Value, R.Dim[2].Value);

       #10
	   $display($time, " Refrraction Dir <Valid = %d> = (%d, %d, %d)\n", Valid, R.Dim[0].Value, R.Dim[1].Value, R.Dim[2].Value);

       #10
	   $display($time, " Refrraction Dir <Valid = %d> = (%d, %d, %d)\n", Valid, R.Dim[0].Value, R.Dim[1].Value, R.Dim[2].Value);

       #10
	   $display($time, " Refrraction Dir <Valid = %d> = (%d, %d, %d)\n", Valid, R.Dim[0].Value, R.Dim[1].Value, R.Dim[2].Value);

       #10
	   $display($time, " Refrraction Dir <Valid = %d> = (%d, %d, %d)\n", Valid, R.Dim[0].Value, R.Dim[1].Value, R.Dim[2].Value);

       #10
	   $display($time, " Refrraction Dir <Valid = %d> = (%d, %d, %d)\n", Valid, R.Dim[0].Value, R.Dim[1].Value, R.Dim[2].Value);

       #10
	   $display($time, " Refrraction Dir <Valid = %d> = (%d, %d, %d)\n", Valid, R.Dim[0].Value, R.Dim[1].Value, R.Dim[2].Value);

       #10
	   $display($time, " Refrraction Dir <Valid = %d> = (%d, %d, %d)\n", Valid, R.Dim[0].Value, R.Dim[1].Value, R.Dim[2].Value);

       #10
	   $display($time, " Refrraction Dir <Valid = %d> = (%d, %d, %d)\n", Valid, R.Dim[0].Value, R.Dim[1].Value, R.Dim[2].Value);

       #10
	   $display($time, " Refrraction Dir <Valid = %d> = (%d, %d, %d)\n", Valid, R.Dim[0].Value, R.Dim[1].Value, R.Dim[2].Value);

       #10
	   $display($time, " Refrraction Dir <Valid = %d> = (%d, %d, %d)\n", Valid, R.Dim[0].Value, R.Dim[1].Value, R.Dim[2].Value);

       #40
	   $display($time, " Refrraction Dir <Valid = %d> = (%d, %d, %d)\n", Valid, R.Dim[0].Value, R.Dim[1].Value, R.Dim[2].Value);

       #40
	   $display($time, " Refrraction Dir <Valid = %d> = (%d, %d, %d)\n", Valid, R.Dim[0].Value, R.Dim[1].Value, R.Dim[2].Value);

       #40
	   $display($time, " Refrraction Dir <Valid = %d> = (%d, %d, %d)\n", Valid, R.Dim[0].Value, R.Dim[1].Value, R.Dim[2].Value);

       #40
	   $display($time, " Refrraction Dir <Valid = %d> = (%d, %d, %d)\n", Valid, R.Dim[0].Value, R.Dim[1].Value, R.Dim[2].Value);

       #40
	   $display($time, " Refrraction Dir <Valid = %d> = (%d, %d, %d)\n", Valid, R.Dim[0].Value, R.Dim[1].Value, R.Dim[2].Value);
					
        #10
	   $finish;
    end	
    
    
endmodule
