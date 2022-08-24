//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/14 21:19:53
// Design Name: 
// Module Name: FixedNorm_ALU
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
`ifndef FIXEDNORM_SV
`define FIXEDNORM_SV

`include "../Types.sv"

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic FixedNorm _FixedNorm(
    input [`FIXED_NORM_WIDTH-1:0] v
    );
    logic S;      
    begin
        S = v[`FIXED_NORM_WIDTH-1];
        if (S) begin
            _FixedNorm.Value = ((~v + 1) << `FIXED_NORM_FRAC_WIDTH);
            _FixedNorm.Value = ~_FixedNorm.Value + 1;
        end
        else begin
            _FixedNorm.Value = (v << `FIXED_NORM_FRAC_WIDTH);
        end
    end
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic FixedNorm FromFixed(
    input Fixed v
    );
    logic S;      
    logic [`FIXED_NORM_WIDTH-1:0] AA;
    begin
        S = v.Value[`FIXED_WIDTH-1];
        AA = (S) ? (~v.Value + 1) : v.Value[15:0];
        FromFixed.Value = (S) ? ~AA + 1 : AA;
    end
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic [`FIXED_NORM_WIDTH-1:0] FixedNorm_Value(
    input FixedNorm a
    );
    logic S;
    logic [`FIXED_NORM_WIDTH-1:0] AA;    

    begin
        S = a.Value[`FIXED_NORM_WIDTH-1];
		AA  = (S) ? (~a.Value + 1) : a.Value;
		AA = AA >> `FIXED_FRAC_WIDTH;
		FixedNorm_Value = (S) ? (~AA + 1) : AA;
    end    
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic FixedNorm FixedNormZero;
    FixedNormZero = _FixedNorm(0);
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic FixedNorm FixedNormOne;
    FixedNormOne = _FixedNorm(1);
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic FixedNorm FixedNormNegOne;
    FixedNormNegOne = _FixedNorm(-1);
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic FixedNorm FixedNorm_Abs(
    input FixedNorm a
    );
    logic S;      
    begin
        S = a.Value[`FIXED_NORM_WIDTH-1];
        FixedNorm_Abs.Value = (S) ? (~a.Value + 1) : a.Value;
    end
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic FixedNorm _FixedNorm_ByShifted(
    input [`FIXED_NORM_WIDTH-1:0] v
    );
    begin
        _FixedNorm_ByShifted.Value = v;
    end
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic FixedNorm FixedNorm_Neg(
    input FixedNorm a
    );
    begin
        FixedNorm_Neg.Value = ~a.Value + 1;
    end    
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic FixedNorm FixedNorm_Add(
    input FixedNorm a,
    input FixedNorm b
    );
    begin
        FixedNorm_Add.Value = a.Value + b.Value;
    end    
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic FixedNorm FixedNorm_Sub(
    input FixedNorm a,
    input FixedNorm b
    );
    begin
        FixedNorm_Sub.Value = a.Value - b.Value;
    end    
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic FixedNorm FixedNorm_Mul(
    input FixedNorm a,
    input FixedNorm b
    );
    logic [`FIXED_NORM_WIDTH * 2 - 1:0] T;
    FixedNorm RA, RB;
    FixedNorm TT;
    logic S1, S2;    
    
    begin
        /*
        T = 0;
        S1 = a.Value[`FIXED_NORM_WIDTH-1];
		S2 = b.Value[`FIXED_NORM_WIDTH-1];

		RA.Value = (S1) ? (~a.Value + 1) : a.Value;
		RB.Value = (S2) ? (~b.Value + 1) : b.Value;	
		
		for (integer i = `FIXED_NORM_WIDTH-1; i >= 0; i = i - 1) begin		
			T = T << 1;
			if ((RB.Value & (1 << i)) >> i) begin
				T = T + RA.Value;
            end			
		end
		
		T = (T >> `FIXED_FRAC_WIDTH);
		TT.Value = T[`FIXED_NORM_WIDTH-1:0];
		FixedNorm_Mul.Value = (S1 ^ S2) ? (~TT.Value + 1) : TT.Value;        
        */
        
        S1 = a.Value[`FIXED_NORM_WIDTH-1];
		S2 = b.Value[`FIXED_NORM_WIDTH-1];

		RA.Value = (S1) ? (~a.Value + 1) : a.Value;
		RB.Value = (S2) ? (~b.Value + 1) : b.Value;			
		T = (RA.Value * RB.Value) >> `FIXED_FRAC_WIDTH;           
		TT.Value = T[`FIXED_NORM_WIDTH-1:0];
		FixedNorm_Mul.Value = (S1 ^ S2) ? (~TT.Value + 1) : TT.Value;		
    end    
endfunction

