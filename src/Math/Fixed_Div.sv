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

module Fixed_Div_V3 (
    input clk,    
	input resetn, 
	input strobe,
    input Fixed a,
    input Fixed b,
	output logic valid,
	output Fixed q
    );
    
	logic [79:0] OutData;

	assign q.Value = (b.Value == `FIXED_ZERO) ? (a.Value | `FIXED_INF) : OutData[63:32];		
	//assign q.Value = (b.Value == `FIXED_ZERO) ? `FIXED_ZERO : OutData[63:32];
	//assign q.Value = OutData[63:32];

    initial begin	 		
	end

	Div DIV(
		.aclk(clk),
		.aresetn(resetn),
		.s_axis_divisor_tvalid(strobe),
		.s_axis_divisor_tdata((b.Value == `FIXED_ZERO) ? `FIXED_WIDTH'b1 : b.Value),
		.s_axis_dividend_tvalid(strobe),
		.s_axis_dividend_tdata({{2{1'b0}}, a.Value, {`FIXED_FRAC_WIDTH{1'b0}}}),
		.m_axis_dout_tvalid(valid),
		.m_axis_dout_tdata(OutData)
	);	
endmodule

module Fixed_Div_V2 #(
    parameter STEP = 8
    ) (
    input clk,    
	input resetn, 
	input strobe,
    input Fixed a,
    input Fixed b,
	output logic valid,
	output Fixed q
    );
    
    `define RES_WIDTH 			`FIXED_WIDTH + `FIXED_FRAC_WIDTH
    
	logic [`RES_WIDTH-1:0] RA;
    Fixed QQ, R;
    logic S1, S2;
    Fixed RB;
	Fixed FQ;
	logic [6:0] Counter;	
	State State, NextState = State_Ready;   	
		
	initial begin	 		
	end
	
	task ComputeQ();
        begin
            if (RB.Value == 0) begin
				valid <= 1;
				//q.Value <= (a.Value | `FIXED_INF);												
				q.Value <= `FIXED_INF;												
				NextState <= State_Ready;						
            end
            else begin				
				for (integer i = 0; i < STEP; i = i + 1) begin
					if (Counter >= 1) begin						
						QQ.Value = QQ.Value << 1;
						R.Value = R.Value << 1;
						R.Value = R.Value | (RA & (1 << (Counter-1))) >> (Counter-1);
						if (R.Value >= RB.Value) begin
							R.Value = R.Value - RB.Value;
							QQ.Value = QQ.Value | 1;
						end		
						Counter = Counter - 1;
						if (Counter == 0) begin
							q.Value = (S1 ^ S2) ? (~QQ.Value + 1) : QQ.Value;						
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
						S1 = a.Value[`FIXED_WIDTH-1];
						S2 = b.Value[`FIXED_WIDTH-1];
						RA = (S1) ? (~a.Value + 1) : a.Value;
						RA = RA << `FIXED_FRAC_WIDTH;
						RB.Value = (S2) ? (~b.Value + 1) : b.Value;									
						QQ.Value <= 0;
						R.Value <= 0;       								
						Counter <= `RES_WIDTH;
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