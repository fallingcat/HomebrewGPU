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
    input RasterInputData input_data,    
    output RasterOutputData out
    );
    always_ff @(posedge clk) begin
        if (valid) begin
            out.x <= input_data.x;
            out.y <= input_data.y;                                 
            out.Color.Channel[0] <= input_data.RasterRay.Dir.Dim[0].Value >> 8;
            out.Color.Channel[1] <= input_data.RasterRay.Dir.Dim[1].Value >> 8;
            out.Color.Channel[2] <= input_data.RasterRay.Dir.Dim[2].Value >> 8;            
        end        
    end
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module BasicRasterUnit (      
    input clk,
    input resetn,    

    // controls... 
    input add_input,

    // inputs...
    input RasterInputData input_data,            
    input RenderState rs,    
    input BVH_Primitive_AABB p[`BVH_AABB_TEST_UNIT_SIZE],
    input output_fifo_full,	    

    // outputs...  
    output logic fifo_full,        
    output logic valid,
    output RasterOutputData out,           
    output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start_primitive,
	output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] end_primitive    
    );       
    
    RasterState State, NextState = RASTS_Init;         
    RasterInputData Input, CurrentInput;    
    logic [3:0] DelayCounter; 
        
    initial begin	        
        fifo_full <= 0;
        NextState <= RASTS_Init;
	end	    

    always_ff @(posedge clk, negedge resetn) begin
        if (!resetn) begin
            fifo_full <= 0; 
            NextState <= RASTS_Init;
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
                (RASTS_Init): begin    
                    valid <= 0;
                    if (fifo_full) begin                        
                        CurrentInput = Input;                  
                        fifo_full <= 0;
                        NextState <= RASTS_Rasterize;                                                   
                    end                    
                end   
                
                (RASTS_Rasterize): begin        
                    DelayCounter = DelayCounter + 1;
                    if (DelayCounter == 0) begin
                        NextState <= RASTS_Done;                        
                    end                    
                end                        

                (RASTS_Done): begin
                    if (!output_fifo_full) begin
                        valid <= 1;                                  
                        NextState <= RASTS_Init;            
                    end                    
                end
                
                default: begin
                    NextState <= RASTS_Init;
                end            
            endcase                
        end        
    end        

    BasicCombineOutput CO (   
        .clk(clk),
        .valid(NextState == RASTS_Done),
        .light_dir(rs.Light[0].Dir),
        .light_invdir(rs.Light[0].InvDir),
        .input_data(CurrentInput),        
        .out(out)
    );      
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module BasicRaster (    
    input clk,
    input resetn,    

    // controls...         
    input add_input,
    input add_ref_input,

    // inputs...
    input RasterInputData input_data,                 
    input RasterInputData ref_input_data,            
    input RenderState rs,    
    input BVH_Primitive_AABB p[`BVH_AABB_TEST_UNIT_SIZE],
    input output_fifo_full,	    

    // outputs...  
    output logic fifo_full,        
    output logic ref_fifo_full,        
    output logic valid,
    output RasterOutputData out,           
    output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start_primitive,
	output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] end_primitive    
    );       

    logic RGEN_Valid, RAS_FIFO_Full;
    RasterInputData RGEN_Output;    

    RastaerRayGeneratorV4 RGEN (
        .clk(clk),
        .resetn(resetn),	
        .add_input(add_input),	    
        .input_data(input_data),                                
        .fifo_full(fifo_full),
        .add_ref_input(add_ref_input),	    
        .ref_input_data(ref_input_data),                                
        .ref_fifo_full(ref_fifo_full),        
        .output_fifo_full(RAS_FIFO_Full),
        .valid(RGEN_Valid),
        .out(RGEN_Output)        
    );

    BasicRasterUnit RAS (    
        .clk(clk),
        .resetn(resetn),
        .add_input(RGEN_Valid),
        .input_data(RGEN_Output),        
        .rs(rs),        
        .output_fifo_full(output_fifo_full),
        .valid(valid),
        .out(out),
        .fifo_full(RAS_FIFO_Full),
        .start_primitive(start_primitive),
        .end_primitive(end_primitive),
        .p(p)
    );
