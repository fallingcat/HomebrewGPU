`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/14 22:07:14
// Design Name: 
// Module Name: RayCoreTest
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

module RayCoreTest;
    
    // Inputs
	logic CLK;
	logic [10:0] x, y;
	logic vsync = 1;
	Fixed HitT;
	logic CoreStart;
    
    //parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz
	parameter CLK_PERIOD = 20;  // 20 ns == 50 MHz
	always #(CLK_PERIOD/2) CLK = ~CLK;	
	
	MemoryControllerRequest mem_request;
	RenderState RenderState;		
	RendererState State = RS_Init;
	
	RGB8 FinalColor[4];
	logic `SCREEN_COORD cx[4], cy[4], ix, iy;	
	logic RayCoreStrobe;
	RayCoreState RayCoreState[4];	
	logic FrameFlip = 0;	
	logic FrameStart = 0;	
	logic [4:0] FrameCounter = 0;

	Fixed Zero;
	Fixed Half;	
	Fixed3 LN;	

	RayCore_1 RC_0(
		.clk(CLK),
		.resetn(1),
		.strobe(RayCoreStrobe),
		.frame_start(0),
		.rs(RenderState),
		.x(cx[0]), 
		.y(cy[0]), 
		.color(FinalColor[0]),
		.state(RayCoreState[0])
	);

	

	/*FrameBufferWriter FBW(
		.clk(CLK),	
		.resetn(1),
		.flip(FrameFlip),	
		.ix(cx[0]),
		.iy(cy[0]),
    	.i_color(FinalColor[0]),
		.ray_core_state(RayCoreState[0]),
		.mem_request(mem_request)
		);   */

	function AlwaysLoop;
		case (State)
			default: begin
				//ix = 0;
				//iy = 0;	
				FrameFlip = 0;
				RayCoreStrobe = 0;
				State = RS_Init;
			end

			(RS_Init): begin					
				if (RayCoreState[0] == RCS_Init) begin						
					RenderState.Light[0].NormDir = FromFixed3(LN);	
					FrameFlip = 0;						
					//ix = 0;
					//iy = 0; 						
					FrameStart = 1;		
					RayCoreStrobe = 1;
					State = RS_Render; 
				end
				else begin
					RayCoreStrobe = 0;
				end
			end

			(RS_Render): begin
				FrameStart = 0;
				RayCoreStrobe = 0;
				if (RayCoreState[0] == RCS_Done) begin						 																		
					State = RS_RenderStep;						
				end					
			end

			(RS_RenderStep): begin
				RayCoreStrobe = 1;
				ix = ix + 1;
				if (ix >= `FRAMEBUFFER_WIDTH) begin
					ix = 0;
					iy = iy + 1;							
				end	

				if (iy >= `FRAMEBUFFER_HEIGHT && ix == 2) begin														
					State = RS_Wait_VSync;								
				end
				else begin
					State = RS_Render;								
				end
			end

			(RS_Wait_VSync): begin
				if (!vsync) begin
					if (RayCoreState[0] == RCS_Init) begin														
						FrameFlip = ~FrameFlip; 
						ix = 0;
						iy = 0; 													
						FrameStart = 1;
						RayCoreStrobe = 1;
						State = RS_Render; 														
					end
				end                    
				else begin
					RayCoreStrobe = 0;  
				end
			end
		endcase		

		cx[0] = ix;
		cy[0] = iy;							
	endfunction

	function RS_RenderFunc;
		FrameStart = 0;
		if (RayCoreState[0] == RCS_Done) begin						 												
			RayCoreStrobe = 1;
			ix = ix + 1;
			if (ix >= `FRAMEBUFFER_WIDTH) begin
				ix = 0;
				iy = iy + 1;							
			end	
		end
		else if (RayCoreState[0] == RCS_SetupRay) begin
			RayCoreStrobe = 0;
		end
		cx[0] = ix;
		cy[0] = iy;		
	endfunction

	initial begin	
		CLK = 1;		

		Zero.Value = 0;
		Half.Value = `FIXED_HALF_UNIT;

		RenderState.ViewportWidth = `FRAMEBUFFER_WIDTH;	
		RenderState.ViewportHeight = `FRAMEBUFFER_HEIGHT;	

		RenderState.Shadowing = 0;

		RenderState.ClearColor.Channel[0] = 8'd0;
        RenderState.ClearColor.Channel[1] = 8'd127;
        RenderState.ClearColor.Channel[2] = 8'd255;

		RenderState.Camera.ViewPortW.Value = 25224;
		RenderState.Camera.ViewPortH.Value = 18918;

		// Initialize Inputs		
		RenderState.Camera.Pos = _Fixed3u(4, 2, 4);
		RenderState.Camera.Look = _Fixed3u(0, 0, 0);
				
		RenderState.Camera.W.Dim[0].Value = 10922;
		RenderState.Camera.W.Dim[1].Value = 5461;
		RenderState.Camera.W.Dim[2].Value = 10922;
		
		RenderState.Camera.U.Dim[0].Value = 12290;
		RenderState.Camera.U.Dim[1].Value = 0;
		RenderState.Camera.U.Dim[2].Value = -11585;
		
		RenderState.Camera.V.Dim[0].Value = 0;
		RenderState.Camera.V.Dim[1].Value = 16384;
		RenderState.Camera.V.Dim[2].Value = 0;
		
		RenderState.Camera.RH.Dim[0].Value = `FIXED_WIDTH'd190457;
		RenderState.Camera.RH.Dim[1].Value = `FIXED_WIDTH'd0;
		RenderState.Camera.RH.Dim[2].Value = `FIXED_WIDTH'd4294776839;
		
		RenderState.Camera.RV.Dim[0].Value = `FIXED_WIDTH'd0;
		RenderState.Camera.RV.Dim[1].Value = `FIXED_WIDTH'd190427;
		RenderState.Camera.RV.Dim[2].Value = `FIXED_WIDTH'd0;
		
		RenderState.Camera.BLC.Dim[0].Value = `FIXED_WIDTH'd4294828384;
		RenderState.Camera.BLC.Dim[1].Value = `FIXED_WIDTH'd4294850241;
		RenderState.Camera.BLC.Dim[2].Value = `FIXED_WIDTH'd51544;	
		
		RenderState.Camera.CUB.Value = `FIXED_WIDTH'd51;
		RenderState.Camera.CVB.Value = `FIXED_WIDTH'd68;						

        //RenderState.Light[0].Dir.Dim[0].Value = `FIXED_WIDTH'd4294954160;
        //RenderState.Light[0].Dir.Dim[1].Value = `FIXED_WIDTH'd8757;
        //RenderState.Light[0].Dir.Dim[2].Value = `FIXED_WIDTH'd4378;
				
		//LightRad.Value <= 0;
		//RenderState.Light[0].Dir = _Fixed3u(-4, 6, 4);				
		RenderState.Light[0].Dir = _Fixed3u(-3, 2, 1);		
		State = RS_Init;		
		ix = 160;
		iy = 120;		
		//ix = 172;
		//iy = 113;		
		//ix = 0;
		//iy = 0;		
		AlwaysLoop();

		
		#20		
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		vsync = 0;
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		vsync = 1;
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();

		#20
		AlwaysLoop();


		#200
		$finish;
	end
	
endmodule
