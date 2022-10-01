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

module MemoryTask(  
    input clk,
    input resetn,
    input r_strobe,
    input MemoryReadTask r_task,    
    input w_strobe,
    input MemoryWriteTask w_task,    
    output logic busy,
    output logic valid,
    output MemoryReadData read_data,    

    // DDR2 chip signals
    inout [15:0] ddr2_dq,
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
    MemoryControllerState State, NextState = MCS_Init;  

    // APP_DATA_WIDTH is 128 bits/4 pixels(4 * 32bits)
    logic MIGUICLK;
    logic app_en, app_wdf_wren, app_wdf_end, init_calib_complete;
    logic [2:0] app_cmd = 3'b0;
    logic [ADDR_WIDTH-1:0] app_addr;
    logic [APP_DATA_WIDTH-1:0] app_wdf_data = 0; 
    logic [APP_DATA_WIDTH-1:0] app_rd_data;    
    logic [APP_MASK_WIDTH-1:0] app_wdf_mask = 0;
    logic app_rdy, app_rd_data_end, app_rd_data_valid, app_wdf_rdy;                    
    logic [`MC_CACHE_BLOCK_SIZE_WIDTH:0] DataCounter, CommandCounter;
    logic [`MC_CACHE_BLOCK_SIZE_WIDTH:0] PackageCounter, PackageOrder;        

    logic LastReadStrobe = 0, LastWriteStrobe = 0;
    logic ReadStrobe, WriteStrobe;

    function ReceieveData();    
        if (app_rd_data_valid) begin                   
            read_data.ID = r_task.ID;               
            read_data.Data[DataCounter * nCK_PER_CLK + 0] <= app_rd_data[127:96];
            read_data.Data[DataCounter * nCK_PER_CLK + 1] <= app_rd_data[95:64];
            read_data.Data[DataCounter * nCK_PER_CLK + 2] <= app_rd_data[63:32];
            read_data.Data[DataCounter * nCK_PER_CLK + 3] <= app_rd_data[31:0];  
            DataCounter = DataCounter + 1;         
            if (DataCounter >= r_task.BlockCount) begin                                                                                                            
                valid <= 1;
                read_data.Valid <= 1;
                NextState <= MCS_Wait; 
            end                                                                 
        end                        
    endfunction

    always_ff @( posedge MIGUICLK, negedge resetn ) begin              
        if (!resetn) begin
            NextState <= MCS_Init;
        end
        else begin
            ReadStrobe = (LastReadStrobe ^ r_strobe) & r_strobe;            
            WriteStrobe = (LastWriteStrobe ^ w_strobe) & w_strobe;
            LastReadStrobe = r_strobe;
            LastWriteStrobe = w_strobe;

            State = NextState;  

            case (State)
                (MCS_Init): begin
                    valid <= 0;
                    busy <= 0;
                    if (init_calib_complete) begin
                        app_en <= 0;
                        app_wdf_wren <= 0;
                        app_wdf_end <= 0;
                        app_cmd <= `DDR_CMD_WRITE;                                        
                        NextState <= MCS_Wait;
                    end    
                end                    

                (MCS_Wait): begin                                                            
                    valid <= 1;                    
                    if (ReadStrobe) begin
                        valid <= 0;
                        busy <= 1;
                        NextState <= MCS_Read_Init;                         
                    end
                    else if (WriteStrobe) begin
                        valid <= 0;
                        busy <= 1;
                        NextState <= MCS_Write_Init;                                                                    
                    end
                end

                (MCS_Read_Init): begin
                    if (app_rdy) begin 
                        app_wdf_wren <= 0;
                        app_addr <= r_task.Address;
                        app_cmd <= `DDR_CMD_READ;
                        app_en <= 1;                                                        
                        CommandCounter <= 1;       
                        DataCounter <= 0;    
                        PackageCounter <= 1;
                        PackageOrder <= 0;
                        read_data.Valid <= 0;
                        valid <= 0;
                        busy <= 1;
                        NextState <= MCS_Read; 
                    end
                end

                (MCS_Read): begin   
                    valid <= 0;
                    busy <= 1;                                
                    if (PackageCounter < (`MC_PACKAGE_SIZE / nCK_PER_CLK)) begin
                        if (CommandCounter < r_task.BlockCount) begin                            
                            if (app_rdy) begin                        
                                app_addr <= r_task.Address + CommandCounter * (nCK_PER_CLK * 2);
                                app_cmd <= `DDR_CMD_READ;
                                app_en <= 1;  
                                CommandCounter = CommandCounter + 1; 
                                PackageCounter = PackageCounter + 1;
                                ReceieveData();            
                            end
                        end                
                        else begin
                            if (app_rdy) begin
                                app_en <= 0;                                                        
                                NextState <= MCS_Read_Wait;
                                ReceieveData();                                
                            end
                        end
                    end
                    else begin
                        if (app_rdy) begin                        
                            app_en <= 0;
                            app_wdf_wren <= 0;
                            app_wdf_end <= 0;
                            PackageCounter = 0;
                            PackageOrder = PackageOrder + 1;
                            NextState <= MCS_Read_Wait;
                            ReceieveData();                         
                        end
                    end
                end

                (MCS_Read_Wait): begin        
                    valid <= 0;
                    busy <= 1;                              
                    ReceieveData();
                    if (DataCounter < r_task.BlockCount && DataCounter >= (PackageOrder * nCK_PER_CLK)) begin
                        if (app_rdy) begin                        
                            app_addr <= r_task.Address + CommandCounter * (nCK_PER_CLK * 2);
                            app_cmd <= `DDR_CMD_READ;
                            app_en <= 1;  
                            CommandCounter = CommandCounter + 1; 
                            PackageCounter = PackageCounter + 1;
                            NextState <= MCS_Read;
                        end                                        
                    end
                end

                (MCS_Write_Init): begin 
                    if (app_wdf_rdy) begin
                        app_wdf_data <= {{w_task.Data[0]}, 
                                         {w_task.Data[1]}, 
                                         {w_task.Data[2]}, 
                                         {w_task.Data[3]}};
                        app_wdf_wren <= 1;
                        app_wdf_end <= 1;                                                                                                
                        CommandCounter <= 0;
                        DataCounter <= 1;
                        PackageCounter <= 1;
                        valid <= 0;
                        busy <= 1;
                        NextState <= MCS_Write;                                            
                    end                                                                                                            
                end 

                (MCS_Write): begin      
                    valid <= 0;
                    busy <= 1;                                             
                    if (DataCounter < w_task.BlockCount) begin
                        if (app_wdf_rdy) begin
                            app_wdf_data <= {{w_task.Data[DataCounter * nCK_PER_CLK + 0]}, 
                                             {w_task.Data[DataCounter * nCK_PER_CLK + 1]}, 
                                             {w_task.Data[DataCounter * nCK_PER_CLK + 2]}, 
                                             {w_task.Data[DataCounter * nCK_PER_CLK + 3]}};
                            app_wdf_wren <= 1;
                            app_wdf_end <= 1;                                                                
                            DataCounter = DataCounter + 1;
                            // Sending data first then send commands when sending data is finished
                            if (DataCounter >= w_task.BlockCount) begin
                                if (app_rdy) begin                            
                                    app_addr <= w_task.Address + CommandCounter * (nCK_PER_CLK * 2);
                                    app_cmd <= `DDR_CMD_WRITE;
                                    app_en <= 1;  
                                    CommandCounter = CommandCounter + 1;
                                end
                            end
                        end                                                    
                    end
                    else begin
                        app_wdf_wren <= 0;
                        app_wdf_end <= 0;
                        if (CommandCounter < w_task.BlockCount) begin
                            if (app_rdy) begin                            
                                app_addr <= w_task.Address + CommandCounter * (nCK_PER_CLK * 2);
                                app_cmd <= `DDR_CMD_WRITE;
                                app_en <= 1;  
                                CommandCounter = CommandCounter + 1;                                                          
                            end
                        end
                        else begin
                            if (app_rdy) begin                            
                                app_en <= 0;          
                                valid <= 1;          
                                NextState <= MCS_Wait;
                            end
                        end
                    end                              
                end
                
                default: begin
                    NextState <= MCS_Init;
                end
            endcase     
        end        
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
        .app_zq_req                 (1'b0),
        .app_wdf_mask               (app_wdf_mask),
        .ui_clk                     (MIGUICLK),
        .init_calib_complete        (init_calib_complete),
        // System Clock Ports
        .sys_clk_i                  (clk),        
        .sys_rst                    (resetn)
    );

endmodule

module MemoryController(    
    input clk,	     
	input clk_mem,	     
    input resetn,   
    input MemoryReadRequest request_r,
    input MemoryWriteRequest request_w,
    output MemoryReadData read_data,        
    output DebugData debug_data,

    // DDR2 chip signals
    inout [15:0] ddr2_dq,
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

    localparam QUEUE_SIZE_WIDTH     = 3;
    localparam QUEUE_SIZE           = 2**QUEUE_SIZE_WIDTH;
    
    logic LastReadStrobe = 0, LastWriteStrobe = 0;    
    logic ReadStrobe, WriteStrobe;
    //logic ReadDone, WriteDone;    
    MemoryControllerState State, NextState = MCS_Init;  
    MemoryReadTask ReadTaskQueue[QUEUE_SIZE];
    MemoryReadTask CurrentReadTask;
    logic [QUEUE_SIZE_WIDTH-1:0] ReadTaskQueueTop = 0, ReadTaskQueueBottom = 0;  
    MemoryWriteTask WriteTaskQueue[QUEUE_SIZE];
    MemoryWriteTask CurrentWriteTask;
    logic [QUEUE_SIZE_WIDTH-1:0] WriteTaskQueueTop = 0, WriteTaskQueueBottom = 0;      
    
    logic TaskValid, ReadTaskStrobe, WriteTaskStrobe, TaskBusy;    
    
    function Reset();    
        ReadTaskQueueTop <= 0;
        ReadTaskQueueBottom <= 0;
        WriteTaskQueueTop <= 0;
        WriteTaskQueueBottom <= 0;
        LastReadStrobe <= 0;
        LastWriteStrobe <= 0;        
        NextState <= MCS_Init;
    endfunction        

    always_comb begin
        
    end

    always_ff @( posedge clk, negedge resetn ) begin      
        if (!resetn) begin
            Reset();
        end
        else begin
            ReadStrobe = (LastReadStrobe ^ request_r.ReadStrobe) & request_r.ReadStrobe;            
            WriteStrobe = (LastWriteStrobe ^ request_w.WriteStrobe) & request_w.WriteStrobe;
            LastReadStrobe = request_r.ReadStrobe;
            LastWriteStrobe = request_w.WriteStrobe;

            if (ReadStrobe && ReadTaskQueue[ReadTaskQueueBottom].Address != request_r.ReadAddress) begin
                ReadTaskQueue[ReadTaskQueueBottom].Address = request_r.ReadAddress;
                ReadTaskQueue[ReadTaskQueueBottom].BlockCount = request_r.BlockCount;
                ReadTaskQueue[ReadTaskQueueBottom].ID = request_r.ReadID;
                ReadTaskQueueBottom = ReadTaskQueueBottom + 1;                                                                
            end

            if (WriteStrobe && WriteTaskQueue[WriteTaskQueueBottom].Address != request_w.WriteAddress) begin
                WriteTaskQueue[WriteTaskQueueBottom].Address = request_w.WriteAddress;
                WriteTaskQueue[WriteTaskQueueBottom].Data = request_w.WriteData;
                WriteTaskQueue[WriteTaskQueueBottom].BlockCount = request_w.BlockCount;
                WriteTaskQueueBottom = WriteTaskQueueBottom + 1;                                      
            end                            
            
            State = NextState;
            
            case (State)
                (MCS_Init): begin
                    ReadTaskStrobe <= 0;
                    WriteTaskStrobe <= 0; 
                    NextState <= MCS_Wait;                    
                end

                (MCS_Wait): begin                
                    if (ReadTaskQueueTop != ReadTaskQueueBottom) begin
                        CurrentReadTask <= ReadTaskQueue[ReadTaskQueueTop];
                        ReadTaskQueueTop = ReadTaskQueueTop + 1;

                        ReadTaskStrobe <= 1;
                        WriteTaskStrobe <= 0; 
                        NextState <= MCS_Read;  
                    end
                    else if (WriteTaskQueueTop != WriteTaskQueueBottom) begin 
                        CurrentWriteTask <= WriteTaskQueue[WriteTaskQueueTop];
                        WriteTaskQueueTop = WriteTaskQueueTop + 1;

                        ReadTaskStrobe <= 0;
                        WriteTaskStrobe <= 1;                                                    
                        NextState <= MCS_Write;                                                                    
                    end             
                    else begin
                        ReadTaskStrobe <= 0;
                        WriteTaskStrobe <= 0;
                    end                                                                                                      
                end
                
                (MCS_Read): begin                    
                    ReadTaskStrobe <= 0;
                    WriteTaskStrobe <= 0;                                         
                    if (TaskValid) begin                                                
                        NextState <= MCS_Wait;
                    end                                            
                end

                (MCS_Write): begin
                    ReadTaskStrobe <= 0;
                    WriteTaskStrobe <= 0;                                         
                    if (TaskValid) begin                            
                        NextState <= MCS_Wait;
                    end                    
                end

                default: begin
                    NextState <= MCS_Init;
                end
            endcase        
        end
    end         

    MemoryTask MT(
        .clk(clk_mem),
        .resetn(resetn),
        .r_strobe(ReadTaskStrobe),
        .r_task(CurrentReadTask),
        .w_strobe(WriteTaskStrobe),
        .w_task(CurrentWriteTask),    
        .busy(TaskBusy),
        .valid(TaskValid),
        .read_data(read_data),        

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
