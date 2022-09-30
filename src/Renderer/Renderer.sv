`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/23 15:44:53
// Design Name: 
// Module Name: Renderer
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

module Renderer(
    input clk,
	input resetn,

	// controls...     
	input vsync,
	output flip,
	input up,
    input down,
    input left,
    input right,

	// SD signals
	input sd_clk,
    output logic SD_SCK,
    inout SD_CMD,
    input logic [3:0] SD_DAT,	

	// inputs...	

    // outputs..
	output DebugData debug_data,    

	output MemoryWriteRequest fb_mem_w_req,
	output MemoryWriteRequest bvh_mem_w_req	
    );			

    RenderState RenderState;
			
	RendererState State, NextState = RS_Init;
    logic `SCREEN_COORD x, y;				
    logic FrameFlip, FrameFinished;		
	logic BVHStructureInitDone;

	// Performance counter
	logic [15:0] FrameCounter = 0;
	logic [9:0] FrameCycleCounter = 0;
	logic [15:0] FrameKCycleCounter = 0, FrameKCycles = 0;

	logic RS_Strobe, RS_Valid;

	logic TG_Strobe = 0, TG_Reset = 0;
	ThreadData TG_Output[`RAY_CORE_SIZE];

    logic RC_Valid[`RAY_CORE_SIZE], RC_FIFOFull[`RAY_CORE_SIZE];	
	ShadeOutputData ShadeOut[`RAY_CORE_SIZE];    	 

	PrimitiveQueryData AABB_Query_0[`RAY_CORE_SIZE];
	Primitive_AABB AABB_0[`RAY_CORE_SIZE][`AABB_TEST_UNIT_SIZE];    	

	PrimitiveQueryData AABB_Query_1[`RAY_CORE_SIZE];
	Primitive_AABB AABB_1[`RAY_CORE_SIZE][`AABB_TEST_UNIT_SIZE];    

	PrimitiveQueryData Sphere_Query_0[`RAY_CORE_SIZE];
	Primitive_Sphere Sphere_0[`RAY_CORE_SIZE][`SPHERE_TEST_UNIT_SIZE];    

	PrimitiveQueryData Sphere_Query_1[`RAY_CORE_SIZE];
	Primitive_Sphere Sphere_1[`RAY_CORE_SIZE][`SPHERE_TEST_UNIT_SIZE];    

	logic [`BVH_NODE_INDEX_WIDTH-1:0] BVHNodeIndex0[`RAY_CORE_SIZE], BVHNodeIndex1[`RAY_CORE_SIZE];
	BVH_Node BVHNode0[`RAY_CORE_SIZE], BVHNode1[`RAY_CORE_SIZE];
	BVH_Leaf BVHLeaf0[`RAY_CORE_SIZE][2], BVHLeaf1[`RAY_CORE_SIZE][2];
	
	Fixed3 CameraPos, CameraLook;
	Fixed CameraFocus;		
	Fixed Radius, OffsetPosX, OffsetPosZ;
	logic [31:0] CorePixelCounter[`RAY_CORE_SIZE];
	logic [31:0] PixelCounter;
	
	//logic [8:0] CameraDegree = 0;
	
    assign flip = FrameFlip;
	assign debug_data.Number[0] = FrameKCycles;	
	
	initial begin
		//$readmemh("E:/MyWork/HomebrewGPU/Prototype/HomebrewGPU/data/CameraPos.txt", CameraPosLUT);		

		//CameraDegree = 0;
		CameraPos = _Fixed3u(50, 30, -50);
		CameraLook = _Fixed3u(0, 10, 0);
		CameraFocus = _Fixed(10);        
		
		/*
		RenderState.ViewportWidth = `FRAMEBUFFER_WIDTH;	
		RenderState.ViewportHeight = `FRAMEBUFFER_HEIGHT;	

		RenderState.Lighting = 1;
		RenderState.Shadow = 1;	
		RenderState.MaxBounceLevel = 3;

		RenderState.ClearColor.Channel[0] = 8'd110;
		RenderState.ClearColor.Channel[1] = 8'd150;
		RenderState.ClearColor.Channel[2] = 8'd255;

		RenderState.Camera.VPW.Value = 25224;
		RenderState.Camera.VPH.Value = 18918;		
		RenderState.Camera.CUB.Value = `FIXED_WIDTH'd51;
		RenderState.Camera.CVB.Value = `FIXED_WIDTH'd68;				
		
		RenderState.Camera.Pos = _Fixed3u(50, 30, -50);
		RenderState.Camera.Look = _Fixed3u(0, 10, 0);				
		RenderState.Camera.FocusDist = _Fixed(10);
		RenderState.Camera.RH.Dim[0].Value = `FIXED_WIDTH'd4294893589;
		RenderState.Camera.RH.Dim[1].Value = `FIXED_WIDTH'd0;
		RenderState.Camera.RH.Dim[2].Value = `FIXED_WIDTH'd4294893589;		
		RenderState.Camera.RV.Dim[0].Value = `FIXED_WIDTH'd0;
		RenderState.Camera.RV.Dim[1].Value = `FIXED_WIDTH'd75718;
		RenderState.Camera.RV.Dim[2].Value = `FIXED_WIDTH'd0;		
		RenderState.Camera.BLC.Dim[0].Value = `FIXED_WIDTH'd811169;
		RenderState.Camera.BLC.Dim[1].Value = `FIXED_WIDTH'd435709;
		RenderState.Camera.BLC.Dim[2].Value = `FIXED_WIDTH'd4294229833;	

		RenderState.Light[0].Dir = _Fixed3u(-4, 6, -4);
		RenderState.Light[0].NormDir.Dim[0].Value = 57589;
		RenderState.Light[0].NormDir.Dim[1].Value = 11921;
		RenderState.Light[0].NormDir.Dim[2].Value = 57589;		
		*/

		Radius = _Fixed(26);	
	end		    
	
	/*
	function AnimateModel;		
		//RenderState.PositionOffset = _Fixed3(Fixed_Mul(_Fixed(26), Sin), _Fixed(11), Fixed_Mul(_Fixed(26), Cos));		
		//RenderState.PositionOffset = _Fixed3(OffsetPosX, _Fixed(11), OffsetPosZ);
		RenderState.PositionOffset.Dim[0].Value = Fixed_LSft(Sin, 4).Value + Fixed_LSft(Sin, 3).Value + Fixed_LSft(Sin, 1).Value;
		RenderState.PositionOffset.Dim[1].Value = _Fixed(11);
		RenderState.PositionOffset.Dim[2].Value = Fixed_LSft(Cos, 4).Value + Fixed_LSft(Cos, 3).Value + Fixed_LSft(Cos, 1).Value;
		RenderState.PositionOffset2 = _Fixed3u(0, 0, 0);				

		ModelDegree = ModelDegree + 6;
		if (ModelDegree >= 360) begin
			ModelDegree = ModelDegree - 360;
		end
	endfunction    

	function AnimateCamera;		
		//CameraPos.Dim[0].Value = CameraPosLUT[CameraDegree][383:352];
		//CameraPos.Dim[1].Value = CameraPosLUT[CameraDegree][351:320];
		//CameraPos.Dim[2].Value = CameraPosLUT[CameraDegree][319:288];

		CameraPos.Dim[0] = Fixed_Mul(_Fixed(40), Cos);
		CameraPos.Dim[1] = _Fixed(18);
		CameraPos.Dim[2] = Fixed_Mul(_Fixed(40), Sin);		

		CameraLook = _Fixed3u(0, -5, 0);
		CameraFocus = _Fixed(10);        

		CameraDegree = CameraDegree + 5;
		if (CameraDegree >= 36) begin
			CameraDegree = CameraDegree - 36;
		end		
	endfunction    
	*/

	always_ff @(posedge clk, negedge resetn) begin			
		if (!resetn) begin			
			NextState <= RS_Init;			
		end
		else begin						
			FrameCycleCounter = FrameCycleCounter + 1;
			if (FrameCycleCounter == 0) begin
				FrameKCycleCounter = FrameKCycleCounter + 1;
			end					

			State = NextState;	    

            case (State)
                default: begin					
					NextState <= RS_Init;
                end

                (RS_Init): begin												
					FrameFlip <= 0;														
					//ModelDegree <= 0;
					FrameCounter <= 0;
					
					TG_Strobe <= 0;
					TG_Reset <= 0;					                                        					
					RS_Strobe <= 0;

					//if (BVHStructureInitDone) begin
						NextState <= RS_FrameSetup;
					//end					
                end

				(RS_FrameSetup): begin						
					FrameCycleCounter = 0;
					FrameKCycleCounter <= 0;													
					
                    FrameFlip <= ~FrameFlip; 
                    x <= 0;
                    y <= 0; 		

					TG_Strobe <= 0;
					TG_Reset <= 1;	
					RS_Strobe <= 1;
					PixelCounter <= 0;
					FrameFinished <= 0;
					NextState <= RS_RenderStateSetup;											
				end

				(RS_RenderStateSetup): begin										
					RS_Strobe <= 0;
					if (RS_Valid) begin
						//RenderState <= NextFrameRS;
						//AnimateModel();							
						TG_Strobe <= 1;
						TG_Reset <= 0;	
						NextState <= RS_Render; 							
					end					
				end				

				(RS_Render): begin					                   
					TG_Strobe <= 1;
					TG_Reset <= 0;	
					RS_Strobe <= 0;					

					PixelCounter = 0;
					for (int i = 0; i < `RAY_CORE_SIZE; i = i + 1) begin                                						
						PixelCounter = PixelCounter + CorePixelCounter[i];
						if (PixelCounter >= `FRAMEBUFFER_PIXEL_COUNT) begin														
							FrameCounter = FrameCounter + 1;
							FrameKCycles = FrameKCycleCounter;
							NextState <= RS_Wait_VSync;
						end						
					end				
                end              

                (RS_Wait_VSync): begin					
                    TG_Strobe <= 0;
					TG_Reset <= 0;      
					RS_Strobe <= 0;    					                          
                    if (!vsync) begin		
						NextState <= RS_FrameSetup;
                    end
                end
            endcase		
		end
	end		  	
	
	// Process render state changes.
	RenderState RS(
		.clk(clk),	
		.resetn(resetn),
		.strobe(RS_Strobe),
		.pos(CameraPos),
		.look(CameraLook),		
		.focus_dist(CameraFocus),
		.up(up),
        .down(down),
        .left(left),
        .right(right),
		.rs(RenderState),
		.valid(RS_Valid)		
	);
	
	// Emit fragment threads for ray cores to process.
	ThreadGenerator TG(
    	.clk(clk),
		.resetn(resetn),	    	
		.strobe(TG_Strobe),
		.reset(TG_Reset),		
		.debug_data(debug_data),
		.rs(RenderState),
		.output_fifo_full(RC_FIFOFull),
    	.x0(x),
    	.y0(y),			
    	.thread_out(TG_Output)
    );

