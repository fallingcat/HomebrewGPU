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

`include "../../../Types.sv"
`include "../../../Math/Fixed.sv"
`include "../../../Math/Fixed3.sv"
`include "../../../Math/FixedNorm.sv"
`include "../../../Math/FixedNorm3.sv"
`include "../../Primitive/PrimitiveFIFOUtil.sv"

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module _SetupClosestHitData ( 
    input clk,    
    input reset,    
    input strobe,
    input RGB8 color,           
    input HitData hit_data,     
    output HitData closest_hit_data     
    );
    logic IsClosestHit;

    always_ff @(posedge clk) begin    
        if (reset) begin
            closest_hit_data.bHit <= 0;			
            closest_hit_data.SurfaceType <= ST_None;
            closest_hit_data.Color <= color;   
            closest_hit_data.T.Value = `FIXED_MAX;
        end
        else begin      
            if (strobe) begin
                if (hit_data.SurfaceType != ST_None && IsClosestHit) begin                
                    closest_hit_data = hit_data;
                end                    
            end
        end        
    end
    
    Fixed_Less A0(hit_data.T, closest_hit_data.T, IsClosestHit);    
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module _ClosestHit (      
    input clk,
	input resetn,    
    input reset,
    input strobe,
    input Ray r,    
    input Primitive_AABB aabb[`AABB_TEST_UNIT_SIZE],
    input Primitive_Sphere sphere[`SPHERE_TEST_UNIT_SIZE],   
    input RGB8 color,     
    output logic valid,         
    output HitData closest_hit_data,     
    output Fixed3 hit_pos
    );

    logic HitDataValid;
    HitData HitData;
    Fixed3 D;

    // Find the current closest hit from current primitive(s)
    RayUnit_FindClosestHit RU(
        .clk(clk),	 
        .resetn(resetn),        
		.r(r), 		
		.aabb(aabb),
        .sphere(sphere),
        .valid(valid),
		.hit_data(HitData)		
	);    

    // Setup HitData if the current closest hit is the final closest hit
    _SetupClosestHitData SETUP_HITDATA( 
        .clk(clk),	         
        .reset(reset),   
        .strobe(strobe && valid),     
        .color(color),                
        .hit_data(HitData),        
        .closest_hit_data(closest_hit_data)     
    );              

    Fixed3_Mul A1(closest_hit_data.T, r.Dir, D);
    Fixed3_Add A2(r.Orig, D, hit_pos);            
endmodule

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module _SurfaceOutput (    
    input clk,  
    input strobe,  
    input Fixed3 light_dir,  
    input Fixed3 light_invdir,
    input SurfaceInputData input_data,
    input HitData hit_data,
    input Fixed3 hit_pos,
    output SurfaceOutputData out
    );
    
    always_ff @(posedge clk) begin
        if (strobe) begin
            out.LastColor <= input_data.LastColor;
            out.BounceLevel <= input_data.BounceLevel;
            out.ViewDir <= input_data.SurfaceRay.Dir;    
            out.x <= input_data.x;
            out.y <= input_data.y;                                             
            out.PI <= hit_data.PI;
            out.Normal <= hit_data.Normal;
            out.SurfaceType <= hit_data.SurfaceType;
            out.ShadowRay.Orig <= hit_pos;            
            out.ShadowRay.Dir <= light_dir;                                
            out.ShadowRay.InvDir <= light_invdir;                                
            out.ShadowRay.MinT <= _Fixed(0);
            out.ShadowRay.MaxT <= _Fixed(-1);                                                      
            out.ShadowRay.PI <= hit_data.PI;   
            out.HitPos <= hit_pos;              
            // Texturing for this fragment if it is a fragment from ground primitive
            if (hit_data.SurfaceType != ST_None && hit_data.PI == `BVH_MODEL_RAW_DATA_SIZE && (hit_pos.Dim[0].Value[18] ^ hit_pos.Dim[2].Value[18])) begin            
                out.Color.Channel[0] <= hit_data.Color.Channel[0] >> 1;
                out.Color.Channel[1] <= hit_data.Color.Channel[1] >> 1;
                out.Color.Channel[2] <= hit_data.Color.Channel[2] >> 1;                
            end                               
            else begin
                out.Color <= hit_data.Color;        
            end                        
        end        
    end
