//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/14 20:07:25
// Design Name: 
// Module Name: Ray
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

`include "../Types.sv"
`include "../Math/Fixed.sv"
`include "../Math/Fixed3.sv"
`include "../Math/FixedNorm.sv"
`include "../Math/FixedNorm3.sv"

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module Texture (
    input clk,    
    input strobe,
    input RGB8 color,
    input Fixed3 pos,
    input logic hit,
    input logic `VOXEL_INDEX vi,
    output RGB8 out
    );
    logic [27:0] PX, PZ;

    always_ff @(posedge clk) begin    
        if (strobe) begin
            out <= color;        
            if (hit && vi == `BVH_MODEL_RAW_DATA_SIZE) begin
                PX = pos.Dim[0].Value >> (`FIXED_FRAC_WIDTH + 4);
                PZ = pos.Dim[2].Value >> (`FIXED_FRAC_WIDTH + 4);
                if (PX[0] ^ PZ[0]) begin                                    
                    out.Channel[0] <= color.Channel[0] >> 1;
                    out.Channel[1] <= color.Channel[1] >> 1;
                    out.Channel[2] <= color.Channel[2] >> 1;
                end      
            end                      
        end        
    end    
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module SetupFinalHitData ( 
    input clk,    
    input logic reset,    
    input RGB8 color,           
    input HitData hit_data,     
    output HitData final_hit_data     
    );
    logic IsClosestHit;

    always_ff @(posedge clk) begin    
        if (reset) begin
            final_hit_data.bHit <= 0;			
            final_hit_data.SurfaceType <= ST_None;
            final_hit_data.Color <= color;   
            final_hit_data.T.Value = `FIXED_MAX;
        end
        else begin            
            if (hit_data.SurfaceType != ST_None && IsClosestHit) begin                
                final_hit_data = hit_data;
            end                    
        end        
    end
    Fixed_Less A0(hit_data.T, final_hit_data.T, IsClosestHit);    
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module RasterCombineOutput (      
    input clk,
    input strobe,  
    input Fixed3 light_dir,  
    input Fixed3 light_invdir,
    input RasterInputData input_data,
    input HitData hit_data,
    output RasterOutputData out
    );
    always_ff @(posedge clk) begin
        if (strobe) begin
            out.LastColor <= input_data.LastColor;
            out.BounceLevel <= input_data.BounceLevel;
            out.ViewDir <= input_data.RasterRay.Dir;    
            out.x <= input_data.x;
            out.y <= input_data.y;                                             
            out.VI <= hit_data.VI;
            out.Normal <= hit_data.Normal;
            out.SurfaceType <= hit_data.SurfaceType;
            out.ShadowingRay.Orig <= out.HitPos;
            out.ShadowingRay.Dir <= light_dir;                                
            out.ShadowingRay.InvDir <= light_invdir;                                
            out.ShadowingRay.MinT <= _Fixed(0);
            out.ShadowingRay.MaxT <= _Fixed(-1);                                                      
            out.ShadowingRay.VI <= hit_data.VI;            
        end        
    end
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module RasterUnit (      
    input clk,
    input resetn,    

    // controls... 
    input add_input,

    // inputs...
    input RasterInputData input_data,            
    input RenderState rs,    
    input output_fifo_full,	    

    input BVH_Primitive p[`BVH_AABB_TEST_UNIT_SIZE],
    input BVH_Node node,    
    input BVH_Leaf leaf[2],    

    // outputs...  
    output logic fifo_full,        
    output logic valid,
    output RasterOutputData out,           
    output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start_primitive,
	output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] end_primitive,
    output logic [`BVH_NODE_INDEX_WIDTH-1:0] node_index    
    );       
    
    RasterState State, NextState = RASTS_Init;         
    RasterInputData Input, CurrentInput;
    HitData PHitData, FinalHitData;	    
       
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
        StartPrimitiveIndex = StartPrimitiveIndex + `BVH_AABB_TEST_UNIT_SIZE;       
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
    //-------------------------------------------------------------------
    //
    //-------------------------------------------------------------------        
    assign start_primitive = StartPrimitiveIndex;  
    assign end_primitive = RealEndPrimitiveIndex;  

    /*
    initial begin	        
        fifo_full <= 0;
        NextState <= RASTS_Init;
	end	    
    */

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
                        NextState <= RASTS_Rasterize;                                                   
                    end                    
                end   
                
                (RASTS_Rasterize): begin                    
                    ResetFinalHitData <= 0;
                    valid <= 0;                    
                    BU_Strobe <= 0;       

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
                                NextState <= RASTS_Done;
                            end                            
                        end                    
                    end                                                                                
                end                        

                (RASTS_Done): begin
                    if (!output_fifo_full) begin
                        valid <= 1;          
                        BU_Strobe <= 0;
                        BU_RestartStrobe <= 1;    
                        NextState <= RASTS_Init;            
                    end                    
                end
                
                default: begin
                    NextState <= RASTS_Init;
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
        .r(CurrentInput.RasterRay),

        .start_prim(LeafStartPrim),    
        .num_prim(LeafNumPrim), 

        .node_index(node_index),        
        .node(node),        
        .leaf(leaf),

        .finished(BU_Finished)        
    );
    
    RayUnit_FindClosestHit RU(
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
    
    Fixed3_Mul A1(FinalHitData.T, CurrentInput.RasterRay.Dir, D);
    Fixed3_Add A2(CurrentInput.RasterRay.Orig, D, out.HitPos);            

    RasterCombineOutput CO (      
        .clk(clk),
        .strobe(NextState == RASTS_Done),
        .light_dir(rs.Light[0].Dir),
        .light_invdir(rs.Light[0].InvDir),
        .input_data(CurrentInput),
        .hit_data(FinalHitData),
        .out(out)
    );
    
    Texture TX(
        .clk(clk),
        .strobe(NextState == RASTS_Done),
        .color(FinalHitData.Color),
        .pos(out.HitPos),
        .hit(FinalHitData.SurfaceType != ST_None),
        .vi(FinalHitData.VI),
        .out(out.Color)
    );        

endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module Raster (    
    input clk,
    input resetn,    

    // controls...         
    input add_input,
    input add_ref_input,

    // inputs...
    input RasterInputData input_data,                 
    input RasterInputData ref_input_data,            
    input RenderState rs,    
    input output_fifo_full,	    

    input BVH_Primitive p[`BVH_AABB_TEST_UNIT_SIZE],
    input BVH_Node node,    
    input BVH_Leaf leaf[2],           

    // outputs...  
    output logic fifo_full,        
    output logic ref_fifo_full,        
    output logic valid,
    output RasterOutputData out,           
    output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start_primitive,
	output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] end_primitive,
    output logic [`BVH_NODE_INDEX_WIDTH-1:0] node_index        
    );       

    logic RGEN_Valid, RAS_FIFO_Full;
    RasterInputData RGEN_Output;    

    RastaerRayGenerator RGEN (
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

    RasterUnit RAS (    
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
        .p(p),

        .node_index(node_index),
        .node(node),
        .leaf(leaf)
    );
endmodule
