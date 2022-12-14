//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/23 16:22:44
// Design Name: 
// Module Name: Lighting
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
`include "../../Primitive/PrimitiveFIFOUtil.sv"

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module _ShadowOutput (    
    input strobe,    
    input SurfaceOutputData input_data,
    input shadow,
    output ShadowOutputData out
    );

    always_comb begin    
        if (strobe) begin
            out.LastColor <= input_data.LastColor;
            out.BounceLevel <= input_data.BounceLevel;
            out.x <= input_data.x;
            out.y <= input_data.y;                    
            out.ViewDir <= input_data.ViewDir;
            out.PI <= input_data.PI;                    
            out.HitPos <= input_data.HitPos;                    
            out.Color <= input_data.Color;
            out.Normal <= input_data.Normal;
            out.SurfaceType <= input_data.SurfaceType;                    
            out.bShadow <= shadow;                           
        end        
    end
endmodule
//-------------------------------------------------------------------
// Do BVH traversal and find the primitives which may have possible hit.
// Then use Ray unit to find the any hit.
// Finally decide if the fragment is in shadow or not.
//-------------------------------------------------------------------    
module ShadowUnit (
    input clk,
    input resetn,

    // controls...         
    input add_input,

    // inputs...    
    input SurfaceOutputData input_data,    
    input RenderState rs,    
    input output_fifo_full,	    

    input Primitive_AABB aabb[`AABB_TEST_UNIT_SIZE],
    input Primitive_Sphere sphere[`SPHERE_TEST_UNIT_SIZE],
    input BVH_Node node,    
    input BVH_Leaf leaf[2],        

    // outputs...      
    output logic fifo_full,
    output logic valid,
    output ShadowOutputData out,    

    output PrimitiveQueryData aabb_query,    
    output PrimitiveQueryData sphere_query,    

    output logic [`BVH_NODE_INDEX_WIDTH-1:0] node_index
    );

    ShadowState State, NextState = SHDWS_Init;     

    SurfaceOutputData Input, CurrentInput;
    logic CurrentHit, AnyHit;
        
    // Result of BVH traversal. Queue the resullt to PrimitiveFIFO for later processing.
    logic BU_Strobe, BU_Valid, BU_Finished, BU_RestartStrobe;        
    logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] LeafStartPrim[2];
    logic [`BVH_PRIMITIVE_AMOUNT_WIDTH-1:0] LeafNumPrim[2]; 

    // Store the primitive groups data. Each group present a range of primitives
    // which may have possible hit.
    PrimitiveGroupFIFO PrimitiveFIFO[`NUM_PRIMITIVE_TYPES];	    
    logic PrimitiveFIFOEmpty;
    logic FIFOFull = 1'b0;

    assign fifo_full = FIFOFull;    
        
    initial begin
        PrimitiveFIFO_QueueGlobalPrimitives(PrimitiveFIFO[PT_AABB], PrimitiveFIFO[PT_Sphere]);
    end

    always_ff @(posedge clk, negedge resetn) begin
        if (!resetn) begin
            FIFOFull <= 0;
            NextState <= SHDWS_Init;
        end
        else begin           
            // If ray FIFO is not full
            if (!FIFOFull) begin        
                if (add_input) begin
                    // Add one ray into ray FIFO                
                    Input = input_data;                                                    
                    FIFOFull = 1;
                end               
            end         

            // Queue possible hit primitives if there is any from BVH Unit.              
            PrimitiveFIFO_QueuePrimitiveGroup(
                BU_Valid,                 
                LeafStartPrim, 
                LeafNumPrim, 
                PrimitiveFIFO[PT_AABB]
            );                          

            State = NextState;
            case (State)
                SHDWS_Init: begin    
                    valid <= 0;
                    BU_Strobe <= 0;
                    BU_RestartStrobe <= 0;  
                    
                    if (FIFOFull) begin                        
                        CurrentInput = Input;                  
                        FIFOFull <= 0;

                        AnyHit <= 0;
                            
                        // Reset primitive FIFO
                        PrimitiveFIFO[PT_AABB].Top = 0;			
                        PrimitiveFIFO[PT_AABB].Bottom = 1;	                        
                        PrimitiveFIFO[PT_Sphere].Top = 0;			
                        PrimitiveFIFO[PT_Sphere].Bottom = 1;			                       
                        PrimitiveFIFOEmpty = 0;
                        
                        if (CurrentInput.SurfaceType == ST_None) begin    
                            // No need to process shadowing as this fragment hits nothing.
                            NextState <= SHDWS_Done;                            
                        end
                        else begin       
                            // Init BVH traversal
                            BU_Strobe <= 1;                                                                                                    
                            NextState <= SHDWS_AnyHit;          
                        end                                                                                                
                    end                    
                end   
                
                SHDWS_AnyHit: begin
                    valid <= 0;                    
                    BU_Strobe <= 0;    
                    
                    if (CurrentHit) begin
                        // If there is any hit, shadowing is done.
                        AnyHit <= 1;
                        BU_Strobe <= 0;
                        BU_RestartStrobe <= 1;
                        NextState <= SHDWS_Done;  
                    end			                 
                    else begin         
                        // Fetch primitives
                        PrimitiveFIFO_Fetch(PrimitiveFIFOEmpty, PrimitiveFIFO[PT_AABB], PrimitiveFIFO[PT_Sphere]);

                        aabb_query.StartIndex    = PrimitiveFIFO[PT_AABB].StartPrimitiveIndex;
                        aabb_query.EndIndex      = PrimitiveFIFO[PT_AABB].EndPrimitiveIndex;
                        sphere_query.StartIndex  = PrimitiveFIFO[PT_Sphere].StartPrimitiveIndex;
                        sphere_query.EndIndex    = PrimitiveFIFO[PT_Sphere].EndPrimitiveIndex;                        
                        
                        // If all primitives have been processed
                        if (BU_Finished && PrimitiveFIFOEmpty) begin
                            NextState <= SHDWS_Done;
                        end                                            
                    end
                end

                SHDWS_WaitNext: begin                   
                    NextState <= SHDWS_AnyHit;
                end

                SHDWS_Done: begin            
                    BU_Strobe <= 0;
                    BU_RestartStrobe <= 1;
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
    
    // Traverse BVH tree and find the possible hit primitives 
    BVHUnit BU(         
        .clk(clk),	 
        .resetn(resetn),
        .strobe(BU_Strobe),    
        .restart_strobe(BU_RestartStrobe),
        .offset(rs.PositionOffset),
        .r(CurrentInput.ShadowRay),

        .start_prim(LeafStartPrim),    
        .num_prim(LeafNumPrim),        

        .node_index(node_index),        
        .node(node),        
        .leaf(leaf),

        .valid(BU_Valid),
        .finished(BU_Finished)        
    );
    
    // Find any hit from all possible primitives
    RayUnit_FindAnyHit RU(            
		.r(CurrentInput.ShadowRay), 		
		.aabb(aabb),
        .sphere(sphere),
		.out_hit(CurrentHit)		
	);   

    // Setup output for next stage
    _ShadowOutput CO(         
        .strobe(NextState == SHDWS_Done && !output_fifo_full),         
        .input_data(CurrentInput),
        .shadow(AnyHit),
        .out(out)
    );    
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module PassOverShadowUnit (
    input clk,
    input resetn,

    // controls...         
    input add_input,

    // inputs...    
    input SurfaceOutputData input_data,    
    input RenderState rs,    
    input output_fifo_full,	    
    
    input Primitive_AABB aabb[`AABB_TEST_UNIT_SIZE],
    input Primitive_Sphere sphere[`SPHERE_TEST_UNIT_SIZE],
    input BVH_Node node,    
    input BVH_Leaf leaf[2],               

    // outputs...      
    output logic fifo_full,
    output logic valid,
    output ShadowOutputData out,  

    output PrimitiveQueryData aabb_query,  
    output PrimitiveQueryData sphere_query,

    output logic [`BVH_NODE_INDEX_WIDTH-1:0] node_index               
    );

    ShadowState State, NextState = SHDWS_Init;     
    SurfaceOutputData Input, CurrentInput;
    logic CurrentHit, AnyHit;
    logic FIFOFull = 1'b0;
    
    assign fifo_full = FIFOFull;

    always_ff @(posedge clk, negedge resetn) begin
        if (!resetn) begin
            FIFOFull <= 0;
            NextState <= SHDWS_Init;
        end
        else begin           
            // If ray FIFO is not full
            if (!FIFOFull) begin        
                if (add_input) begin
                    // Add one ray into ray FIFO                
                    Input = input_data;                                                    
                    FIFOFull = 1;
                end               
            end                                   

            State = NextState;
            case (State)
                SHDWS_Init: begin    
                    valid <= 0;
                    if (FIFOFull) begin                        
                        CurrentInput = Input;                  
                        FIFOFull <= 0;
                        AnyHit <= 0;                        
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
    
    // Setup output for next stage
    _ShadowOutput CO (         
        .strobe(NextState == SHDWS_Done && !output_fifo_full),         
        .input_data(CurrentInput),
        .shadow(AnyHit),
        .out(out)
    );
    
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module Shadow(
    input clk,
    input resetn,

    // controls... 
    input add_input,

    // inputs...
    input SurfaceOutputData input_data,    
    input RenderState rs,    
    input output_fifo_full,	    
    input Primitive_AABB aabb[`AABB_TEST_UNIT_SIZE],
    input Primitive_Sphere sphere[`SPHERE_TEST_UNIT_SIZE],
    input BVH_Node node,    
    input BVH_Leaf leaf[2],           

    // outputs...  
    output logic fifo_full,
    output logic valid,
    output ShadowOutputData out,

    output PrimitiveQueryData aabb_query,
    output PrimitiveQueryData sphere_query,

    output logic [`BVH_NODE_INDEX_WIDTH-1:0] node_index            
    );

    logic SRGEN_Valid, SHDW_FIFO_Full; 
    SurfaceOutputData SRGEN_Output;    


`ifdef IMPLEMENT_SHADOWING
    ShadowUnit SHDW(
        .clk(clk),
        .resetn(resetn),

        .add_input(add_input),
        .input_data(input_data),        

        .rs(rs),        
        .output_fifo_full(output_fifo_full),        
        .valid(valid),
        .out(out),
        .fifo_full(fifo_full),

        .aabb_query(aabb_query),
        .aabb(aabb),
        .sphere(sphere),

        .node_index(node_index),
        .node(node),
        .leaf(leaf)    
    );
`else
    PassOverShadowUnit SHDW(
        .clk(clk),
        .resetn(resetn),
        .add_input(add_input),
        .input_data(input_data),        
        .rs(rs),        
        .output_fifo_full(output_fifo_full),
        .valid(valid),
        .out(out),
        .fifo_full(fifo_full),

        .aabb_query(aabb_query),
        .aabb(aabb),

        .sphere_query(sphere_query),
        .sphere(sphere),

        .node_index(node_index),
        .node(node),
        .leaf(leaf)    
    );
`endif

endmodule