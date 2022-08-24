`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:10:44 03/30/2021 
// Design Name: 
// Module Name:    GetVGASignals 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module GetVGASignals(
    input clk,
    output hs,
    output vs,
    output [9:0] current_x,
    output reg [9:0] current_y,
    output blank
    );

	reg [9:0] RealX;
	 
	// Horizontal 640 + fp 16 + HS 96 + bp 48 = 800 pixel clocks
	// Vertical, 480 + fp 11 lines + VS 2 lines + bp 31 lines = 524 lines
	assign blank = ((RealX < 160) | (RealX > 800) | (current_y > 479));
	assign hs = ~ ((RealX > 16) & (RealX < 112));
	assign vs = ~ ((current_y > 491) & (current_y < 494));
	assign current_x = ((RealX < 160)?0:(RealX - 160));

	always @(posedge clk) begin
		if (RealX == 800) begin
			RealX <= 0;
			current_y <= current_y + 1;
		end
		else begin
			RealX <= RealX + 2;
		end
		
		if (current_y == 524) begin
			current_y <= 0; 
		end
	end

endmodule
