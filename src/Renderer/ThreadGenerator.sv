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
  
module _SurfaceRayDir(
    input logic `SCREEN_COORD x,
    input logic `SCREEN_COORD y,
    input logic `SCREEN_COORD vp_h,
    input Fixed3 camera_pos,    
    input Fixed3 camera_blc,
    input Fixed3 camera_rh,
    input Fixed3 camera_rv,
    input Fixed camera_cub,    
    input Fixed camera_cvb,        
    output Fixed3 out
    );

    Fixed CU, CV, X, Y;
    Fixed3 H, V, O, T;

    always_comb begin
        X <= _Fixed(x);        
        Y <= _Fixed((vp_h - 1) - y);        
    end

    Fixed_Mul A0(X, camera_cub, CU);
    Fixed_Mul A1(Y, camera_cvb, CV);
    Fixed3_Mul A2(CU, camera_rh, H);
    Fixed3_Mul A3(CV, camera_rv, V);
    
    //Fixed3_Mul A2(X, rs.Camera.dU, H);
    //Fixed3_Mul A3(Y, rs.Camera.dV, V);

    Fixed3_Add A4(H, V, T);
    Fixed3_Add A5(T, camera_blc, O);
    Fixed3_Sub A6(O, camera_pos, out);
endmodule

`ifdef MULTI_ISSUE
    module _CoreThreadDataGenerator(
        input clk,
        input strobe,
        input logic output_fifo_full,        
        input RenderState rs,    
        input logic `SCREEN_COORD x0,
        input logic `SCREEN_COORD y0,     

        output DebugData debug_data,   
        output logic busy, 
        output ThreadData thread_out        
        );	    

        ThreadGeneratorState State, NextState = TGS_Wait;
        logic Busy = 0;
        logic `SCREEN_COORD SX, SY;
        logic [`RAY_CORE_COVER_SIZE_WIDTH-1:0] Count = 0;
        
        //assign debug_data.Number[1] = x0;//SX;
        //assign debug_data.Number[0] = Count;//SY;

        assign debug_data.Number[1] = thread_out.RayCoreInput.x;
        assign debug_data.Number[0] = thread_out.RayCoreInput.y;
        assign busy = (State == TGS_Generate);

        //always_comb begin          
        always_ff @( posedge clk ) begin		  
            State = NextState;       
            case (State)
                TGS_Wait: begin
                    thread_out.DataValid <= 0;
                    if (strobe) begin             
                        SX = x0;
                        SY = y0;
                        Count = 0;                   
                        NextState <= TGS_Generate;                    
                    end
                end         

                TGS_Generate: begin
                    if (strobe) begin
                        if (!output_fifo_full) begin
                            if (SY < `FRAMEBUFFER_HEIGHT) begin      
                                thread_out.RayCoreInput.x <= SX + Count;
                                thread_out.RayCoreInput.y <= SY;                      
                                thread_out.RayCoreInput.BounceLevel <= 0;
                                thread_out.RayCoreInput.LastColor <= _RGB8(0, 0, 0);                                        
                                thread_out.RayCoreInput.SurfaceRay.MinT <= _Fixed(0);
                                thread_out.RayCoreInput.SurfaceRay.MaxT <= _Fixed(1000);                                                  
                                thread_out.RayCoreInput.SurfaceRay.Orig <= rs.Camera.Pos;
                                thread_out.RayCoreInput.SurfaceRay.PI <= `NULL_PRIMITIVE_INDEX; // means the raster ray is from camera                          
                                // Indicate that the thread data for currey core is ready
                                thread_out.DataValid <= 1;

                                Count = Count + 1;             
                                if (Count == 0) begin
                                    NextState <= TGS_Wait;                       
                                end                        
                            end
                            else begin
                                thread_out.DataValid <= 0;
                                NextState <= TGS_Wait;                       
                            end                            
                        end
                        else begin
                            thread_out.DataValid <= 0;
                        end
                    end
                end
            endcase
        end



            /*
            if (strobe) begin             
                if (Busy) begin                    
                    if (!output_fifo_full) begin
                        if (SY < `FRAMEBUFFER_HEIGHT) begin      
                            // Prepare the thraed data
                            thread_out.RayCoreInput.x <= SX + Count;
                            thread_out.RayCoreInput.y <= SY;                      
                            thread_out.RayCoreInput.BounceLevel <= 0;
                            thread_out.RayCoreInput.LastColor <= _RGB8(0, 0, 0);                                        
                            thread_out.RayCoreInput.SurfaceRay.MinT <= _Fixed(0);
                            thread_out.RayCoreInput.SurfaceRay.MaxT <= _Fixed(1000);                                                  
                            thread_out.RayCoreInput.SurfaceRay.Orig <= rs.Camera.Pos;
                            thread_out.RayCoreInput.SurfaceRay.PI <= `NULL_PRIMITIVE_INDEX; // means the raster ray is from camera                          
                            // Indicate that the thread data for currey core is ready
                            thread_out.DataValid <= 1;

                            Count = Count + 1;             
                            if (Count == 0) begin
                                Busy = 0;     
                            end                        
                        end    
                        else begin
                            thread_out.DataValid <= 0;
                            Busy = 0;     
                        end
                    end
                    else begin
                        thread_out.DataValid <= 0;
                    end
                end
                else begin                    
                    thread_out.DataValid <= 0;
                    SX = x0;
                    SY = y0;
                    Count = 0;
                    Busy = 1;
                end
            end                        
        end
        */

        _SurfaceRayDir SURF_DIR(
            .x(thread_out.RayCoreInput.x),
            .y(thread_out.RayCoreInput.y),
            .vp_h(rs.ViewportHeight),
            .camera_pos(rs.Camera.Pos),    
            .camera_blc(rs.Camera.BLC),
            .camera_rh(rs.Camera.RH),
            .camera_rv(rs.Camera.RV),
            .camera_cub(rs.Camera.CUB),    
            .camera_cvb(rs.Camera.CVB),        
            .out(thread_out.RayCoreInput.SurfaceRay.Dir)              
        );        
    endmodule
    
    module ThreadGenerator(
        input clk,
        input resetn,	
        input strobe,
        input reset,        
        input output_fifo_full[`RAY_CORE_SIZE],        
        input RenderState rs,    
        input logic `SCREEN_COORD x0,
        input logic `SCREEN_COORD y0,   
        output DebugData debug_data,            
        output ThreadData thread_out[`RAY_CORE_SIZE]
        );		   
        ThreadGeneratorState State, NextState = TGS_Init;             
        logic `SCREEN_COORD CX, CY;                    
        logic `SCREEN_COORD NX[`RAY_CORE_SIZE], NY[`RAY_CORE_SIZE];                    
        logic CoreBusy[`RAY_CORE_SIZE];
        logic [20:0] Counter = 0;
                
        //assign debug_data.Number[1] = CX;
        //assign debug_data.Number[0] = CY;
        assign debug_data.LED[0] = CoreBusy[0];

        always_ff @( posedge clk, negedge resetn) begin		                       
            if (!resetn) begin            
                CX = x0;                                    
                CY = y0;                          
                NextState <= TGS_Init;            
            end
            else begin
                State = NextState;                

                if (reset) begin                                                
                    CX = x0;                                    
                    CY = y0;                              
                    NextState <= TGS_Wait;
                end
                else begin
                    case (State)
                        TGS_Init: begin                    
                            if (reset) begin                                                
                                CX = x0;                                    
                                CY = y0;                                          
                                NextState <= TGS_Wait;
                            end
                        end

                        TGS_Wait: begin                    
                            if (strobe) begin                                  
                                NextState <= TGS_Generate;
                            end            
                        end

                        TGS_Generate: begin                                                                                    
                            for (int i = 0; i < `RAY_CORE_SIZE; i = i + 1) begin
                                NX[i] = CX;
                                NY[i] = CY;
                                if (!CoreBusy[i]) begin
                                    CX = CX + `RAY_CORE_COVER_SIZE;                                    
                                    if (CX >= `FRAMEBUFFER_WIDTH) begin
                                        CX = CX - `FRAMEBUFFER_WIDTH;                                        
                                        CY = CY + 1;
                                    end
                                end
                            end                            
                            NextState <= TGS_NextThread;
                        end                                   

                        TGS_NextThread: begin
                            //Counter = Counter + 1;
                            //if (Counter == 0) begin
                                NextState <= TGS_Generate;                                                                                            
                            //end
                        end

                        default: begin
                            NextState <= TGS_Init;                
                        end                        
                    endcase                            
                end
            end
        end	

        generate
            for (genvar i = 0; i < `RAY_CORE_SIZE; i = i + 1) begin : CORE_THREAD_ARRY    
                _CoreThreadDataGenerator CORE_THREAD_DATA(       
                    .clk(clk),          
                    .strobe(State == TGS_Generate),	
                    .output_fifo_full(output_fifo_full[i]),
                    .rs(rs),    
                    .x0(NX[i]),
                    .y0(NY[i]),
                    .busy(CoreBusy[i]),
                    .debug_data(debug_data),
                    .thread_out(thread_out[i])
                );	    
            end
        endgenerate      
    endmodule
