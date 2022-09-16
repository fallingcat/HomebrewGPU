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
module _AABBFindT0T1(    
    input Fixed3 orig,
    input Fixed3 invdir,
    input AABB aabb,
    output Fixed t0[3],
    output Fixed t1[3]
    );  
    Fixed3 T0, T1;
   
    Fixed3_Sub A0(
        .a(aabb.Min), 
        .b(orig), 
        .o(T0));

    Fixed_Mul A0_0(
        .a(invdir.Dim[0]), 
        .b(T0.Dim[0]), 
        .o(t0[0]));

    Fixed_Mul A0_1(
        .a(invdir.Dim[1]), 
        .b(T0.Dim[1]), 
        .o(t0[1]));

    Fixed_Mul A0_2(
        .a(invdir.Dim[2]), 
        .b(T0.Dim[2]), 
        .o(t0[2]));

    Fixed3_Sub A1(
        .a(aabb.Max), 
        .b(orig), 
        .o(T1));

    Fixed_Mul A1_0(
        .a(invdir.Dim[0]), 
        .b(T1.Dim[0]), 
        .o(t1[0]));

    Fixed_Mul A1_1(
        .a(invdir.Dim[1]), 
        .b(T1.Dim[1]), 
        .o(t1[1]));

    Fixed_Mul A1_2(
        .a(invdir.Dim[2]), 
        .b(T1.Dim[2]), 
        .o(t1[2]));

endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module _AABBFindMinTMaxT(
    input Fixed t0[3],
    input Fixed t1[3],
    output Fixed min_t,
    output Fixed max_t    
    );   

    Fixed T0[4], T1[4];

    // Find min_t
    Fixed_Min A0(
        .a(t0[0]), 
        .b(t1[0]), 
        .o(T0[0])
    );

    Fixed_Min A1(
        .a(t0[1]), 
        .b(t1[1]), 
        .o(T0[1])
    );

    Fixed_Min A2(
        .a(t0[2]), 
        .b(t1[2]), 
        .o(T0[2])
    );

    Fixed_Max A3(
        .a(T0[0]), 
        .b(T0[1]), 
        .o(T0[3])
    );

    Fixed_Max A4(
        .a(T0[2]), 
        .b(T0[3]), 
        .o(min_t)
    );

    // Find max_t
    Fixed_Max A5(
        .a(t0[0]), 
        .b(t1[0]), 
        .o(T1[0])
    );

    Fixed_Max A6(
        .a(t0[1]), 
        .b(t1[1]), 
        .o(T1[1])
    );

    Fixed_Max A7(
        .a(t0[2]), 
        .b(t1[2]), 
        .o(T1[2])
    );

    Fixed_Min A8(
        .a(T1[0]), 
        .b(T1[1]), 
        .o(T1[3])
    );

    Fixed_Min A9(
        .a(T1[2]), 
        .b(T1[3]), 
        .o(max_t)
    );

endmodule

