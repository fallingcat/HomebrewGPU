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
module RastaerRayGenerator(    
    input clk,
	input resetn,	

    // controls... 
    input add_input,
    input add_ref_input,	        

    // inputs...
    input RasterInputData input_data,        
    input RasterInputData ref_input_data,       
    input output_fifo_full,	        

    // outputs...    
    output logic fifo_full,         
    output logic ref_fifo_full,         
    output logic valid,
    output RasterInputData out    
    );		
	
    RayGeneratorState State, NextState = RGS_Init;    

    RasterInputData Input;        
    RasterInputData RefInput;    
    
    Fixed3 InvDir;    
	logic InvDir_Valid, InvDir_Strobe;          

    /*
    initial begin	        
        fifo_full <= 0;
        ref_fifo_full <= 0;  
        NextState <= RGS_Init;
	end	   
    */
    
	always_ff @( posedge clk, negedge resetn) begin		                
		if (!resetn) begin
            fifo_full <= 0;
            ref_fifo_full <= 0;  
			NextState <= RGS_Init;
		end
		else begin			                   
            if (add_input) begin
                // If FIFO is not full       
                if (!fifo_full) begin                                    
                    // Add one ray into FIFO                
                    Input = input_data;                                
                    fifo_full = 1;
                end               
            end        

            if (add_ref_input) begin
                // If FIFO is not full 
                if (!ref_fifo_full) begin                                    
                    // Add one reflection/refraction ray into FIFO                
                    RefInput = ref_input_data;                                
                    ref_fifo_full = 1;
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
                    if (ref_fifo_full) begin                        
                        out = RefInput;                  
                        ref_fifo_full <= 0;
                        InvDir_Strobe <= 1;
                        NextState <= RGS_Generate;                                                
                    end                                                                        
                    else if (fifo_full) begin                        
                        out = Input;
                        fifo_full <= 0;                            
                        InvDir_Strobe <= 1;
                        NextState <= RGS_Generate;                                                
                    end                             
                end

				(RGS_Generate): begin                    
                    InvDir_Strobe <= 0;
                    if (InvDir_Valid) begin                          
                        out.RasterRay.InvDir <= InvDir;                                                                        
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

    // Compute inverse direction of ray
    Fixed3_Inv_V3 DIR_INV(
		.clk(clk),
        .resetn(resetn),
		.strobe(InvDir_Strobe),
		.v(out.RasterRay.Dir), 
		.valid(InvDir_Valid),
		.ov(InvDir)
	);    
    
endmodule
