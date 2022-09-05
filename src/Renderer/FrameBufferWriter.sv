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

module FrameBufferWriter (
	input clk,	
    input resetn,
    input strobe[`RAY_CORE_SIZE],
    input flip,	    
    input ShadeOutputData data[`RAY_CORE_SIZE],
    output MemoryWriteRequest mem_request    
    );        
    logic [`MC_CACHE_SET_SIZE_WIDTH-1:0] CacheSetIndex;
    logic [`MC_CACHE_BLOCK_SIZE_WIDTH-1:0] CacheBlockIndex;
    logic [31:0] Cache[`MC_CACHE_SET_SIZE][`MC_CACHE_BLOCK_SIZE];
    logic [`MC_CACHE_BLOCK_SIZE-1:0] CacheBlockDirty[`MC_CACHE_SET_SIZE]; 
    CacheWriteElement CacheWriteFIFO[`MC_CACHE_WRITE_FIFO_SIZE];
    CacheWriteElement CurrentCacheWriteElement;    
    logic [`MC_CACHE_WRITE_FIFO_SIZE_WIDTH-1:0] CacheWriteFIFOTop = 0, CacheWriteFIFOBottom = 0;    
    logic [ADDR_WIDTH-1:0] Offset;
    logic LastStrobe = 0;
    
    initial begin
        for (int i = 0; i < `MC_CACHE_SET_SIZE; i = i + 1) begin
            CacheBlockDirty[i] <= {`MC_CACHE_BLOCK_SIZE{1'b0}};
        end        
    end

    always_ff @(posedge clk, negedge resetn) begin			
        if (!resetn) begin
            LastStrobe = 0;
            mem_request.WriteStrobe <= 0;
            CacheWriteFIFOTop = 0;
            CacheWriteFIFOBottom = 0;
            for (int i = 0; i < `MC_CACHE_SET_SIZE; i = i + 1) begin
                CacheBlockDirty[i] <= {`MC_CACHE_BLOCK_SIZE{1'b0}};
            end                        
        end
        else begin            
            for (int i = 0; i < `RAY_CORE_SIZE; i = i + 1) begin
                if (strobe[i]) begin                
                    if (data[i].x < `FRAMEBUFFER_WIDTH && data[i].y < `FRAMEBUFFER_HEIGHT) begin
                        Offset = (data[i].y * `FRAMEBUFFER_WIDTH) + data[i].x;        
                        CacheSetIndex = Offset[(`MC_CACHE_BLOCK_SIZE_WIDTH + `MC_CACHE_SET_SIZE_WIDTH - 1):`MC_CACHE_BLOCK_SIZE_WIDTH];                    
                        CacheBlockIndex = Offset[`MC_CACHE_BLOCK_SIZE_WIDTH-1:0];                             

                        Cache[CacheSetIndex][CacheBlockIndex][31:24] = data[i].Color.Channel[0];
                        Cache[CacheSetIndex][CacheBlockIndex][23:16] = data[i].Color.Channel[1];
                        Cache[CacheSetIndex][CacheBlockIndex][15:08] = data[i].Color.Channel[2];
                        Cache[CacheSetIndex][CacheBlockIndex][07:00] = 8'd255;                     
                        CacheBlockDirty[CacheSetIndex][CacheBlockIndex] = 1'b1;

                        // if the block is full, push it to FIFO and the bolcks in FIFO will be written to memory later
                        if (CacheBlockDirty[CacheSetIndex] == {`MC_CACHE_BLOCK_SIZE{1'b1}}) begin
                            CacheWriteFIFO[CacheWriteFIFOBottom].CacheSet = CacheSetIndex;
                            CacheWriteFIFO[CacheWriteFIFOBottom].x = data[i].x;
                            CacheWriteFIFO[CacheWriteFIFOBottom].y = data[i].y;
                            CacheWriteFIFOBottom = CacheWriteFIFOBottom + 1;
                            CacheBlockDirty[CacheSetIndex] = {`MC_CACHE_BLOCK_SIZE{1'b0}};
                        end

                        // Debug code ----------------------------------------------------------
                        /*
                        if (CacheBlockIndex == {`MC_CACHE_BLOCK_SIZE_WIDTH{1'b1}}) begin
                            Cache[CacheSetIndex][CacheBlockIndex][31:24] = 0;
                            Cache[CacheSetIndex][CacheBlockIndex][23:16] = 0;
                            Cache[CacheSetIndex][CacheBlockIndex][15:08] = 0;
                        end                    
                        */
                        // Debug code ----------------------------------------------------------                    
                    end
                end
            end           

            // If FIFO is not empty, pop one and write it to memory
            if (!LastStrobe && CacheWriteFIFOTop != CacheWriteFIFOBottom) begin
                CurrentCacheWriteElement = CacheWriteFIFO[CacheWriteFIFOTop];
                CacheWriteFIFOTop = CacheWriteFIFOTop + 1;
                
                mem_request.WriteAddress = (CurrentCacheWriteElement.y * `FRAMEBUFFER_WIDTH) + CurrentCacheWriteElement.x;
                mem_request.WriteAddress[`MC_CACHE_BLOCK_SIZE_WIDTH-1:0] = 0;        
                mem_request.WriteAddress = (mem_request.WriteAddress * 2) + (APP_DATA_WIDTH / DQ_WIDTH);
                mem_request.WriteAddress = (flip) ? mem_request.WriteAddress + `FRAMEBUFFER_ADDR_0 : mem_request.WriteAddress + `FRAMEBUFFER_ADDR_1;
                
                mem_request.WriteData = Cache[CurrentCacheWriteElement.CacheSet];
                mem_request.BlockCount = (32 * `MC_CACHE_BLOCK_SIZE / APP_DATA_WIDTH);
                mem_request.WriteStrobe <= 1;
            end                                           
            else begin
                mem_request.WriteStrobe <= 0;
            end         
            LastStrobe = mem_request.WriteStrobe;           
        end                               
    end         
endmodule
