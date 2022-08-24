`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/28 10:51:23
// Design Name: 
// Module Name: MIGTest
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


module MIGTest(
    input CLK100MHZ,
    input CPU_RESETN,    
	input BTNU,
    input BTND,
    input BTNL,
    input BTNR,
    output VGA_HS,    
    output VGA_VS,
    output [3:0] VGA_R,
    output [3:0] VGA_G,
    output [3:0] VGA_B,
    output [15:0] LED,

    // DDR2 chip signals
    inout [15:0]            ddr2_dq,
    inout [1:0]             ddr2_dqs_n,
    inout [1:0]             ddr2_dqs_p,
    output [12:0]           ddr2_addr,
    output [2:0]            ddr2_ba,
    output                  ddr2_ras_n,
    output                  ddr2_cas_n,
    output                  ddr2_we_n,
    output [0:0]            ddr2_ck_p,
    output [0:0]            ddr2_ck_n,
    output [0:0]            ddr2_cke,
    output [0:0]            ddr2_cs_n,
    output [1:0]            ddr2_dm,
    output [0:0]            ddr2_odt	
    );
    parameter DQ_WIDTH          = 16;
    parameter ECC_TEST          = "OFF";
    parameter ADDR_WIDTH        = 27;
    parameter nCK_PER_CLK       = 4;
 
    localparam DATA_WIDTH       = 16;
    localparam PAYLOAD_WIDTH    = (ECC_TEST == "OFF") ? DATA_WIDTH : DQ_WIDTH;
    localparam APP_DATA_WIDTH   = 2 * nCK_PER_CLK * PAYLOAD_WIDTH;
    localparam APP_MASK_WIDTH   = APP_DATA_WIDTH / 8;
     
    // Wire declarations
    logic init_calib_complete;
    logic app_en, app_wdf_wren, app_wdf_end, app_ref_req, app_ref_ack;
    logic [2:0] app_cmd;
    logic [ADDR_WIDTH-1:0] app_addr;
    logic [APP_DATA_WIDTH-1:0] app_wdf_data;
    logic [APP_DATA_WIDTH-1:0] app_rd_data;
    logic [APP_MASK_WIDTH-1:0] app_wdf_mask;
    logic app_rdy, app_rd_data_end, app_rd_data_valid, app_wdf_rdy;
    logic sys_rst;
    logic [4:0] State;
    logic Reset = 1;

    logic [15:0] counter = 0;    
    logic [15:0] DataCounter = 0;
    logic DataCorrection = 1;
    parameter cnt_init = 16'h1; // minimum: 1
    logic [26:0] addr0 = 27'h000_0008;    
    logic [127:0] data[6];
    logic CorrectData[6];
    logic [1:0] stop_w = 2'b00;
    logic read_valid = 1'b0;
    logic [127:0] read_data;    

    logic CLK200MHZ, CLK50MHZ, CLK25MHZ;
	logic Blank, PLLLocked;	
	logic [9:0] vx, vy;	
    reg  [3:0] R, G, B;
    logic MIG_Clk;

    localparam DATA_COUNT       = 16'd4;

    localparam STATE_INIT       = 0;
    localparam STATE_WRITE      = 1;
    localparam STATE_WRITE_WAIT = 2;
    localparam STATE_WAIT       = 3;
    localparam STATE_READ       = 4;
    localparam STATE_READ_WAIT  = 5;



    ClockWizard ClkWiz (
        .clk_in1    (CLK100MHZ),
        .clk_200    (CLK200MHZ),
		.clk_50     (CLK50MHZ),
		.clk_25     (CLK25MHZ)
    );

    wire clk_ref_i; // temp
	assign clk_ref_i = CLK100MHZ;
    
	VGA_320x240_25M_Clk VGA_SYNC(
	   .clk         (CLK25MHZ), 
	   .hs          (VGA_HS), 
	   .vs          (VGA_VS), 
	   .current_x   (vx), 
	   .current_y   (vy), 
	   .blank       (Blank)
	);	

	assign VGA_R = Blank ? 0 : R;
	assign VGA_G = Blank ? 0 : G;
	assign VGA_B = Blank ? 0 : B;

    assign LED[15] = CorrectData[5];
    assign LED[14] = CorrectData[4];
    assign LED[13] = CorrectData[3];
    assign LED[12] = CorrectData[2];
    assign LED[11] = CorrectData[1];     
    assign LED[10] = CorrectData[0];     
    assign LED[9] = 0;     
    assign LED[8] = 0;     
    assign LED[7] = 0;     
    assign LED[6] = 0;     
    assign LED[5] = 0;         
    assign LED[4] = app_rd_data_valid;     
    assign LED[3] = app_wdf_rdy;     
    assign LED[2] = app_rdy;         
    assign LED[1] = app_en;        
    assign LED[0] = init_calib_complete;        
    

              
    initial begin
        //State = STATE_INIT;      
        data[0] = 128'hf000_0f00_00f0_4444_5555_6666_7777_ff00;
        data[1] = 128'h9999_0000_aaaa_bbbb_cccc_dddd_eeee_f000;
        data[2] = 128'h1111_2222_3333_4444_5555_6666_7777_8888;
        data[3] = 128'h9876_3535_6676_5652_8675_5555_2222_3564;
        data[4] = 128'h9df9_0dd0_aaaa_b888_cccc_2345_eeee_f000;        
        data[5] = 128'h3333_3333_6666_6666_9999_9999_1222_3345;        
        counter = 0;
        app_ref_req = 0;
    end
   
    always_ff @( posedge CLK25MHZ ) begin
        case (State)
            (STATE_INIT): begin
                if (vx < 32) begin
                    R = 0;
                    G = 0;
                    B = 15;
                end
                else begin
                    R = 0;
                    G = 0;
                    B = 0;
                end
            end

            (STATE_WAIT): begin
                if (vx < 32) begin
                    R = 0;
                    G = 0;
                    B = 15;
                end
                else begin
                    R = 0;
                    G = 0;
                    B = 0;
                end
            end

            (STATE_READ): begin
                if (vx >= 32 && vx < 64) begin
                    R = 15;
                    G = 15;
                    B = 0;
                end
                else begin
                    R = 0;
                    G = 0;
                    B = 0;
                end                
            end

            (STATE_READ_WAIT): begin    
                if (DataCounter == DATA_COUNT && DataCorrection) begin            
                    if (vx >= 64 && vx < 96) begin
                        R = 0;
                        G = 15;
                        B = 0;
                    end
                    else begin
                        R = 0;
                        G = 0;
                        B = 0;
                    end    
                end        
                else begin
                    if (vx >= 64 && vx < 96) begin
                        R = 15;
                        G = 0;
                        B = 0;
                    end
                    else begin
                        R = 0;
                        G = 0;
                        B = 0;
                    end    
                end         
            end
        endcase        
    end

    always@ (posedge MIG_Clk) begin       
        case (State)
            default: begin
                State = STATE_INIT;
            end

            (STATE_INIT): begin                    
                if (init_calib_complete) begin
                    app_en = 1'b0;                    
                    app_wdf_wren = 1'b0;
                    app_wdf_end = 1'b0;   
                    counter = 0;          
                    CorrectData[0]  = 0;
                    CorrectData[1]  = 0;
                    CorrectData[2]  = 0;
                    CorrectData[3]  = 0;
                    CorrectData[4]  = 0;
                    CorrectData[5]  = 0;                    
                    State = STATE_WRITE;                     
                end                                                
            end

            (STATE_WRITE): begin
                if (counter < DATA_COUNT) begin
                    if (app_rdy && app_wdf_rdy) begin
                        app_cmd = 3'b0;                  
                        app_addr = addr0 + counter * 8;  
                        app_wdf_data = {counter, counter, counter, counter, counter, counter, counter, counter};//data[counter>>4];
                        app_wdf_wren = 1'b1;
                        app_wdf_end = 1'b1;  
                        app_en = 1'b1;                                            
                        counter = counter + 1;
                        //State = STATE_WRITE_WAIT;
                    end
                end
                else begin
                    app_en = 1'b0;           
                    app_wdf_wren = 1'b0;
                    app_wdf_end = 1'b0;           
                    counter = 0;                    
                    //State = STATE_WAIT;           
                    State = STATE_READ;                    
                end                 
            end            

            (STATE_WRITE_WAIT): begin             
                app_en = 1'b0;                        
                app_wdf_wren = 1'b0;
                app_wdf_end = 1'b0;                           
                State = STATE_WRITE;                      
            end                        
        
            /*
            (STATE_WRITE): begin
                if (app_rdy & app_wdf_rdy) begin                    
                    if (counter < 6) begin      
                        app_en = 1'b1;                    
                        app_cmd = 3'b0;                  
                        app_addr = addr0 + counter * 8;  
                        app_wdf_data = data[counter];
                        app_wdf_wren = 1'b1;
                        app_wdf_end = 1'b1;   

                        R = 0;
                        G = 0;
                        B = 255; 

                        counter = counter + 1;                        
                    end
                    else begin                                     
                        app_en = 1'b0;                        
                        app_wdf_wren = 1'b0;
                        app_wdf_end = 1'b0;                           
                        State = STATE_WAIT;
                        counter = 0;
                    end                                                      
                end
            end                
            */

            (STATE_WAIT): begin
                app_en = 1'b0;                        
                app_wdf_wren = 1'b0;
                app_wdf_end = 1'b0;                           
                if (BTNL) begin
                    State = STATE_READ;   
                    counter = 0;    
                    DataCorrection = 1;
                    DataCounter = 0;
                end                       
            end            

            (STATE_READ): begin                
                if (counter < DATA_COUNT) begin 
                    if (app_rdy) begin
                        app_wdf_wren = 1'b0;
                        app_wdf_end = 1'b0;                                                                                    
                        app_cmd = 3'b1;                                               
                        app_addr = addr0 + (counter * 8);
                        app_en = 1'b1;                                                                
                        counter = counter + 1;                    
                    end                    
                end
                else begin
                    app_en = 1'b0;                                             
                    State = STATE_READ_WAIT;    

                    counter = 0;
                    
                    DataCorrection = 1;                    
                    DataCounter = 0; 
                end                

                if (BTNR) begin
                    State = STATE_INIT;   
                    DataCorrection = 1;
                    counter = 0;
                    DataCounter = 0; 
                end                       
            end
                     
            (STATE_READ_WAIT): begin                 
                app_en = 1'b0; 
                app_wdf_wren = 1'b0;
                app_wdf_end = 1'b0;                           
                if (DataCounter < DATA_COUNT) begin                    
                    if (app_rd_data_valid) begin                    
                        read_data = app_rd_data;    
                        //if (read_data == data[DataCounter>>4]) begin
                        if (read_data == {DataCounter, DataCounter, DataCounter, DataCounter, DataCounter, DataCounter, DataCounter, DataCounter}) begin                            
                            DataCorrection = DataCorrection & 1;    
                        end
                        else begin
                            DataCorrection = DataCorrection & 0;    
                        end                        
                        read_data = 0;
                        DataCounter = DataCounter + 1;                                                
                    end                                                             
                end
                else begin
                    State = STATE_WRITE;                       
                end
            end                                                  
        endcase
    end

    mig DDR2 (
        // Memory interface ports
        .ddr2_cs_n                  (ddr2_cs_n),
        .ddr2_addr                  (ddr2_addr),
        .ddr2_ba                    (ddr2_ba),
        .ddr2_we_n                  (ddr2_we_n),
        .ddr2_ras_n                 (ddr2_ras_n),
        .ddr2_cas_n                 (ddr2_cas_n),
        .ddr2_ck_n                  (ddr2_ck_n),
        .ddr2_ck_p                  (ddr2_ck_p),
        .ddr2_cke                   (ddr2_cke),
        .ddr2_dq                    (ddr2_dq),
        .ddr2_dqs_n                 (ddr2_dqs_n),
        .ddr2_dqs_p                 (ddr2_dqs_p),
        .ddr2_dm                    (ddr2_dm),
        .ddr2_odt                   (ddr2_odt),
        // Application interface ports
        .app_addr                   (app_addr),
        .app_cmd                    (app_cmd),
        .app_en                     (app_en),
        .app_wdf_rdy                (app_wdf_rdy),
        .app_wdf_data               (app_wdf_data),
        .app_wdf_end                (app_wdf_end),
        .app_wdf_wren               (app_wdf_wren),
        .app_rd_data                (app_rd_data),
        .app_rd_data_end            (app_rd_data_end),
        .app_rd_data_valid          (app_rd_data_valid),
        .app_rdy                    (app_rdy),
        .app_sr_req                 (1'b0),
        .app_ref_req                (1'b0),
        .app_ref_ack                (app_ref_ack),
        .app_zq_req                 (1'b0),
        .app_wdf_mask               (16'h0000),
        .init_calib_complete        (init_calib_complete),
        .ui_clk                     (MIG_Clk),
        // System Clock Ports
        .sys_clk_i                  (CLK200MHZ),        
        .sys_rst                    (Reset)//(CPU_RESETN)// & PLLLocked)
    );


endmodule