endmodule

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module BasicShadowingCombineOutput (     
    input clk,
    input valid, 
    input RasterOutputData input_data,    
    output ShadowingOutputData out
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
module BasicShadowingUnit (
    input clk,
    input resetn,

    // controls...         
    input add_input,

    // inputs...    
    input RasterOutputData input_data,    
    input RenderState rs,    
    input BVH_Primitive_AABB p[`BVH_AABB_TEST_UNIT_SIZE],
    input output_fifo_full,	    

    // outputs...      
    output logic fifo_full,
    output logic valid,
    output ShadowingOutputData out,    
    output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start_primitive,
	output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] end_primitive    
    );

    ShadowingState State, NextState = SHDWS_Init;     

    RasterOutputData Input, CurrentInput;

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
    
    BasicShadowingCombineOutput CO (     
        .clk(clk),
        .valid(NextState == SHDWS_Done), 
        .input_data(CurrentInput),        
        .out(out)
    );    
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module BasicShadowing (
    input clk,
    input resetn,

    // controls... 
    input add_input,

    // inputs...
    input RasterOutputData input_data,    
    input RenderState rs,    
    input output_fifo_full,	    
    input BVH_Primitive_AABB p[`BVH_AABB_TEST_UNIT_SIZE],

    // outputs...  
    output logic fifo_full,
    output logic valid,
    output ShadowingOutputData out,
    output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start_primitive,
	output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] end_primitive    
    );

    logic SRGEN_Valid, SHDW_FIFO_Full; 
    RasterOutputData SRGEN_Output;    

    BasicShadowingUnit SHDW (
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
module BasicShaderCombineOutput (    
    input clk,
    input valid,  
    input ShadowingOutputData input_data,    
    input FixedNorm3 l,          
    output ShaderOutputData out
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
module BasicShader(   
    input clk,
    input resetn,    

    // controls...     
    input add_input,

    // inputs...
    input ShadowingOutputData input_data,    
    input RenderState rs,          
    input logic output_fifo_full,

    // outputs...      
    output logic fifo_full,
    output logic valid,
    output ShaderOutputData out,    
    output logic ref_valid,
    output RasterInputData ref_out   
    );

    ShaderState State, NextState = SS_Init;
    ShadowingOutputData Input, CurrentInput;    
    
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

    SimpleShaderCombineOutput CO (
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
    input RasterInputData input_data,        
    input RenderState rs,
    input BVH_Primitive_AABB p0[`BVH_AABB_TEST_UNIT_SIZE],
    input BVH_Primitive_AABB p1[`BVH_AABB_TEST_UNIT_SIZE],
        
    // outputs...  
    output logic fifo_full,        
    output logic valid,
    output ShaderOutputData shader_out,
    output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start_primitive_0,
	output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] end_primitive_0,	    
    output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start_primitive_1,
	output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] end_primitive_1		
    );       
        
    logic RAS_Valid, RAS_REF_FIFO_Full;
    RasterOutputData RAS_Output;    

    logic SHDW_Valid, SHDW_FIFO_Full;   
    ShadowingOutputData SHDW_Output;          
     
    logic SHDR_Valid, SHDR_FIFO_Full;

    logic SHDR_REF_Valid;
    RasterInputData SHDR_REF_Output;
	
	
    // 3 pipeline stages : RAS -> SHDW -> SHDR, the SHDR output will be redirected back to RAS for trflection
    // For example : RAS -> SHDW -> SHDR -> RAS -> SHDW -> SHDR -> RAS -> SHDW -> SHDR -> Frame Buffer for 3 bounces
    BasicRaster RAS (    
        .clk(clk),
        .resetn(resetn),
        .add_input(add_input),
        .input_data(input_data),        
        .fifo_full(fifo_full),
        .add_ref_input(SHDR_REF_Valid),
        .ref_input_data(SHDR_REF_Output),        
        .ref_fifo_full(RAS_REF_FIFO_Full),
        .rs(rs),        
        .output_fifo_full(SHDW_FIFO_Full),
        .valid(RAS_Valid),
        .out(RAS_Output),        
        .start_primitive(start_primitive_0),
        .end_primitive(end_primitive_0),
        .p(p0)
    );

    BasicShadowing SHDW (
        .clk(clk),
        .resetn(resetn),
        .add_input(RAS_Valid),
        .input_data(RAS_Output),        
        .rs(rs),        
        .output_fifo_full(SHDR_FIFO_Full),
        .valid(SHDW_Valid),
        .out(SHDW_Output),
        .fifo_full(SHDW_FIFO_Full),
        .start_primitive(start_primitive_1),
        .end_primitive(end_primitive_1),
        .p(p1)    
    );         

    BasicShader SHDR (
        .clk(clk),
        .resetn(resetn),
        .add_input(SHDW_Valid),
        .input_data(SHDW_Output),        
        .fifo_full(SHDR_FIFO_Full),
        .rs(rs),                
        .valid(valid),
        .out(shader_out),        
        .ref_valid(SHDR_REF_Valid),
        .ref_out(SHDR_REF_Output),
        .output_fifo_full(RAS_REF_FIFO_Full)        
    );            
endmodule