`else
    module _CoreThreadDataGenerator(
        input strobe,
        input logic output_fifo_full,        
        input RenderState rs,    
        input logic `SCREEN_COORD x,
        input logic `SCREEN_COORD y,     

        output DebugData debug_data,    
        output ThreadData thread_out        
        );	    

        always_comb begin
            if (strobe && !output_fifo_full) begin                                                       
                // Prepare the thraed data
                thread_out.RayCoreInput.x <= x;
                thread_out.RayCoreInput.y <= y;                      
                thread_out.RayCoreInput.BounceLevel <= 0;
                thread_out.RayCoreInput.LastColor <= _RGB8(0, 0, 0);                                        
                thread_out.RayCoreInput.SurfaceRay.MinT <= _Fixed(0);
                thread_out.RayCoreInput.SurfaceRay.MaxT <= _Fixed(1000);                                                  
                thread_out.RayCoreInput.SurfaceRay.Orig <= rs.Camera.Pos;
                thread_out.RayCoreInput.SurfaceRay.PI <= `NULL_PRIMITIVE_INDEX; // means the raster ray is from camera                          
                // Indicate that the thread data for currey core is ready
                thread_out.DataValid <= 1;
            end   
            else begin
                thread_out.DataValid <= 0;
            end                                                                                
        end

        _SurfaceRayDir SURF_DIR(
            .x(x),
            .y(y),
            .vp_h(rs.ViewportHeight),
            .camera_pos(rs.Camera.Pos),    
            .camera_blc(rs.Camera.BLC),
            .camera_rh(rs.Camera.RH),
            .camera_rv(rs.Camera.RV),
            .camera_cub(rs.Camera.CUB),    
            .camera_cvb(rs.Camera.CVB),        
            .out(thread_out.RayCoreInput.SurfaceRay.Dir)              
        );             
    endmodule

    module ThreadGenerator(
        input clk,
        input resetn,	
        input strobe,
        input reset,        
        input output_fifo_full[`RAY_CORE_SIZE],        
        input RenderState rs,    
        input logic `SCREEN_COORD x0,
        input logic `SCREEN_COORD y0,   
        output DebugData debug_data,    
        output ThreadData thread_out[`RAY_CORE_SIZE]
        );		
        
        logic [`RAY_CORE_SIZE_WIDTH:0] CurrentCore = 0;
        ThreadGeneratorState State, NextState = TGS_Init;    
        logic `SCREEN_COORD CX, CY;            
        ThreadData ThreadOut;    

        assign debug_data.LED[0] = strobe;
        assign debug_data.LED[1] = (State == TGS_Generate);   
        assign debug_data.LED[2] = thread_out[CurrentCore].DataValid;    	            

        //assign debug_data.Number = thread_out[CurrentCore].RayCoreInput.y;

        always_ff @( posedge clk, negedge resetn) begin		                       
            if (!resetn) begin            
                CurrentCore = 0;
                NextState <= TGS_Init;
                CX = x0;
                CY = y0;                                   
            end
            else begin
                for (int i = 0; i < `RAY_CORE_SIZE; i = i + 1) begin
                    thread_out[i].DataValid = 0;
                end                                     

                State = NextState;                

                case (State)
                    TGS_Init: begin                    
                        if (reset) begin                                                
                            CurrentCore <= 0;
                            CX <= x0;
                            CY <= y0;                                                                            
                            NextState <= TGS_Wait;
                        end
                    end

                    TGS_Wait: begin                    
                        if (strobe) begin                                              
                            NextState <= TGS_Generate;
                        end            
                    end

                    TGS_Generate: begin                             
                        thread_out[CurrentCore] = ThreadOut;    
                        if (thread_out[CurrentCore].DataValid) begin                           
                            NextState = TGS_NextThread;               
                        end                                        
                    end    

                    TGS_NextThread: begin
                        NextState <= TGS_Generate;                                        

                        // Core index for next clock
                        CurrentCore = CurrentCore + 1;
                        if (CurrentCore >= `RAY_CORE_SIZE) begin
                            CurrentCore = CurrentCore - `RAY_CORE_SIZE;
                        end                                                                                            
                        
                        CX = CX + 1;
                        if (CX >= `FRAMEBUFFER_WIDTH) begin
                            CX = x0;
                            CY = CY + 1;							                           
                            if (CY >= `FRAMEBUFFER_HEIGHT) begin                                
                                NextState <= TGS_Init; 
                            end
                        end	                       
                    end        
                                

                    //TGS_Generate: begin         
                    //    CoreStrobe <= 1;                    
                    //    thread_out[CurrentCore] = ThreadOut;    
                    //    if (thread_out[CurrentCore].DataValid) begin                           
                    //        CoreStrobe <= 0;
                    //        CurrentCore = CurrentCore + 1;
                    //        if (CurrentCore >= `RAY_CORE_SIZE) begin
                    //            CurrentCore = CurrentCore - `RAY_CORE_SIZE;
                    //        end                                                                                            
                    //        
                    //        CX = CX + 1;
                    //        if (CX >= `FRAMEBUFFER_WIDTH) begin
                    //            CX = x0;
                    //            CY = CY + 1;							                           
                    //            if (CY >= `FRAMEBUFFER_HEIGHT) begin
                    //                frame_finished <= 1;                             
                    //                NextState <= TGS_Init; 
                    //            end
                    //        end	                                      
                    //    end                                        
                    //end                                
                    
                    default: begin
                        NextState <= TGS_Init;                
                    end                        
                endcase                            
            end
        end	

        _CoreThreadDataGenerator CORE_THREAD_DATA(
            .strobe(State == TGS_Generate),	
            .output_fifo_full(output_fifo_full[CurrentCore]),
            .rs(rs),    
            .x(CX),
            .y(CY),
            .debug_data(debug_data),
            .thread_out(ThreadOut)
        );	    
    endmodule
