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
module _PixelCounter(    
    input clk,
	input resetn,        	
    input valid,
    input reset_pixel_counter,
    output logic [31:0] pixel_counter
    );

    always_ff @(posedge clk, negedge resetn) begin			
		if (!resetn) begin			
			pixel_counter <= 0;
		end
		else begin				
            if (reset_pixel_counter) begin
                pixel_counter = 0;
            end
            else if (valid) begin
                pixel_counter = pixel_counter + 1;
            end
        end
    end		
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module RayCore(    
    input clk,
	input resetn,        	

    // controls... 
    input logic add_input,

    // inputs...    
    input SurfaceInputData input_data,        
    input RenderState rs,
    input reset_pixel_counter,
    input Primitive_AABB aabb_0[`AABB_TEST_UNIT_SIZE],
    input Primitive_AABB aabb_1[`AABB_TEST_UNIT_SIZE],
    input Primitive_Sphere sphere_0[`SPHERE_TEST_UNIT_SIZE],
    input Primitive_Sphere sphere_1[`SPHERE_TEST_UNIT_SIZE],
    input BVH_Node node_0,    
    input BVH_Node node_1,    
    input BVH_Leaf leaf_0[2],       
    input BVH_Leaf leaf_1[2],
        
    // outputs...  
    output DebugData debug_data,    

    output logic fifo_full,        
    output logic valid,
    output logic [31:0] pixel_counter,
    output ShadeOutputData shade_out,
    // The primitive indeices [0] for query
    output PrimitiveQueryData aabb_query_0,
    // The primitive indeices [1] for query
    output PrimitiveQueryData aabb_query_1,
    // The primitive indeices [0] for query
    output PrimitiveQueryData sphere_query_0,
    // The primitive indeices [1] for query
    output PrimitiveQueryData sphere_query_1,
    // The node index 0 for query
    output logic [`BVH_NODE_INDEX_WIDTH-1:0] node_index_0,
    // The node index 1 for query
    output logic [`BVH_NODE_INDEX_WIDTH-1:0] node_index_1	
    );       
        
    logic SURF_Valid, SURF_REF_FIFO_Full;
    SurfaceOutputData SURF_Output;    

    logic SHDW_Valid, SHDW_FIFO_Full;   
    ShadowOutputData SHDW_Output;          
     
    logic SHAD_Valid, SHAD_FIFO_Full;

    logic SHAD_REF_Valid;
    SurfaceInputData SHAD_REF_Output;    
		
    // 3 pipeline stages : SURF -> SHDW -> SHAD, the SHAD output will be redirected back to SURF for the reflection/refraction
    // For example : (SURF -> SHDW -> SHAD) -> (SURF -> SHDW -> SHAD) -> (SURF -> SHDW -> SHAD) -> Frame Buffer for 3 bounces
    //------------------------------------------------------------------------------------
    //              SURF            SHDW            SHAD                Frame Buffer
    //------------------------------------------------------------------------------------
    //  c0          Frag_N          x               x
    //------------------------------------------------------------------------------------
    //  c1          Frag_N+1        Frag_N          x
    //------------------------------------------------------------------------------------
    //  c3          Frag_N+2        Frag_N+1        Frag_N
    //------------------------------------------------------------------------------------
    //  c4          Frag_N+3        Frag_N+2        Frag_N+1            Frag_N
    //------------------------------------------------------------------------------------
    //  c5          Frag_N+1_Ref    Frag_N+3        Frag_N+2
    //------------------------------------------------------------------------------------
    //  c6          Frag_N+4        Frag_N+1_Ref    Frag_N+3            Frag_N+2
    //------------------------------------------------------------------------------------
    //  c7          Frag_N+5        Frag_N+4        Frag_N+1_Ref        Frag_N+3
    //------------------------------------------------------------------------------------
    //  c8          Frag_N+6        Frag_N+5        Frag_N+4            Frag_N+1_Ref
    //------------------------------------------------------------------------------------
    
    Surface SURF(    
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
        
        .debug_data(debug_data),
        
        .aabb_query(aabb_query_0),       
        .aabb(aabb_0),

        .sphere_query(sphere_query_0),
        .sphere(sphere_0),        

        .node_index(node_index_0),
        .node(node_0),
        .leaf(leaf_0)
    );

    Shadow SHDW(
        .clk(clk),
        .resetn(resetn),
        .add_input(SURF_Valid),
        .input_data(SURF_Output),        
        .rs(rs),        
        .output_fifo_full(SHAD_FIFO_Full),
        .valid(SHDW_Valid),
        .out(SHDW_Output),
        .fifo_full(SHDW_FIFO_Full),        

        .aabb_query(aabb_query_1),
        .aabb(aabb_1),

        .sphere_query(sphere_query_1),
        .sphere(sphere_1),

        .node_index(node_index_1),
        .node(node_1),
        .leaf(leaf_1)    
    );         

    Shade SHAD(
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

    /*
    _PixelCounter PIXEL_COUNTER(
        .clk(clk),
        .resetn(resetn),
        .reset_pixel_counter(reset_pixel_counter),
        .valid(valid),
        .pixel_counter(pixel_counter)        
    );      
    */

endmodule