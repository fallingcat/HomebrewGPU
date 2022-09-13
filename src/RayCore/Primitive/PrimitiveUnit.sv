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
    input strobe,         
    input [31:0] s,
    input [95:0] a,
    output AABB out
    );      
    Fixed S;  
    Fixed3 A;

    always_comb begin
        if (strobe) begin
            S.Value <= s;        
            A.Dim[0].Value <= a[95:64];
            A.Dim[1].Value <= a[63:32];
            A.Dim[2].Value <= a[31:0];        
        end
    end

    Fixed3_SubOffset MIN(A, S, out.Min);
    Fixed3_AddOffset MAX(A, S, out.Max);    
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module _QueryPrimitiveColor (   
    input strobe,     
    input [23:0] a,
    output RGB8 out
    );

    always_comb begin
        if (strobe) begin
            out.Channel[0] <= a[23:16];
            out.Channel[1] <= a[15:8];
            out.Channel[2] <= a[7:0];
        end
    end
    
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module _QueryPrimitiveSurafceType (   
    input strobe,     
    input PrimitiveType prim_type,
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] i,
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] bound,    
    output logic `PRIMITIVE_INDEX pi,      
    output SurfaceType out
    );

    always_comb begin
        if (strobe) begin
            case (prim_type)
                default: begin                
                end

                (PT_AABB): begin
                    if (i[`PRIMITIVE_INDEX_WIDTH - 1] == 0 && i < bound && i < `BVH_AABB_RAW_DATA_SIZE) begin
                        pi <=  i;
                    end
                    else begin
                        pi <= `NULL_PRIMITIVE_INDEX;  
                    end
                end

                (PT_Sphere): begin
                    if (i[`PRIMITIVE_INDEX_WIDTH - 1] == 0 && i < bound && i < `BVH_SPHERE_RAW_DATA_SIZE) begin
                        pi <=  i;
                    end
                    else begin
                        pi <= `NULL_PRIMITIVE_INDEX;  
                    end
                end
            endcase        

            // If pi is not NULL_PRIMITIVE
            if (pi[`PRIMITIVE_INDEX_WIDTH-1] == 0) begin        
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
        end
        else begin
            pi <= `NULL_PRIMITIVE_INDEX;  
            out <= ST_None;
        end
    end           
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module _PostQueryPrimitive (
    input strobe,      
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] i,
    input Fixed3 offset,
    input AABB aabb,    
    output AABB out_aabb
    );
    Fixed3 FinalOffset;    

    always_comb begin       
        if (strobe) begin
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
    end
    
    Fixed3_Add A0(aabb.Min, FinalOffset, out_aabb.Min);
    Fixed3_Add A1(aabb.Max, FinalOffset, out_aabb.Max);
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module _QueryAABB (       
    input strobe,
    input [`BVH_AABB_RAW_DATA_WIDTH-1:0] raw,
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] i,
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] bound,    
    input Fixed3 offset,    
    output BVH_Primitive_AABB p
    );    

    AABB TempAABB;
    
    _QueryPrimitiveAABB QUERY_AABB(
        .strobe(strobe),
        .s(raw[55:24]),
        .a(raw[151:56]),
        .out(TempAABB)
    );

    _QueryPrimitiveColor QUERY_COLOR(
        .strobe(strobe),
        .a(raw[23:0]),
        .out(p.Color)
    );

    _QueryPrimitiveSurafceType QUERY_SURFACE(
        .strobe(strobe),
        .prim_type(PT_AABB),
        .i(i),
        .bound(bound),
        .pi(p.PI),
        .out(p.SurfaceType)
    );

    _PostQueryPrimitive QUERY_POST(
        .strobe(strobe),
        .i(i),
        .offset(offset),
        .aabb(TempAABB),
        .out_aabb(p.Aabb)
    );    
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module _QueryPrimitveSphere (      
    input strobe,     
    input [31:0] r,
    input [95:0] p,  
    output Fixed3 pos,
    output Fixed radius
    );      

    always_comb begin
        if (strobe) begin
            radius.Value <= r;        
            pos.Dim[0].Value <= p[95:64];
            pos.Dim[1].Value <= p[63:32];
            pos.Dim[2].Value <= p[31:0];        
        end
    end
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module _QuerySphere (       
    input strobe,
    input [`BVH_SPHERE_RAW_DATA_WIDTH-1:0] raw,
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] i,
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] bound,    
    input Fixed3 offset,    
    output BVH_Primitive_Sphere p    
    );    

    _QueryPrimitveSphere QUERY_SPHERE (
        .strobe(strobe),
        .r(raw[55:24]),
        .p(raw[151:56]),
        .pos(p.Sphere.Center),
        .radius(p.Sphere.Radius)
    );

    _QueryPrimitiveColor QUERY_COLOR(
        .strobe(strobe),
        .a(raw[23:0]),
        .out(p.Color)
    );

    _QueryPrimitiveSurafceType QUERY_SURFACE(
        .strobe(strobe),
        .prim_type(PT_Sphere),
        .i(i),
        .bound(bound),
        .pi(p.PI),
        .out(p.SurfaceType)
    );

endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module _QueryPrimitive (   
    input [`BVH_AABB_RAW_DATA_WIDTH-1:0] raw,
    input [`BVH_AABB_RAW_DATA_WIDTH-1:0] raw_sphere,
    input PrimitiveType prim_type,
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] i,
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] bound,    
    input Fixed3 offset,    
    output BVH_Primitive_AABB p,
    output BVH_Primitive_Sphere ps
    );    

    logic StrobeAABB, StrobeSphere;

    always_comb begin
        case (prim_type)
            (PT_AABB): begin
                StrobeAABB <= 1;
                StrobeSphere <= 0;                
            end

            (PT_Sphere): begin    
                StrobeAABB <= 0;
                StrobeSphere <= 0;                            
            end            
        endcase
    end

    _QueryAABB QUERY_AABB(
        .strobe(StrobeAABB),
        .raw(raw),
        .i(i),
        .bound(bound),    
        .offset(offset),    
        .p(p)    
    );

    _QuerySphere QUERY_SPHERE(
        .strobe(StrobeSphere),
        .raw(raw_sphere),
        .i(i),
        .bound(bound),    
        .offset(offset),    
        .p(ps)    
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
        // Check if index is NULL_PRIMITIVE or not
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
    input PrimitiveQueryData primitive_query_0[`RAY_CORE_SIZE],
    output BVH_Primitive_AABB p0[`RAY_CORE_SIZE][`AABB_TEST_UNIT_SIZE],
    output BVH_Primitive_Sphere ps0[`RAY_CORE_SIZE][`SPHERE_TEST_UNIT_SIZE],

    input PrimitiveQueryData primitive_query_1[`RAY_CORE_SIZE],   
    output BVH_Primitive_AABB p1[`RAY_CORE_SIZE][`AABB_TEST_UNIT_SIZE],    
    output BVH_Primitive_Sphere ps1[`RAY_CORE_SIZE][`SPHERE_TEST_UNIT_SIZE]    
    );

    logic [`BVH_AABB_RAW_DATA_WIDTH-1:0] AABBRawData[`BVH_AABB_RAW_DATA_SIZE];         
    logic [`BVH_SPHERE_RAW_DATA_WIDTH-1:0] SphereRawData[`BVH_SPHERE_RAW_DATA_SIZE];         
    Fixed Scale[6];    
    logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] PI_0[`RAY_CORE_SIZE], PI_1[`RAY_CORE_SIZE];

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
            _Fixed3(_Fixed(0), _Fixed(13), _Fixed(0)),
            _Fixed(10),
            _RGB8(255, 255, 145)
        );
        _SetupAABB(
            `BVH_GLOBAL_PRIMITIVE_START_IDX + 2,
            _Fixed3(_Fixed(0), _Fixed(20), _Fixed(60)),
            _Fixed(20),
            _RGB8(255, 100, 125)
        );                         
        
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
            _CheckPrimitiveIndex CHECK_PRIM_INDEX_0(   
                primitive_query_0[c].StartIndex,
                PI_0[c]
            );    

            _CheckPrimitiveIndex CHECK_PRIM_INDEX_1(   
                primitive_query_1[c].StartIndex,
                PI_1[c]
            );    

            for (genvar i = 0; i < `AABB_TEST_UNIT_SIZE; i = i + 1) begin : QUERY_PRIM
                _QueryPrimitive QUERY_PRIM_0(   
                    .raw(AABBRawData[PI_0[c] + i]),    
                    .raw_sphere(SphereRawData[PI_0[c] + i]), 
                    .prim_type(primitive_query_0[c].PrimType),
                    .i(primitive_query_0[c].StartIndex + i),
                    .bound(primitive_query_0[c].EndIndex),    
                    .offset(offset),
                    .p(p0[c][i]),
                    .ps(ps0[c][i])
                ); 

                _QueryPrimitive QUERY_PRIM_1(   
                    .raw(AABBRawData[PI_1[c] + i]),    
                    .raw_sphere(SphereRawData[PI_1[c] + i]), 
                    .prim_type(primitive_query_1[c].PrimType),
                    .i(primitive_query_1[c].StartIndex + i),
                    .bound(primitive_query_1[c].EndIndex),    
                    .offset(offset),    
                    .p(p1[c][i]),
                    .ps(ps1[c][i])
                );    
            end            
        end
    endgenerate  
endmodule