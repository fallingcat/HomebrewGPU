//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/14 17:55:28
// Design Name: 
// Module Name: RayCore
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

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module BasicCombineOutput ( 
    input clk,
    input valid,
    input Fixed3 light_dir, 
    input Fixed3 light_invdir,             
    input SurfaceInputData input_data,    
    output SurfaceOutputData out
    );
    always_ff @(posedge clk) begin
        if (valid) begin
            out.x <= input_data.x;
            out.y <= input_data.y;                                 
            out.Color.Channel[0] <= input_data.SurfaceRay.Dir.Dim[0].Value >> 8;
            out.Color.Channel[1] <= input_data.SurfaceRay.Dir.Dim[1].Value >> 8;
            out.Color.Channel[2] <= input_data.SurfaceRay.Dir.Dim[2].Value >> 8;            
        end        
    end
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module BasicSurfaceUnit (      
    input clk,
    input resetn,    

    // controls... 
    input add_input,

    // inputs...
    input SurfaceInputData input_data,            
    input RenderState rs,    
    input Primitive_AABB p[`AABB_TEST_UNIT_SIZE],
    input output_fifo_full,	    

    // outputs...  
    output logic fifo_full,        
    output logic valid,
    output SurfaceOutputData out,           
    output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start_primitive,
	output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] end_primitive    
    );       
    
    SurfaceState State, NextState = SURFS_Init;         
    SurfaceInputData Input, CurrentInput;    
    logic [3:0] DelayCounter; 
        
    initial begin	        
        fifo_full <= 0;
        NextState <= SURFS_Init;
	end	    

    always_ff @(posedge clk, negedge resetn) begin
        if (!resetn) begin
            fifo_full <= 0; 
            NextState <= SURFS_Init;
        end
        else begin           
            // If ray FIFO is not full
            if (!fifo_full) begin        
                if (add_input) begin
                    // Add one ray into ray FIFO                
                    Input = input_data;                                
                    fifo_full = 1;                            
                end               
            end                                            

            State = NextState;
            case (State)
                (SURFS_Init): begin    
                    valid <= 0;
                    if (fifo_full) begin                        
                        CurrentInput = Input;                  
                        fifo_full <= 0;
                        NextState <= SURFS_Surfacing;                                                   
                    end                    
                end   
                
                (SURFS_Surfacing): begin        
                    DelayCounter = DelayCounter + 1;
                    if (DelayCounter == 0) begin
                        NextState <= SURFS_Done;                        
                    end                    
                end                        

                (SURFS_Done): begin
                    if (!output_fifo_full) begin
                        valid <= 1;                                  
                        NextState <= SURFS_Init;            
                    end                    
                end
                
                default: begin
                    NextState <= SURFS_Init;
                end            
            endcase                
        end        
    end        

    BasicCombineOutput CO (   
        .clk(clk),
        .valid(NextState == SURFS_Done),
        .light_dir(rs.Light[0].Dir),
        .light_invdir(rs.Light[0].InvDir),
        .input_data(CurrentInput),        
        .out(out)
    );      
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module BasicSurface (    
    input clk,
    input resetn,    

    // controls...         
    input add_input,
    input add_ref_input,

    // inputs...
    input SurfaceInputData input_data,                 
    input SurfaceInputData ref_input_data,            
    input RenderState rs,    
    input Primitive_AABB p[`AABB_TEST_UNIT_SIZE],
    input output_fifo_full,	    

    // outputs...  
    output logic fifo_full,        
    output logic ref_fifo_full,        
    output logic valid,
    output SurfaceOutputData out,           
    output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start_primitive,
	output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] end_primitive    
    );       

    logic RGEN_Valid, SURF_FIFO_Full;
    SurfaceInputData RGEN_Output;    

    SurfaceRayGeneratorV4 RGEN (
        .clk(clk),
        .resetn(resetn),	
        .add_input(add_input),	    
        .input_data(input_data),                                
        .fifo_full(fifo_full),
        .add_ref_input(add_ref_input),	    
        .ref_input_data(ref_input_data),                                
        .ref_fifo_full(ref_fifo_full),        
        .output_fifo_full(SURF_FIFO_Full),
        .valid(RGEN_Valid),
        .out(RGEN_Output)        
    );

    BasicSurfaceUnit SURF (    
        .clk(clk),
        .resetn(resetn),
        .add_input(RGEN_Valid),
        .input_data(RGEN_Output),        
        .rs(rs),        
        .output_fifo_full(output_fifo_full),
        .valid(valid),
        .out(out),
        .fifo_full(SURF_FIFO_Full),
        .start_primitive(start_primitive),
        .end_primitive(end_primitive),
        .p(p)
    );
