module HexDisplay_7_Seg(
    input clk,
    input [15:0] number,
    output [7:0] seg,
    output reg [7:0] digit
    );
	 
	reg [3:0] digit_data;
	reg [2:0] digit_posn;
	reg [23:0] prescaler;
		 
	wire [3:0] D1, D2, D3, D4, D5;

	assign D1 = (number >> 12) & 4'b1111;
    assign D2 = (number >> 8) & 4'b1111;
	assign D3 = (number >> 4) & 4'b1111;
    assign D4 = (number & 4'b1111);
	
	always @(posedge clk) begin
		prescaler <= prescaler + 24'd1;		
		if (prescaler == 24'd50000) begin
			prescaler <= 0;
			digit_posn <= digit_posn + 2'd1;
			if (digit_posn == 0) begin
				digit_data <= D4;
				digit <= 8'b11111110;
			end
			if (digit_posn == 1) begin
				digit_data <= D3;
				digit <= 8'b11111101;
			end
			if (digit_posn == 2) begin
				digit_data <= D2;
				digit <= 8'b11111011;				
			end	
			if (digit_posn == 3) begin
				digit_data <= D1;
				digit <= 8'b11110111;				
				digit_posn <= 0;
			end				
		end
	end

	Decoder_7_Seg Decoder(
		.clk(clk), 
		.d(digit_data),
		.seg(seg)		
		);	

endmodule
