`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/23 15:44:53
// Design Name: 
// Module Name: Renderer
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
`include "../Types.sv"
`include "../Math/Fixed.sv"
`include "../Math/Fixed3.sv"
`include "../Math/FixedNorm.sv"
`include "../Math/FixedNorm3.sv"

module BuildMemoryReadRequest (
    input clk,	    
    input resetn,
    input `SCREEN_COORD x,
    input `SCREEN_COORD y,
    input [`MC_CACHE_BLOCK_SIZE_WIDTH-1:0] block_index,         
    input blank,
    input flip,
    output MemoryReadRequest mem_request,
    output logic [ADDR_WIDTH-1:0] read_address            
    );
    logic `SCREEN_COORD FBX, FBY;

    always_ff @(posedge clk, negedge resetn) begin			    
        if (!resetn) begin
            mem_request.ReadStrobe <= 0;
        end        
        else begin          
            mem_request.ReadStrobe <= 0;           
            if (!blank) begin
                FBX = x >> 1;
                FBY = y >> 1;                    

                if (x[0] == 0 && block_index == 0) begin                        
                    FBX[`MC_CACHE_BLOCK_SIZE_WIDTH-1:0] = 0;
                    FBX = FBX + `MC_CACHE_BLOCK_SIZE;
                    if (FBX >= `FRAMEBUFFER_WIDTH) begin
                        if (y[0] == 0) begin
                            FBX = 0;
                        end            
                        else begin
                            FBX = 0;
                            FBY = FBY + 1;
                            if (FBY >= `FRAMEBUFFER_HEIGHT) begin
                                FBX = 0;
                                FBY = 0;
                            end            
                        end
                    end
                    mem_request.ReadAddress = (FBY * `FRAMEBUFFER_WIDTH + FBX);       
                    mem_request.ReadAddress = (mem_request.ReadAddress * 2) + (APP_DATA_WIDTH / DQ_WIDTH);
                    mem_request.ReadAddress = (flip) ? mem_request.ReadAddress + `FRAMEBUFFER_ADDR_1 : mem_request.ReadAddress + `FRAMEBUFFER_ADDR_0;
                    mem_request.BlockCount = (32 * `MC_CACHE_BLOCK_SIZE / APP_DATA_WIDTH);                                                            
                    read_address = mem_request.ReadAddress;                 
                    mem_request.ReadStrobe <= 1;   
                end                
            end            
        end          
    end           
endmodule

module FrameBufferReader(
	input clk,	    
    input resetn,
    input vsync,
    input blank,
    input flip,	
    input MemoryReadData read_data,    
    input `SCREEN_COORD x,
    input `SCREEN_COORD y,
    output RGB8 out_color,
    output MemoryReadRequest mem_request
    );    

    // Frame buffer read     
    logic [0:0] CacheSetIndex;    
    logic [ADDR_WIDTH-1:0] CacheReadAddress;            
    logic [31:0] Cache[2][`MC_CACHE_BLOCK_SIZE];            
    logic [`MC_CACHE_BLOCK_SIZE_WIDTH-1:0] CacheBlockIndex;         

    logic [ADDR_WIDTH-1:0] Offset;
    logic `SCREEN_COORD FBX, FBY;
    
    always_comb begin                 
        if (read_data.ReadAddress == CacheReadAddress) begin        
            Cache[~CacheSetIndex] <= read_data.Data;            
        end
    end            

    always_ff @(posedge clk) begin			    
        if (!blank) begin
            FBX = x >> 1;
            FBY = y >> 1;                    

            Offset = (FBY * `FRAMEBUFFER_WIDTH) + FBX;        
            CacheSetIndex = Offset[`MC_CACHE_BLOCK_SIZE_WIDTH];                    
            CacheBlockIndex = Offset[`MC_CACHE_BLOCK_SIZE_WIDTH-1:0];                         
            out_color.Channel[0] = Cache[CacheSetIndex][CacheBlockIndex][31:24];
            out_color.Channel[1] = Cache[CacheSetIndex][CacheBlockIndex][23:16];
            out_color.Channel[2] = Cache[CacheSetIndex][CacheBlockIndex][15:08];               
        end                    
    end            
    BuildMemoryReadRequest BMRR(clk, resetn, x, y, CacheBlockIndex, blank, flip, mem_request, CacheReadAddress);
endmodule