//-------------------------------------------------------------------
// Find the the hit T. 
//-------------------------------------------------------------------    
module _AABBFindHitT(
    input Fixed min_t,
    input Fixed max_t,
    input Fixed ray_min_t,
    input Fixed ray_max_t,
    output Fixed hit_t,
    output logic hit
    );    
    logic B1, B2, B3, B4, B5;
    
    assign hit_t = B1 ? min_t : max_t; 
    assign hit = B2 && B3 && (ray_max_t.Value[`FIXED_WIDTH-1] == 1 || (B4 && B5));

    Fixed_Greater A0(min_t, _Fixed(0), B1);
    Fixed_Less A1(min_t, max_t, B2);
    Fixed_Greater A2(max_t, _Fixed(0), B3);
    Fixed_LessEqual A3(hit_t, ray_max_t, B4);    
    Fixed_GreaterEqual A4(hit_t, ray_min_t, B5);    
endmodule
//-------------------------------------------------------------------
// Find the the hit point. 
//-------------------------------------------------------------------    
module _AABBFindHit(
    input `PRIMITIVE_INDEX ray_vi,
    input Fixed ray_min_t,
    input Fixed ray_max_t,
    input Fixed min_t,
    input Fixed max_t,
    input RGB8 color,
    input `PRIMITIVE_INDEX pi,   
    input SurfaceType st,
    output HitData hit_data    
    );   
    logic HitCondition;

    always_comb begin        
        // If primitive is not null
        if (pi[`PRIMITIVE_INDEX_WIDTH - 1] == 0 && ray_vi != pi && HitCondition) begin
            hit_data.bHit <= 1;
            hit_data.PI <= pi; 
            hit_data.Color <= color;     
            hit_data.SurfaceType <= st;                
        end                
        else begin
            hit_data.bHit <= 0;             
            hit_data.PI <= `NULL_PRIMITIVE_INDEX;                            
        end
    end

    _AABBFindHitT A0(min_t, max_t, ray_min_t, ray_max_t, hit_data.T, HitCondition);
endmodule
//-------------------------------------------------------------------
// 
//-------------------------------------------------------------------    
module AABBHit_NormalMux(
    input b0,
    input b1,
    output FixedNorm n    
    );   
    always_comb begin 
        if (b0) begin
            n <= _FixedNorm(-1);                
        end
        else if (b1) begin
            n <= _FixedNorm(1);                
        end
        else begin
            n.Value <= 0;
        end
    end
endmodule
//-------------------------------------------------------------------
// Find the normal vector of the hit point. 
//-------------------------------------------------------------------    
module _AABBHit_FindNormal(
    input Fixed3 dir,
    //inout HitData hit_data,
    input Fixed t0[3],
    input Fixed t1[3],    
    inout HitData hit_data    
    );   

    logic B[6][2];       
    
    Fixed_Equal         X00(hit_data.T, t0[0], B[0][0]);
    Fixed_Greater       X01(dir.Dim[0], _Fixed(0), B[0][1]);
    Fixed_Equal         X10(hit_data.T, t1[0], B[1][0]);
    Fixed_Less          X11(dir.Dim[0], _Fixed(0), B[1][1]);   
    AABBHit_NormalMux   XN(hit_data.bHit && B[0][0] && B[0][1], hit_data.bHit && B[1][0] && B[1][1], hit_data.Normal.Dim[0]);    

    Fixed_Equal         Y00(hit_data.T, t0[1], B[2][0]);
    Fixed_Greater       Y01(dir.Dim[1], _Fixed(0), B[2][1]);
    Fixed_Equal         Y10(hit_data.T, t1[1], B[3][0]);
    Fixed_Less          Y11(dir.Dim[1], _Fixed(0), B[3][1]);
    AABBHit_NormalMux   YN(hit_data.bHit && B[2][0] && B[2][1], hit_data.bHit && B[3][0] && B[3][1], hit_data.Normal.Dim[1]);

    Fixed_Equal         Z00(hit_data.T, t0[2], B[4][0]);
    Fixed_Greater       Z01(dir.Dim[2], _Fixed(0), B[4][1]);
    Fixed_Equal         Z10(hit_data.T, t1[2], B[5][0]);
    Fixed_Less          Z11(dir.Dim[2], _Fixed(0), B[5][1]);
    AABBHit_NormalMux   ZN(hit_data.bHit && B[4][0] && B[4][1], hit_data.bHit && B[5][0] && B[5][1], hit_data.Normal.Dim[2]);       
endmodule
//-------------------------------------------------------------------
// 
//-------------------------------------------------------------------    
module _AABBFindTest(
    input Fixed min_t,
    input Fixed max_t,
    output logic hit    
    );    

    logic B[2];
   
    assign hit = (B[0] && B[1]);

    Fixed_Less A0(
        .a(min_t),
        .b(max_t),
        .o(B[0])
    );

    Fixed_Greater A1(
        .a(max_t),
        .b(_Fixed(0)),
        .o(B[1])
    );
endmodule

//-------------------------------------------------------------------
// Find hit point between MinT and MaxT, get the normal of hit point
//-------------------------------------------------------------------    
module AABBHit(
    input Ray r,
    input AABB aabb,
    input RGB8 color,
    input `PRIMITIVE_INDEX pi,  
    input SurfaceType st,      
    output HitData hit_data    
    );    

    Fixed t0[3];
    Fixed t1[3];
    Fixed MinT;
    Fixed MaxT;
    wire HitData HitData;
    
    assign hit_data = HitData;

    _AABBFindT0T1 FIND_T0T1(
        .orig(r.Orig),
        .invdir(r.InvDir),
        .aabb(aabb),
        .t0(t0),
        .t1(t1)
    );    

    _AABBFindMinTMaxT FIND_MINTMAXT(        
        .t0(t0),
        .t1(t1),
        .min_t(MinT),
        .max_t(MaxT)        
    );

    _AABBFindHit FIND_HIT(
        .ray_vi(r.PI),
        .ray_min_t(r.MinT),
        .ray_max_t(r.MaxT),
        .min_t(MinT),
        .max_t(MaxT),
        .color(color),
        .pi(pi),     
        .st(st),
        .hit_data(HitData)
    );

    _AABBHit_FindNormal FIND_NORM(
        .dir(r.Dir),
        //.hit_data(HitData),        
        .t0(t0),
        .t1(t1),        
        .hit_data(HitData)
    );                      
