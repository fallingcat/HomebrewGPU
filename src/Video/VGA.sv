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
module VGA_320x240_25M_Clk(
    input clk,
    output hs,
    output vs,
    output [9:0] current_x,
    output [9:0] current_y,
    output blank
    );

	logic [9:0] RealX, RealY;
	 	 
	// Horizontal 640 + fp 16 + HS 96 + bp 48 = 800 pixel clocks
	// Vertical, 480 + fp 11 lines + VS 2 lines + bp 31 lines = 524 lines
	assign blank = ((RealX < 160) | (RealX > 800) | (RealY > 479));
	assign hs = ~ ((RealX > 16) & (RealX < 112));
	assign vs = ~ ((RealY > 491) & (RealY < 494));
	assign current_x = ((RealX < 160) ? 0 : (RealX - 160) >> 1);	
	assign current_y = RealY >> 1;

	always_ff @(posedge clk) begin	
	
        if (RealX == 800) begin
            RealX <= 0;
            RealY <= RealY + 1;
        end						
        else begin
            RealX <= RealX + 1;
        end
        
        if (RealY == 524) begin
            RealY <= 0; 		
        end
	end	
endmodule

module VGA_640x480_25M_Clk(
    input clk,
    output hs,
    output vs,
    output [9:0] current_x,
    output [9:0] current_y,
    output blank
    );

	logic [9:0] RealX, RealY;
	 	 
	// Horizontal 640 + fp 16 + HS 96 + bp 48 = 800 pixel clocks
	// Vertical, 480 + fp 11 lines + VS 2 lines + bp 31 lines = 524 lines
	assign blank = ((RealX < 160) | (RealX > 800) | (RealY > 479));
	assign hs = ~ ((RealX > 16) & (RealX < 112));
	assign vs = ~ ((RealY > 491) & (RealY < 494));
	assign current_x = ((RealX < 160) ? 0 : (RealX - 160));	
	assign current_y = RealY;

	always_ff @(posedge clk) begin	
	
        if (RealX == 800) begin
            RealX <= 0;
            RealY <= RealY + 1;
        end						
        else begin
            RealX <= RealX + 1;
        end
        
        if (RealY == 524) begin
            RealY <= 0; 		
        end
	end	
endmodule

module VGA_640x480_12M_Clk(
    input clk,
    output hs,
    output vs,
    output [9:0] current_x,
    output [9:0] current_y,
    output blank
    );

	logic [9:0] RealX, RealY;
	 	 
	// Horizontal 640 + fp 16 + HS 96 + bp 48 = 800 pixel clocks
	// Vertical, 480 + fp 11 lines + VS 2 lines + bp 31 lines = 524 lines
	assign blank = ((RealX < 160) | (RealX > 800) | (RealY > 479));
	assign hs = ~ ((RealX > 16) & (RealX < 112));
	assign vs = ~ ((RealY > 491) & (RealY < 494));
	assign current_x = ((RealX < 160) ? 0 : (RealX - 160));	
	assign current_y = RealY;

	always_ff @(posedge clk) begin	
	
        if (RealX == 800) begin
            RealX <= 0;
            RealY <= RealY + 1;
        end						
        else begin
            RealX <= RealX + 2;
        end
        
        if (RealY == 524) begin
            RealY <= 0; 		
        end
	end	
endmodule

module VGA_320x240_100M_Clk(
    input clk,
    output hs,
    output vs,
    output [9:0] current_x,
    output [9:0] current_y,
    output blank
    );

	logic [1:0] Counter;
	logic [9:0] RealX, RealY;
	 	 
	// Horizontal 640 + fp 16 + HS 96 + bp 48 = 800 pixel clocks
	// Vertical, 480 + fp 11 lines + VS 2 lines + bp 31 lines = 524 lines
	assign blank = ((RealX < 160) | (RealX > 800) | (RealY > 479));
	assign hs = ~ ((RealX > 16) & (RealX < 112));
	assign vs = ~ ((RealY > 491) & (RealY < 494));
	assign current_x = ((RealX < 160) ? 0 : (RealX - 160) >> 1);	
	assign current_y = RealY >> 1;	

	always_ff @(posedge clk) begin	
	
		Counter <= Counter + 1;
		if (Counter == 0) begin
			if (RealX == 800) begin
				RealX <= 0;
				RealY <= RealY + 1;
			end						
			else begin
				RealX <= RealX + 1;
			end
			
			if (RealY == 524) begin
				RealY <= 0; 		
			end
		end
	end
	
endmodule

module VGA_640x480_100M_Clk(
    input clk,
    output hs,
    output vs,
    output [9:0] current_x,
    output [9:0] current_y,
    output blank
    );

	logic [1:0] Counter;
	logic [9:0] RealX, RealY;
	 	 
	// Horizontal 640 + fp 16 + HS 96 + bp 48 = 800 pixel clocks
	// Vertical, 480 + fp 11 lines + VS 2 lines + bp 31 lines = 524 lines
	assign blank = ((RealX < 160) | (RealX > 800) | (RealY > 479));
	assign hs = ~ ((RealX > 16) & (RealX < 112));
	assign vs = ~ ((RealY > 491) & (RealY < 494));
	assign current_x = ((RealX < 160) ? 0 : (RealX - 160));	
	assign current_y = RealY;	

	always_ff @(posedge clk) begin	
	
		Counter <= Counter + 1;
		if (Counter == 0) begin
			if (RealX == 800) begin
				RealX <= 0;
				RealY <= RealY + 1;
			end						
			else begin
				RealX <= RealX + 1;
			end
			
			if (RealY == 524) begin
				RealY <= 0; 		
			end
		end
	end
	
endmodule

