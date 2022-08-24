`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/22 00:51:02
// Design Name: 
// Module Name: ClockDivider
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


module ClockDivider(
    input clk,
    output logic o_clk
    );
    
    always@(posedge clk) begin
        o_clk <= ~o_clk;
    end    
endmodule

module ClockDividedBy3(
    input clk,
    input clk2,
    output logic o_clk
    );

    logic [1:0] Counter = 0;
    
    always_ff @(posedge clk, negedge clk2) begin
        if (clk) begin
            Counter <= Counter + 1;
            if (Counter >= 3) begin
                Counter <= 0;
            end            
        end
        
        case (Counter)
            0 : begin
               o_clk <= 1; 
            end

            1: begin
                if (!clk2) begin
                    o_clk <= clk2;                     
                end                
            end

            2: begin
                o_clk <= 0; 
            end
        endcase        
    end    
endmodule