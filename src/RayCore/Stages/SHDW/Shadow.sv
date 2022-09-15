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

    input BVH_Primitive_AABB p[`AABB_TEST_UNIT_SIZE],
    input BVH_Node node,    
    input BVH_Leaf leaf[2],        

    // outputs...      
    output logic fifo_full,
    output logic valid,
    output ShadowOutputData out,    

    output PrimitiveQueryData primitive_query,    

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
    PrimitiveGroupFIFO PrimitiveFIFO;	
	PrimitiveType CurrentPrimitiveType;
	logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] StartPrimitiveIndex, EndPrimitiveIndex, RealEndPrimitiveIndex, AlignedNumPrimitives;    
    logic FIFOFull = 1'b0;

    //-------------------------------------------------------------------
    //
    //-------------------------------------------------------------------    
	function void NextPrimitiveData;
        StartPrimitiveIndex = StartPrimitiveIndex + `AABB_TEST_UNIT_SIZE;       
	endfunction    
    //-------------------------------------------------------------------
    //
    //-------------------------------------------------------------------    
    function void QueuePrimitiveGroup;	
        for (int i = 0; i < 2; i = i + 1) begin
            if (LeafNumPrim[i] > 0) begin
                PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].PrimType = PT_AABB;
                PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].StartPrimitive = LeafStartPrim[i];
                PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].NumPrimitives = LeafNumPrim[i];		    
                PrimitiveFIFO.Bottom = PrimitiveFIFO.Bottom + 1;
            end            
        end                        
	endfunction
    //-------------------------------------------------------------------
    //
    //-------------------------------------------------------------------    
	function void DequeuePrimitiveGroup;		
        CurrentPrimitiveType = PrimitiveFIFO.Groups[PrimitiveFIFO.Top].PrimType; 
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
    function void QueueGlobalPrimitives();
        //PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].PrimType = PT_Sphere;
        //PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].StartPrimitive = 0;
        //PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].NumPrimitives = 1;		    
        //PrimitiveFIFO.Bottom = PrimitiveFIFO.Bottom + 1;
        
        PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].PrimType = PT_AABB;
        PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].StartPrimitive = `BVH_GLOBAL_PRIMITIVE_START_IDX;
        PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].NumPrimitives = 3;		    
        PrimitiveFIFO.Bottom = PrimitiveFIFO.Bottom + 1;
    endfunction
    //-------------------------------------------------------------------
    //
    //-------------------------------------------------------------------    

    assign fifo_full = FIFOFull;
    assign primitive_query.PrimType = CurrentPrimitiveType;
    assign primitive_query.StartIndex = StartPrimitiveIndex;
    assign primitive_query.EndIndex = EndPrimitiveIndex;
        
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
                    BU_Strobe <= 0;
                    BU_RestartStrobe <= 0;  

                    StartPrimitiveIndex <= 0;
                    EndPrimitiveIndex <= 0;             
                    RealEndPrimitiveIndex <= 0;         

                    if (FIFOFull) begin                        
                        CurrentInput = Input;                  
                        FIFOFull <= 0;

                        AnyHit <= 0;
                            
                        PrimitiveFIFO.Top = 0;			
                        PrimitiveFIFO.Bottom = 0;			
                        
                        if (CurrentInput.SurfaceType == ST_None) begin    
                            // Shadow is done since the fragment is not a primitive.
                            NextState <= SHDWS_Done;                            
                        end
                        else begin       
                            // Init BVH traversal
                            BU_Strobe <= 1;                                                                        
                            QueueGlobalPrimitives();                                                            
                            NextState <= SHDWS_AnyHit;          
                        end                                                                                                
                    end                    
                end   
                
                SHDWS_AnyHit: begin
                    valid <= 0;                    
                    BU_Strobe <= 0;     

                    // Queue possible hit primitives.  
                    QueuePrimitiveGroup();     

                    if (CurrentHit) begin
                        // If there is any hit, shadowing is done.
                        AnyHit <= 1;
                        NextState <= SHDWS_Done;  
                    end			                 
                    else begin                       
                        // If there are no primitives need to be processed
                        if (StartPrimitiveIndex >= EndPrimitiveIndex) begin	                        		                             
                            if (PrimitiveFIFO.Top != PrimitiveFIFO.Bottom) begin
                                // Dequeue possible hit primitives for closest hit test.
                                DequeuePrimitiveGroup();                                
                                //if (CurrentPrimitiveType == PT_Sphere) begin
                                    NextState <= SHDWS_WaitNext;				                                                                                            
                                //end
                            end
                            else begin
                                // All possible hit primitives are processed.
                                if (BU_Finished) begin                                          
                                    NextState <= SHDWS_Done;
                                end                            
                            end               
                        end
                        // If there are primitives need to be processed, fetch next primitive
                        else begin                        
                            NextPrimitiveData();		                        
                            //if (CurrentPrimitiveType == PT_Sphere) begin
                                NextState <= SHDWS_WaitNext;				                                            
                            //end
                        end   
                    end
                end

                SHDWS_WaitNext: begin
                    NextState <= SHDWS_AnyHit;
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
        .r(CurrentInput.ShadowRay),

        .start_prim(LeafStartPrim),    
        .num_prim(LeafNumPrim),        

        .node_index(node_index),        
        .node(node),        
        .leaf(leaf),

        .finished(BU_Finished)        
    );
    
    // Find any hit from all possible primitives
    RayUnit_FindAnyHit RU(            
		.r(CurrentInput.ShadowRay), 		
		.p(p),
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
    
    input BVH_Primitive_AABB p[`AABB_TEST_UNIT_SIZE],
    input BVH_Node node,    
    input BVH_Leaf leaf[2],               

    // outputs...      
    output logic fifo_full,
    output logic valid,
    output ShadowOutputData out,  

    output PrimitiveQueryData primitive_query,  

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
    input BVH_Primitive_AABB p[`AABB_TEST_UNIT_SIZE],
    input BVH_Node node,    
    input BVH_Leaf leaf[2],           

    // outputs...  
    output logic fifo_full,
    output logic valid,
    output ShadowOutputData out,

    output PrimitiveQueryData primitive_query,

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

        .primitive_query(primitive_query),
        .p(p),

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

        .primitive_query(primitive_query),
        .p(p),

        .node_index(node_index),
        .node(node),
        .leaf(leaf)    
    );
`endif

endmodule