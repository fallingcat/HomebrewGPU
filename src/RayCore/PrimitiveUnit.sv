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

/*
`include "../Types.sv"
`include "../Math/Fixed.sv"
`include "../Math/Fixed3.sv"
`include "../Math/FixedNorm.sv"
`include "../Math/FixedNorm3.sv"

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module PostPrimitiveUnit (   
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] i,
    input Fixed3 offset,
    input AABB aabb,    
    output AABB out_aabb
    );
    Fixed3 FinalOffset;    

    always_comb begin       
    `ifdef NO_BVH_MODEL         
        if (i < `BVH_MODEL_RAW_DATA_SIZE || i == (`BVH_MODEL_RAW_DATA_SIZE + 1)) begin          
            FinalOffset <= offset;            
        end
        else begin
            FinalOffset <= _Fixed3(FixedZero(), FixedZero(), FixedZero());
        end
    `else
        if (i < `BVH_MODEL_RAW_DATA_SIZE) begin          
            FinalOffset <= offset;            
        end
        else begin
            FinalOffset <= _Fixed3(FixedZero(), FixedZero(), FixedZero());
        end
    `endif
    end
    
    Fixed3_Add A0(aabb.Min, FinalOffset, out_aabb.Min);
    Fixed3_Add A1(aabb.Max, FinalOffset, out_aabb.Max);
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module FetchPrimitiveAABB (   
    input logic [31:0] s,
    input logic [95:0] a,
    output AABB out
    );      
    Fixed S;  
    Fixed3 A;

    always_comb begin
        S.Value <= s;        
        A.Dim[0].Value <= a[95:64];
        A.Dim[1].Value <= a[63:32];
        A.Dim[2].Value <= a[31:0];        
    end

    Fixed3_SubOffset MIN(A, S, out.Min);
    Fixed3_AddOffset MAX(A, S, out.Max);
    
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module FetchPrimitiveColor (   
    input logic [23:0] a,
    output RGB8 out
    );

    always_comb begin
        out.Channel[0] <= a[23:16];
        out.Channel[1] <= a[15:8];
        out.Channel[2] <= a[7:0];
    end
    
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module FetchPrimitiveSurafceType (   
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] i,
    input logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] threshold,    
    output logic `VOXEL_INDEX vi,      
    output SurfaceType out
    );

    always_comb begin
        if (i < threshold && i < `BVH_PRIMITIVE_RAW_DATA_SIZE) begin
            vi <=  i;
        end
        else begin
            vi <= `NULL_VOXEL_INDEX;  
        end

        if (i >= (`BVH_MODEL_RAW_DATA_SIZE + 1)) begin                    
            out <= ST_Metal;
            //out <= ST_Lambertian;            
        end 
        else begin
            out <= ST_Lambertian;
        end                
    end   
        
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module BVHPrimitiveUnit (   
    input Fixed3 offset,
    input logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start0,     
    input logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] threshold0,    
    input logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start1,     
    input logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] threshold1,    
    output BVH_Primitive p0[`BVH_AABB_TEST_UNIT_SIZE],
    output BVH_Primitive p1[`BVH_AABB_TEST_UNIT_SIZE]
    );
    
    Fixed Scale, Scale2, Scale3;
    AABB TempAABB[2][`BVH_AABB_TEST_UNIT_SIZE];
    logic [151:0] PrimitiveRawData[`BVH_PRIMITIVE_RAW_DATA_SIZE];          
    //-------------------------------------------------------------------
    //
    //-------------------------------------------------------------------    
    function AddReflectiveBoxAndGroundPrimitive();
        // Ground ----
        Scale = _Fixed(256);
        Scale2 = _Fixed(-256);        

        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE][151:120] = `FIXED_ZERO;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE][119:88]  = Scale2.Value;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE][87:56]   = `FIXED_ZERO;
        
        //`ifdef TEST_RAY_CORE
        //    Scale = _Fixed(2);
        //`else
            Scale = _Fixed(256);
        //`endif
        
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE][55:24]   = Scale.Value;

        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE][23:16]   = 100;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE][15:8]    = 225;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE][7:0]     = 100;	        

        // ReflectiveBox ----
        Scale = _Fixed(12);        

        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 1][151:120]     = `FIXED_ZERO;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 1][119:88]      = Scale.Value;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 1][87:56]       = `FIXED_ZERO;
        
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 1][55:24]       = Scale.Value;
        
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 1][23:16]       = 255;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 1][15:8]        = 255;//155;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 1][7:0]         = 145;//155;	        

        Scale = _Fixed(8);        
        Scale2 = _Fixed(-10);                         
        Scale3 = _Fixed(-37);

        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 2][151:120]     = Scale2.Value;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 2][119:88]      = Scale.Value;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 2][87:56]       = Scale3.Value;
        
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 2][55:24]       = Scale.Value;

        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 2][23:16]       = 255;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 2][15:8]        = 100;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 2][7:0]         = 125;	                
    endfunction 

    initial begin	
        $readmemh(`BVH_PRIMITIVE_PATH, PrimitiveRawData);
        AddReflectiveBoxAndGroundPrimitive();				        
	end		
    
    always_comb begin        
    end

    generate
        for (genvar i = 0; i < `BVH_AABB_TEST_UNIT_SIZE; i = i + 1) begin : OFFSET_AABB
            // Group 1
            FetchPrimitiveAABB FETCH_AABB0(
                .s(PrimitiveRawData[start0 + i][55:24]),
                .a(PrimitiveRawData[start0 + i][151:56]),
                .out(TempAABB[0][i])
            );

            FetchPrimitiveColor FETCH_COLOR0(
                .a(PrimitiveRawData[start0 + i][23:0]),
                .out(p0[i].Color)
            );

            FetchPrimitiveSurafceType FETCH_ST0(
                .i(start0 + i),
                .threshold(threshold0),
                .vi(p0[i].VI),
                .out(p0[i].SurfaceType)
            );

            PostPrimitiveUnit FETCH_POST0(
                .i(start0 + i),
                .offset(offset),
                .aabb(TempAABB[0][i]),
                .out_aabb(p0[i].Aabb)
            );       

            // Group 2
            FetchPrimitiveAABB FETCH_AABB1(
                .s(PrimitiveRawData[start1 + i][55:24]),
                .a(PrimitiveRawData[start1 + i][151:56]),
                .out(TempAABB[1][i])
            );

            FetchPrimitiveColor FETCH_COLOR1(
                .a(PrimitiveRawData[start1 + i][23:0]),
                .out(p1[i].Color)
            );

            FetchPrimitiveSurafceType FETCH_ST1(
                .i(start1 + i),
                .threshold(threshold1),
                .vi(p1[i].VI),
                .out(p1[i].SurfaceType)
            );

            PostPrimitiveUnit FETCH_POST1(
                .i(start1 + i),
                .offset(offset),
                .aabb(TempAABB[1][i]),
                .out_aabb(p1[i].Aabb)
            );       
        end
    endgenerate  

endmodule
*/