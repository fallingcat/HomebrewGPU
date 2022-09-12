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
	

    // Process render state changes.
	RenderState RS(
		.clk(CLK),			
		.rs(RenderState)
	);
	
	// Emit fragment threads for ray cores to process.
	ThreadGenerator TG(
    	.clk(CLK),
		.strobe(1),
		.reset(0),				
		.rs(RenderState),
		.output_fifo_full(RC_FIFOFull),
    	.x0(0),
    	.y0(0),			
    	.thread_out(TG_Output)
    );

    PrimitiveUnit PRIM(   
		.clk(CLK),	    				
		.primitive_query_0(PrimitiveQuery0),
		.p0(P0),		
		.primitive_query_1(PrimitiveQuery1),		
		.p1(P1)
	);			

	generate
        for (genvar i = 0; i < `RAY_CORE_SIZE; i = i + 1) begin : CORE_ARRY
			RayCore RAYCORE(
				.clk(CLK),
				
                .add_input(TG_Output[i].DataValid),					
				.input_data(TG_Output[i].RayCoreInput),                

				.rs(RenderState),	

				.fifo_full(RC_FIFOFull[i]),        
				.valid(RC_Valid[i]),
				.shade_out(ShadeOut[i]),        				
				
				.primitive_query_0(PrimitiveQuery0[i]),
				.p0(P0[i]),

				.primitive_query_1(PrimitiveQuery1[i]),				
				.p1(P1[i])
			);                			
        end
    endgenerate      

endmodule