endmodule
//-------------------------------------------------------------------
// Test if a ray hit AABB between MinT and MaxT
//-------------------------------------------------------------------    
module AABBAnyHit(
    input Ray r,
    input AABB aabb,
    input RGB8 color,
    input `PRIMITIVE_INDEX pi,  
    input SurfaceType st,      
    output HitData hit_data    
    );    

    Fixed t0[3];
    Fixed t1[3];
    Fixed MinT;
    Fixed MaxT;
    
    _AABBFindT0T1 FIND_T0T1(
        .orig(r.Orig),
        .invdir(r.InvDir),
        .aabb(aabb),
        .t0(t0),
        .t1(t1)
    );    

    _AABBFindMinTMaxT FIND_MINTMAXT(        
        .t0(t0),
        .t1(t1),
        .min_t(MinT),
        .max_t(MaxT)        
    );

    _AABBFindHit FIND_HIT(
        .ray_vi(r.PI),
        .ray_min_t(r.MinT),
        .ray_max_t(r.MaxT),
        .min_t(MinT),
        .max_t(MaxT),
        .color(color),
        .pi(pi),     
        .st(st),
        .hit_data(hit_data)
    );    
endmodule
//-------------------------------------------------------------------
// Test if a ray hit AABB between 0 and infinite
//-------------------------------------------------------------------    
module AABBTest(
    input Ray r,
    input AABB aabb,    
    output logic hit            
    );    
    Fixed t0[3];
    Fixed t1[3];
    Fixed MinT;
    Fixed MaxT;     
    
    _AABBFindT0T1 FIND_T0T1(
        .orig(r.Orig),
        .invdir(r.InvDir),
        .aabb(aabb),
        .t0(t0),
        .t1(t1)
    );    

    _AABBFindMinTMaxT FIND_MINTMAXT(        
        .t0(t0),
        .t1(t1),
        .min_t(MinT),
        .max_t(MaxT)        
    );

    _AABBFindTest FIND_TEST(
        .min_t(MinT),
        .max_t(MaxT),
        .hit(hit)
    );    
endmodule
//-------------------------------------------------------------------
// Add offset to AABB
//-------------------------------------------------------------------    
module OffsetAABB(   
    input AABB aabb,     
    input Fixed3 offset,
    output AABB out_aabb
    );
    
    Fixed3_Add A0(aabb.Min, offset, out_aabb.Min);
    Fixed3_Add A1(aabb.Max, offset, out_aabb.Max);
endmodule