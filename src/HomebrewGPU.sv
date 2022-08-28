`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/23 16:07:02
// Design Name: 
// Module Name: HomebrewGPU
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
`include "Math/Fixed.sv"
`include "Math/Fixed3.sv"

module HomebrewGPU(
    input clk,	
    input resetn,

    // controls...     	
    input clk_vga,
    input clk_mc,
	input clk_mem,        
    input hsync,
	input vsync,	
    input blank,

    // inputs...
    input up,
    input down,
    input left,
    input right,
    input `SCREEN_COORD x,
    input `SCREEN_COORD y,

    // outputs...  
    output RGB8 color,
    output [15:0] kcycle_per_frame,    

    // SD signals
    input sd_clk,
    output logic SD_SCK,
    inout SD_CMD,
    input logic [3:0] SD_DAT,

    // UART tx signal, connected to host-PC's UART-RXD, baud=115200
    output logic UART_RXD_OUT,

    // LED signals
    output [15:0] LED,
    
	// DDR2 chip signals
    inout [15:0]ddr2_dq,
    inout [1:0] ddr2_dqs_n,
    inout [1:0] ddr2_dqs_p,
    output [12:0] ddr2_addr,
    output [2:0] ddr2_ba,
    output ddr2_ras_n,
    output ddr2_cas_n,
    output ddr2_we_n,
    output [0:0] ddr2_ck_p,
    output [0:0] ddr2_ck_n,
    output [0:0] ddr2_cke,
    output [0:0] ddr2_cs_n,
    output [1:0] ddr2_dm,
    output [0:0] ddr2_odt
    );

    logic FrameFlip;    
    MemoryReadRequest FB_MemRRequest;
    MemoryWriteRequest BVH_MemWRequest, FB_MemWRequest, MC_Write_Request;	
    MemoryReadData ReadData;    
    logic [15:0] KCyclePerFrame;    
    
    
    assign kcycle_per_frame = KCyclePerFrame;
    
    always_ff @(posedge clk) begin	
        MC_Write_Request = FB_MemWRequest;
    end
    /*always_ff @(posedge clk, negedge resetn) begin	    
        if (!resetn) begin
            MemW_QueueTop <= 0;
            MemW_QueueBottom <= 0;
        end
        else begin      
            //if (BVH_MemWRequest.WriteStrobe) begin
            //    MemW_Queue[MemW_QueueBottom] = BVH_MemWRequest;
            //    MemW_QueueBottom = MemW_QueueBottom + 1;
            //end
            //if (FB_MemWRequest.WriteStrobe) begin
                MemW_Queue[MemW_QueueBottom] = FB_MemWRequest;
                MemW_QueueBottom = MemW_QueueBottom + 1;
            //end

             if (MemW_QueueTop != MemW_QueueBottom) begin
                MC_Write_Request = MemW_Queue[MemW_QueueTop];
                MemW_QueueTop = MemW_QueueTop + 1;
            end            
        end       
    end
    */

    Renderer RENDERER(
		.clk(clk),		
        .resetn(resetn),
		.vsync(vsync),	
        .flip(FrameFlip),

        .up(up),
        .down(down),
        .left(left),
        .right(right),

        .sd_clk(sd_clk),
        .SD_SCK(SD_SCK),
        .SD_CMD(SD_CMD),
        .SD_DAT(SD_DAT),

        .UART_RXD_OUT(UART_RXD_OUT),

        .kcycle_per_frame(KCyclePerFrame),

        .fb_mem_w_req(FB_MemWRequest),
	    .bvh_mem_w_req(BVH_MemWRequest)        
	);    
    
    FrameBufferReader FBR(
        .clk(clk_vga),	    
        .resetn(resetn),		
        .blank(blank),	
        .flip(FrameFlip),	
        .read_data(ReadData),
        .x(x),
		.y(y),
    	.out_color(color),
        .mem_request(FB_MemRRequest)        
    );

    /*
    MemoryRequestFIFO MRFIFO(
		.clk(clk),
		.resetn(restn),   
		.mem_w_req_0(BVH_MemWRequest),
		.mem_w_req_1(FB_MemWRequest),		
		.out_mem_w_req(MC_Write_Request)
	);	
    */

    MemoryController MC (                
        .clk(clk_mc),
        .clk_mem(clk_mem),
        .resetn(resetn),
        .request_r(FB_MemRRequest),             
        .request_w(MC_Write_Request),             
        .read_data(ReadData),                        
        .LED(LED),
        // DDR2 chip signals
        .ddr2_dq(ddr2_dq),
        .ddr2_dqs_n(ddr2_dqs_n),
        .ddr2_dqs_p(ddr2_dqs_p),
        .ddr2_addr(ddr2_addr),
        .ddr2_ba(ddr2_ba),
        .ddr2_ras_n(ddr2_ras_n),
        .ddr2_cas_n(ddr2_cas_n),
        .ddr2_we_n(ddr2_we_n),
        .ddr2_ck_p(ddr2_ck_p),
        .ddr2_ck_n(ddr2_ck_n),
        .ddr2_cke(ddr2_cke),
        .ddr2_cs_n(ddr2_cs_n),
        .ddr2_dm(ddr2_dm),
        .ddr2_odt(ddr2_odt)
    );
    
endmodule