endmodule

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module BasicShadowCombineOutput (     
    input clk,
    input valid, 
    input SurfaceOutputData input_data,    
    output ShadowOutputData out
    );
    always_ff @(posedge clk) begin
        if (valid) begin
            out.x <= input_data.x;
            out.y <= input_data.y;                    
            out.Color <= input_data.Color;            
        end        
    end
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module BasicShadowUnit (
    input clk,
    input resetn,

    // controls...         
    input add_input,

    // inputs...    
    input SurfaceOutputData input_data,    
    input RenderState rs,    
    input Primitive_AABB p[`AABB_TEST_UNIT_SIZE],
    input output_fifo_full,	    

    // outputs...      
    output logic fifo_full,
    output logic valid,
    output ShadowOutputData out,    
    output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start_primitive,
	output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] end_primitive    
    );

    ShadowState State, NextState = SHDWS_Init;     

    SurfaceOutputData Input, CurrentInput;

    initial begin	        
        fifo_full <= 0;
        NextState <= SHDWS_Init;
	end	   
    
    always_ff @(posedge clk, negedge resetn) begin
        if (!resetn) begin
            fifo_full <= 0;
            NextState <= SHDWS_Init;
        end
        else begin           
            // If ray FIFO is not full
            if (!fifo_full) begin        
                if (add_input) begin
                    // Add one ray into ray FIFO                
                    Input = input_data;                                                    
                    fifo_full = 1;
                end               
            end                                   

            State = NextState;
            case (State)
                SHDWS_Init: begin    
                    valid <= 0;
                    if (fifo_full) begin                        
                        CurrentInput = Input;                  
                        fifo_full <= 0;
                        NextState <= SHDWS_Done;                        
                    end                    
                end                  
                               
                SHDWS_Done: begin                   
                    if (!output_fifo_full) begin
                        valid <= 1;                            
                        NextState <= SHDWS_Init;            
                    end                    
                end
                
                default: begin
                    NextState <= SHDWS_Init;
                end            
            endcase                
        end        
    end            
    
    BasicShadowCombineOutput CO (     
        .clk(clk),
        .valid(NextState == SHDWS_Done), 
        .input_data(CurrentInput),        
        .out(out)
    );    
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module BasicShadow (
    input clk,
    input resetn,

    // controls... 
    input add_input,

    // inputs...
    input SurfaceOutputData input_data,    
    input RenderState rs,    
    input output_fifo_full,	    
    input Primitive_AABB p[`AABB_TEST_UNIT_SIZE],

    // outputs...  
    output logic fifo_full,
    output logic valid,
    output ShadowOutputData out,
    output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start_primitive,
	output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] end_primitive    
    );

    logic SRGEN_Valid, SHDW_FIFO_Full; 
    SurfaceOutputData SRGEN_Output;    

    BasicShadowUnit SHDW (
        .clk(clk),
        .resetn(resetn),
        .add_input(add_input),
        .input_data(input_data),        
        .rs(rs),        
        .output_fifo_full(output_fifo_full),
        .valid(valid),
        .out(out),
        .fifo_full(fifo_full),
        .start_primitive(start_primitive),
        .end_primitive(end_primitive),
        .p(p)    
    );    
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module BasicShadeCombineOutput (    
    input clk,
    input valid,  
    input ShadowOutputData input_data,    
    input FixedNorm3 l,          
    output ShadeOutputData out
    );
    FixedNorm Diffuse;            

    always_ff @(posedge clk) begin
        if (valid) begin
            out.x <= input_data.x;
            out.y <= input_data.y;        
            out.Color <= input_data.Color;                        
        end        
    end    
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module BasicShade(   
    input clk,
    input resetn,    

    // controls...     
    input add_input,

    // inputs...
    input ShadowOutputData input_data,    
    input RenderState rs,          
    input logic output_fifo_full,

    // outputs...      
    output logic fifo_full,
    output logic valid,
    output ShadeOutputData out,    
    output logic ref_valid,
    output SurfaceInputData ref_out   
    );

    ShadeState State, NextState = SS_Init;
    ShadowOutputData Input, CurrentInput;    
    
    initial begin	        
        fifo_full <= 0;
        NextState <= SS_Init;
	end	   

    always @(posedge clk, negedge resetn) begin
        if (!resetn) begin
            fifo_full <= 0;
            NextState <= SS_Init;
        end
        else begin
            if (add_input) begin
                if (!fifo_full) begin                        
                    Input = input_data;
                    fifo_full = 1;                                            
                end               
            end    

            State = NextState;         

            case (State)
                (SS_Init): begin
                    valid <= 0;
                    ref_valid <= 0;                    
                    if (fifo_full) begin                        
                        CurrentInput <= Input;                  
                        fifo_full <= 0;                      
                        NextState <= SS_Done;   
                    end                                                            
                end                
               
                SS_Done: begin
                    if (!output_fifo_full) begin
                        valid <= 1;
                        ref_valid <= 0;
                        NextState <= SS_Init;            
                    end                                        
                end

                default: begin
                    valid <= 0;
                    ref_valid <= 0;
                    NextState <= SS_Init;
                end
            endcase            
        end        
    end   

    SimpleShadeCombineOutput CO (
        .clk(clk),
        .valid(NextState == SS_Done),
        .input_data(CurrentInput),
        .l(rs.Light[0].NormDir),
        .out(out)
    );    
