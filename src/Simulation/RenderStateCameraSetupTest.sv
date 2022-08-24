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

module RenderStateCameraSetupTest;
	logic CLK;
    Fixed3 CameraPos, CameraLook;
    Fixed VPW;
    Fixed VPH;
    Fixed CameraFocus;
    Camera CameraData;
    
    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz
	always #(CLK_PERIOD/2) CLK = ~CLK;	

    RenderState_Camera RS_C(
		.clk(CLK),	
        .pos(CameraPos),
        .look(CameraLook),
        .focus_dist(CameraFocus),
        .vp_w(VPW),
	    .vp_h(VPH),
	    .camera(CameraData)	
        );    
    

    initial begin
	    CLK = 1;

        #10
        CameraPos = _Fixed3u(15, 15, -25);
	    CameraLook = _Fixed3u(0, -5, 0);
        CameraFocus = _Fixed(10);        
        VPW.Value = 25224;
        VPH.Value = 18919;

        #30
        $display($time, " Camera U = (%d, %d, %d)\n", CameraData.U.Dim[0].Value, CameraData.U.Dim[1].Value, CameraData.U.Dim[2].Value);
        $display($time, " Camera V = (%d, %d, %d)\n", CameraData.V.Dim[0].Value, CameraData.V.Dim[1].Value, CameraData.V.Dim[2].Value);
        $display($time, " Camera W = (%d, %d, %d)\n", CameraData.W.Dim[0].Value, CameraData.W.Dim[1].Value, CameraData.W.Dim[2].Value);

        #30
        $display($time, " Camera U = (%d, %d, %d)\n", CameraData.U.Dim[0].Value, CameraData.U.Dim[1].Value, CameraData.U.Dim[2].Value);
        $display($time, " Camera V = (%d, %d, %d)\n", CameraData.V.Dim[0].Value, CameraData.V.Dim[1].Value, CameraData.V.Dim[2].Value);
        $display($time, " Camera W = (%d, %d, %d)\n", CameraData.W.Dim[0].Value, CameraData.W.Dim[1].Value, CameraData.W.Dim[2].Value);

        #30
        $display($time, " Camera U = (%d, %d, %d)\n", CameraData.U.Dim[0].Value, CameraData.U.Dim[1].Value, CameraData.U.Dim[2].Value);
        $display($time, " Camera V = (%d, %d, %d)\n", CameraData.V.Dim[0].Value, CameraData.V.Dim[1].Value, CameraData.V.Dim[2].Value);
        $display($time, " Camera W = (%d, %d, %d)\n", CameraData.W.Dim[0].Value, CameraData.W.Dim[1].Value, CameraData.W.Dim[2].Value);

        #30
        $display($time, " Camera U = (%d, %d, %d)\n", CameraData.U.Dim[0].Value, CameraData.U.Dim[1].Value, CameraData.U.Dim[2].Value);
        $display($time, " Camera V = (%d, %d, %d)\n", CameraData.V.Dim[0].Value, CameraData.V.Dim[1].Value, CameraData.V.Dim[2].Value);
        $display($time, " Camera W = (%d, %d, %d)\n", CameraData.W.Dim[0].Value, CameraData.W.Dim[1].Value, CameraData.W.Dim[2].Value);

        #30
        $display($time, " Camera U = (%d, %d, %d)\n", CameraData.U.Dim[0].Value, CameraData.U.Dim[1].Value, CameraData.U.Dim[2].Value);
        $display($time, " Camera V = (%d, %d, %d)\n", CameraData.V.Dim[0].Value, CameraData.V.Dim[1].Value, CameraData.V.Dim[2].Value);
        $display($time, " Camera W = (%d, %d, %d)\n", CameraData.W.Dim[0].Value, CameraData.W.Dim[1].Value, CameraData.W.Dim[2].Value);

        #30
        $display($time, " Camera U = (%d, %d, %d)\n", CameraData.U.Dim[0].Value, CameraData.U.Dim[1].Value, CameraData.U.Dim[2].Value);
        $display($time, " Camera V = (%d, %d, %d)\n", CameraData.V.Dim[0].Value, CameraData.V.Dim[1].Value, CameraData.V.Dim[2].Value);
        $display($time, " Camera W = (%d, %d, %d)\n", CameraData.W.Dim[0].Value, CameraData.W.Dim[1].Value, CameraData.W.Dim[2].Value);

        #130
        $display($time, "-----------------------------------------------------------------------------------------------\n\n");
        $display($time, " Camera U = (%d, %d, %d)\n", CameraData.U.Dim[0].Value, CameraData.U.Dim[1].Value, CameraData.U.Dim[2].Value);
        $display($time, " Camera V = (%d, %d, %d)\n", CameraData.V.Dim[0].Value, CameraData.V.Dim[1].Value, CameraData.V.Dim[2].Value);
        $display($time, " Camera W = (%d, %d, %d)\n", CameraData.W.Dim[0].Value, CameraData.W.Dim[1].Value, CameraData.W.Dim[2].Value);
        $display($time, " Camera RH = (%d, %d, %d)\n", CameraData.RH.Dim[0].Value, CameraData.RH.Dim[1].Value, CameraData.RH.Dim[2].Value);
        $display($time, " Camera RV = (%d, %d, %d)\n", CameraData.RV.Dim[0].Value, CameraData.RV.Dim[1].Value, CameraData.RV.Dim[2].Value);
        $display($time, " Camera BLC = (%d, %d, %d)\n", CameraData.BLC.Dim[0].Value, CameraData.BLC.Dim[1].Value, CameraData.BLC.Dim[2].Value);

	    #100
	    $finish;
    end	
    
endmodule
