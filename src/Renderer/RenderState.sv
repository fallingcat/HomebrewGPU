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

`define CONSTANT_CAMERA				1

module ModelAnimation(
	input clk,
	input resetn,
	input strobe,
	output Fixed3 offset,
	output Fixed3 offset2
	);			
	Fixed Sin, Cos;
	logic [8:0] ModelDegree = 0;
	Fixed Radius, OffsetPosX, OffsetPosZ;

	initial begin
		Radius = _Fixed(26);
	end

	always_ff @(posedge clk, negedge resetn) begin			
		if (!resetn) begin
			ModelDegree <= 0;			
		end
		else begin		
			if (strobe) begin
				//offset <= _Fixed3(Fixed_Mul(_Fixed(26), Sin), _Fixed(11), Fixed_Mul(_Fixed(26), Cos));		
				offset <= _Fixed3(OffsetPosX, _Fixed(11), OffsetPosZ);
				//RenderState.PositionOffset.Dim[0].Value = Fixed_LSft(Sin, 4).Value + Fixed_LSft(Sin, 3).Value + Fixed_LSft(Sin, 1).Value;
				//RenderState.PositionOffset.Dim[1].Value = _Fixed(11);
				//offset.PositionOffset.Dim[2].Value = Fixed_LSft(Cos, 4).Value + Fixed_LSft(Cos, 3).Value + Fixed_LSft(Cos, 1).Value;
				offset2 <= _Fixed3u(0, 0, 0);				

				ModelDegree = ModelDegree + 3;
				if (ModelDegree >= 360) begin
					ModelDegree = ModelDegree - 360;
				end						
			end			
		end
	end
	Fixed_CosSin COSSIN(ModelDegree, Cos, Sin);
	Fixed_Mul MODEL_ANI_0(Radius, Sin, OffsetPosX);
	Fixed_Mul MODEL_ANI_1(Radius, Cos, OffsetPosZ);
endmodule

module ModelControl(
	input clk,
	input resetn,		
	input up,
	input down,
	input left,
	input right,
	output Fixed3 offset,
	output Fixed3 offset2
	);				

	logic [20:0] Counter;
	
	always_ff @(posedge clk, negedge resetn) begin			
		if (!resetn) begin				
		end
		else begin			
			Counter = Counter + 1;
			if (Counter == 0) begin
				if (up) begin
					offset.Dim[2] = Fixed_Add(offset.Dim[2], _Fixed(1));
				end
				else if (down) begin
					offset.Dim[2] = Fixed_Sub(offset.Dim[2], _Fixed(1));
				end

				if (left) begin
					offset.Dim[0] = Fixed_Add(offset.Dim[0], _Fixed(1));
				end
				else if (right) begin
					offset.Dim[0] = Fixed_Sub(offset.Dim[0], _Fixed(1));
				end
				offset.Dim[1] = _Fixed(11);
				offset2 <= _Fixed3u(0, 0, 0);							
			end
		end
	end	
endmodule

module RenderState (
	input clk,	
	input resetn,
	input strobe,
    input Fixed3 pos,
    input Fixed3 look,
	input Fixed focus_dist,

	input up,
    input down,
    input left,
    input right,
	
	output RenderState rs,
	output logic valid
	);

	logic Norm_Strobe = 0, Norm_Valid, AnimationStrobe;
    Fixed3 A, B;
	Fixed TempFixed;	
    RenderStateState State, NextState = RSS_Init;	
	
`ifdef CONSTANT_CAMERA
	initial begin
		rs.ViewportWidth <= `FRAMEBUFFER_WIDTH;	
		rs.ViewportHeight <= `FRAMEBUFFER_HEIGHT;	

		rs.Lighting <= 1;
		rs.Shadow <= 1;	
		rs.MaxBounceLevel <= `RS_MAX_BOUNCE_LEVEL;

		rs.ClearColor.Channel[0] <= 8'd110;
		rs.ClearColor.Channel[1] <= 8'd150;
		rs.ClearColor.Channel[2] <= 8'd255;		                        

		rs.Camera.VPW.Value <= `FIXED_WIDTH'd25224;
		rs.Camera.VPH.Value <= `FIXED_WIDTH'd18919;
		rs.Camera.CUB.Value <= `FIXED_WIDTH'd51;
		rs.Camera.CVB.Value <= `FIXED_WIDTH'd68;	

		rs.Camera.Pos <= _Fixed3u(40, 40, -40);
		rs.Camera.Look <= _Fixed3u(0, 10, 0);				
		rs.Camera.FocusDist <= _Fixed(10);

		rs.Camera.RH.Dim[0].Value <= `FIXED_WIDTH'd4294432198;
		rs.Camera.RH.Dim[1].Value <= `FIXED_WIDTH'd0;
		rs.Camera.RH.Dim[2].Value <= `FIXED_WIDTH'd4294432198;		

		rs.Camera.RV.Dim[0].Value <= `FIXED_WIDTH'd0;
		rs.Camera.RV.Dim[1].Value <= `FIXED_WIDTH'd567557;
		rs.Camera.RV.Dim[2].Value <= `FIXED_WIDTH'd0;		

		rs.Camera.BLC.Dim[0].Value <= `FIXED_WIDTH'd615859;
		rs.Camera.BLC.Dim[1].Value <= `FIXED_WIDTH'd141293;
		rs.Camera.BLC.Dim[2].Value <= `FIXED_WIDTH'd4294886536;		

		//rs.Camera.dU <= Fixed3_Mul(rs.Camera.CUB, rs.Camera.RH);
		//rs.Camera.dV <= Fixed3_Mul(rs.Camera.CVB, rs.Camera.RV);
		
		rs.Camera.dU.Dim[0].Value <= `FIXED_WIDTH'd4294955711;
		rs.Camera.dU.Dim[1].Value <= `FIXED_WIDTH'd0;
		rs.Camera.dU.Dim[2].Value <= `FIXED_WIDTH'd4294955711;
		
		rs.Camera.dV.Dim[0].Value <= `FIXED_WIDTH'd0;
		rs.Camera.dV.Dim[1].Value <= `FIXED_WIDTH'd16384;
		rs.Camera.dV.Dim[2].Value <= `FIXED_WIDTH'd0;		

		/*
		rs.Camera.Pos <= _Fixed3u(50, 30, -50);
		rs.Camera.Look <= _Fixed3u(0, 10, 0);				
		rs.Camera.FocusDist <= _Fixed(10);

		rs.Camera.RH.Dim[0].Value <= `FIXED_WIDTH'd4294893589;
		rs.Camera.RH.Dim[1].Value <= `FIXED_WIDTH'd0;
		rs.Camera.RH.Dim[2].Value <= `FIXED_WIDTH'd4294893589;		

		rs.Camera.RV.Dim[0].Value <= `FIXED_WIDTH'd0;
		rs.Camera.RV.Dim[1].Value <= `FIXED_WIDTH'd75718;
		rs.Camera.RV.Dim[2].Value <= `FIXED_WIDTH'd0;		

		rs.Camera.BLC.Dim[0].Value <= `FIXED_WIDTH'd811169;
		rs.Camera.BLC.Dim[1].Value <= `FIXED_WIDTH'd435709;
		rs.Camera.BLC.Dim[2].Value <= `FIXED_WIDTH'd4294229833;		

		//rs.Camera.dU <= Fixed3_Mul(rs.Camera.CUB, rs.Camera.RH);
		//rs.Camera.dV <= Fixed3_Mul(rs.Camera.CVB, rs.Camera.RV);
		
		rs.Camera.dU.Dim[0].Value <= `FIXED_WIDTH'd4294967074;
		rs.Camera.dU.Dim[1].Value <= `FIXED_WIDTH'd0;
		rs.Camera.dU.Dim[2].Value <= `FIXED_WIDTH'd4294967074;
		
		rs.Camera.dV.Dim[0].Value <= `FIXED_WIDTH'd0;
		rs.Camera.dV.Dim[1].Value <= `FIXED_WIDTH'd315;
		rs.Camera.dV.Dim[2].Value <= `FIXED_WIDTH'd0;		
		*/
		
		rs.Light[0].Dir <= _Fixed3u(-4, 6, -4);
		rs.Light[0].InvDir.Dim[0].Value <= `FIXED_WIDTH'd4294963200;
		rs.Light[0].InvDir.Dim[1].Value <= `FIXED_WIDTH'd2730;
		rs.Light[0].InvDir.Dim[2].Value <= `FIXED_WIDTH'd4294963200;
		rs.Light[0].NormDir.Dim[0].Value <= `FIXED_WIDTH'd57589;
		rs.Light[0].NormDir.Dim[1].Value <= `FIXED_WIDTH'd11921;
		rs.Light[0].NormDir.Dim[2].Value <= `FIXED_WIDTH'd57589;

		rs.PositionOffset <= _Fixed3u(0, 11, 0);							
		rs.PositionOffset2 <= _Fixed3u(0, 0, 0);							
	end
	
	always_ff @( posedge clk, negedge resetn ) begin
		if (!resetn) begin
			NextState <= RSS_Init;
		end
		else begin		
			State = NextState;

			case (State)
				default: begin
					Norm_Strobe <= 0;
					AnimationStrobe <= 0;
					NextState <= RSS_Init;
				end

				(RSS_Init): begin						
					Norm_Strobe <= 0;	
					AnimationStrobe <= 0;	

					if (strobe) begin		
						valid <= 0;
						AnimationStrobe <= 1;	
                        NextState <= RSS_Done;					
					end
				end

				(RSS_Done): begin
					Norm_Strobe <= 0;
					AnimationStrobe <= 0;
					valid <= 1;
					NextState <= RSS_Init;
				end
			endcase
		end
	end

	/*
	ModelAnimation MDL_ANI(
		.clk(clk),	
		.resetn(resetn),
		.strobe(AnimationStrobe),
		.offset(rs.PositionOffset),
		.offset2(rs.PositionOffset2)
	);
	*/
	
	ModelControl MDL_CONTROL(
		.clk(clk),	
		.resetn(resetn),
		.up(up),
        .down(down),
        .left(left),
        .right(right),
		.offset(rs.PositionOffset),
		.offset2(rs.PositionOffset2)
	);

