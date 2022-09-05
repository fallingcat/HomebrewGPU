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
            thread_out.DataValid = 1;
        end   
        else begin
            thread_out.DataValid = 0;
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
    output logic frame_finished,
    output ThreadData thread_out[`RAY_CORE_SIZE]
    );		
    
    logic [4:0] CurrentCore = 0;
    ThreadGeneratorState State, NextState = TGS_Init;    
    logic `SCREEN_COORD CX, CY;        
    Fixed3 Dir;    
    ThreadData ThreadOut;
    logic CoreStrobe;   

    assign debug_data.LED[0] = strobe;
    assign debug_data.LED[1] = (State == TGS_Generate);   
    assign debug_data.LED[2] = thread_out[CurrentCore].DataValid;    	    
    assign debug_data.LED[3] = !frame_finished;    	    

    //assign debug_data.Number = thread_out[CurrentCore].RayCoreInput.y;

	always_ff @( posedge clk, negedge resetn) begin		                       
        if (!resetn) begin            
            CurrentCore = 0;
            NextState <= TGS_Init;
            CX = x0;
            CY = y0;       
            CoreStrobe = 0;   
            frame_finished = 0;                                   
		end
		else begin
            for (int i = 0; i < `RAY_CORE_SIZE; i = i + 1) begin
                thread_out[i].DataValid = 0;
            end                                     

            State = NextState;                

            case (State)
                TGS_Init: begin
                    CoreStrobe = 0;
                    if (reset) begin                                                
                        CurrentCore <= 0;
                        CX <= x0;
                        CY <= y0;                                                
                        frame_finished <= 0;      
                        NextState <= TGS_Wait;
                    end
                end

                TGS_Wait: begin
                    CoreStrobe <= 0;
                    if (strobe) begin                                              
                        NextState <= TGS_Generate;
                    end            
                end

                TGS_Generate: begin         
                    CoreStrobe <= 1;                    
                    thread_out[CurrentCore] = ThreadOut;    
                    if (thread_out[CurrentCore].DataValid) begin                           
                        NextState = TGS_NextThread;               
                    end                                        
                end    

                TGS_NextThread: begin
                    NextState <= TGS_Generate;                    
                    CoreStrobe <= 0;                     

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
                            frame_finished = 1;                             
                            NextState <= TGS_Init; 
                        end
                    end	                       
                end        
                               

                /*
                TGS_Generate: begin         
                    CoreStrobe <= 1;                    
                    thread_out[CurrentCore] = ThreadOut;    
                    if (thread_out[CurrentCore].DataValid) begin                           
                        CoreStrobe <= 0;
                        CurrentCore = CurrentCore + 1;
                        if (CurrentCore >= `RAY_CORE_SIZE) begin
                            CurrentCore = CurrentCore - `RAY_CORE_SIZE;
                        end                                                                                            
                        
                        CX = CX + 1;
                        if (CX >= `FRAMEBUFFER_WIDTH) begin
                            CX = x0;
                            CY = CY + 1;							                           
                            if (CY >= `FRAMEBUFFER_HEIGHT) begin
                                frame_finished <= 1;                             
                                NextState <= TGS_Init; 
                            end
                        end	                                      
                    end                                        
                end       
                */         
                
                default: begin
                    NextState <= TGS_Init;                
                end                        
            endcase                            
		end
	end	

    _CoreThreadDataGenerator CORE_THREAD_DATA(
        .strobe(CoreStrobe),	
        .output_fifo_full(output_fifo_full[CurrentCore]),
        .rs(rs),    
        .x(CX),
        .y(CY),
        .debug_data(debug_data),
        .thread_out(ThreadOut)
    );	    
endmodule


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
