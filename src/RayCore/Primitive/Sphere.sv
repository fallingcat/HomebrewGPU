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

    Fixed a, half_b, c0, c1, c, R1, R2;
    Fixed3 Oc;
    
    Fixed3_Sub A0(r.Orig, sphere.Center, Oc);           // float3 Oc = r.Orig - sphere.Center;    
    Fixed3_Dot A1(r.Dir, r.Dir, a);                     // float a = dot(r.Dir, r.Dir);
    Fixed3_Dot A2(Oc, r.Dir, half_b);                   // float half_b = dot(Oc, r.Dir);
    Fixed3_Dot A3(Oc, Oc, c0);                          // float c0 = dot(Oc, Oc);
    Fixed_Mul A4(sphere.Radius, sphere.Radius, c1);     // float c1 = dot(sphere.Radius, sphere.Radius);
    Fixed_Sub A5(c0, c1, c);                            // float c = c0 - c1;
    Fixed_Mul A6(half_b, half_b, R1);                   // float R1 = half_b * half_b;
    Fixed_Mul A7(a, c, R2);                             // float R2 = a * c;
    Fixed_Sub A8(R1, R2, discr);                        // float discr = R1 - R2;
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
    output logic valid,    
    output HitData hit_data    
    );    

    assign valid = 1;
    assign hit_data.PI = pi;
    assign hit_data.Color = color;

    Fixed Discriminant;    

    //always_comb begin
    always_ff @(posedge clk) begin			
        if (IsValidPrimitiveIndex(pi) && Discriminant.Value[`FIXED_WIDTH-1] == 0) begin
            hit_data.bHit = 1;
            hit_data.T = _Fixed(0);
            hit_data.SurfaceType = st;
            hit_data.Normal = _FixedNorm3(_FixedNorm(0), _FixedNorm(1), _FixedNorm(0));
            valid <= 1;
        end
        else begin
            hit_data.bHit = 0;
            hit_data.SurfaceType = ST_None;
            valid <= 1;
        end        
    end

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