`else
	always_ff @( posedge clk, negedge resetn ) begin
		if (!resetn) begin
			NextState <= RSS_Init;
		end
		else begin		
			State = NextState;

			case (State)
				default: begin
					Norm_Strobe <= 0;
					NextState <= RSS_Init;
				end

				(RSS_Init): begin	
					valid <= 0;
					Norm_Strobe <= 0;		

					if (strobe) begin			
                        rs.ViewportWidth <= `FRAMEBUFFER_WIDTH;	
                        rs.ViewportHeight <= `FRAMEBUFFER_HEIGHT;	

                        rs.Lighting <= 1;
                        rs.Shadow <= 1;	
                        rs.MaxBounceLevel <= 4;

                        rs.ClearColor.Channel[0] <= 8'd110;
                        rs.ClearColor.Channel[1] <= 8'd150;
                        rs.ClearColor.Channel[2] <= 8'd255;		

                        rs.Light[0].Dir <= _Fixed3u(-4, 6, -4);
                        rs.Light[0].NormDir.Dim[0].Value <= 57589;
                        rs.Light[0].NormDir.Dim[1].Value <= 11921;
                        rs.Light[0].NormDir.Dim[2].Value <= 57589;	

                        rs.Camera.VPW.Value <= `FIXED_WIDTH'd25224;
					    rs.Camera.VPH.Value <= `FIXED_WIDTH'd18919;

                        rs.Camera.VPW.Value <= `FIXED_WIDTH'd25224;
                        rs.Camera.VPH.Value <= `FIXED_WIDTH'd18919;						
                        rs.Camera.CUB.Value <= `FIXED_WIDTH'd51;
					    rs.Camera.CVB.Value <= `FIXED_WIDTH'd68;	

						NextState <= RSS_InitCameraSetup;					
					end
				end

                (RSS_InitCameraSetup): begin
					valid <= 0;
                    rs.Camera.Pos = pos;
					rs.Camera.Look = look;		
					rs.Camera.FocusDist = focus_dist;
					A = Fixed3_Sub(rs.Camera.Pos, rs.Camera.Look);					
					Norm_Strobe <= 1;						
					NextState <= RSS_SetupCameraW;										
                end

				(RSS_SetupCameraW): begin								
					valid <= 0;
					Norm_Strobe <= 0;
					if (Norm_Valid) begin						
						rs.Camera.W = B;	
						Norm_Strobe <= 1;
						A = _Fixed3(rs.Camera.W.Dim[2], _Fixed(0), Fixed_Neg(rs.Camera.W.Dim[0]));																		
						NextState <= RSS_SetupCameraU;					
					end
				end

				(RSS_SetupCameraU): begin							
					valid <= 0;
					Norm_Strobe <= 0;											
					if (Norm_Valid) begin						
						rs.Camera.U = B;	
						Norm_Strobe <= 1;
						A = _Fixed3(Fixed_Mul(rs.Camera.W.Dim[2], Fixed_Neg(rs.Camera.U.Dim[1])),
									Fixed_Sub(Fixed_Mul(rs.Camera.W.Dim[2], rs.Camera.U.Dim[0]), Fixed_Mul(rs.Camera.W.Dim[0], rs.Camera.U.Dim[2])),
									Fixed_Mul(rs.Camera.W.Dim[0], rs.Camera.U.Dim[1]));																				
						NextState <= RSS_SetupCameraV;					
					end
				end

				(RSS_SetupCameraV): begin		
					valid <= 0;				
					Norm_Strobe <= 0;				
					if (Norm_Valid) begin
						rs.Camera.V = B;					
						NextState <= RSS_SetupCameraBLC;
					end
				end

				(RSS_SetupCameraBLC): begin	
					valid <= 0;
					Norm_Strobe <= 0;

					TempFixed = Fixed_Mul(rs.Camera.FocusDist, rs.Camera.VPW);
					rs.Camera.RH.Dim[0] = Fixed_Mul(TempFixed, rs.Camera.U.Dim[0]);
					rs.Camera.RH.Dim[1] = Fixed_Mul(TempFixed, rs.Camera.U.Dim[1]);
					rs.Camera.RH.Dim[2] = Fixed_Mul(TempFixed, rs.Camera.U.Dim[2]);	
					
					TempFixed = Fixed_Mul(rs.Camera.FocusDist, rs.Camera.VPH);
					rs.Camera.RV.Dim[0] = Fixed_Mul(TempFixed, rs.Camera.V.Dim[0]);
					rs.Camera.RV.Dim[1] = Fixed_Mul(TempFixed, rs.Camera.V.Dim[1]);
					rs.Camera.RV.Dim[2] = Fixed_Mul(TempFixed, rs.Camera.V.Dim[2]);									

					rs.Camera.BLC = _Fixed3(
						Fixed_Sub(Fixed_Sub(Fixed_Sub(rs.Camera.Pos.Dim[0], Fixed_RSft(rs.Camera.RH.Dim[0], 1)), Fixed_RSft(rs.Camera.RV.Dim[0], 1)), Fixed_Mul(rs.Camera.FocusDist, rs.Camera.W.Dim[0])),
						Fixed_Sub(Fixed_Sub(Fixed_Sub(rs.Camera.Pos.Dim[1], Fixed_RSft(rs.Camera.RH.Dim[1], 1)), Fixed_RSft(rs.Camera.RV.Dim[1], 1)), Fixed_Mul(rs.Camera.FocusDist, rs.Camera.W.Dim[1])),
						Fixed_Sub(Fixed_Sub(Fixed_Sub(rs.Camera.Pos.Dim[2], Fixed_RSft(rs.Camera.RH.Dim[2], 1)), Fixed_RSft(rs.Camera.RV.Dim[2], 1)), Fixed_Mul(rs.Camera.FocusDist, rs.Camera.W.Dim[2])));					
					
					NextState <= RSS_Done;					
				end

				(RSS_Done): begin
					valid <= 1;
					NextState <= RSS_Init;
				end
			endcase			
		end
	end

	Fixed3_NormV2 FNorm_0(
		.clk(clk), 
		.strobe(Norm_Strobe),
		.v(A),
		.ov(B),
		.valid(Norm_Valid)
	);	   	

	ModelAnimation MDL_ANI(
		.clk(clk),	
		.resetn(resetn),
		.strobe(AnimationStrobe),
		.offset(rs.PositionOffset),
		.offset2(rs.PositionOffset2)
	);

`endif

endmodule