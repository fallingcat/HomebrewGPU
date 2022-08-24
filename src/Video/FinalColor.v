`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:04:38 03/30/2021 
// Design Name: 
// Module Name:    FinalColor 
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
module FinalColor(
	output [2:0] r, output [2:0] g,	output [1:0] b,
	input [0:0] b_shadow, input [0:0] b_link, input [0:0] b_trans,
	input [0:0] blank,
	input [7:0] link_color, input [7:0] tile_color
	);
	
	if (blank) begin
		r = 0;
		g = 0;
		b = 0;
	end
	else if ((b_shadow || b_link) && !b_trans) begin
		if (b_shadow) begin
			r = ColorGetR(tile_color) >> 1;
			g = ColorGetG(tile_color) >> 1;
			b = ColorGetB(tile_color) >> 1;
		end
		else begin
			r = ColorGetR(link_color);
			g = ColorGetG(link_color);
			b = ColorGetB(link_color);
		end
	end
	else begin
		r = ColorGetR(tile_color);
		g = ColorGetG(tile_color);
		b = ColorGetB(tile_color);
	end		
endmodule

