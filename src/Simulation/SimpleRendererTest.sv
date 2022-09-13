`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/10 20:36:45
// Design Name: 
// Module Name: RendererTest
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

module SimpleRendererTest;
	logic CLK;
    logic Flip;
    //MemoryControllerRequest mem_request;
	
    parameter CLK_PERIOD = 40;  // 10 ns == 100 MHz
	always #(CLK_PERIOD/2) CLK = ~CLK;	

    initial begin
	    CLK = 1;
	
	    #2000
	    $finish;
    end	

    RenderState RenderState;			
	
	logic TG_Strobe = 0, TG_Reset = 0;
	ThreadData TG_Output[`RAY_CORE_SIZE];

    logic RC_Valid[`RAY_CORE_SIZE], RC_FIFOFull[`RAY_CORE_SIZE];	
	ShadeOutputData ShadeOut[`RAY_CORE_SIZE];    	 

	PrimitiveQueryData PrimitiveQuery0[`RAY_CORE_SIZE];
	BVH_Primitive_AABB P0[`RAY_CORE_SIZE][`AABB_TEST_UNIT_SIZE];    	

	PrimitiveQueryData PrimitiveQuery1[`RAY_CORE_SIZE];
	BVH_Primitive_AABB P1[`RAY_CORE_SIZE][`AABB_TEST_UNIT_SIZE];    	

	logic [`BVH_NODE_INDEX_WIDTH-1:0] BVHNodeIndex0[`RAY_CORE_SIZE], BVHNodeIndex1[`RAY_CORE_SIZE];
	BVH_Node BVHNode0[`RAY_CORE_SIZE], BVHNode1[`RAY_CORE_SIZE];
	BVH_Leaf BVHLeaf0[`RAY_CORE_SIZE][2], BVHLeaf1[`RAY_CORE_SIZE][2];
	
	Fixed3 CameraPos, CameraLook;
	Fixed CameraFocus;		
	Fixed Radius, OffsetPosX, OffsetPosZ;
	logic [31:0] CorePixelCounter[`RAY_CORE_SIZE];
	logic [31:0] PixelCounter;
	
	logic SURF_Valid, SURF_REF_FIFO_Full;
    SurfaceOutputData SURF_Output;    

    logic SHDW_Valid, SHDW_FIFO_Full;   
    ShadowOutputData SHDW_Output;          
     
    logic SHAD_Valid, SHAD_FIFO_Full;

    logic SHAD_REF_Valid;
    SurfaceInputData SHAD_REF_Output;    
	

    // Process render state changes.
	RenderState RS(
		.clk(CLK),	
		.resetn(1'b1),
		.strobe(1'b1),
		.pos(CameraPos),
		.look(CameraLook),		
		.focus_dist(CameraFocus),
		.rs(RenderState),
		.valid(RS_Valid)		
	);

	Surface SURF(    
        .clk(CLK),
        .resetn(1'b1),
		
        .add_input(1'b1),
        .input_data(TG_Output[0].RayCoreInput),        

        //.fifo_full(fifo_full),
        .add_ref_input(1'b0),
        .ref_input_data(SHAD_REF_Output),        
        //.ref_fifo_full(SURF_REF_FIFO_Full),

        .rs(RenderState),        
        .output_fifo_full(SHDW_FIFO_Full),

        .valid(SURF_Valid),
        .out(SURF_Output),        

        .primitive_query(PrimitiveQuery0[0]),

        //.debug_data(debug_data),
        
        .p(P0[0]),

        .node_index(BVHNodeIndex0[0]),
        .node(BVHNode0[0]),
        .leaf(BVHLeaf0[0])
    );

endmodule