/*
function automatic FixedNorm FixedNorm_Div(
    input FixedNorm a,
    input FixedNorm b
    );
    reg [FIXED_NORM_WIDTH * 2 - 1:0] Q, R, RA;
    reg S1, S2;
    reg FixedNorm RB;
    integer i;

    begin
        Q = 0;
		R = 0;

		if (b == 0) begin		
			FixedNorm_Div = FIXED_NORM_WIDTH'h7fffffff;
		end 
		else begin
			S1 = a[FIXED_NORM_WIDTH-1];
		    S2 = b[FIXED_NORM_WIDTH-1];

			RA = (S1) ? (~a + 1) : a;
			RA = RA << FixedNorm_FRAC_WIDTH;
			RB = (S2) ? (~b + 1) : b;

			for (i = FIXED_NORM_WIDTH*2-1; i >= 0; i = i - 1) begin
				Q  = Q << 1;
				R  = R << 1;
				R = R | (RA & (FIXED_NORM_WIDTH*2'b1 << i)) >> i;
				if (R >= RB) begin
					R = R - RB;
					Q = Q | 1;
                end
            end
			Q = (S1 ^ S2) ? (~Q + 1) : Q;
			FixedNorm_Div = Q[FIXED_NORM_WIDTH-1:0];
		end
    end    
endfunction
*/
/*
function automatic FixedNorm FixedNorm_Sqrt(
    input FixedNorm a
    );
    reg FixedNorm X, Y;
    
    begin
        X = a + 1;
		Y = a;
		while (X > Y) begin
			X = Y;
			Y = (FixedNorm_Add(Y, FixedNorm_Div(a, Y))) >> 1;
        end
        FixedNorm_Sqrt = X;
    end    
endfunction
*/
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic FixedNorm FixedNorm_RSft(
    input FixedNorm a,
    input [5:0] s
    );
    logic S;
    FixedNorm AA;    

    begin
        S = a.Value[`FIXED_NORM_WIDTH-1];
		AA.Value  = (S) ? (~a.Value + 1) : a.Value;
		AA.Value = AA.Value >> s;
		FixedNorm_RSft.Value = (S) ? (~AA.Value + 1) : AA.Value;
    end    
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic FixedNorm FixedNorm_LSft(
    input FixedNorm a,
    input [5:0] s
    );
    logic S;
    FixedNorm AA;    

    begin
        S = a.Value[`FIXED_NORM_WIDTH-1];
		AA.Value  = (S) ? (~a.Value + 1) : a.Value;
		AA.Value = AA.Value << s;
		FixedNorm_LSft.Value = (S) ? (~AA.Value + 1) : AA.Value;
    end    
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic FixedNorm FixedNorm_Min(
    input FixedNorm a,
    input FixedNorm b
    );
    logic SA, SB;    

    begin
        SA = a.Value[`FIXED_NORM_WIDTH-1];
		SB = b.Value[`FIXED_NORM_WIDTH-1];

		if (SA ^ SB) begin		
			FixedNorm_Min = (SA) ? a : b;
		end		
		else begin 
			FixedNorm_Min = (a.Value > b.Value) ? b : a;
		end
    end    
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic FixedNorm FixedNorm_Max(
    input FixedNorm a,
    input FixedNorm b
    );
    logic SA, SB;    

    begin
        SA = a.Value[`FIXED_NORM_WIDTH-1];
		SB = b.Value[`FIXED_NORM_WIDTH-1];

		if (SA ^ SB) begin		
			FixedNorm_Max = (SA) ? b : a;
		end		
		else begin 
			FixedNorm_Max = (a.Value > b.Value) ? a : b;
		end
    end    
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic FixedNorm_Greater(
    input FixedNorm a,
    input FixedNorm b
    );
    logic SA, SB;
    
    begin
        SA = a.Value[`FIXED_NORM_WIDTH-1];
		SB = b.Value[`FIXED_NORM_WIDTH-1];

		if (SA ^ SB) begin		
			FixedNorm_Greater = (SA) ? 0 : 1;
		end
		else begin
			FixedNorm_Greater = (a.Value > b.Value);
		end
    end    
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic FixedNorm_Less(
    input FixedNorm a,
    input FixedNorm b
    );
    logic SA, SB;
    
    begin
        SA = a.Value[`FIXED_NORM_WIDTH-1];
		SB = b.Value[`FIXED_NORM_WIDTH-1];

		if (SA ^ SB) begin		
			FixedNorm_Less = (SA) ? 1 : 0;
		end
		else begin
			FixedNorm_Less = (a.Value < b.Value);
		end
    end    
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic FixedNorm_Equal(
    input FixedNorm a,
    input FixedNorm b
    );
    begin
        FixedNorm_Equal = ( a.Value == b.Value);
    end    
endfunction

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module FixedNorm_Add(   
    input FixedNorm a,
    input FixedNorm b,
    output FixedNorm o
    );
    always_comb begin
        o <= FixedNorm_Add(a, b);        
    end
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module FixedNorm_Sub(   
    input FixedNorm a,
    input FixedNorm b,
    output FixedNorm o
    );
    always_comb begin
        o <= FixedNorm_Sub(a, b);        
    end
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module FixedNorm_Mul(
    input FixedNorm a,
    input FixedNorm b,
    output FixedNorm o
    );
    always_comb begin
        o <= FixedNorm_Mul(a, b);
    end    
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module FixedNorm_Greater(   
    input FixedNorm a,
    input FixedNorm b,
    output logic o
    );
    always_comb begin
        o <= FixedNorm_Greater(a, b);        
    end
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module FixedNorm_Less(   
    input FixedNorm a,
    input FixedNorm b,
    output logic o
    );
    always_comb begin
        o <= FixedNorm_Less(a, b);        
    end
endmodule

`endif

