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
`include "../../../Math/Fixed.sv"
`include "../../../Math/Fixed3.sv"
`include "../../../Math/FixedNorm.sv"
`include "../../../Math/FixedNorm3.sv"

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module ShadowRayGenerator(
    input clk,
	input resetn,	

    // controls...    
    input add_input,	        

    // inputs...
    input SurfaceOutputData input_data,
    input output_fifo_full,	    

    // outputs...     
    output logic fifo_full,           
    output logic valid,
    output SurfaceOutputData out    
    );		
	
    RayGeneratorState State, NextState = RGS_Init;    
    SurfaceOutputData Input;                
    
    Fixed3 InvDir;    
	logic InvDir_Valid, InvDir_Strobe;   
  
    initial begin	        
        fifo_full <= 0;
        NextState <= RGS_Init;
	end	   
    
    always_ff @( posedge clk, negedge resetn) begin		                
		if (!resetn) begin
            fifo_full <= 0;
            NextState <= RGS_Init;
		end
		else begin			       
            // If FIFO is not full       
            if (add_input) begin
                if (!fifo_full) begin                                    
                    Input = input_data;
                    fifo_full = 1;          
                end               
            end                                

            State = NextState;

            case (State)
                default: begin
                    valid <= 0;                            
                    InvDir_Strobe <= 0;
					NextState <= RGS_Init;                    
                end
                
                (RGS_Init): begin	 
                    valid <= 0;    
                    InvDir_Strobe <= 0;                                            
                    if (fifo_full) begin
                        out = Input; 
                        fifo_full <= 0;            

                        if (out.bHit) begin                                                       
                            InvDir_Strobe <= 1;
                            NextState <= RGS_Generate;
                        end
                        else begin
                            InvDir_Strobe <= 0;
                            NextState <= RGS_Done;
                        end                                                
                    end
                end
                
				(RGS_Generate): begin                    
                    InvDir_Strobe <= 0;
                    if (InvDir_Valid) begin                          
                        out.ShadowRay.InvDir <= InvDir;                                                
                        NextState <= RGS_Done;
                    end                                            
                end

                (RGS_Done): begin
                    if (!output_fifo_full) begin                        
                        InvDir_Strobe <= 0;                                              
                        valid <= 1;
                        NextState <= RGS_Init;                        
                    end
                end
            endcase	
		end
	end	   
    
    Fixed3_Inv_V2 DIR_INV(
		.clk(clk),
        .resetn(resetn),
		.strobe(InvDir_Strobe),
		.v(out.ShadowRay.Dir), 
		.valid(InvDir_Valid),
		.ov(InvDir)
	);

endmodule