`ifdef DEBUG_CORE
	generate
        for (genvar i = 0; i < `RAY_CORE_SIZE; i = i + 1) begin : CORE_ARRY
			DebugCore DEBGCORE(
				.clk(clk),
				.resetn(resetn),		          
				.reset_pixel_counter(State == RS_FrameSetup),
				// controls...
				.add_input(TG_Output[i].DataValid),
				// inputs...
				.input_data(TG_Output[i].RayCoreInput),                
				.rs(RenderState),	

				.pixel_counter(CorePixelCounter[i]),
				.frame_counter(FrameCounter),
				// outputs...		
				.fifo_full(RC_FIFOFull[i]),        
				.valid(RC_Valid[i]),
				.shade_out(ShadeOut[i])
			);	
		end
	endgenerate  		
`else	
	`ifdef IMPLEMENT_BVH_TRAVERSAL
		BVHStructure BVHSTRUCTURE(   
			.clk(clk),	    
			.resetn(resetn), 

			.sd_clk(sd_clk),
			.SD_SCK(SD_SCK),
			.SD_CMD(SD_CMD),
			.SD_DAT(SD_DAT),

			.debug_data(debug_data),

			.mem_w_req(bvh_mem_w_req),
			
			.init_done(BVHStructureInitDone),
			.offset(RenderState.PositionOffset),

			.node_index_0(BVHNodeIndex0), 					
			.node_index_1(BVHNodeIndex1), 
			.node_0(BVHNode0),   
			.node_1(BVHNode1),    
			.leaf_0(BVHLeaf0),   
			.leaf_1(BVHLeaf1)
		);			
	`endif

	PrimitiveUnit PRIM(   
		.clk(clk),	    
		.resetn(resetn), 

		.offset(RenderState.PositionOffset),

		.aabb_query_0(AABB_Query_0),
		.aabb_0(AABB_0),		

		.aabb_query_1(AABB_Query_1),		
		.aabb_1(AABB_1),

		.sphere_query_0(Sphere_Query_0),		
		.sphere_0(Sphere_0),   

		.sphere_query_1(Sphere_Query_1),		
		.sphere_1(Sphere_1)  
	);			

	generate
        for (genvar i = 0; i < `RAY_CORE_SIZE; i = i + 1) begin : CORE_ARRY
			RayCore RAYCORE(
				.clk(clk),
				.resetn(resetn),
				.reset_pixel_counter(State == RS_FrameSetup),

				.add_input(TG_Output[i].DataValid),					
				.input_data(TG_Output[i].RayCoreInput),                

				.rs(RenderState),	

				.debug_data(debug_data),

				.pixel_counter(CorePixelCounter[i]),
				.fifo_full(RC_FIFOFull[i]),        
				.valid(RC_Valid[i]),
				.shade_out(ShadeOut[i]),        
				
				.node_index_0(BVHNodeIndex0[i]),
				.node_0(BVHNode0[i]),
				.leaf_0(BVHLeaf0[i]),

				.node_index_1(BVHNodeIndex1[i]),				
				.node_1(BVHNode1[i]),						
				.leaf_1(BVHLeaf1[i]),

				.aabb_query_0(AABB_Query_0[i]),
				.aabb_0(AABB_0[i]),

				.aabb_query_1(AABB_Query_1[i]),				
				.aabb_1(AABB_1[i]),

				.sphere_query_0(Sphere_Query_0[i]),
				.sphere_0(Sphere_0[i]),

				.sphere_query_1(Sphere_Query_1[i]),				
				.sphere_1(Sphere_1[i])
			);                			
        end
    endgenerate  
`endif

	FrameBufferWriter FBW(
		.clk(clk),	
		.resetn(resetn),
        .strobe(RC_Valid),        
		.flip(FrameFlip),	
		.data(ShadeOut),
		.mem_request(fb_mem_w_req)
	);        		  

endmodule
