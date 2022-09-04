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

`include "../../Types.sv"
`include "../../Math/Fixed.sv"
`include "../../Math/Fixed3.sv"
`include "../../Math/FixedNorm.sv"
`include "../../Math/FixedNorm3.sv"

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module _QueryPrimitiveAABB (   
    input [31:0] s,
    input [95:0] a,
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
module _QueryPrimitiveColor (   
    input [23:0] a,
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
module _QueryPrimitiveSurafceType (   
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] i,
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] bound,    
    output logic `PRIMITIVE_INDEX pi,      
    output SurfaceType out
    );

    always_comb begin
        if (i[`PRIMITIVE_INDEX_WIDTH - 1] == 0 && i < bound && i < `BVH_AABB_RAW_DATA_SIZE) begin
            pi <=  i;
        end
        else begin
            pi <= `NULL_PRIMITIVE_INDEX;  
        end

    `ifdef IMPLEMENT_REFRACTION        
        if (i == (`BVH_GLOBAL_PRIMITIVE_START_IDX + 1)) begin                                
            out <= ST_Dielectric;            
        end 
        else if (i == (`BVH_GLOBAL_PRIMITIVE_START_IDX + 2)) begin                    
            out <= ST_Metal;
        end 
        else begin
            out <= ST_Lambertian;
        end                
    `elsif IMPLEMENT_REFLECTION
        if (i >= (`BVH_GLOBAL_PRIMITIVE_START_IDX + 1)) begin                    
            out <= ST_Metal;            
        end     
        else begin
            out <= ST_Lambertian;
        end     
    `else
        out <= ST_Lambertian;
    `endif  
    end           
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module _PostQueryPrimitive (   
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] i,
    input Fixed3 offset,
    input AABB aabb,    
    output AABB out_aabb
    );
    Fixed3 FinalOffset;    

    always_comb begin       
    `ifdef LOAD_BVH_MODEL
        if (i < `BVH_MODEL_RAW_DATA_SIZE) begin          
            FinalOffset <= offset;            
        end
        else begin
            FinalOffset <= _Fixed3(FixedZero(), FixedZero(), FixedZero());
        end
    `else
        if (i == `BVH_GLOBAL_PRIMITIVE_START_IDX + 1) begin          
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
module _QueryPrimitive (   
    input [`BVH_AABB_RAW_DATA_WIDTH-1:0] raw,
    input PrimitiveType prim_type,
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] i,
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] bound,    
    input Fixed3 offset,    
    output BVH_Primitive_AABB p,
    output BVH_Primitive_Sphere ps
    );    

    AABB TempAABB;
    
    _QueryPrimitiveAABB QUERY_AABB(
        .s(raw[55:24]),
        .a(raw[151:56]),
        .out(TempAABB)
    );

    _QueryPrimitiveColor QUERY_COLOR(
        .a(raw[23:0]),
        .out(p.Color)
    );

    _QueryPrimitiveSurafceType QUERY_ST(
        .i(i),
        .bound(bound),
        .pi(p.PI),
        .out(p.SurfaceType)
    );

    _PostQueryPrimitive QUERY_POST(
        .i(i),
        .offset(offset),
        .aabb(TempAABB),
        .out_aabb(p.Aabb)
    );     
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module _CheckPrimitiveIndex (   
    input logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] index,
    output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] out_index
    );    

    always_comb begin
        if (index[`BVH_PRIMITIVE_INDEX_WIDTH-1] == 0) begin                    
            out_index <= index;
        end
        else begin                                    
            out_index <= 0;
        end        
    end
