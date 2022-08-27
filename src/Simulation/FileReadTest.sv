`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/30 16:58:48
// Design Name: 
// Module Name: FrameBufferTest
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

module FileReadTest;

    logic CLK, CLK100;
    integer file;
    BVH_Primitive_AABB P[4];
    

    

    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz
	always #(CLK_PERIOD / 2) CLK100 = ~CLK100;
    always #(CLK_PERIOD * 2) CLK = ~CLK;

    initial begin
        CLK100 = 1;
	    CLK = 1;
	
	    #10
        /*file = $fopen("E:/MyWork/HomebrewGPU/Prototype/HomebrewGPU/data/test_4voxel.bvh.primitives.txt", "r");
        if (file == 0) begin
            $display($time, "Fail to open file!\n");	   
        end
        */

        //while(!$feof(file))
        //begin
            //for (int i = 0; i< 4; i = i + 1) begin
                $readmemh("E:/MyWork/HomebrewGPU/Prototype/HomebrewGPU/data/test_4voxel.bvh.primitives.txt", P);
                
                    //$fscanf(file, "%d", P[i].Aabb.Min.Dim[0].Value);                
                    //$fscanf(file, "%d", P[i].Aabb.Min.Dim[1].Value);                
                    //$fscanf(file, "%d", P[i].Aabb.Min.Dim[2].Value);                

                    //$fscanf(file, "%d", P[i].Aabb.Max.Dim[0].Value);                
                    //$fscanf(file, "%d", P[i].Aabb.Max.Dim[1].Value);                
                    //$fscanf(file, "%d", P[i].Aabb.Max.Dim[2].Value);                

                    //$fscanf(file, "%d", P[i].Color);                

                    //$fscanf(file, "%h", P[0]);                
            //end				
        //end

        //$fclose(file);

	    	
        #100
        //$display($time, " AABB : Min (%f, %f, %f)\n", Fixed_Neg(P[0].Aabb.Min.Dim[0].Value)/(1.0 * (1 << `FIXED_FRAC_WIDTH)), Fixed_Neg(P[0].Aabb.Min.Dim[1].Value)/(1.0 * (1 << `FIXED_FRAC_WIDTH)), Fixed_Neg(P[0].Aabb.Min.Dim[2].Value)/(1.0 * (1 << `FIXED_FRAC_WIDTH)));	   
        $display($time, " AABB : Min (%f, %f, %f)\n", P[0].Aabb.Max.Dim[0].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), P[0].Aabb.Max.Dim[1].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)), P[0].Aabb.Max.Dim[2].Value/(1.0 * (1 << `FIXED_FRAC_WIDTH)));	   

        $display($time, " AABB : Min (%x, %x, %x)\n", P[3].Aabb.Min.Dim[0].Value, P[3].Aabb.Min.Dim[1].Value, P[3].Aabb.Min.Dim[2].Value);	   
        $display($time, " AABB : Max (%x, %x, %x)\n", P[3].Aabb.Max.Dim[0].Value, P[3].Aabb.Max.Dim[1].Value, P[3].Aabb.Max.Dim[2].Value);	   
        $display($time, " AABB : Color (%x, %x, %x)\n", P[3].Color.Channel[0], P[3].Color.Channel[1], P[3].Color.Channel[2]);	   

	    #600
	    $finish;
    end   

endmodule

