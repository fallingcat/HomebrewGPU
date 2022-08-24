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
`include "../Math/Fixed.sv"
`include "../Math/Fixed3.sv"
`include "../Math/FixedNorm.sv"
`include "../Math/FixedNorm3.sv"

module FrameBufferCacheTest (
	input clk,	
    input clk_50,
    input clk_mem,	    
    input `SCREEN_COORD x,
    input `SCREEN_COORD y,
    input RGB8 color,
    output [15:0] LED
    );

    FrameBufferCacheData FBData;
    
    // MIC var 
    parameter DQ_WIDTH          = 16;
    parameter ECC_TEST          = "OFF";
    parameter ADDR_WIDTH        = 27;
    parameter nCK_PER_CLK       = 4;
 
    localparam DATA_WIDTH       = 16;
    localparam PAYLOAD_WIDTH    = (ECC_TEST == "OFF") ? DATA_WIDTH : DQ_WIDTH;
    localparam APP_DATA_WIDTH   = 2 * nCK_PER_CLK * PAYLOAD_WIDTH;
    localparam APP_MASK_WIDTH   = APP_DATA_WIDTH / 8;

    logic StartToWriteOut = 0;
    logic `SCREEN_COORD WritePos;
    FrameBufferCacheState State;

    logic app_en, app_wdf_wren, app_wdf_end, init_calib_complete;
    logic [2:0] app_cmd = 0;
    logic [ADDR_WIDTH-1:0] app_addr = 27'h000_0008;
    logic [APP_DATA_WIDTH-1:0] app_wdf_data = 0;
    logic [APP_DATA_WIDTH-1:0] app_rd_data;
    logic [APP_MASK_WIDTH-1:0] app_wdf_mask = 0;
    logic app_rdy, app_rd_data_end, app_rd_data_valid, app_wdf_rdy;    
    
    assign LED[0] = app_en;
    assign LED[1] = app_rdy;
    assign LED[2] = app_wdf_rdy;
    
    initial begin
        FBData.WriteBank = 0;        
    end

    always_ff @( posedge clk_50 ) begin
        case (State)
            (State_Wait): begin
                if (y < `FRAMEBUFFER_HEIGHT) begin
                    if (x >= `FRAMEBUFFER_WIDTH - 1 && StartToWriteOut) begin
                        // The scanline data is full, ready to write out                        
                        FBData.WriteBank = ~FBData.WriteBank;

                        app_addr = `FRAMEBUFFER_ADDR0 + (y * (`FRAMEBUFFER_WIDTH * 2));
                        FBData.CurrentWritePos = 0;
                        app_en = 1;
                        State = State_Write;
                        $display($time, " Reay to write <%d> (x=%d, y=%d)\n", ~FBData.WriteBank, x, y);	   
                    end                    
                end                
                else begin
                    // disable MIG
                    app_en = 0;   
                    FBData.CurrentWritePos = 0;                 
                end
            end

            (State_Write): begin
                if (FBData.CurrentWritePos >= `FRAMEBUFFER_WIDTH) begin
                    // disable MIG
                    app_en = 0;
                    State = State_Write_Done;

                    $display($time, " Write Done!\n");
                end
                else begin
                    if (1) begin
                        // strt to write out to DDR
                        app_addr = app_addr + 27'h8;                    
                        app_en = 1;
                        app_cmd = 3'b0;
                        app_wdf_data = {{FBData.Scanline[~FBData.WriteBank][WritePos]}, {FBData.Scanline[~FBData.WriteBank][WritePos+1]}, {FBData.Scanline[~FBData.WriteBank][WritePos+2]}, {FBData.Scanline[~FBData.WriteBank][WritePos+3]}};
                        
                        app_wdf_wren = 1;
                        app_wdf_end = 1;                

                        $display($time, " Write 4 colors <%d>\n", ~FBData.WriteBank);

                        FBData.CurrentWritePos = FBData.CurrentWritePos + 4;                                                    
                    end
                end                
            end

            (State_Write_Done): begin
                State = State_Wait;
            end

            default: begin
                State = State_Wait;
            end
        endcase
    end

    always_ff @( posedge clk ) begin
        FBData.Scanline[FBData.WriteBank][x][31:24] = color.Channel[0];
        FBData.Scanline[FBData.WriteBank][x][23:16] = color.Channel[1];
        FBData.Scanline[FBData.WriteBank][x][15:08] = color.Channel[2];
        FBData.Scanline[FBData.WriteBank][x][07:00] = 8'd255;      
        if (x == (`FRAMEBUFFER_WIDTH - 1)) begin
            StartToWriteOut = 1;
        end
        else begin
            StartToWriteOut = 0;
        end
        $display($time, " Write to scanline <%d>\n", FBData.WriteBank);	   
    end
    
endmodule
