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

module Detla(
    input Fixed d0,
    input Fixed d1,
    input logic [8:0] d,
    output Fixed delta
    );
    Fixed D;
    always_comb begin
        D = Fixed_Sub(d1, d0);
        delta.Value = D.Value * d;
    end
endmodule

module Lerp(
    input Fixed d0,
    input Fixed delta,    
    output Fixed out
    );
    Fixed D;
    always_comb begin
        D = Fixed_RSft(delta, 2);
        out = Fixed_Add(d0, D);
    end
endmodule

module Fixed_CosSin(
    input [8:0] d,
	output Fixed cos,
    output Fixed sin
    );

    logic [31:0] SinLUT[90];
    logic [31:0] CosLUT[90];

	initial begin	
        $readmemh("E:/MyWork/HomebrewGPU/Prototype/HomebrewGPU/data/QuickCos.txt", CosLUT);		
		$readmemh("E:/MyWork/HomebrewGPU/Prototype/HomebrewGPU/data/QuickSin.txt", SinLUT);		
	end

    Fixed C0, C1, D0, S0, S1, D1;
    logic [8:0] R, D, DD;

    always_comb begin
        D = d >> 2;
        R = d - (D << 2);
        DD = D + 1;
        if (DD >= 90) begin
            DD = DD - 90;
        end

        C0.Value <= CosLUT[D];        
        C1.Value <= CosLUT[DD];                

        S0.Value <= SinLUT[D];        
        S1.Value <= SinLUT[DD];            

        //cos.Value = CosLUT[D];        
        //sin.Value = SinLUT[D];        
    end        

    Detla DELTA0(C0, C1, R, D0);
    Lerp LERP0(C0, D0, cos);

    Detla DELTA1(S0, S1, R, D1);
    Lerp LERP1(S0, D1, sin);
endmodule

