`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/14 18:23:25
// Design Name: 
// Module Name: Fixed_Div
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
`include "Fixed.sv"

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module Div_16_V2 #(
    parameter STEP = 16
    ) (
    input clk,    
	input resetn, 
	input strobe,
    input [15:0] a,
    input [7:0] b,
	output logic valid,
	output logic [7:0] q
    );
        
	logic [15:0] A;
    logic [7:0] Q, R, B;    
	logic [6:0] Counter;	
	State State, NextState = State_Ready;   	
		
	initial begin	 		
	end
	task ComputeQ();
        begin
            if (B == 0) begin
				valid <= 1;
				q <= 255;											
				NextState <= State_Ready;						
            end
            else begin
				for (integer i = 0; i < STEP; i = i + 1) begin
					if (Counter >= 1) begin
						Q = Q << 1;
						R = R << 1;
						R = R | (A & (1 << (Counter-1))) >> (Counter-1);
						if (R >= B) begin
							R = R - B;
							Q = Q | 1;
						end	
						Counter = Counter - 1;							

						if (Counter == 0) begin
							q <= Q;						
							valid <= 1;						
							NextState <= State_Ready;																		
						end						
					end
				end
			end	
		end
	endtask	
	
	always @(posedge clk, negedge resetn) begin
		if (!resetn) begin
            valid <= 0;
			NextState <= State_Ready;
        end
		else begin
			State = NextState;

			case (State)			
				default: begin
					valid <= 0;
					NextState <= State_Ready;
				end		

				(State_Ready): begin				
					valid <= 0;
					if (strobe) begin
						A <= a;
						B <= b;									
						Q <= 0;
						R <= 0;       	
						Counter <= 16;							
						NextState <= State_Busy;							
					end
				end

				(State_Busy) : begin				
					ComputeQ();
				end

				(State_Done): begin	
					valid <= 1;			
					NextState <= State_Ready;
				end		
			endcase			
		end              	   	           
	end	 	

endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module RGB8_Div_V2 (
    input clk,    
	input resetn,
	input strobe,
    input [15:0] a[3],
    input [7:0] b,
	output logic valid,
	output RGB8 q
    );
    
    logic Valid[3];
	logic [23:0] OutData[3];

    assign valid = Valid[0] & Valid[1] & Valid[2];
	
	Div_16_V2#(`RGB8_DIV_STEP) DIV0(
		.clk(clk),
		.resetn(resetn),
		.strobe(strobe),
		.a(a[0]),
		.b(b),
		.valid(Valid[0]),
		.q(q.Channel[0])
	);	

    Div_16_V2#(`RGB8_DIV_STEP) DIV1(
		.clk(clk),
		.resetn(resetn),
		.strobe(strobe),
		.a(a[1]),
		.b(b),
		.valid(Valid[1]),
		.q(q.Channel[1])
	);	

	Div_16_V2#(`RGB8_DIV_STEP) DIV2(
		.clk(clk),
		.resetn(resetn),
		.strobe(strobe),
		.a(a[2]),
		.b(b),
		.valid(Valid[2]),
		.q(q.Channel[2])
	);	
endmodule

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module RGB8_Div_V3 (
    input clk,    
	input resetn,
	input strobe,
    input [15:0] a[3],
    input [7:0] b,
	output logic valid,
	output RGB8 q
    );
    
    logic Valid[3];
	logic [23:0] OutData[3];

    assign valid = Valid[0] & Valid[1] & Valid[2];
	assign q.Channel[0] = OutData[0][15:8];		
    assign q.Channel[1] = OutData[1][15:8];		
    assign q.Channel[2] = OutData[2][15:8];	

	Div_16 DIV0(
		.aclk(clk),
		.aresetn(resetn),
		.s_axis_divisor_tvalid(strobe),
		.s_axis_divisor_tdata(b),
		.s_axis_dividend_tvalid(strobe),
		.s_axis_dividend_tdata(a[0]),
		.m_axis_dout_tvalid(Valid[0]),
		.m_axis_dout_tdata(OutData[0])
	);	

    Div_16 DIV1(
		.aclk(clk),
		.aresetn(resetn),
		.s_axis_divisor_tvalid(strobe),
		.s_axis_divisor_tdata(b),
		.s_axis_dividend_tvalid(strobe),
		.s_axis_dividend_tdata(a[1]),
		.m_axis_dout_tvalid(Valid[1]),
		.m_axis_dout_tdata(OutData[1])
	);	

    Div_16 DIV2(
		.aclk(clk),
		.aresetn(resetn),
		.s_axis_divisor_tvalid(strobe),
		.s_axis_divisor_tdata(b),
		.s_axis_dividend_tvalid(strobe),
		.s_axis_dividend_tdata(a[2]),
		.m_axis_dout_tvalid(Valid[2]),
		.m_axis_dout_tdata(OutData[2])
	);	
endmodule