endmodule
//-------------------------------------------------------------------
// Do BVH traversal and find the primitives which may have possible hit.
// Then use Ray unit to find the closest hit.
// Finally get the hiy position, normal, color, material, etc. data.
//-------------------------------------------------------------------    
module SurfaceUnit (      
    input clk,
    input resetn,    

    // controls... 
    input add_input,

    // inputs...
    input SurfaceInputData input_data,            
    input RenderState rs,    
    input output_fifo_full,	    

    input Primitive_AABB aabb[`AABB_TEST_UNIT_SIZE],
    input Primitive_Sphere sphere[`SPHERE_TEST_UNIT_SIZE],
    input BVH_Node node,    
    input BVH_Leaf leaf[2],    

    // outputs...  
    output DebugData debug_data,    

    output logic fifo_full,        
    output logic valid,
    output SurfaceOutputData out, 

    output PrimitiveQueryData aabb_query,
    output PrimitiveQueryData sphere_query,
    
    output logic [`BVH_NODE_INDEX_WIDTH-1:0] node_index    
    );       
    
    SurfaceState State, NextState = SURFS_Init;         
    SurfaceInputData Input, CurrentInput;
    HitData HitData, ClosestHitData;	      
    Fixed3 ClosestHitPos;       
    logic ResetClosestHitData = 1'b0, HitDataValid = 1'b0, FIFOFull = 1'b0; 
    
    // Result of BVH traversal. Queue the resullt to PrimitiveFIFO for later processing.    
    logic BU_Strobe, BU_Valid, BU_Finished, BU_RestartStrobe;        
    logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] LeafStartPrim[2];
    logic [`BVH_PRIMITIVE_AMOUNT_WIDTH-1:0] LeafNumPrim[2];       

    // Store the primitive groups data. Each group present a range of primitives
    // which may have possible hit.
    PrimitiveGroupFIFO PrimitiveFIFO[`NUM_PRIMITIVE_TYPES];	    
    logic PrimitiveFIFOEmpty;    

    assign debug_data.Number[1] = sphere_query.StartIndex;
    assign debug_data.Number[0] = sphere[0].Color.Channel[0];

    assign fifo_full = FIFOFull;    
        
    initial begin
        PrimitiveFIFO_QueueGlobalPrimitives(PrimitiveFIFO[PT_AABB], PrimitiveFIFO[PT_Sphere]);
    end

    always_ff @(posedge clk, negedge resetn) begin
        if (!resetn) begin
            FIFOFull <= 0; 
            NextState <= SURFS_Init;
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
                (SURFS_Init): begin    
                    valid <= 0;
                    BU_Strobe <= 0;
                    BU_RestartStrobe <= 0;       
                    
                    if (FIFOFull) begin                        
                        CurrentInput = Input;                  
                        FIFOFull <= 0;
                        ResetClosestHitData <= 1;

                        // Reset primitive FIFO
                        PrimitiveFIFO_Reset(PrimitiveFIFO[PT_AABB], PrimitiveFIFO[PT_Sphere]);
                        PrimitiveFIFOEmpty = 0;

                        BU_Strobe <= 1;                                                                                           
                        
                        NextState <= SURFS_Surfacing;                                                   
                    end                    
                end   
                
                (SURFS_Surfacing): begin                    
                    ResetClosestHitData <= 0;
                    valid <= 0;                    
                    BU_Strobe <= 0;                                               

                    // Fetch primitives
                    PrimitiveFIFO_Fetch(PrimitiveFIFOEmpty, PrimitiveFIFO[PT_AABB], PrimitiveFIFO[PT_Sphere]);

                    aabb_query.StartIndex    = PrimitiveFIFO[PT_AABB].StartPrimitiveIndex;
                    aabb_query.EndIndex      = PrimitiveFIFO[PT_AABB].EndPrimitiveIndex;
                    sphere_query.StartIndex  = PrimitiveFIFO[PT_Sphere].StartPrimitiveIndex;
                    sphere_query.EndIndex    = PrimitiveFIFO[PT_Sphere].EndPrimitiveIndex;                        
                    
                    // If all primitives have been processed
                    if (BU_Finished && PrimitiveFIFOEmpty) begin
                        NextState <= SURFS_Done;
                    end                                            
                end               

                (SURFS_WaitHitData): begin                    
                    if (HitDataValid) begin
                        NextState <= SURFS_Surfacing;
                    end                                        
                end                        
                
                (SURFS_Done): begin
                    BU_Strobe <= 0;
                    BU_RestartStrobe <= 1;    
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

    // Traverse BVH tree and find the possible hit primitives 
    BVHUnit BU(    
        .clk(clk),	 
        .resetn(resetn),
        .strobe(BU_Strobe),    
        .restart_strobe(BU_RestartStrobe),
        .offset(rs.PositionOffset),
        .r(CurrentInput.SurfaceRay),

        .start_prim(LeafStartPrim),    
        .num_prim(LeafNumPrim), 

        .node_index(node_index),        
        .node(node),        
        .leaf(leaf),

        .valid(BU_Valid),
        .finished(BU_Finished)        
    );    

    // Find closest hit from all possible primitives
    _ClosestHit FIND_CLOSEST_HIT(      
        .clk(clk),
        .resetn(resetn),    
        .reset(ResetClosestHitData),
        .strobe(State != SURFS_Done),
        .r(CurrentInput.SurfaceRay), 		
        .aabb(aabb),
        .sphere(sphere),
        .color(rs.ClearColor),                       
        .valid(HitDataValid),
        .closest_hit_data(ClosestHitData),
        .hit_pos(ClosestHitPos)
    );

    // Setup output for next stage
    _SurfaceOutput SURF_OUT (      
        .clk(clk),
        .strobe(NextState == SURFS_Done),
        .light_dir(rs.Light[0].Dir),
        .light_invdir(rs.Light[0].InvDir),
        .input_data(CurrentInput),
        .hit_data(ClosestHitData),
        .hit_pos(ClosestHitPos),
        .out(out)
    );   

endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module Surface (    
    input clk,
    input resetn,    

    // controls...         
    input add_input,
    input add_ref_input,

    // inputs...
    input SurfaceInputData input_data,                 
    input SurfaceInputData ref_input_data,            
    input RenderState rs,    
    input output_fifo_full,	    

    input Primitive_AABB aabb[`AABB_TEST_UNIT_SIZE],
    input Primitive_Sphere sphere[`SPHERE_TEST_UNIT_SIZE],    
    input BVH_Node node,    
    input BVH_Leaf leaf[2],           

    // outputs...  
    output DebugData debug_data,    

    output logic fifo_full,        
    output logic ref_fifo_full,        
    output logic valid,
    output SurfaceOutputData out,

    output PrimitiveQueryData aabb_query,
    output PrimitiveQueryData sphere_query,
    
    output logic [`BVH_NODE_INDEX_WIDTH-1:0] node_index        
    );       

    logic RGEN_Valid, SURF_FIFO_Full;
    SurfaceInputData RGEN_Output;    

    SurfaceRayGenerator RGEN(
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

    SurfaceUnit SURF(
        .clk(clk),
        .resetn(resetn),
        .add_input(RGEN_Valid),
        .input_data(RGEN_Output),        
        .rs(rs),        
        .output_fifo_full(output_fifo_full),
        .valid(valid),
        .out(out),
        .fifo_full(SURF_FIFO_Full),       

        .debug_data(debug_data),

        .aabb_query(aabb_query),
        .aabb(aabb),

        .sphere_query(sphere_query),
        .sphere(sphere),

        .node_index(node_index),
        .node(node),
        .leaf(leaf)
    );
endmodule
