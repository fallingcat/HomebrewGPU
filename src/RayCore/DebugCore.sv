//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/14 17:55:28
// Design Name: 
// Module Name: RayCore
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
`include "../Math/Fixed.sv"
`include "../Math/Fixed3.sv"
`include "../Math/FixedNorm.sv"
`include "../Math/FixedNorm3.sv"

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module DebugCore(    
    input clk,
	input resetn,        	

    // controls... 
    input logic add_input,

    // inputs...    
    input SurfaceInputData input_data,        
    input RenderState rs,        
    input logic reset_pixel_counter,    
    input logic [15:0] frame_counter,
    // outputs...  
    output logic [31:0] pixel_counter,
    output logic fifo_full,        
    output logic valid,
    output ShadeOutputData shade_out
    );       
    
    DebugCoreState State, NextState = DCS_Init;       

    always_ff @( posedge clk, negedge resetn) begin		                       
        if (!resetn) begin
            pixel_counter <= 0;
            NextState <= DCS_Init;            
		end
		else begin                        
            State = NextState;            

            if (reset_pixel_counter) begin
                pixel_counter = 0;
            end
            else if (valid) begin
                pixel_counter = pixel_counter + 1;
            end

            case (State)
                DCS_Init: begin 
                    fifo_full = 0;
                    valid = 0;
                    if (add_input) begin
                        fifo_full = 1;                   
                        NextState <= DCS_Render;
                    end
                end

                DCS_Render: begin  
                    fifo_full = 1;                   
                    shade_out.x = input_data.x;                   
                    shade_out.y = input_data.y;
                    if (frame_counter[6]) begin
                        if (input_data.x[5] ^ input_data.y[5]) begin
                            shade_out.Color = _RGB8(255, 0, 0);
                        end
                        else begin
                            shade_out.Color = _RGB8(0, 255, 0);
                        end
                    end
                    else begin
                        if (input_data.x[5] ^ input_data.y[5]) begin
                            shade_out.Color = _RGB8(255, 255, 0);
                        end
                        else begin
                            shade_out.Color = _RGB8(0, 255, 255);
                        end
                    end
                    NextState <= DCS_Done;
                end

                DCS_Done: begin     
                    valid = 1;
                    NextState <= DCS_Init;
                end                       

                default: begin
                    NextState <= DCS_Init;                
                end                        
            endcase                            
		end
	end	

    _PixelCounter PIXEL_COUNTER(
        .clk(clk),
        .resetn(resetn),
        .reset_pixel_counter(reset_pixel_counter),
        .valid(valid),
        .pixel_counter(pixel_counter)        
    );
    
endmodule