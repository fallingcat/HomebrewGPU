//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/15 11:18:04
// Design Name: 
// Module Name: Fixed3
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

`ifndef FIXED3_SV
`define FIXED3_SV

`include "Fixed.sv"

//-------------------------------------------------------------------
// Set up with unshifted values
//-------------------------------------------------------------------    
function automatic Fixed3 _Fixed3u(
    input `FIXED x,
    input `FIXED y,
    input `FIXED z
    );
    begin
        _Fixed3u.Dim[0] = _Fixed(x);
        _Fixed3u.Dim[1] = _Fixed(y);
        _Fixed3u.Dim[2] = _Fixed(z);        
    end
endfunction
//-------------------------------------------------------------------
// Set up with shifted values
//-------------------------------------------------------------------    
function automatic Fixed3 _Fixed3s(
    input `FIXED x,
    input `FIXED y,
    input `FIXED z
    );
    begin
        _Fixed3s.Dim[0].Value = x;
        _Fixed3s.Dim[1].Value = y;
        _Fixed3s.Dim[2].Value = z;        
    end
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed3 _Fixed3(
    input Fixed x,
    input Fixed y,
    input Fixed z
    );
    begin
        _Fixed3.Dim[0] = x;
        _Fixed3.Dim[1] = y;
        _Fixed3.Dim[2] = z;        
    end
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed3 FromFixedNorm3(
    input FixedNorm3 v
    );
    begin
        FromFixedNorm3.Dim[0] = FromFixedNorm(v.Dim[0]);
        FromFixedNorm3.Dim[1] = FromFixedNorm(v.Dim[1]);
        FromFixedNorm3.Dim[2] = FromFixedNorm(v.Dim[2]);
    end
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed3 Fixed3_Add(
    input Fixed3 a,
    input Fixed3 b    
    );
    begin
        for (integer d = 0; d < 3; d = d + 1) begin
            Fixed3_Add.Dim[d] = Fixed_Add(a.Dim[d], b.Dim[d]);
        end        
    end
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed3 Fixed3_Sub(
    input Fixed3 a,
    input Fixed3 b    
    );
    begin
        for (integer d = 0; d < 3; d = d + 1) begin
            Fixed3_Sub.Dim[d] = Fixed_Sub(a.Dim[d], b.Dim[d]);
        end
    end
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed3 Fixed3_Mul(
    input Fixed f,
    input Fixed3 a    
    );
    begin
        for (integer d = 0; d < 3; d = d + 1) begin
            Fixed3_Mul.Dim[d] = Fixed_Mul(f, a.Dim[d]);
        end
    end
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed Fixed3_Dot(
    input Fixed3 a,
    input Fixed3 b    
    );
    begin
        Fixed3_Dot.Value = 0;
        for (integer d = 0; d < 3; d = d + 1) begin
            Fixed3_Dot = Fixed_Add(Fixed3_Dot, Fixed_Mul(a.Dim[d], b.Dim[d]));
        end
    end
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed3 Fixed3_Cross(
    input Fixed3 a,
    input Fixed3 b    
    );
    begin
        Fixed3_Cross.Dim[0] = Fixed_Sub(Fixed_Mul(a.Dim[1], b.Dim[2]), Fixed_Mul(a.Dim[2], b.Dim[1]));        
        Fixed3_Cross.Dim[1] = Fixed_Sub(Fixed_Mul(a.Dim[2], b.Dim[0]), Fixed_Mul(a.Dim[0], b.Dim[2]));
        Fixed3_Cross.Dim[2] = Fixed_Sub(Fixed_Mul(a.Dim[0], b.Dim[1]), Fixed_Mul(a.Dim[1], b.Dim[0]));
    end
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module Fixed3_Add(   
    input Fixed3 a,
    input Fixed3 b,
    output Fixed3 o
    );

    Fixed_Add A0(a.Dim[0], b.Dim[0], o.Dim[0]);
    Fixed_Add A1(a.Dim[1], b.Dim[1], o.Dim[1]);
    Fixed_Add A2(a.Dim[2], b.Dim[2], o.Dim[2]);
    
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module Fixed3_AddOffset(   
    input Fixed3 a,
    input Fixed b,
    output Fixed3 o
    );

    Fixed_Add A0(a.Dim[0], b, o.Dim[0]);
    Fixed_Add A1(a.Dim[1], b, o.Dim[1]);
    Fixed_Add A2(a.Dim[2], b, o.Dim[2]);
    
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module Fixed3_Sub(   
    input Fixed3 a,
    input Fixed3 b,
    output Fixed3 o
    );

    Fixed_Sub A0(a.Dim[0], b.Dim[0], o.Dim[0]);
    Fixed_Sub A1(a.Dim[1], b.Dim[1], o.Dim[1]);
    Fixed_Sub A2(a.Dim[2], b.Dim[2], o.Dim[2]);

endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module Fixed3_SubOffset(   
    input Fixed3 a,
    input Fixed b,
    output Fixed3 o
    );

    Fixed_Sub A0(a.Dim[0], b, o.Dim[0]);
    Fixed_Sub A1(a.Dim[1], b, o.Dim[1]);
    Fixed_Sub A2(a.Dim[2], b, o.Dim[2]);
    
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module Fixed3_Mul(   
    input Fixed a,
    input Fixed3 b,
    output Fixed3 o
    );

    Fixed_Mul A0(a, b.Dim[0], o.Dim[0]);
    Fixed_Mul A1(a, b.Dim[1], o.Dim[1]);
    Fixed_Mul A2(a, b.Dim[2], o.Dim[2]);

endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module Fixed3_Dot(   
    input Fixed3 a,
    input Fixed3 b,
    output Fixed o
    );

    Fixed O[4];

    Fixed_Mul A0(a.Dim[0], b.Dim[0], O[0]);
    Fixed_Mul A1(a.Dim[1], b.Dim[1], O[1]);
    Fixed_Mul A2(a.Dim[2], b.Dim[2], O[2]);
    Fixed_Add A3(O[0], O[1], O[3]);
    Fixed_Add A4(O[2], O[3], o);

endmodule

`endif
