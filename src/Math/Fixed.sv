//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/14 21:19:53
// Design Name: 
// Module Name: Fixed_ALU
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
`ifndef FIXED_SV
`define FIXED_SV

`include "../Types.sv"
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed _Fixed(
    input [`FIXED_WIDTH-1:0] v
    );
    logic S;      
    begin
        S = v[`FIXED_WIDTH-1];
        if (S) begin
            _Fixed.Value = ((~v + 1) << `FIXED_FRAC_WIDTH);
            _Fixed.Value = ~_Fixed.Value + 1;
        end
        else begin
            _Fixed.Value = (v << `FIXED_FRAC_WIDTH);
        end
    end
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed _Fixeds(
    input [`FIXED_WIDTH-1:0] v
    );
    begin
        _Fixeds.Value = v;        
    end
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed FixedZero;
    FixedZero = _Fixed(0);
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed FixedOne;
    FixedOne = _Fixed(1);
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed FixedNegOne;
    FixedNegOne = _Fixed(-1);
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed FixedHalf;
    FixedHalf.Value = `FIXED_HALF_UNIT;
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed FixedMax;
    FixedMax.Value = `FIXED_MAX;
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed FixedInf;
    FixedInf.Value = `FIXED_INF;
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic logic IsFixedInf(
    input Fixed a
    );    
    begin        
        if ((a.Value & `FIXED_INF) == `FIXED_INF) begin        
             IsFixedInf = 1;
        end
        else begin
            IsFixedInf = 0;
        end        
    end
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed FromFixedNorm(
    input FixedNorm v
    );
    logic S;      
    begin
        S = v.Value[`FIXED_NORM_WIDTH-1];
        FromFixedNorm.Value = (S) ? {{16{1'b1}}, v.Value} : {{16{1'b0}}, v.Value};        
    end
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic [`FIXED_WIDTH-1:0] Fixed_Value(
    input Fixed a
    );
    logic S;
    logic [`FIXED_WIDTH-1:0] AA;    

    begin
        S = a.Value[`FIXED_WIDTH-1];
		AA  = (S) ? (~a.Value + 1) : a.Value;
		AA = AA >> `FIXED_FRAC_WIDTH;
		Fixed_Value = (S) ? (~AA + 1) : AA;
    end    
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed Fixed_Abs(
    input Fixed a
    );
    logic S;      
    begin
        S = a.Value[`FIXED_WIDTH-1];
        Fixed_Abs.Value = (S) ? (~a.Value + 1) : a.Value;
    end
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed _Fixed_ByShifted(
    input [`FIXED_WIDTH-1:0] v
    );
    begin
        _Fixed_ByShifted.Value = v;
    end
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed Fixed_Neg(
    input Fixed a
    );
    begin
        Fixed_Neg.Value = ~a.Value + 1;
    end    
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed Fixed_Add(
    input Fixed a,
    input Fixed b
    );
    begin
        Fixed_Add.Value = a.Value + b.Value;                    
    end    
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed Fixed_Sub(
    input Fixed a,
    input Fixed b
    );
    begin
        Fixed_Sub.Value = a.Value - b.Value;            
    end    
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed Fixed_Mul(
    input Fixed a,
    input Fixed b
    );
    logic [`FIXED_WIDTH * 2 - 1:0] T, RA, RB;	
    Fixed TT;
    logic S1, S2;
    //reg Fixed RA, RB;
    
    begin
        /*
        T = 0;
        S1 = a.Value[`FIXED_WIDTH-1];
		S2 = b.Value[`FIXED_WIDTH-1];

		RA.Value = (S1) ? (~a.Value + 1) : a.Value;
		RB.Value = (S2) ? (~b.Value + 1) : b.Value;	
		
		for (integer i = `FIXED_WIDTH-1; i >= 0; i = i - 1) begin		
			T = T << 1;
			if ((RB.Value & (1 << i)) >> i) begin
				T = T + RA.Value;
            end			
		end
		
		T = (T >> `FIXED_FRAC_WIDTH);
		TT.Value = T[`FIXED_WIDTH-1:0];
		Fixed_Mul.Value = (S1 ^ S2) ? (~TT.Value + 1) : TT.Value;        
        */
        S1 = a.Value[`FIXED_WIDTH-1];
        S2 = b.Value[`FIXED_WIDTH-1];

        RA = (S1) ? ({{`FIXED_WIDTH{1'b0}}, ~a.Value + 1}) : {{`FIXED_WIDTH{1'b0}}, a.Value};
        RB = (S2) ? ({{`FIXED_WIDTH{1'b0}}, ~b.Value + 1}) : {{`FIXED_WIDTH{1'b0}}, b.Value};		
        T = (RA * RB) >> `FIXED_FRAC_WIDTH;           
        TT.Value = T[`FIXED_WIDTH-1:0];
        Fixed_Mul.Value = (S1 ^ S2) ? (~TT.Value + 1) : TT.Value;		                    
    end    
endfunction

/*
function automatic Fixed Fixed_Div(
    input Fixed a,
    input Fixed b
    );
    reg [Fixed_WIDTH * 2 - 1:0] Q, R, RA;
    reg S1, S2;
    reg Fixed RB;
    integer i;

    begin
        Q = 0;
		R = 0;

		if (b == 0) begin		
			Fixed_Div = Fixed_WIDTH'h7fffffff;
		end 
		else begin
			S1 = a[Fixed_WIDTH-1];
		    S2 = b[Fixed_WIDTH-1];

			RA = (S1) ? (~a + 1) : a;
			RA = RA << Fixed_FRAC_WIDTH;
			RB = (S2) ? (~b + 1) : b;

			for (i = Fixed_WIDTH*2-1; i >= 0; i = i - 1) begin
				Q  = Q << 1;
				R  = R << 1;
				R = R | (RA & (Fixed_WIDTH*2'b1 << i)) >> i;
				if (R >= RB) begin
					R = R - RB;
					Q = Q | 1;
                end
            end
			Q = (S1 ^ S2) ? (~Q + 1) : Q;
			Fixed_Div = Q[Fixed_WIDTH-1:0];
		end
    end    
endfunction
*/
/*
function automatic Fixed Fixed_Sqrt(
    input Fixed a
    );
    reg Fixed X, Y;
    
    begin
        X = a + 1;
		Y = a;
		while (X > Y) begin
			X = Y;
			Y = (Fixed_Add(Y, Fixed_Div(a, Y))) >> 1;
        end
        Fixed_Sqrt = X;
    end    
endfunction
*/
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed Fixed_RSft(
    input Fixed a,
    input [5:0] s
    );
    logic S;
    Fixed AA;    

    begin
        S = a.Value[`FIXED_WIDTH-1];
		AA.Value  = (S) ? (~a.Value + 1) : a.Value;
		AA.Value = AA.Value >> s;
		Fixed_RSft.Value = (S) ? (~AA.Value + 1) : AA.Value;
    end    
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed Fixed_LSft(
    input Fixed a,
    input [5:0] s
    );
    logic S;
    Fixed AA;    

    begin
        S = a.Value[`FIXED_WIDTH-1];
		AA.Value  = (S) ? (~a.Value + 1) : a.Value;
		AA.Value = AA.Value << s;
		Fixed_LSft.Value = (S) ? (~AA.Value + 1) : AA.Value;
    end    
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed Fixed_Min(
    input Fixed a,
    input Fixed b
    );
    logic SA, SB;    

    begin
        SA = a.Value[`FIXED_WIDTH-1];
		SB = b.Value[`FIXED_WIDTH-1];

		if (SA ^ SB) begin		
			Fixed_Min = (SA) ? a : b;
		end		
		else begin 
			Fixed_Min = (a.Value > b.Value) ? b : a;
		end
    end    
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed Fixed_Max(
    input Fixed a,
    input Fixed b
    );
    logic SA, SB;    

    begin
        SA = a.Value[`FIXED_WIDTH-1];
		SB = b.Value[`FIXED_WIDTH-1];

		if (SA ^ SB) begin		
			Fixed_Max = (SA) ? b : a;
		end		
		else begin 
			Fixed_Max = (a.Value > b.Value) ? a : b;
		end
    end    
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed_Greater(
    input Fixed a,
    input Fixed b
    );
    logic SA, SB;
    
    begin
        SA = a.Value[`FIXED_WIDTH-1];
		SB = b.Value[`FIXED_WIDTH-1];

		if (SA ^ SB) begin		
			Fixed_Greater = (SA) ? 0 : 1;
		end
		else begin
			Fixed_Greater = (a.Value > b.Value);
		end
    end    
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed_GreaterEqual(
    input Fixed a,
    input Fixed b
    );
    logic SA, SB;
    
    begin
        SA = a.Value[`FIXED_WIDTH-1];
		SB = b.Value[`FIXED_WIDTH-1];

		if (SA ^ SB) begin		
			Fixed_GreaterEqual = (SA) ? 0 : 1;
		end
		else begin
			Fixed_GreaterEqual = (a.Value >= b.Value);
		end
    end    
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed_Less(
    input Fixed a,
    input Fixed b
    );
    logic SA, SB;
    
    begin
        SA = a.Value[`FIXED_WIDTH-1];
		SB = b.Value[`FIXED_WIDTH-1];

		if (SA ^ SB) begin		
			Fixed_Less = (SA) ? 1 : 0;
		end
		else begin
			Fixed_Less = (a.Value < b.Value);
		end
    end    
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed_LessEqual(
    input Fixed a,
    input Fixed b
    );
    logic SA, SB;
    
    begin
        SA = a.Value[`FIXED_WIDTH-1];
		SB = b.Value[`FIXED_WIDTH-1];

		if (SA ^ SB) begin		
			Fixed_LessEqual = (SA) ? 1 : 0;
		end
		else begin
			Fixed_LessEqual = (a.Value <= b.Value);
		end
    end    
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function automatic Fixed_Equal(
    input Fixed a,
    input Fixed b
    );
    begin
        Fixed_Equal = ( a.Value == b.Value);
    end    
endfunction




//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module Fixed_Add(   
    input Fixed a,
    input Fixed b,
    output Fixed o
    );
    always_comb begin
        o = Fixed_Add(a, b);        
    end
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module Fixed_Sub(   
    input Fixed a,
    input Fixed b,
    output Fixed o
    );
    always_comb begin
        o = Fixed_Sub(a, b);        
    end
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module Fixed_Mul(   
    input Fixed a,
    input Fixed b,
    output Fixed o
    );
    always_comb begin
        o = Fixed_Mul(a, b);        
    end
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module Fixed_LSft(   
    input Fixed a,
    input logic [5:0] b,
    output Fixed o
    );
    always_comb begin
        o = Fixed_LSft(a, b);        
    end
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module Fixed_Min(   
    input Fixed a,
    input Fixed b,
    output Fixed o
    );
    always_comb begin
        o = Fixed_Min(a, b);        
    end
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module Fixed_Max(   
    input Fixed a,
    input Fixed b,
    output Fixed o
    );
    always_comb begin
        o = Fixed_Max(a, b);        
    end
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module Fixed_Greater(   
    input Fixed a,
    input Fixed b,
    output logic o
    );
    always_comb begin
        o = Fixed_Greater(a, b);        
    end
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module Fixed_GreaterEqual(
    input Fixed a,
    input Fixed b,
    output logic o
    );
    always_comb begin
        o = Fixed_GreaterEqual(a, b);        
    end
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module Fixed_Less(   
    input Fixed a,
    input Fixed b,
    output logic o
    );
    always_comb begin
        o = Fixed_Less(a, b);        
    end
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module Fixed_LessEqual(
    input Fixed a,
    input Fixed b,
    output logic o
    );
    always_comb begin
        o = Fixed_LessEqual(a, b);        
    end
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module Fixed_Equal(
    input Fixed a,
    input Fixed b,
    output logic o
    );
    always_comb begin
        o = Fixed_Equal(a, b);        
    end
endmodule

`endif