endmodule

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module BasicRayCore(    
    input clk,
	input resetn,        	

    // controls... 
    input logic add_input,

    // inputs...    
    input SurfaceInputData input_data,        
    input RenderState rs,
    input Primitive_AABB p0[`AABB_TEST_UNIT_SIZE],
    input Primitive_AABB p1[`AABB_TEST_UNIT_SIZE],
        
    // outputs...  
    output logic fifo_full,        
    output logic valid,
    output ShadeOutputData shade_out,
    output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start_primitive_0,
	output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] end_primitive_0,	    
    output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start_primitive_1,
	output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] end_primitive_1		
    );       
        
    logic SURF_Valid, SURF_REF_FIFO_Full;
    SurfaceOutputData SURF_Output;    

    logic SHDW_Valid, SHDW_FIFO_Full;   
    ShadowOutputData SHDW_Output;          
     
    logic SHAD_Valid, SHAD_FIFO_Full;

    logic SHAD_REF_Valid;
    SurfaceInputData SHAD_REF_Output;
	
	
    // 3 pipeline stages : SURF -> SHDW -> SHAD, the SHAD output will be redirected back to SURF for trflection
    // For example : SURF -> SHDW -> SHAD -> SURF -> SHDW -> SHAD -> SURF -> SHDW -> SHAD -> Frame Buffer for 3 bounces
    BasicSurface SURF (    
        .clk(clk),
        .resetn(resetn),
        .add_input(add_input),
        .input_data(input_data),        
        .fifo_full(fifo_full),
        .add_ref_input(SHAD_REF_Valid),
        .ref_input_data(SHAD_REF_Output),        
        .ref_fifo_full(SURF_REF_FIFO_Full),
        .rs(rs),        
        .output_fifo_full(SHDW_FIFO_Full),
        .valid(SURF_Valid),
        .out(SURF_Output),        
        .start_primitive(start_primitive_0),
        .end_primitive(end_primitive_0),
        .p(p0)
    );

    BasicShadow SHDW (
        .clk(clk),
        .resetn(resetn),
        .add_input(SURF_Valid),
        .input_data(SURF_Output),        
        .rs(rs),        
        .output_fifo_full(SHAD_FIFO_Full),
        .valid(SHDW_Valid),
        .out(SHDW_Output),
        .fifo_full(SHDW_FIFO_Full),
        .start_primitive(start_primitive_1),
        .end_primitive(end_primitive_1),
        .p(p1)    
    );         

    BasicShade SHAD (
        .clk(clk),
        .resetn(resetn),
        .add_input(SHDW_Valid),
        .input_data(SHDW_Output),        
        .fifo_full(SHAD_FIFO_Full),
        .rs(rs),                
        .valid(valid),
        .out(shade_out),        
        .ref_valid(SHAD_REF_Valid),
        .ref_out(SHAD_REF_Output),
        .output_fifo_full(SURF_REF_FIFO_Full)        
    );            
endmodule