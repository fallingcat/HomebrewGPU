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

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module ShadowingCombineOutput (    
    input clk,
    input strobe,    
    input RasterOutputData input_data,
    input HitData hit_data,
    output ShadowingOutputData out
    );
    always_ff @(posedge clk) begin
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
            out.bShadow <= hit_data.bHit;                           
        end        
    end
endmodule
//-------------------------------------------------------------------
// Do BVH traversal and find the primitives which may have possible hit.
// Then use Ray unit to find the any hit.
// Finally decide if the fragment is in shadow or not.
//-------------------------------------------------------------------    
module ShadowingUnit (
    input clk,
    input resetn,

    // controls...         
    input add_input,

    // inputs...    
    input RasterOutputData input_data,    
    input RenderState rs,    
    input output_fifo_full,	    

    input BVH_Primitive_AABB p[`AABB_TEST_UNIT_SIZE],
    input BVH_Node node,    
    input BVH_Leaf leaf[2],        

    // outputs...      
    output logic fifo_full,
    output logic valid,
    output ShadowingOutputData out,    
    output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start_primitive,
	output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] end_primitive,
    output logic [`BVH_NODE_INDEX_WIDTH-1:0] node_index        
    );

    ShadowingState State, NextState = SHDWS_Init;     

    RasterOutputData Input, CurrentInput;

    HitData HitData;	       
        
    // Result of BVH traversal. Queue the resullt to PrimitiveFIFO for later processing.
    logic BU_Strobe, BU_Valid, BU_Finished, BU_RestartStrobe;        
    logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] LeafStartPrim[2];
    logic [`BVH_PRIMITIVE_AMOUNT_WIDTH-1:0] LeafNumPrim[2]; 

    // Store the primitive groups data. Each group present a range of primitives
    // which may have possible hit.
    PrimitiveGroupFIFO PrimitiveFIFO;	
	logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] StartPrimitiveIndex, EndPrimitiveIndex, RealEndPrimitiveIndex, AlignedNumPrimitives;

    //-------------------------------------------------------------------
    //
    //-------------------------------------------------------------------    
    function NextPrimitiveData;
        StartPrimitiveIndex = StartPrimitiveIndex + `AABB_TEST_UNIT_SIZE;       
	endfunction    
    //-------------------------------------------------------------------
    //
    //-------------------------------------------------------------------    
    function QueuePrimitiveGroup;	
        for (int i = 0; i < 2; i = i + 1) begin
            if (LeafNumPrim[i] > 0) begin
                PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].StartPrimitive = LeafStartPrim[i];
                PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].NumPrimitives = LeafNumPrim[i];		    
                PrimitiveFIFO.Bottom = PrimitiveFIFO.Bottom + 1;
            end            
        end                        
	endfunction   
    //-------------------------------------------------------------------
    //
    //-------------------------------------------------------------------    
	function DequeuePrimitiveGroup;		
		StartPrimitiveIndex = PrimitiveFIFO.Groups[PrimitiveFIFO.Top].StartPrimitive;                
        AlignedNumPrimitives = PrimitiveFIFO.Groups[PrimitiveFIFO.Top].NumPrimitives;
        RealEndPrimitiveIndex = StartPrimitiveIndex + AlignedNumPrimitives;

        if (`AABB_TEST_UNIT_SIZE_WIDTH >= 1) begin
            if (AlignedNumPrimitives[`AABB_TEST_UNIT_SIZE_WIDTH-1:0] != 0) begin
                AlignedNumPrimitives = (((AlignedNumPrimitives >> `AABB_TEST_UNIT_SIZE_WIDTH) + 1) << `AABB_TEST_UNIT_SIZE_WIDTH);
            end
        end

		EndPrimitiveIndex = StartPrimitiveIndex + AlignedNumPrimitives;        
		PrimitiveFIFO.Top = PrimitiveFIFO.Top + 1;        
	endfunction    
    //-------------------------------------------------------------------
    //
    //-------------------------------------------------------------------    
    function QueueGlobalPrimitives();
        PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].StartPrimitive = `BVH_MODEL_RAW_DATA_SIZE;
        PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].NumPrimitives = 3;		    
        PrimitiveFIFO.Bottom = PrimitiveFIFO.Bottom + 1;
    endfunction
    //-------------------------------------------------------------------
    //
    //-------------------------------------------------------------------    
    assign start_primitive = StartPrimitiveIndex;  
    assign end_primitive = RealEndPrimitiveIndex;  

    /*
    initial begin	        
        fifo_full <= 0;
        NextState <= SHDWS_Init;
	end	   
    */
    
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
                    BU_Strobe <= 0;
                    BU_RestartStrobe <= 0;                                        
                    if (fifo_full) begin                        
                        CurrentInput = Input;                  
                        fifo_full <= 0;

                        ClosestHitData.bHit <= 0;
                            
                        PrimitiveFIFO.Top = 0;			
                        PrimitiveFIFO.Bottom = 0;			
                        StartPrimitiveIndex = 0;
                        EndPrimitiveIndex = 0;             
                        RealEndPrimitiveIndex = 0;             
                        
                        if (CurrentInput.SurfaceType == ST_None) begin    
                            // Shadowing is done since the fragment is not a primitive.
                            NextState <= SHDWS_Done;                            
                        end
                        else begin       
                            // Init BVH traversal
                            BU_Strobe <= 1;                                                                        
                            QueueGlobalPrimitives();                                                            
                            NextState <= SHDWS_Rasterize;          
                        end                                                                                                
                    end                    
                end   
                
                SHDWS_Rasterize: begin
                    valid <= 0;                    
                    BU_Strobe <= 0;     

                    // Queue possible hit primitives.  
                    QueuePrimitiveGroup();               
                                        
                    if (HitData.bHit) begin
                        // If there is any hit, shadowing is done.
                        ClosestHitData.bHit <= HitData.bHit;
                        NextState <= SHDWS_Done;  
                    end			                 
                    else begin
                        if (StartPrimitiveIndex != EndPrimitiveIndex) begin			                        
                            // Process next batch of primitives.
                            NextPrimitiveData();						                                            
                        end
                        else begin
                            if (PrimitiveFIFO.Top != PrimitiveFIFO.Bottom) begin
                                // Dequeue possible hit primitives for any hit test.
                                DequeuePrimitiveGroup();                                 
                            end
                            else begin
                                if (BU_Finished) begin    
                                    // The fragment is not in shadow
                                    NextState <= SHDWS_Done;                                                                                             
                                end                            
                            end                    
                        end                                                                
                    end
                end      
                
                SHDWS_Done: begin                   
                    if (!output_fifo_full) begin
                        valid <= 1;          
                        BU_Strobe <= 0;
                        BU_RestartStrobe <= 1;    
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
        .r(CurrentInput.ShadowingRay),

        .start_prim(LeafStartPrim),    
        .num_prim(LeafNumPrim),        

        .node_index(node_index),        
        .node(node),        
        .leaf(leaf),

        .finished(BU_Finished)        
    );
    
    // Find any hit from all possible primitives
    RayUnit_FindAnyHit RU(            
		.r(CurrentInput.ShadowingRay), 		
		.p(p),
		.out_hit(HitData.bHit)		
	);   

    // Setup output for next stage
    ShadowingCombineOutput CO ( 
        .clk(clk),
        .strobe(NextState == SHDWS_Done),         
        .input_data(CurrentInput),
        .hit_data(HitData),
        .out(out)
    );    
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module PassOverShadowingUnit (
    input clk,
    input resetn,

    // controls...         
    input add_input,

    // inputs...    
    input RasterOutputData input_data,    
    input RenderState rs,    
    input output_fifo_full,	    
    
    input BVH_Primitive_AABB p[`AABB_TEST_UNIT_SIZE],
    input BVH_Node node,    
    input BVH_Leaf leaf[2],               

    // outputs...      
    output logic fifo_full,
    output logic valid,
    output ShadowingOutputData out,    
    output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start_primitive,
	output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] end_primitive,
    output logic [`BVH_NODE_INDEX_WIDTH-1:0] node_index               
    );

    ShadowingState State, NextState = SHDWS_Init;     

    RasterOutputData Input, CurrentInput;

    HitData HitData;	        
    
    /*
    initial begin	        
        fifo_full <= 0;
        NextState <= SHDWS_Init;
	end	   
    */
    
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
                        HitData.bHit <= 0;                        
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
    ShadowingCombineOutput CO ( 
        .clk(clk),
        .strobe(NextState == SHDWS_Done),         
        .input_data(CurrentInput),
        .hit_data(HitData),
        .out(out)
    );
    
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module Shadowing(
    input clk,
    input resetn,

    // controls... 
    input add_input,

    // inputs...
    input RasterOutputData input_data,    
    input RenderState rs,    
    input output_fifo_full,	    
    input BVH_Primitive_AABB p[`AABB_TEST_UNIT_SIZE],
    input BVH_Node node,    
    input BVH_Leaf leaf[2],           

    // outputs...  
    output logic fifo_full,
    output logic valid,
    output ShadowingOutputData out,
    output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start_primitive,
	output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] end_primitive,
    output logic [`BVH_NODE_INDEX_WIDTH-1:0] node_index            
    );

    logic SRGEN_Valid, SHDW_FIFO_Full; 
    RasterOutputData SRGEN_Output;    


`ifdef IMPLEMENT_SHADOWING
    ShadowingUnit SHDW(
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
        .p(p),

        .node_index(node_index),
        .node(node),
        .leaf(leaf)    
    );
`else
    PassOverShadowingUnit SHDW(
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
        .p(p),

        .node_index(node_index),
        .node(node),
        .leaf(leaf)    
    );
`endif

endmodule