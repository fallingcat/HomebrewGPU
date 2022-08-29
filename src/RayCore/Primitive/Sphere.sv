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
// Find hit point and get the normal of hit point
//-------------------------------------------------------------------    
module SphereHit(
    input Ray r,
    input Sphere sphere,
    input RGB8 color,
    input `PRIMITIVE_INDEX pi,  
    input SurfaceType st,      
    output HitData hit_data    
    );    
endmodule
//-------------------------------------------------------------------
// Find any hit
//-------------------------------------------------------------------    
module SphereAnyHit(
    input Ray r,
    input Sphere sphere,
    input RGB8 color,
    input `PRIMITIVE_INDEX pi,  
    input SurfaceType st,      
    output HitData hit_data    
    );    
endmodule
//-------------------------------------------------------------------
// Test if a ray hit Sphere with infinite length
//-------------------------------------------------------------------    
module SphereTest(
    input Fixed3 orig,
    input Fixed3 invdir,
    input Sphere sphere,
    output logic hit            
    );        
endmodule