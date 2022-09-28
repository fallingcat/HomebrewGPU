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
    input [`PRIMITIVE_INDEX_WIDTH-1:0] i,
    input [31:0] s,
    input [95:0] a,
    output AABB out
    );      
    Fixed S;  
    Fixed3 A;

    always_comb begin
        if (IsValidPrimitiveIndex(i)) begin
            S.Value <= s;        
            A.Dim[0].Value <= a[95:64];
            A.Dim[1].Value <= a[63:32];            
            A.Dim[2].Value <= a[31:0]; 
        end
        else begin
            S <= _Fixed(0);        
            A.Dim[0] <= _Fixed(0);
            A.Dim[1] <= _Fixed(0);            
            A.Dim[2] <= _Fixed(0); 
        end               
    end

    Fixed3_SubOffset MIN(A, S, out.Min);
    Fixed3_AddOffset MAX(A, S, out.Max);    
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module _QueryPrimitiveColor (   
    input [`PRIMITIVE_INDEX_WIDTH-1:0] i,
    input [23:0] a,
    output RGB8 out
    );

    always_comb begin
        if (IsValidPrimitiveIndex(i)) begin
            out.Channel[0] <= a[23:16];
            out.Channel[1] <= a[15:8];
            out.Channel[2] <= a[7:0];        
        end
        else begin
            out.Channel[0] <= 0;
            out.Channel[1] <= 0;
            out.Channel[2] <= 0;        
        end
    end
    
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module _QueryPrimitiveSurafceType (   
    input [`PRIMITIVE_INDEX_WIDTH-1:0] i,
    output logic `PRIMITIVE_INDEX pi,      
    output SurfaceType out
    );

    always_comb begin                    
        // If pi is not NULL_PRIMITIVE
        if (IsValidPrimitiveIndex(i)) begin        
            pi <= i;

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
        else begin
            pi <=  `NULL_PRIMITIVE_INDEX;
            out <= ST_Lambertian;
        end
    end           
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module _PostQueryPrimitive (
    input [`PRIMITIVE_INDEX_WIDTH-1:0] i,
    input Fixed3 offset,
    input AABB aabb,    
    output AABB out_aabb
    );
    Fixed3 FinalOffset;    

    always_comb begin       
        if (IsValidPrimitiveIndex(i)) begin   
            `ifdef LOAD_BVH_MODEL
                if (i < `BVH_MODEL_RAW_DATA_SIZE) begin          
                    FinalOffset <= offset;            
                end
                else begin
                    FinalOffset <= _Fixed3(_Fixed(0), _Fixed(0), _Fixed(0));
                end
            `else
                if (i == `BVH_GLOBAL_PRIMITIVE_START_IDX + 1) begin          
                    FinalOffset <= offset;            
                end
                else begin
                    FinalOffset <= _Fixed3(_Fixed(0), _Fixed(0), _Fixed(0));
                end
            `endif        
        end
        else begin
            FinalOffset <= offset;
        end
    end
    
    Fixed3_Add A0(aabb.Min, FinalOffset, out_aabb.Min);
    Fixed3_Add A1(aabb.Max, FinalOffset, out_aabb.Max);
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module _QueryAABB (       
    input [`BVH_AABB_RAW_DATA_WIDTH-1:0] raw,
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] i,
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] bound,    
    input Fixed3 offset,    
    output Primitive_AABB p
    );    

    AABB TempAABB;
    logic [`PRIMITIVE_INDEX_WIDTH-1:0] Index;

    _CheckPrimitiveIndex CHECK_PRIM_INDEX(   
        .index(i),
        .bound(bound),
        .out_index(Index)
    );
    
    _QueryPrimitiveAABB QUERY_AABB(
        .i(Index),
        .s(raw[55:24]),
        .a(raw[151:56]),
        .out(TempAABB)
    );

    _QueryPrimitiveColor QUERY_COLOR(
        .i(Index),
        .a(raw[23:0]),
        .out(p.Color)
    );

    _QueryPrimitiveSurafceType QUERY_SURFACE(
        .i(Index),
        .pi(p.PI),
        .out(p.SurfaceType)
    );

    _PostQueryPrimitive QUERY_POST(
        .i(Index),
        .offset(offset),
        .aabb(TempAABB),
        .out_aabb(p.Aabb)
    );    
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module _QueryPrimitveSphere (      
    input [`PRIMITIVE_INDEX_WIDTH-1:0] i,
    input [31:0] r,
    input [95:0] p,  
    output Fixed3 pos,
    output Fixed radius
    );      

    always_comb begin
        if (IsValidPrimitiveIndex(i)) begin   
            radius.Value <= r;        
            pos.Dim[0].Value <= p[95:64];
            pos.Dim[1].Value <= p[63:32];
            pos.Dim[2].Value <= p[31:0];      
        end
        else begin
            radius <= _Fixed(0);        
            pos.Dim[0] <= _Fixed(0);
            pos.Dim[1] <= _Fixed(0);
            pos.Dim[2] <= _Fixed(0);      
        end          
    end
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module _QuerySphere (       
    input [`BVH_SPHERE_RAW_DATA_WIDTH-1:0] raw,
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] i,
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] bound,    
    input Fixed3 offset,    
    output Primitive_Sphere p    
    );    

    logic [`PRIMITIVE_INDEX_WIDTH-1:0] Index;

    _CheckPrimitiveIndex CHECK_PRIM_INDEX(   
        .index(i),
        .bound(bound),
        .out_index(Index)
    );    

    _QueryPrimitveSphere QUERY_SPHERE (
        .i(Index),
        .r(raw[55:24]),
        .p(raw[151:56]),
        .pos(p.Sphere.Center),
        .radius(p.Sphere.Radius)
    );

    _QueryPrimitiveColor QUERY_COLOR(
        .i(Index),
        .a(raw[23:0]),
        .out(p.Color)
    );

    _QueryPrimitiveSurafceType QUERY_SURFACE(
        .i(Index),
        .pi(p.PI),
        .out(p.SurfaceType)
    );

endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module _CheckPrimitiveIndex (   
    input logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] index,
    input logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] bound,
    output logic [`PRIMITIVE_INDEX_WIDTH-1:0] out_index
    );    

    always_comb begin
        // Check if index is NULL_PRIMITIVE or not
        if (IsValidBVHPrimitiveIndex(index) && index < bound) begin                    
            out_index <= index[`PRIMITIVE_INDEX_WIDTH-1:0];
        end
        else begin                                    
            out_index <= `NULL_PRIMITIVE_INDEX;
        end        
    end
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module _CheckPrimitiveRawIndex (   
    input logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] index,
    input logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] bound,
    output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] out_index
    );    

    always_comb begin
        // Check if index is NULL_PRIMITIVE or not
        if (IsValidBVHPrimitiveIndex(index) && index < bound) begin                    
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
    input PrimitiveQueryData aabb_query_0[`RAY_CORE_SIZE],
    output Primitive_AABB aabb_0[`RAY_CORE_SIZE][`AABB_TEST_UNIT_SIZE],    

    input PrimitiveQueryData aabb_query_1[`RAY_CORE_SIZE],   
    output Primitive_AABB aabb_1[`RAY_CORE_SIZE][`AABB_TEST_UNIT_SIZE],        

    input PrimitiveQueryData sphere_query_0[`RAY_CORE_SIZE],   
    output Primitive_Sphere sphere_0[`RAY_CORE_SIZE][`SPHERE_TEST_UNIT_SIZE],

    input PrimitiveQueryData sphere_query_1[`RAY_CORE_SIZE],   
    output Primitive_Sphere sphere_1[`RAY_CORE_SIZE][`SPHERE_TEST_UNIT_SIZE]    
    );

    logic [`BVH_AABB_RAW_DATA_WIDTH-1:0] AABBRawData[`BVH_AABB_RAW_DATA_SIZE];         
    logic [`BVH_SPHERE_RAW_DATA_WIDTH-1:0] SphereRawData[`BVH_SPHERE_RAW_DATA_SIZE];         
    Fixed Scale[6];    
    logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] PI_0[`RAY_CORE_SIZE][`BVH_AABB_RAW_DATA_SIZE], PI_1[`RAY_CORE_SIZE][`BVH_AABB_RAW_DATA_SIZE];
    logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] PSI_0[`RAY_CORE_SIZE][`BVH_AABB_RAW_DATA_SIZE], PSI_1[`RAY_CORE_SIZE][`BVH_AABB_RAW_DATA_SIZE];

    //-------------------------------------------------------------------
    //
    //-------------------------------------------------------------------    
    function void _SetupAABB(
        input [10:0] index,
        input Fixed3 pos,
        input Fixed scale,
        input RGB8 color
        );
        begin
            AABBRawData[index][151:120] = pos.Dim[0].Value;
            AABBRawData[index][119:88]  = pos.Dim[1].Value;
            AABBRawData[index][87:56]   = pos.Dim[2].Value;
            
            AABBRawData[index][55:24]   = scale.Value;

            AABBRawData[index][23:16]   = color.Channel[0];
            AABBRawData[index][15:8]    = color.Channel[1];
            AABBRawData[index][7:0]     = color.Channel[2];	        
        end    
    endfunction
    //-------------------------------------------------------------------
    //
    //-------------------------------------------------------------------    
    function void _SetupSphere(
        input [10:0] index,
        input Fixed3 pos,
        input Fixed radius,
        input RGB8 color
        );
        begin
            SphereRawData[index][151:120] = pos.Dim[0].Value;
            SphereRawData[index][119:88]  = pos.Dim[1].Value;
            SphereRawData[index][87:56]   = pos.Dim[2].Value;
            
            SphereRawData[index][55:24]   = radius.Value;

            SphereRawData[index][23:16]   = color.Channel[0];
            SphereRawData[index][15:8]    = color.Channel[1];
            SphereRawData[index][7:0]     = color.Channel[2];	        
        end    
    endfunction
    //-------------------------------------------------------------------
    //
    //-------------------------------------------------------------------    
    function void _SetupGlobalPrimitives();
        // Ground ----
        _SetupAABB(
            `BVH_GLOBAL_PRIMITIVE_START_IDX,
            _Fixed3(_Fixed(0), _Fixed(-256), _Fixed(0)),
            _Fixed(256),
            _RGB8(100, 255, 100)
        );
        // Box ---
        _SetupAABB(
            `BVH_GLOBAL_PRIMITIVE_START_IDX + 1,
            _Fixed3(_Fixed(0), _Fixed(12), _Fixed(24)),
            _Fixed(12),
            _RGB8(255, 255, 145)
        );
        _SetupAABB(
            `BVH_GLOBAL_PRIMITIVE_START_IDX + 2,
            _Fixed3(_Fixed(-25), _Fixed(12), _Fixed(0)),
            _Fixed(12),
            _RGB8(255, 70, 85)
        );
        /*
        _SetupAABB(
            `BVH_GLOBAL_PRIMITIVE_START_IDX + 3,
            _Fixed3(_Fixed(20), _Fixed(10), _Fixed(40)),
            _Fixed(10),
            _RGB8(255, 100, 125)
        );                         
        _SetupAABB(
            `BVH_GLOBAL_PRIMITIVE_START_IDX + 4,
            _Fixed3(_Fixed(-20), _Fixed(10), _Fixed(40)),
            _Fixed(10),
            _RGB8(255, 100, 125)
        );                         
        */
        
        // Global sphere 
        _SetupSphere(
            0, 
            _Fixed3(_Fixed(0), _Fixed(16), _Fixed(0)),
            _Fixed(16),
            _RGB8(255, 255, 0)
        );

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
        _SetupGlobalPrimitives();
	end		
    
    generate
        for (genvar c = 0; c < `RAY_CORE_SIZE; c = c + 1) begin : CORE_PRIM			
            for (genvar i = 0; i < `AABB_TEST_UNIT_SIZE; i = i + 1) begin : QUERY_AABB_PRIM
                _CheckPrimitiveRawIndex CHK_0_0(aabb_query_0[c].StartIndex + i, aabb_query_0[c].EndIndex, PI_0[c][i]);
                _QueryAABB QUERY_AABB_0(
                    .raw(AABBRawData[PI_0[c][i]]),    
                    .i(aabb_query_0[c].StartIndex + i),
                    .bound(aabb_query_0[c].EndIndex),    
                    .offset(offset),    
                    .p(aabb_0[c][i])
                );

                _CheckPrimitiveRawIndex CHK_0_1(aabb_query_1[c].StartIndex + i, aabb_query_1[c].EndIndex, PI_1[c][i]);                
                _QueryAABB QUERY_AABB_1(
                    .raw(AABBRawData[PI_1[c][i]]),    
                    .i(aabb_query_1[c].StartIndex + i),
                    .bound(aabb_query_1[c].EndIndex),    
                    .offset(offset),    
                    .p(aabb_1[c][i])
                );
            end            

            for (genvar i = 0; i < `SPHERE_TEST_UNIT_SIZE; i = i + 1) begin : QUERY_SPHERE_PRIM
                _CheckPrimitiveRawIndex CHK_1_0(sphere_query_0[c].StartIndex + i, sphere_query_0[c].EndIndex, PSI_0[c][i]);                
                _QuerySphere QUERY_SPHERE_0(
                    .raw(SphereRawData[PSI_0[c][i]]), 
                    .i(sphere_query_0[c].StartIndex + i),
                    .bound(sphere_query_0[c].EndIndex),        
                    .offset(offset),    
                    .p(sphere_0[c][i])
                );

                _CheckPrimitiveRawIndex CHK_1_1(sphere_query_1[c].StartIndex + i, sphere_query_1[c].EndIndex, PSI_1[c][i]);
                _QuerySphere QUERY_SPHERE_1(
                    .raw(SphereRawData[PSI_1[c][i]]), 
                    .i(sphere_query_1[c].StartIndex + i),
                    .bound(sphere_query_1[c].EndIndex),        
                    .offset(offset),    
                    .p(sphere_1[c][i])
                );
            end            
        end
    endgenerate  
endmodule