endmodule
//-------------------------------------------------------------------
// BVH structure module. 
// Store BVH data and resposible for primitive data query 
// from other modules.
//-------------------------------------------------------------------    
module PrimitiveUnit (   
    input clk,	    
    input resetn, 
    input Fixed3 offset, 
    // Query Primitive
    input PrimitiveType prim_type_0,
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] prim_index_0[`RAY_CORE_SIZE],
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] prim_bound_0[`RAY_CORE_SIZE],    
    input PrimitiveType prim_type_1,
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] prim_index_1[`RAY_CORE_SIZE],    
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] prim_bound_1[`RAY_CORE_SIZE],
    output BVH_Primitive_AABB p0[`RAY_CORE_SIZE][`AABB_TEST_UNIT_SIZE],
    output BVH_Primitive_AABB p1[`RAY_CORE_SIZE][`AABB_TEST_UNIT_SIZE]    
    //output BVH_Primitive_Sphere ps0[`SPHERE_TEST_UNIT_SIZE],
    //output BVH_Primitive_Sphere ps1[`SPHERE_TEST_UNIT_SIZE]    
    );

    logic [`BVH_AABB_RAW_DATA_WIDTH-1:0] AABBRawData[`BVH_AABB_RAW_DATA_SIZE];         
    Fixed Scale[6];    
    logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] PI_0[`RAY_CORE_SIZE], PI_1[`RAY_CORE_SIZE];
    //-------------------------------------------------------------------
    //
    //-------------------------------------------------------------------    
    function SetupGlobalPrimitives();
        // Ground ----
        Scale[0] = _Fixed(256);
        Scale[1] = _Fixed(-256);        

        AABBRawData[`BVH_GLOBAL_PRIMITIVE_START_IDX][151:120] = `FIXED_ZERO;
        AABBRawData[`BVH_GLOBAL_PRIMITIVE_START_IDX][119:88]  = Scale[1].Value;
        AABBRawData[`BVH_GLOBAL_PRIMITIVE_START_IDX][87:56]   = `FIXED_ZERO;
        
        //`ifdef TEST_RAY_CORE
        //    Scale = _Fixed(2);
        //`else
            //Scale[0] = _Fixed(256);
        //`endif
        
        AABBRawData[`BVH_GLOBAL_PRIMITIVE_START_IDX][55:24]   = Scale[0].Value;

        AABBRawData[`BVH_GLOBAL_PRIMITIVE_START_IDX][23:16]   = 100;
        AABBRawData[`BVH_GLOBAL_PRIMITIVE_START_IDX][15:8]    = 225;
        AABBRawData[`BVH_GLOBAL_PRIMITIVE_START_IDX][7:0]     = 100;	        

        Scale[0] = _Fixed(10);        
        Scale[1] = _Fixed(13);        

        AABBRawData[`BVH_GLOBAL_PRIMITIVE_START_IDX + 1][151:120]     = `FIXED_ZERO;
        AABBRawData[`BVH_GLOBAL_PRIMITIVE_START_IDX + 1][119:88]      = Scale[1].Value;
        AABBRawData[`BVH_GLOBAL_PRIMITIVE_START_IDX + 1][87:56]       = `FIXED_ZERO;
        
        AABBRawData[`BVH_GLOBAL_PRIMITIVE_START_IDX + 1][55:24]       = Scale[0].Value;
        
        AABBRawData[`BVH_GLOBAL_PRIMITIVE_START_IDX + 1][23:16]       = 255;
        AABBRawData[`BVH_GLOBAL_PRIMITIVE_START_IDX + 1][15:8]        = 255;//155;
        AABBRawData[`BVH_GLOBAL_PRIMITIVE_START_IDX + 1][7:0]         = 145;//155;

        Scale[0] = _Fixed(20);        
        Scale[1] = _Fixed(60);                                 

        AABBRawData[`BVH_GLOBAL_PRIMITIVE_START_IDX + 2][151:120]     = `FIXED_ZERO;
        AABBRawData[`BVH_GLOBAL_PRIMITIVE_START_IDX + 2][119:88]      = Scale[0].Value;
        AABBRawData[`BVH_GLOBAL_PRIMITIVE_START_IDX + 2][87:56]       = Scale[1].Value;
        
        AABBRawData[`BVH_GLOBAL_PRIMITIVE_START_IDX + 2][55:24]       = Scale[0].Value;

        AABBRawData[`BVH_GLOBAL_PRIMITIVE_START_IDX + 2][23:16]       = 255;
        AABBRawData[`BVH_GLOBAL_PRIMITIVE_START_IDX + 2][15:8]        = 100;
        AABBRawData[`BVH_GLOBAL_PRIMITIVE_START_IDX + 2][7:0]         = 125;	  	        

        /*
        // ReflectiveBox ----
        Scale = _Fixed(12);        

        AABBRawData[`BVH_MODEL_RAW_DATA_SIZE + 1][151:120]     = `FIXED_ZERO;
        AABBRawData[`BVH_MODEL_RAW_DATA_SIZE + 1][119:88]      = Scale.Value;
        AABBRawData[`BVH_MODEL_RAW_DATA_SIZE + 1][87:56]       = `FIXED_ZERO;
        
        AABBRawData[`BVH_MODEL_RAW_DATA_SIZE + 1][55:24]       = Scale.Value;
        
        AABBRawData[`BVH_MODEL_RAW_DATA_SIZE + 1][23:16]       = 255;
        AABBRawData[`BVH_MODEL_RAW_DATA_SIZE + 1][15:8]        = 255;//155;
        AABBRawData[`BVH_MODEL_RAW_DATA_SIZE + 1][7:0]         = 145;//155;	        

        Scale = _Fixed(8);        
        Scale2 = _Fixed(-10);                         
        Scale3 = _Fixed(-37);

        AABBRawData[`BVH_MODEL_RAW_DATA_SIZE + 2][151:120]     = Scale2.Value;
        AABBRawData[`BVH_MODEL_RAW_DATA_SIZE + 2][119:88]      = Scale.Value;
        AABBRawData[`BVH_MODEL_RAW_DATA_SIZE + 2][87:56]       = Scale3.Value;
        
        AABBRawData[`BVH_MODEL_RAW_DATA_SIZE + 2][55:24]       = Scale.Value;

        AABBRawData[`BVH_MODEL_RAW_DATA_SIZE + 2][23:16]       = 255;
        AABBRawData[`BVH_MODEL_RAW_DATA_SIZE + 2][15:8]        = 100;
        AABBRawData[`BVH_MODEL_RAW_DATA_SIZE + 2][7:0]         = 125;	                
        */
    endfunction 

    initial begin	
    `ifdef LOAD_BVH_MODEL
        $readmemh(`BVH_PRIMITIVE_PATH, AABBRawData);
    `endif
        SetupGlobalPrimitives();
	end		

    generate
        for (genvar c = 0; c < `RAY_CORE_SIZE; c = c + 1) begin : CORE_PRIM			
            _CheckPrimitiveIndex CHECK_PRIM_INDEX_0(   
                prim_index_0[c],
                PI_0[c]
            );    

            _CheckPrimitiveIndex CHECK_PRIM_INDEX_1(   
                prim_index_1[c],
                PI_1[c]
            );    

            for (genvar i = 0; i < `AABB_TEST_UNIT_SIZE; i = i + 1) begin : QUERY_PRIM
                _QueryPrimitive QUERY_PRIM_0(   
                    .raw(AABBRawData[PI_0[c] + i]),    
                    .i(prim_index_0[c] + i),
                    .bound(prim_bound_0[c]),    
                    .offset(offset),    
                    .p(p0[c][i])
                ); 

                _QueryPrimitive QUERY_PRIM_1(   
                    .raw(AABBRawData[PI_1[c] + i]),    
                    .i(prim_index_1[c] + i),
                    .bound(prim_bound_1[c]),    
                    .offset(offset),    
                    .p(p1[c][i])
                );    
            end            
        end
    endgenerate  
endmodule