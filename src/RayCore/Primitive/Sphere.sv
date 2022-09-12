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
//-------------------------------------------------------------------    
module _Discriminant(
    input Ray r,
    input Sphere sphere,
    output Fixed discr            
    );   

    Fixed a, half_b, c0, c1, c, A1, A2;
    Fixed3 Oc;

    Fixed3_Sub A0(r.Orig, sphere.Center, Oc);
    Fixed3_Dot A1(r.Dir, r.Dir, a);
    Fixed3_Dot A2(Oc, r.Dir, half_b);
    Fixed3_Dot A3(Oc, Oc, c0);
    Fixed_Mul A4(sphere.Radius, sphere.Radius, c1);
    Fixed3_Sub A5(c0, c1, c);

    Fixed_Mul A6(half_b, half_b, A1);
    Fixed_Mul A7(a, c, A2);
    Fixed3_Sub A8(A1, A2, discr);
endmodule
//-------------------------------------------------------------------
// Find hit point and get the normal of hit point
//-------------------------------------------------------------------    
module SphereHit(
    input clk,
	input resetn,
    input Ray r,
    input Sphere sphere,
    input RGB8 color,
    input `PRIMITIVE_INDEX pi,  
    input SurfaceType st,      
    output valid,    
    output HitData hit_data    
    );    

    Fixed Discriminant;    

    _Discriminant Discr(r, sphere, Discriminant);

endmodule
//-------------------------------------------------------------------
// Find any hit
//-------------------------------------------------------------------    
module SphereAnyHit(
    input clk,
	input resetn,
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
    input Ray r,
    input Sphere sphere,
    output logic hit            
    );   

    assign hit = !Discriminant.Value[`FIXED_WIDTH-1];

    Fixed Discriminant;    

    _Discriminant Discr(r, sphere, Discriminant);
endmodule

/*
bool Sphere_Hit(Sphere s, Ray r, float t_min, float t_max, inout HitRecord rec)
{
	float3 oc = r.Orig - s.Center;
	float a = dot(r.Dir, r.Dir);
	float half_b = dot(oc, r.Dir);
	float c = dot(oc, oc) - s.Radius * s.Radius;

	float Discriminant = half_b * half_b - a * c;
	if (Discriminant < 0)
	{
		return false;
	}

	float sqrtd = sqrt(Discriminant);

	// Find the nearest root that lies in the acceptable range.
	float root = (-half_b - sqrtd) / a;
	if (root < t_min || t_max < root)
	{
		root = (-half_b + sqrtd) / a;
		if (root < t_min || t_max < root)
		{
			return false;
		}
	}

	rec.t = root;
	rec.P = Ray_At(r, rec.t);
	float3 OutwardNormal = (rec.P - s.Center) / s.Radius;
	HitRecord_SetFaceNormal(rec, r, OutwardNormal);
	rec.Material = s.Material;

	return true;
}
*/