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

`include "../Types.sv"
`include "../Math/Fixed.sv"
`include "../Math/Fixed3.sv"
`include "../Math/FixedNorm.sv"
`include "../Math/FixedNorm3.sv"

//-------------------------------------------------------------------
// Find the closest Hit. 
// Compare the all HitData.T and find the closest HitData which has smallest T.
//-------------------------------------------------------------------    
module HitDataMux( 
    input HitData h1,	
    input HitData h2,	
    input s,	
    output HitData out
    );		
    assign out = (s) ? h2 : h1;
endmodule
//-------------------------------------------------------------------
// Find the closest Hit. 
// Compare the all HitData.T and find the closest HitData which has smallest T.
//-------------------------------------------------------------------    
module MinHitMux( 
    input HitData h1,	
    input HitData h2,	
    output HitData out
    );		
    logic C;
    
    Fixed_Greater A0(h1.T, h2.T, C);
    HitDataMux A2(h1, h2, (C && h2.bHit), out);
endmodule
//-------------------------------------------------------------------
// Find the closest Hit. 
// Compare the all HitData.T and find the closest HitData which has smallest T.
//-------------------------------------------------------------------    
module FindClosestHit( 
    input Ray r,    
    input HitData p_hit_data[`BVH_AABB_TEST_UNIT_SIZE],	
    output HitData final_hit_data		
    );             
    HitData HitData[`BVH_AABB_TEST_UNIT_SIZE+1];

    always_comb begin        
        HitData[0].bHit <= 0;
        HitData[0].T <= FixedInf();              
    end  

    generate
        for (genvar i = 0; i < `BVH_AABB_TEST_UNIT_SIZE; i = i + 1) begin : MIN_HIT
            MinHitMux MIN_HIT(
                .h1(HitData[i]),
                .h2(p_hit_data[i]),
                .out(HitData[i+1])                
            );         
        end
    endgenerate  

    assign final_hit_data = HitData[`BVH_AABB_TEST_UNIT_SIZE];               
endmodule
//-------------------------------------------------------------------
// Find the closest Hit. 
// Compare the all HitData.T and find the closest HitData which has smallest T.
//-------------------------------------------------------------------    
module HitMux( 
    input h1,	
    input h2,	
    input s,	
    output out
    );		
    assign out = (s) ? h2 : h1;
endmodule
//-------------------------------------------------------------------
// Find any Hit. 
// Compare the all HitData.T and find the hit if any HitData is hit.
//-------------------------------------------------------------------    
module FindAnyHit(     
    input HitData p_hit_data[`BVH_AABB_TEST_UNIT_SIZE],	
    output logic out_hit		
    );          

    logic Hit[`BVH_AABB_TEST_UNIT_SIZE+1];

    always_comb begin        
        Hit[0] <= 0;        
    end  

    generate
        for (genvar i = 0; i < `BVH_AABB_TEST_UNIT_SIZE; i = i + 1) begin : HITMUX
            HitMux HITMUX(
                .h1(Hit[i]),
                .h2(p_hit_data[i].bHit),
                .s(p_hit_data[i].bHit),
                .out(Hit[i+1])                
            );         
        end
    endgenerate 
    
    assign out_hit = Hit[`BVH_AABB_TEST_UNIT_SIZE];
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module RayUnit_FindClosestHit (    
    input Ray r,    
    input BVH_Primitive p[`BVH_AABB_TEST_UNIT_SIZE],
    output HitData hit_data
	);

    HitData PHitData[`BVH_AABB_TEST_UNIT_SIZE];    

    generate
        for (genvar i = 0; i < `BVH_AABB_TEST_UNIT_SIZE; i = i + 1) begin : AABB_HIT
            AABBHit AABB_HIT(
                .r(r),
                .vi(p[i].VI),
                .st(p[i].SurfaceType),
                .aabb(p[i].Aabb),
                .color(p[i].Color),
                .hit_data(PHitData[i])                
            );         
        end
    endgenerate  

    // Process 4 HitData and output the FinalHitData
    FindClosestHit PRP(
        .r(r),
        .p_hit_data(PHitData),	
        .final_hit_data(hit_data)		
    );  
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module RayUnit_FindClosestHitNoNormal (    
    input Ray r,    
    input BVH_Primitive p[`BVH_AABB_TEST_UNIT_SIZE],
    output HitData hit_data
	);

    HitData PHitData[`BVH_AABB_TEST_UNIT_SIZE];    

    generate
        for (genvar i = 0; i < `BVH_AABB_TEST_UNIT_SIZE; i = i + 1) begin : AABB_HIT
            AABBAnyHit AABB_HIT(
                .r(r),
                .vi(p[i].VI),
                .st(p[i].SurfaceType),
                .aabb(p[i].Aabb),
                .color(p[i].Color),
                .hit_data(PHitData[i])                
            );         
        end
    endgenerate  

    // Process 4 HitData and output the FinalHitData
    FindClosestHit PRP(
        .r(r),
        .p_hit_data(PHitData),	
        .final_hit_data(hit_data)		
    );  
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module RayUnit_FindAnyHit (    
    input Ray r,    
    input BVH_Primitive p[`BVH_AABB_TEST_UNIT_SIZE],
    output logic out_hit
	);

    HitData PHitData[`BVH_AABB_TEST_UNIT_SIZE];    

    generate
        for (genvar i = 0; i < `BVH_AABB_TEST_UNIT_SIZE; i = i + 1) begin : AABB_HIT
            AABBAnyHit AABB_HIT(
                .r(r),
                .vi(p[i].VI),
                .st(p[i].SurfaceType),
                .aabb(p[i].Aabb),
                .color(p[i].Color),
                .hit_data(PHitData[i])                
            );         
        end
    endgenerate  

    // Process 4 HitData and output the FinalHitData
    FindAnyHit PRP(        
        .p_hit_data(PHitData),	
        .out_hit(out_hit)		
    );  

endmodule

