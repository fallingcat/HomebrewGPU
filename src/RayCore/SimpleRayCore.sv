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
module SimpleCombineOutput ( 
    input clk,
    input valid,
    input Fixed3 light_dir, 
    input Fixed3 light_invdir,             
    input RasterInputData input_data,
    input HitData hit_data,    
    output RasterOutputData out
    );
    always_ff @(posedge clk) begin
        if (valid) begin
            out.x <= input_data.x;
            out.y <= input_data.y;                                 
            out.bHit <= hit_data.bHit;                                                            
            out.VI <= hit_data.VI;            
        end        
    end
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module SimpleRasterUnit (      
    input clk,
    input resetn,    

    // controls... 
    input add_input,

    // inputs...
    input RasterInputData input_data,            
    input RenderState rs,    
    input BVH_Primitive p[`BVH_AABB_TEST_UNIT_SIZE],
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
    HitData PHitData, FinalHitData, HitData;	    
       
    PrimitiveGroupFIFO PrimitiveFIFO;	
	logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] StartPrimitiveIndex, EndPrimitiveIndex, RealEndPrimitiveIndex, AlignedNumPrimitives;    
    logic ResetFinalHitData;    
    
    Fixed3 D;
    
    //-------------------------------------------------------------------
    //
    //-------------------------------------------------------------------    
	function NexPrimitiveData;
        StartPrimitiveIndex = StartPrimitiveIndex + `BVH_AABB_TEST_UNIT_SIZE;       
	endfunction   
    //-------------------------------------------------------------------
    //
    //-------------------------------------------------------------------    
	function DequeuePrimitiveGroup;		
		StartPrimitiveIndex = PrimitiveFIFO.Groups[PrimitiveFIFO.Top].StartPrimitive;                
        AlignedNumPrimitives = PrimitiveFIFO.Groups[PrimitiveFIFO.Top].NumPrimitives;
        RealEndPrimitiveIndex = StartPrimitiveIndex + AlignedNumPrimitives;

        if (`BVH_AABB_TEST_UNIT_SIZE_WIDTH >= 1) begin
            if (AlignedNumPrimitives[`BVH_AABB_TEST_UNIT_SIZE_WIDTH-1:0] != 0) begin
                AlignedNumPrimitives = (((AlignedNumPrimitives >> `BVH_AABB_TEST_UNIT_SIZE_WIDTH) + 1) << `BVH_AABB_TEST_UNIT_SIZE_WIDTH);
            end
        end

		EndPrimitiveIndex = StartPrimitiveIndex + AlignedNumPrimitives;        
		PrimitiveFIFO.Top = PrimitiveFIFO.Top + 1;        
	endfunction    

    //-------------------------------------------------------------------
    //
    //-------------------------------------------------------------------    
    function QueueReflectiveBoxAndGround();
        PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].StartPrimitive = `BVH_MODEL_RAW_DATA_SIZE;
        PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].NumPrimitives = 3;		    
        PrimitiveFIFO.Bottom = PrimitiveFIFO.Bottom + 1;
    endfunction  

    
    assign start_primitive = StartPrimitiveIndex;  
    assign end_primitive = RealEndPrimitiveIndex;  

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
                        ResetFinalHitData <= 1;                        

                        PrimitiveFIFO.Top = 0;			
                        PrimitiveFIFO.Bottom = 0;			
                        StartPrimitiveIndex = 0;
                        EndPrimitiveIndex = 0;             
                        RealEndPrimitiveIndex = 0;                                   
                        QueueReflectiveBoxAndGround();    
                        NextState <= RASTS_Rasterize;                                                   
                    end                    
                end   
                
                (RASTS_Rasterize): begin        
                    ResetFinalHitData <= 0;                                                                                
                    valid <= 0;                                                    
                    
                    if (StartPrimitiveIndex != EndPrimitiveIndex) begin			                        
                        NexPrimitiveData();						                                            
                    end
                    else begin
                        if (PrimitiveFIFO.Top != PrimitiveFIFO.Bottom) begin
                            DequeuePrimitiveGroup();                                                    
                        end
                        else begin
                            NextState <= RASTS_Done;                            
                        end                    
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
    
    RayUnitV3_FindClosestHit RU(
    	.r(CurrentInput.RasterRay), 		
		.p(p),
		.hit_data(PHitData)		
	);    

    SetupFinalHitData SETUPHITDATA( 
        .clk(clk),	         
        .reset(ResetFinalHitData),        
        .color(rs.ClearColor),                
        .hit_data(PHitData),        
        .final_hit_data(FinalHitData)     
    );    

    SimpleCombineOutput CO (   
        .clk(clk),
        .valid(NextState == RASTS_Done),
        .light_dir(rs.Light[0].Dir),
        .light_invdir(rs.Light[0].InvDir),
        .input_data(CurrentInput),
        .hit_data(FinalHitData),
        .out(out)
    );  

    Fixed3_Mul A1(FinalHitData.T, CurrentInput.RasterRay.Dir, D);
    Fixed3_Add A2(CurrentInput.RasterRay.Orig, D, out.HitPos);            
    
    Texture TX(
        .clk(clk),
        .strobe(NextState == RASTS_Done),
        .color(FinalHitData.Color),
        .pos(out.HitPos),
        .hit(FinalHitData.bHit),
        .vi(FinalHitData.VI),
        .out(out.Color)
    ); 
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module SimpleRaster (    
    input clk,
    input resetn,    

    // controls...         
    input add_input,
    input add_ref_input,

    // inputs...
    input RasterInputData input_data,                 
    input RasterInputData ref_input_data,            
    input RenderState rs,    
    input BVH_Primitive p[`BVH_AABB_TEST_UNIT_SIZE],
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

    SimpleRasterUnit RAS (    
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
module SimpleShadowingCombineOutput (     
    input clk,
    input valid, 
    input RasterOutputData input_data,
    input HitData hit_data,
    output ShadowingOutputData out
    );
    always_ff @(posedge clk) begin
        if (valid) begin
            //out.LastColor <= input_data.LastColor;
            //out.BounceLevel <= input_data.BounceLevel;
            out.x <= input_data.x;
            out.y <= input_data.y;                    
            //out.ViewDir <= input_data.ViewDir;
            out.bHit <= input_data.bHit;                    
            //out.VI <= input_data.VI;                    
            //out.HitPos <= input_data.HitPos;                    
            out.Color <= input_data.Color;
            //out.Normal <= input_data.Normal;
            //out.SurfaceType <= input_data.SurfaceType;                                        
            out.bShadow <= 0;            
        end        
    end
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module SimpleShadowingUnit (
    input clk,
    input resetn,

    // controls...         
    input add_input,

    // inputs...    
    input RasterOutputData input_data,    
    input RenderState rs,    
    input BVH_Primitive p[`BVH_AABB_TEST_UNIT_SIZE],
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
    HitData PHitData, FinalHitData;	        
        
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
    
    SimpleShadowingCombineOutput CO (     
        .clk(clk),
        .valid(NextState == SHDWS_Done), 
        .input_data(CurrentInput),
        .hit_data(FinalHitData),
        .out(out)
    );    
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module SimpleShadowing (
    input clk,
    input resetn,

    // controls... 
    input add_input,

    // inputs...
    input RasterOutputData input_data,    
    input RenderState rs,    
    input output_fifo_full,	    
    input BVH_Primitive p[`BVH_AABB_TEST_UNIT_SIZE],

    // outputs...  
    output logic fifo_full,
    output logic valid,
    output ShadowingOutputData out,
    output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start_primitive,
	output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] end_primitive    
    );

    logic SRGEN_Valid, SHDW_FIFO_Full; 
    RasterOutputData SRGEN_Output;    

    SimpleShadowingUnit SHDW (
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
module SimpleShaderCombineOutput (    
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

            //out.Color <= input_data.Color;            
            
            if (input_data.bShadow) begin
                out.Color.Channel[0] <= input_data.Color.Channel[0] >> 1;
                out.Color.Channel[1] <= input_data.Color.Channel[1] >> 1;
                out.Color.Channel[2] <= input_data.Color.Channel[2] >> 1;
            end                     
            else begin
                out.Color <= input_data.Color;
            end                                                       
        end        
    end    
    
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module SimpleShader(   
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
module SimpleRayCore(    
    input clk,
	input resetn,        	

    // controls... 
    input logic add_input,

    // inputs...    
    input RasterInputData input_data,        
    input RenderState rs,
    input BVH_Primitive p0[`BVH_AABB_TEST_UNIT_SIZE],
    input BVH_Primitive p1[`BVH_AABB_TEST_UNIT_SIZE],
        
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
    SimpleRaster RAS (    
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

    SimpleShadowing SHDW (
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

    SimpleShader SHDR (
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