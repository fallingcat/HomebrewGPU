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
module RayCore(    
    input clk,
	input resetn,        	

    // controls... 
    input logic add_input,

    // inputs...    
    input SurfaceInputData input_data,        
    input RenderState rs,
    input BVH_Primitive_AABB p0[`AABB_TEST_UNIT_SIZE],
    input BVH_Primitive_AABB p1[`AABB_TEST_UNIT_SIZE],
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
    // For example : (SURF -> SHDW -> SHAD) -> (SURF -> SHDW -> SHAD) -> (SURF -> SHDW -> SHAD) -> Frame Buffer for 3 bounces
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
        .start_primitive(start_primitive_0),
        .end_primitive(end_primitive_0),
        .p(p0),
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
        .start_primitive(start_primitive_1),
        .end_primitive(end_primitive_1),
        .p(p1),
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
    
endmodule