`endif

/*
// TODO : Find out why DataValid will last 2 cycles.
module ThreadGenerator(
    input clk,
	input resetn,	
    input strobe,
    input reset,        
    input output_fifo_full[`RAY_CORE_SIZE],        
    input RenderState rs,    
    input logic `SCREEN_COORD x0,
    input logic `SCREEN_COORD y0,   
    output DebugData debug_data,    
    output logic frame_finished,
    output ThreadData thread_out[`RAY_CORE_SIZE]
    );		    
    
    ThreadGeneratorState State, NextState = TGS_Init;    
    logic `SCREEN_COORD CX, CY;        
    
	always_ff @( posedge clk, negedge resetn) begin		                       
        if (!resetn) begin
            NextState <= TGS_Init;
            CX = x0;
            CY = y0;       
            frame_finished = 0;                                   
		end
		else begin
            State = NextState;                

            case (State)
                TGS_Init: begin
                    thread_out[0].DataValid <= 0;
                    if (reset) begin                                                
                        CX = x0;
                        CY = y0;                                                
                        frame_finished = 0;      
                        NextState <= TGS_Wait;
                    end
                end

                TGS_Wait: begin
                    thread_out[0].DataValid <= 0;
                    if (strobe) begin
                        NextState <= TGS_Generate;
                    end            
                end

                TGS_Generate: begin   
                    if (!output_fifo_full[0]) begin                       
                        thread_out[0].DataValid <= 1;
                        thread_out[0].RayCoreInput.x <= CX;
                        thread_out[0].RayCoreInput.y <= CY;                                                
                        NextState <= TGS_NextThread;                    
                    end                    
                    else begin
                        thread_out[0].DataValid <= 0;
                    end
                end                                 

                TGS_NextThread: begin
                    NextState <= TGS_Generate;
                    thread_out[0].DataValid <= 0;                    
                    CX = CX + 1;
                    if (CX >= `FRAMEBUFFER_WIDTH) begin
                        CX = 0;
                        CY = CY + 1;							                           
                        if (CY >= `FRAMEBUFFER_HEIGHT) begin
                            frame_finished = 1;                             
                            NextState <= TGS_Init; 
                        end
                    end	                       
                end       
                
                default: begin
                    NextState <= TGS_Init;                
                end                        
            endcase                            
		end
	end	
endmodule
*/
