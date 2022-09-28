module HexDisplay_7_Seg(
    input clk,
    input [15:0] number_0,
	input [15:0] number_1,
    output [7:0] seg,
    output reg [7:0] digit
    );
	 
	reg [3:0] digit_data;
	reg [2:0] digit_posn;
	reg [23:0] prescaler;
		 
	wire [3:0] D1, D2, D3, D4, D5, D6, D7, D8;

	assign D1 = (number_0 >> 12) & 4'b1111;
    assign D2 = (number_0 >> 8) & 4'b1111;
	assign D3 = (number_0 >> 4) & 4'b1111;
    assign D4 = (number_0 & 4'b1111);

	assign D5 = (number_1 >> 12) & 4'b1111;
    assign D6 = (number_1 >> 8) & 4'b1111;
	assign D7 = (number_1 >> 4) & 4'b1111;
    assign D8 = (number_1 & 4'b1111);
	
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
			end			

			if (digit_posn == 4) begin
				digit_data <= D8;
				digit <= 8'b11101111;								
			end				
			if (digit_posn == 5) begin
				digit_data <= D7;
				digit <= 8'b11011111;								
			end				
			if (digit_posn == 6) begin
				digit_data <= D6;
				digit <= 8'b10111111;								
			end				
			if (digit_posn == 7) begin
				digit_data <= D5;
				digit <= 8'b01111111;				
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
