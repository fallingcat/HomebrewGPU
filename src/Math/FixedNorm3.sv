//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/15 11:18:04
// Design Name: 
// Module Name: FixedNorm3
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
`ifndef FIXEDNORM3_SV
`define FIXEDNORM3_SV

`include "FixedNorm.sv"

// Set up with unshifted values
function automatic FixedNorm3 _FixedNorm3u(
    input `FIXED x,
    input `FIXED y,
    input `FIXED z
    );
    begin
        _FixedNorm3u.Dim[0] = _FixedNorm(x);
        _FixedNorm3u.Dim[1] = _FixedNorm(y);
        _FixedNorm3u.Dim[2] = _FixedNorm(z);        
    end
endfunction

// Set up with shifted values
function automatic FixedNorm3 _FixedNorm3s(
    input `FIXED x,
    input `FIXED y,
    input `FIXED z
    );
    begin
        _FixedNorm3s.Dim[0].Value = x;
        _FixedNorm3s.Dim[1].Value = y;
        _FixedNorm3s.Dim[2].Value = z;        
    end
endfunction

function automatic FixedNorm3 _FixedNorm3(
    input FixedNorm x,
    input FixedNorm y,
    input FixedNorm z
    );
    begin
        _FixedNorm3.Dim[0] = x;
        _FixedNorm3.Dim[1] = y;
        _FixedNorm3.Dim[2] = z;        
    end
endfunction

function automatic FixedNorm3 FromFixed3(
    input Fixed3 v
    );
    begin
        FromFixed3.Dim[0] = FromFixed(v.Dim[0]);
        FromFixed3.Dim[1] = FromFixed(v.Dim[1]);
        FromFixed3.Dim[2] = FromFixed(v.Dim[2]);
    end
endfunction

function automatic FixedNorm3 FixedNorm3_Add(
    input FixedNorm3 a,
    input FixedNorm3 b    
    );
    begin
        for (integer d = 0; d < 3; d = d + 1) begin
            FixedNorm3_Add.Dim[d] = FixedNorm_Add(a.Dim[d], b.Dim[d]);
        end        
    end
endfunction

function automatic FixedNorm3 FixedNorm3_Sub(
    input FixedNorm3 a,
    input FixedNorm3 b    
    );
    begin
        for (integer d = 0; d < 3; d = d + 1) begin
            FixedNorm3_Sub.Dim[d] = FixedNorm_Sub(a.Dim[d], b.Dim[d]);
        end
    end
endfunction

function automatic FixedNorm3 FixedNorm3_Mul(
    input FixedNorm f,
    input FixedNorm3 a    
    );
    begin
        for (integer d = 0; d < 3; d = d + 1) begin
            FixedNorm3_Mul.Dim[d] = FixedNorm_Mul(f, a.Dim[d]);
        end
    end
endfunction

function automatic FixedNorm FixedNorm3_Dot(
    input FixedNorm3 a,
    input FixedNorm3 b    
    );
    begin
        FixedNorm3_Dot = FixedNorm_Add(FixedNorm_Add(FixedNorm_Mul(a.Dim[0], b.Dim[0]), FixedNorm_Mul(a.Dim[1], b.Dim[1])), FixedNorm_Mul(a.Dim[2], b.Dim[2]));        
    end
endfunction

function automatic FixedNorm3 FixedNorm3_Cross(
    input FixedNorm3 a,
    input FixedNorm3 b    
    );
    begin
        FixedNorm3_Cross.Dim[0] = FixedNorm_Sub(FixedNorm_Mul(a.Dim[1], b.Dim[2]), FixedNorm_Mul(a.Dim[2], b.Dim[1]));        
        FixedNorm3_Cross.Dim[1] = FixedNorm_Sub(FixedNorm_Mul(a.Dim[2], b.Dim[0]), FixedNorm_Mul(a.Dim[0], b.Dim[2]));
        FixedNorm3_Cross.Dim[2] = FixedNorm_Sub(FixedNorm_Mul(a.Dim[0], b.Dim[1]), FixedNorm_Mul(a.Dim[1], b.Dim[0]));
    end
endfunction

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module FixedNorm3_Dot(   
    input FixedNorm3 a,
    input FixedNorm3 b,
    output FixedNorm o
    );

    FixedNorm O[4];

    FixedNorm_Mul A0(a.Dim[0], b.Dim[0], O[0]);
    FixedNorm_Mul A1(a.Dim[1], b.Dim[1], O[1]);
    FixedNorm_Mul A2(a.Dim[2], b.Dim[2], O[2]);
    FixedNorm_Add A3(O[0], O[1], O[3]);
    FixedNorm_Add A4(O[2], O[3], o);

endmodule

`endif
