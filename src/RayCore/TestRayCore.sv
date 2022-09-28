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
module TestCombineOutput ( 
    input clk,
    input valid,
    input Fixed3 light_dir, 
    input Fixed3 light_invdir,             
    input SurfaceInputData input_data,
    input HitData hit_data,    
    output SurfaceOutputData out
    );
    always_ff @(posedge clk) begin
        if (valid) begin
            //out.LastColor <= input_data.LastColor;
            //out.BounceLevel <= input_data.BounceLevel;
            //out.ViewDir <= input_data.SurfaceRay.Dir;    
            out.x <= input_data.x;
            out.y <= input_data.y;                                 
            out.bHit <= hit_data.bHit;                                                            
            out.PI <= hit_data.PI;
            //out.Color <= hit_data.Color;
            out.Normal <= hit_data.Normal;
            //out.SurfaceType <= hit_data.SurfaceType;
            out.ShadowRay.Orig <= out.HitPos;
            out.ShadowRay.Dir <= light_dir;  
            out.ShadowRay.InvDir <= light_invdir;
            out.ShadowRay.MinT <= _Fixed(0);
            out.ShadowRay.MaxT <= _Fixed(-1);                                                      
            out.ShadowRay.PI <= hit_data.PI;            
        end        
    end
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module TestSurfaceUnit (      
    input clk,
    input resetn,    

    // controls... 
    input add_input,

    // inputs...
    input SurfaceInputData input_data,            
    input RenderState rs,        
    input Primitive_AABB p[`AABB_TEST_UNIT_SIZE],    
    input BVH_Node node,    
    input BVH_Leaf leaf[2],
    input output_fifo_full,	    

    // outputs...  
    output logic fifo_full,        
    output logic valid,
    output SurfaceOutputData out,           
    output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start_primitive,
	output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] end_primitive,        
    output logic [`BVH_NODE_INDEX_WIDTH-1:0] node_index    
    );       
    
    SurfaceState State, NextState = SURFS_Init;         
    SurfaceInputData Input, CurrentInput;
    HitData PHitData, FinalHitData, HitData;	    
       
    PrimitiveGroupFIFO PrimitiveFIFO;	
	logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] StartPrimitiveIndex, EndPrimitiveIndex, RealEndPrimitiveIndex, AlignedNumPrimitives;
    
    logic BU_Strobe, BU_Valid, BU_Finished, BU_RestartStrobe;        
    logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] LeafStartPrim[2];
    logic [`BVH_PRIMITIVE_AMOUNT_WIDTH-1:0] LeafNumPrim[2];       
    logic ResetFinalHitData;    
    
    Fixed3 D;
    
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
    function QueueReflectiveBoxAndGround();
        PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].StartPrimitive = `BVH_MODEL_RAW_DATA_SIZE;
        PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].NumPrimitives = 3;		    
        PrimitiveFIFO.Bottom = PrimitiveFIFO.Bottom + 1;
    endfunction  

    
    assign start_primitive = StartPrimitiveIndex;  
    assign end_primitive = RealEndPrimitiveIndex;  

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
                    BU_Strobe <= 0;
                    BU_RestartStrobe <= 0;                    
                    if (fifo_full) begin                        
                        CurrentInput = Input;                  
                        fifo_full <= 0;
                        ResetFinalHitData <= 1;                        

                        PrimitiveFIFO.Top = 0;			
                        PrimitiveFIFO.Bottom = 0;			
                        StartPrimitiveIndex = 0;
                        EndPrimitiveIndex = 0;             
                        RealEndPrimitiveIndex = 0;           
                        BU_Strobe <= 1;                                                                    
                        QueueReflectiveBoxAndGround();    
                        NextState <= SURFS_Surfacing;                                                   
                    end                    
                end   
                
                (SURFS_Surfacing): begin        
                    BU_RestartStrobe <= 0;            
                    ResetFinalHitData <= 0;                                                            
                    BU_Strobe <= 0;        
                    valid <= 0;                                                    

                    QueuePrimitiveGroup();
                    
                    if (StartPrimitiveIndex != EndPrimitiveIndex) begin			                        
                        NextPrimitiveData();						                                            
                    end
                    else begin
                        if (PrimitiveFIFO.Top != PrimitiveFIFO.Bottom) begin
                            DequeuePrimitiveGroup();                                                    
                        end
                        else begin
                            if (BU_Finished) begin                                  
                                BU_RestartStrobe <= 1;    
                                BU_Strobe <= 0;
                                NextState <= SURFS_Done;
                            end                            
                        end                    
                    end                                                                                
                end                        

                (SURFS_Done): begin
                    BU_RestartStrobe <= 1;
                    BU_Strobe <= 0;                        
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

    BVHUnit BU(    
        .clk(clk),	 
        .resetn(resetn),
        .strobe(BU_Strobe),    
        .restart_strobe(BU_RestartStrobe),
        .offset(rs.PositionOffset),
        .r(CurrentInput.SurfaceRay),
        .node_index(node_index),
        .node(node),
        .leaf(leaf),
        .start_prim(LeafStartPrim),    
        .num_prim(LeafNumPrim),            
        .finished(BU_Finished)        
    );
    
    RayUnitV3_FindClosestHit RU(
    	.r(CurrentInput.SurfaceRay), 		
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

    Fixed3_Mul A1(FinalHitData.T, CurrentInput.SurfaceRay.Dir, D);
    Fixed3_Add A2(CurrentInput.SurfaceRay.Orig, D, out.HitPos);            

    TestCombineOutput CO (   
        .clk(clk),
        .valid(NextState == SURFS_Done),
        .light_dir(rs.Light[0].Dir),
        .light_invdir(rs.Light[0].InvDir),
        .input_data(CurrentInput),
        .hit_data(FinalHitData),
        .out(out)
    );  

    Texture TX(
        .clk(clk),
        .strobe(NextState == SURFS_Done),
        .color(FinalHitData.Color),
        .pos(out.HitPos),
        .hit(FinalHitData.bHit),
        .pi(FinalHitData.PI),
        .out(out.Color)
    );
 
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module TestSurface (    
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
    input BVH_Node node,    
    input BVH_Leaf leaf[2],       
    input output_fifo_full,	    

    // outputs...  
    output logic fifo_full,        
    output logic ref_fifo_full,        
    output logic valid,
    output SurfaceOutputData out,           
    output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start_primitive,
	output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] end_primitive,
    output logic [`BVH_NODE_INDEX_WIDTH-1:0] node_index    
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

    TestSurfaceUnit SURF (    
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
        .p(p),
        .node_index(node_index),
        .node(node),
        .leaf(leaf)
    );
endmodule

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module TestShadowRayGenerator(
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
					NextState <= RGS_Init;                    
                end
                
                (RGS_Init): begin	 
                    valid <= 0;                        
                    if (fifo_full) begin
                        out = Input; 
                        fifo_full <= 0;          
                        NextState <= RGS_Done;                        
                    end
                end                
				
                (RGS_Done): begin
                    if (!output_fifo_full) begin                        
                        valid <= 1;
                        NextState <= RGS_Init;                        
                    end
                end
            endcase	
		end
	end	       

endmodule

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module TestShadowUnit_Simple (
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

    HitData PHitData, FinalHitData, HitData;	    
    
    PrimitiveGroupFIFO PrimitiveFIFO;	
	logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] StartPrimitiveIndex, EndPrimitiveIndex, RealEndPrimitiveIndex, AlignedNumPrimitives;
    
    logic BU_Strobe, BU_Valid, BU_Finished, BU_RestartStrobe;        
    logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] LeafStartPrim[2];
    logic [`BVH_PRIMITIVE_AMOUNT_WIDTH-1:0] LeafNumPrim[2]; 
    assign start_primitive = StartPrimitiveIndex;  
    assign end_primitive = RealEndPrimitiveIndex;  

    initial begin	        
        fifo_full <= 0;
        NextState <= SHDWS_Init;
	end	   
    
    always @(posedge clk, negedge resetn) begin
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

                        out.x <= CurrentInput.x;
                        out.y <= CurrentInput.y;                    
                        out.Color <= CurrentInput.Color;
                        out.Normal <= CurrentInput.Normal;
                        out.bShadow <= 0;               
                        NextState <= SHDWS_Done;  
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
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module TestShadowCombineOutput (     
    input clk,
    input valid, 
    input SurfaceOutputData input_data,
    input HitData hit_data,
    output ShadowOutputData out
    );
    always_ff @(posedge clk) begin
        if (valid) begin
            //out.LastColor <= input_data.LastColor;
            //out.BounceLevel <= input_data.BounceLevel;
            out.x <= input_data.x;
            out.y <= input_data.y;                    
            //out.ViewDir <= input_data.ViewDir;
            out.bHit <= input_data.bHit;                    
            //out.PI <= input_data.PI;                    
            //out.HitPos <= input_data.HitPos;                    
            out.Color <= input_data.Color;
            out.Normal <= input_data.Normal;
            out.bShadow <= hit_data.bHit;                     
            //out.SurfaceType <= input_data.SurfaceType;                                        
        end        
    end
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module TestShadowUnit (
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

    HitData PHitData, FinalHitData;	    
    
    PrimitiveGroupFIFO PrimitiveFIFO;	
	logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] StartPrimitiveIndex, EndPrimitiveIndex, RealEndPrimitiveIndex, AlignedNumPrimitives;
    
    logic BU_Strobe, BU_Valid, BU_Finished, BU_RestartStrobe;        
    logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] LeafStartPrim[2];
    logic [`BVH_PRIMITIVE_AMOUNT_WIDTH-1:0] LeafNumPrim[2]; 

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
    function QueueReflectiveBoxAndGround();
        PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].StartPrimitive = `BVH_MODEL_RAW_DATA_SIZE;
        PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].NumPrimitives = 3;		    
        PrimitiveFIFO.Bottom = PrimitiveFIFO.Bottom + 1;
    endfunction

    assign start_primitive = StartPrimitiveIndex;  
    assign end_primitive = RealEndPrimitiveIndex;  

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
                    BU_Strobe <= 0;
                    BU_RestartStrobe <= 0;                                        
                    if (fifo_full) begin                        
                        CurrentInput = Input;                  
                        fifo_full <= 0;

                        FinalHitData.bHit <= 0;							                        
                            
                        PrimitiveFIFO.Top = 0;			
                        PrimitiveFIFO.Bottom = 0;			
                        StartPrimitiveIndex = 0;
                        EndPrimitiveIndex = 0;             
                        RealEndPrimitiveIndex = 0;             

                        if (CurrentInput.bHit) begin    
                            BU_Strobe <= 1;                                                                        
                            QueueReflectiveBoxAndGround();                                                            
                            NextState <= SHDWS_AnyHit;          
                        end
                        else begin                           
                            NextState <= SHDWS_Done;
                        end                                                                                                                        
                    end                    
                end   
                
                SHDWS_AnyHit: begin
                    valid <= 0;                    
                    BU_Strobe <= 0;                    

                    QueuePrimitiveGroup();
                    
                    if (PHitData.bHit) begin
                        FinalHitData.bHit <= 1;
                        NextState <= SHDWS_Done;  
                    end			                 
                    else begin
                        if (StartPrimitiveIndex != EndPrimitiveIndex) begin			                        
                            NextPrimitiveData();						                                            
                        end
                        else begin
                            if (PrimitiveFIFO.Top != PrimitiveFIFO.Bottom) begin
                                DequeuePrimitiveGroup();                                 
                            end
                            else begin
                                if (BU_Finished) begin    
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
    
    BVHUnit BU(    
        .clk(clk),	 
        .resetn(resetn),
        .strobe(BU_Strobe),    
        .restart_strobe(BU_RestartStrobe),
        .offset(rs.PositionOffset),
        .r(CurrentInput.ShadowRay),
        .start_prim(LeafStartPrim),    
        .num_prim(LeafNumPrim),            
        .finished(BU_Finished)        
    );
    
    RayUnitV3_FindAnyHit RU(            
		.r(CurrentInput.ShadowRay), 		
		.p(p),
		.out_hit(PHitData.bHit)		
	);   

    TestShadowCombineOutput CO (     
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
module TestShadow (
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

    TestShadowUnit_Simple SHDW (
    //TestShadowUnit SHDW (
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
module TestShadeCombineOutput (    
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

    /*
    FinalDiffuse DIFFUSE(
        .l(l),
        .n(input_data.Normal),
        .hit(input_data.bHit),
        .shadow(input_data.bShadow),
        .o(Diffuse)
    );
    
    Fixed_RGB8_Mul CURRENT_COLOR(
        .a(Diffuse),        
        .b(input_data.Color),
        .o(out.Color)
    );
    */    
    
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module TestShade(   
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

    TestShadeCombineOutput CO (
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
module TestRayCore(    
    input clk,
	input resetn,        	

    // controls... 
    input logic add_input,

    // inputs...    
    input SurfaceInputData input_data,        
    input RenderState rs,
    input Primitive_AABB p0[`AABB_TEST_UNIT_SIZE],
    input Primitive_AABB p1[`AABB_TEST_UNIT_SIZE],
    input BVH_Node node_0,    
    input BVH_Node node_1,    
    input BVH_Leaf leaf_0[2],       
    input BVH_Leaf leaf_1[2],

    // outputs...  
    output logic fifo_full,        
    output logic valid,
    output ShadeOutputData shade_out,
    output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start_primitive_0,
	output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] end_primitive_0,	    
    output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start_primitive_1,
	output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] end_primitive_1,		
    output logic [`BVH_NODE_INDEX_WIDTH-1:0] node_index_0,
    output logic [`BVH_NODE_INDEX_WIDTH-1:0] node_index_1
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
    TestSurface SURF (    
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
        .p(p0),
        .node_index(node_index_0),
        .node(node_0),
        .leaf(leaf_0)
    );

    TestShadow SHDW (
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

    TestShade SHAD (
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