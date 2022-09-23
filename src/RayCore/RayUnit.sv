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
module FindClosestHit#(
    parameter WIDTH = `AABB_TEST_UNIT_SIZE
    ) ( 
    input Ray r,    
    input HitData hit_data[WIDTH],	
    output HitData closest_hit_data		
    );             
    HitData HitData[WIDTH+1];

    always_comb begin        
        HitData[0].bHit <= 0;
        HitData[0].T <= FixedInf();              
    end  

    generate
        for (genvar i = 0; i < WIDTH; i = i + 1) begin : MIN_HIT
            MinHitMux MIN_HIT(
                .h1(HitData[i]),
                .h2(hit_data[i]),
                .out(HitData[i+1])                
            );         
        end
    endgenerate  

    assign closest_hit_data = HitData[WIDTH];               
    //assign r.MaxT = closest_hit_data.T;
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
module FindAnyHit#(
    parameter WIDTH = `AABB_TEST_UNIT_SIZE
    ) (      
    input HitData hit_data[WIDTH],	
    output logic out_hit		
    );          

    logic Hit[WIDTH+1];

    always_comb begin        
        Hit[0] <= 0;        
    end  

    generate
        for (genvar i = 0; i < WIDTH; i = i + 1) begin : HITMUX
            HitMux HITMUX(
                .h1(Hit[i]),
                .h2(hit_data[i].bHit),
                .s(hit_data[i].bHit),
                .out(Hit[i+1])                
            );         
        end
    endgenerate 
    
    assign out_hit = Hit[WIDTH];
endmodule
//-------------------------------------------------------------------
// Find the closest hit of primitives against the ray and compute the
// normal direction.
//-------------------------------------------------------------------    
module RayUnit_FindClosestHit (        
    input clk,
	input resetn,    
    input Ray r,    
    input Primitive_AABB aabb[`AABB_TEST_UNIT_SIZE],
    input Primitive_Sphere sphere[`SPHERE_TEST_UNIT_SIZE],
    output valid,
    output HitData hit_data
	);

    logic [`AABB_TEST_UNIT_SIZE-1:0] AABBValid;
    logic [`SPHERE_TEST_UNIT_SIZE-1:0] SphereValid;
    HitData HitData[`AABB_TEST_UNIT_SIZE + `SPHERE_TEST_UNIT_SIZE];    

    assign valid = 1;//AABBValid && SphereValid;

    // AABB test
    generate
        for (genvar i = 0; i < `AABB_TEST_UNIT_SIZE; i = i + 1) begin : AABB_HIT
            AABBHit AABB_HIT(
                .r(r),
                .pi(aabb[i].PI),
                .st(aabb[i].SurfaceType),
                .aabb(aabb[i].Aabb),
                .color(aabb[i].Color),
                .valid(AABBValid[i]),
                .hit_data(HitData[i])                
            );         
        end
    endgenerate 

    //TODO : Sphere test 
    generate
        for (genvar i = 0; i < `SPHERE_TEST_UNIT_SIZE; i = i + 1) begin : SPHERE_HIT
            SphereHit Sphere_HIT(
                .clk(clk),
                .r(r),
                .sphere(sphere[i].Sphere),
                .pi(sphere[i].PI),
                .st(sphere[i].SurfaceType),
                .color(sphere[i].Color),
                .valid(SphereValid[i]),
                .hit_data(HitData[`AABB_TEST_UNIT_SIZE + i])
            );         
        end
    endgenerate 
    //TODO : Triangle test

    // Process all HitData and output the FinalHitData
    FindClosestHit#(`AABB_TEST_UNIT_SIZE + `SPHERE_TEST_UNIT_SIZE) PRP(
        .r(r),
        .hit_data(HitData),	
        .closest_hit_data(hit_data)		
    );      
endmodule
//-------------------------------------------------------------------
// Find any hit primitives against the ray.
//-------------------------------------------------------------------    
module RayUnit_FindAnyHit (    
    input Ray r,    
    input Primitive_AABB aabb[`AABB_TEST_UNIT_SIZE],
    input Primitive_Sphere sphere[`SPHERE_TEST_UNIT_SIZE],
    output logic out_hit
	);

    HitData HitData[`AABB_TEST_UNIT_SIZE];    

    // AABB test
    generate
        for (genvar i = 0; i < `AABB_TEST_UNIT_SIZE; i = i + 1) begin : AABB_HIT
            AABBAnyHit AABB_HIT(
                .r(r),
                .pi(aabb[i].PI),
                .st(aabb[i].SurfaceType),
                .aabb(aabb[i].Aabb),
                .color(aabb[i].Color),
                .hit_data(HitData[i])                
            );         
        end
    endgenerate  

    //TODO : Sphere test 
    //TODO : Triangle test

    // Process all HitData and output the FinalHitData
    FindAnyHit#(`AABB_TEST_UNIT_SIZE) PRP(
        .hit_data(HitData),	
        .out_hit(out_hit)		
    );  

endmodule

