module Decoder_7_Seg(
	input clk,
	input [3:0] d,
	output reg [7:0] seg
	);

	always @(posedge clk) begin
		case(d)
			4'd0: seg <= 8'b00000011;
			4'd1: seg <= 8'b10011111; 
			4'd2: seg <= 8'b00100101;
			4'd3: seg <= 8'b00001101;
			4'd4: seg <= 8'b10011001;
			4'd5: seg <= 8'b01001001;
			4'd6: seg <= 8'b01000001;
			4'd7: seg <= 8'b00011111;
			4'd8: seg <= 8'b00000001;
			4'd9: seg <= 8'b00001001;
			4'd10: seg <= 8'b00010001;
			4'd11: seg <= 8'b11000001;
			4'd12: seg <= 8'b01100011;
			4'd13: seg <= 8'b10000101;
			4'd14: seg <= 8'b01100001;
			4'd15: seg <= 8'b01110001;
			default: seg <= 8'b11111111;
		endcase
	end

endmodule
