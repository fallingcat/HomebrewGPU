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
    
module _RasterRayDir(
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

module ThreadGenerator#(
    parameter PEROID_WIDTH = 10
    ) (
    input clk,
	input resetn,	
    input strobe,
    input reset,    
    input [PEROID_WIDTH-1:0] period,        
    input output_fifo_full[`RAY_CORE_SIZE],        
    input RenderState rs,    
    input logic `SCREEN_COORD x0,
    input logic `SCREEN_COORD y0,       
    output ThreadData out
    );		
    
    logic [`RAY_CORE_SIZE_WIDTH:0] CurrentRayCore;
    ThreadGeneratorState State, NextState = TGS_Generate;    
    logic `SCREEN_COORD CX = 0, CY = 0;    
    logic [PEROID_WIDTH-1:0] IssueTimer = 0;    
    logic Finished = 0;    
    
    assign out.Finished = Finished;
    
	always_ff @( posedge clk, negedge resetn) begin		                       
        if (!resetn) begin
            CurrentRayCore <= 0;
            CX <= x0;
            CY <= y0;                                    
            IssueTimer <= 0;
            Finished <= 0;            
            NextState <= TGS_Init;
		end
		else begin
            IssueTimer <= IssueTimer + 1;
            if (IssueTimer >= period) begin
                IssueTimer <= 0;
            end            
            
            State = NextState;           

            case (State)
                TGS_Init: begin
                    for (int i = 0; i < `RAY_CORE_SIZE; i = i + 1) begin
                        out.DataValid[i] <= 0;
                    end                           

                    if (reset) begin
                        CurrentRayCore <= 0;
                        CX <= x0;
                        CY <= y0;                             
                        IssueTimer <= 0;
                        Finished <= 0;                        
                        NextState <= TGS_Generate;
                    end            
                end

                TGS_Generate: begin                                        
                    Finished <= 0;

                    for (int i = 0; i < `RAY_CORE_SIZE; i = i + 1) begin
                        out.DataValid[i] <= 0;                        
                    end        

                    if ((strobe && IssueTimer == 0) || (CX == x0 && CY == y0)) begin                        
                        if (!output_fifo_full[CurrentRayCore]) begin
                            out.DataValid[CurrentRayCore] <= 1;                                                         
                            out.RayCoreInput[CurrentRayCore].x <= CX;
                            out.RayCoreInput[CurrentRayCore].y <= CY;                      

                            out.RayCoreInput[CurrentRayCore].BounceLevel <= 0;
                            out.RayCoreInput[CurrentRayCore].LastColor <= _RGB8(0, 0, 0);                                          
                            
                            out.RayCoreInput[CurrentRayCore].RasterRay.MinT <= _Fixed(0);
                            out.RayCoreInput[CurrentRayCore].RasterRay.MaxT <= _Fixed(1000);                                                  
                            out.RayCoreInput[CurrentRayCore].RasterRay.Orig <= rs.Camera.Pos;
                            out.RayCoreInput[CurrentRayCore].RasterRay.PI <= `NULL_PRIMITIVE_INDEX; // means the raster ray is from camera                          

                            CurrentRayCore = CurrentRayCore + 1;
                            if (CurrentRayCore >= `RAY_CORE_SIZE) begin
                                CurrentRayCore = CurrentRayCore - `RAY_CORE_SIZE;
                            end
                            
                            // Prepare next fragment thread
                            CX = CX + 1;
                            if (CX >= `FRAMEBUFFER_WIDTH) begin
                                CX = 0;
                                CY = CY + 1;							
                            end	

                            if (CY >= `FRAMEBUFFER_HEIGHT && CX >= 2) begin
                                Finished <= 1;        
                                NextState <= TGS_Init;                
                            end                               
                        end                                                                                   
                    end                       
                end                
            endcase                            
		end
	end	

    // Compute direction of generated raster rays. 
    generate
        for (genvar i = 0; i < `RAY_CORE_SIZE; i = i + 1) begin : RAS_DIR
            _RasterRayDir RAS_DIR(
                .x(out.RayCoreInput[i].x),
                .y(out.RayCoreInput[i].y),
                .vp_h(rs.ViewportHeight),
                .camera_pos(rs.Camera.Pos),    
                .camera_blc(rs.Camera.BLC),
                .camera_rh(rs.Camera.RH),
                .camera_rv(rs.Camera.RV),
                .camera_cub(rs.Camera.CUB),    
                .camera_cvb(rs.Camera.CVB),        
                .out(out.RayCoreInput[i].RasterRay.Dir)              
            );         
        end
    endgenerate  

endmodule