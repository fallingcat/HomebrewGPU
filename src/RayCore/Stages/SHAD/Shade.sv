//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/23 16:22:44
// Design Name: 
// Module Name: Lighting
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
`include "../../../Math/Fixed.sv"
`include "../../../Math/Fixed3.sv"
`include "../../../Math/FixedNorm.sv"
`include "../../../Math/FixedNorm3.sv"

//-------------------------------------------------------------------
// 
//-------------------------------------------------------------------    
module _LightingDiffuse(
    input FixedNorm3 l,
    input FixedNorm3 n,
    input logic shadow,
    output FixedNorm o
    );

    logic Neg;
    FixedNorm D;  

    FixedNorm3_Dot A0(l, n, D);
    FixedNorm_Less A1(D, _FixedNorm(0), Neg);

    assign o = (shadow || Neg) ? _FixedNorm(0) : D;

endmodule
//-------------------------------------------------------------------
// 
//-------------------------------------------------------------------    
module _FinalDiffuse(
    input FixedNorm3 l,
    input FixedNorm3 n,
    input logic hit,
    input logic shadow,
    output FixedNorm o
    );

    FixedNorm Ambient;
    FixedNorm D, Diffuse;
    logic Over;

    initial begin
        Ambient.Value <= `FIXED_NORM_WIDTH'd4915; 
    end

    _LightingDiffuse A0(l, n, shadow, D);
    FixedNorm_Add A1(D, Ambient, Diffuse);
    FixedNorm_Greater A2(Diffuse, _FixedNorm(1), Over);

    assign o = (Over || !hit) ? _FixedNorm(1) : Diffuse;

endmodule 
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module Fixed_Color_Mul(
    input FixedNorm a,
    input logic [7:0] b,
    output logic [7:0] o
    );

    always_comb begin
        o <= (({{16{1'b0}}, a.Value} * b) >> `FIXED_FRAC_WIDTH);
    end
endmodule   
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module Fixed_RGB8_Mul(
    input FixedNorm a,
    input RGB8 b,
    output RGB8 o
    );

    Fixed_Color_Mul A0(a, b.Channel[0], o.Channel[0]);
    Fixed_Color_Mul A1(a, b.Channel[1], o.Channel[1]);
    Fixed_Color_Mul A2(a, b.Channel[2], o.Channel[2]);
endmodule   
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module Texturing (
    input clk,    
    input strobe,
    input RGB8 color,
    input Fixed3 pos,
    input logic hit,
    input logic `PRIMITIVE_INDEX pi,
    output RGB8 out
    );
    logic [27:0] PX, PZ;

    always_ff @(posedge clk) begin    
        if (strobe) begin
            out <= color;        
            if (hit && pi == `BVH_MODEL_RAW_DATA_SIZE) begin
                PX = pos.Dim[0].Value >> (`FIXED_FRAC_WIDTH + 4);
                PZ = pos.Dim[2].Value >> (`FIXED_FRAC_WIDTH + 4);
                if (PX[0] ^ PZ[0]) begin                                    
                    out.Channel[0] <= color.Channel[0] >> 1;
                    out.Channel[1] <= color.Channel[1] >> 1;
                    out.Channel[2] <= color.Channel[2] >> 1;
                end      
            end                      
        end        
    end    
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module _ComputeCurrentColor(    
    input SurfaceType surface,
    input FixedNorm diffuse,
    input RGB8 color,
    output RGB8 o
    );

    FixedNorm Diffuse;

    always_comb begin            
        if (surface == ST_Metal) begin            
            Diffuse <= FixedNorm_RSft(diffuse, 2);
        end
        else begin
            Diffuse <= diffuse;
        end
    end    
    
    Fixed_RGB8_Mul CURRENT_COLOR(
        .a(Diffuse),
        .b(color),
        .o(o)
    );
endmodule
//-------------------------------------------------------------------
// o = c0 * a + c1;
//-------------------------------------------------------------------    
module Color_Accu(
    input logic [7:0] c0,
    input logic `BOUNCE_LEVEL a,
    input logic [7:0] c1,
    output logic [15:0] o
    );

    always_comb begin
        o <= ((c0 * a) + {{8{1'b0}}, c1});
    end
endmodule 
//-------------------------------------------------------------------
// Accumulate RGB8 values
//-------------------------------------------------------------------    
module RGB8_Accu(
    input RGB8 c0,
    input logic `BOUNCE_LEVEL a,
    input RGB8 c1,
    output logic [15:0] o[3]
    );

    Color_Accu A0(c0.Channel[0], a, c1.Channel[0], o[0]);
    Color_Accu A1(c0.Channel[1], a, c1.Channel[1], o[1]);
    Color_Accu A2(c0.Channel[2], a, c1.Channel[2], o[2]);
    
endmodule 
//-------------------------------------------------------------------
// Compute reflection direction
//-------------------------------------------------------------------    
module ReflectionDir(
    input FixedNorm3 n,
    input Fixed3 i,    
    output Fixed3 r
    );

`ifdef IMPLEMENT_REFLECTION
    Fixed3 TN, NV;
    Fixed D, D2;

    always_comb begin
        TN <= FromFixedNorm3(n);
    end

    Fixed3_Dot A0(TN, i, D);
    Fixed_LSft A1(D, 6'd1, D2);
    Fixed3_Mul A2(D2, TN, NV);  
    Fixed3_Sub A3(i, NV, r);
`endif

endmodule 
//-------------------------------------------------------------------
// 
//-------------------------------------------------------------------    
module ComputeETA(
    input clk,    
    input resetn,    
    input strobe,
    input Fixed d,
    input Fixed eta,    
    output Fixed out,
    output logic valid
    );    

    logic DivStrobe, DivValid;
    Fixed ETAInv, FinalETA;
    State State, NextState = State_Ready;

    always_ff @(posedge clk, negedge resetn) begin
        if (!resetn) begin
            NextState <= State_Ready;
        end
        else begin
            State <= NextState;
            case (State)
                State_Ready: begin  
                    valid <= 0;      
                    DivStrobe <= 0;
                    FinalETA = eta;
                    if (strobe) begin
                        if (Fixed_Less(d, _Fixed(0))) begin            
                            FinalETA = eta;
                            NextState <= State_Done; 
                        end 
                        else begin
                            DivStrobe <= 1;
                            NextState <= State_Busy; 
                        end                                      
                    end
                end

                State_Busy: begin 
                    DivStrobe <= 0;
                    valid <= 0;
                    if (DivValid) begin
                        FinalETA <= ETAInv;
                        NextState <= State_Done; 
                    end                    
                end

                State_Done: begin                
                    valid <= 1;
                    out <= FinalETA;          
                    NextState <= State_Ready;              
                end

                default: begin
                    valid <= 0;  
                    NextState <= State_Ready;              
                end
            endcase
        end
    end   

    Fixed_Div_V3 ETA_INV(
        .clk(clk),
        .resetn(resetn),
		.strobe(DivStrobe),
        .a(_Fixed(1)), 
		.b(eta), 
		.valid(DivValid),
		.q(ETAInv)
        );
endmodule 
//---------------------------------------------------------------
//  Base = I * I;
//	k = Base - eta * eta * (Base - dot(N, I) * dot(N, I));
//	if (k < 0.0)
//		R = genType(0.0);       // or genDType(0.0)
//	else
//		R = eta * I - (eta * dot(N, I) + sqrt(k)) * N;
//---------------------------------------------------------------
module RefractionDir(
    input clk,    
    input resetn,  
    input strobe,  
    input FixedNorm3 n,
    input Fixed3 i,
    input Fixed eta,    
    output Fixed3 r,
    output logic valid
    );

`ifdef IMPLEMENT_REFRACTION
    logic ETAStrobe, ETAValid, SqrtKValid;
    Fixed3 N, R0, R1, R;
    Fixed Base, D, D2, ETA, ETA2, K, SqrtK, T, T2, T3, T4;
    State State, NextState = State_Ready;

    always_comb begin : blockName
        N <= FromFixedNorm3(n);
    end

    always_ff @(posedge clk, negedge resetn) begin
        if (!resetn) begin
            NextState <= State_Ready;
        end
        else begin
            State <= NextState;

            case (State)
                State_Ready: begin
                    valid <= 0;  
                    ETAStrobe <= 0;                     
                    if (strobe) begin
                        ETAStrobe <= 1;
                        NextState = State_Busy; 
                    end
                end

                State_Busy: begin
                    valid <= 0;   
                    ETAStrobe <= 0; 
                    if (SqrtKValid) begin
                       NextState = State_Done; 
                    end                    
                end

                State_Done: begin
                    if (Fixed_Less(K, _Fixed(0))) begin
                        r <= _Fixed3u(0, 0, 0);
                    end
                    else begin
                        r <= R;
                    end        
                    valid <= 1;  
                    NextState = State_Ready;                  
                end

                default: begin
                    valid <= 0;  
                    NextState <= State_Ready;              
                end
            endcase
        end        
    end

    Fixed3_Dot REFRA_I2(i, i, Base);
    Fixed3_Dot REFRA_NI(N, i, D);        
    ComputeETA REFRA_ETA(clk, resetn, ETAStrobe, D, eta, ETA, ETAValid);
    Fixed_Mul REFRA_D2(D, D, D2);
    Fixed_Mul REFRA_ETA2(ETA, ETA, ETA2);

    // compute K
    Fixed_Sub REFRA_T(Base, D2, T);
    Fixed_Mul REFRA_T2(ETA2, T, T2);
    Fixed_Sub REFRA_K(Base, T2, K);  
    Fixed_SqrtV2 REFRA_SQRTK(clk, ETAValid, K, SqrtKValid, SqrtK);    

    //compute refraction dir
    Fixed3_Mul REFRA_R0(ETA, i, R0);
    Fixed_Mul REFRA_T3(ETA, D, T3);
    Fixed_Add REFRA_T4(T3, SqrtK, T4);
    Fixed3_Mul REFRA_R1(T4, N, R1);
    Fixed3_Sub REFRA_R(R0, R1, R);
`else
    assign valid = 0;
`endif

endmodule 
//-------------------------------------------------------------------
// Prepare final output data for fragment
//-------------------------------------------------------------------    
module ShadeCombineOutput (      
    input clk,
    input strobe,    
    input ShadowOutputData input_data,
    input RGB8 color,
    output ShadeOutputData out
    );
    always_ff @(posedge clk) begin
        if (strobe) begin
            out.x <= input_data.x;
            out.y <= input_data.y;
            out.Color <= color;            
        end        
    end
endmodule
//-------------------------------------------------------------------
// Prepare reflection/refraction output data 
//-------------------------------------------------------------------    
module ShadeCombineRefOutput (      
    input clk,
    input strobe,    
    input ShadowOutputData input_data,
    input RGB8 color,
    output SurfaceInputData out
    );
    always_ff @(posedge clk) begin
        if (strobe) begin
            out.x <= input_data.x;
            out.y <= input_data.y;
            out.LastColor <= color;
            out.BounceLevel <= input_data.BounceLevel + 1;   
            out.SurfaceRay.Orig <= input_data.HitPos;                        
            out.SurfaceRay.PI <= input_data.PI;
            
            case (input_data.SurfaceType)              
                (ST_Metal): begin
                    out.SurfaceRay.MinT <= _Fixed(0);
                    out.SurfaceRay.MaxT <= _Fixed(1000);         
                    //out.SurfaceRay.PI <= input_data.PI;
                end

                (ST_Dielectric): begin
                    out.SurfaceRay.MinT <= _Fixeds(2457); // 0.15f
                    out.SurfaceRay.MaxT <= _Fixed(1000);                                                                      
                    //out.SurfaceRay.PI <= `NULL_PRIMITIVE_INDEX;
                end
            endcase         
        end
    end
endmodule
//-------------------------------------------------------------------
// Compute reflection or refraction direction
//-------------------------------------------------------------------    
module _ReflectionAndRefractionDir (      
    input clk,
    input resetn,
    input strobe,  

    input FixedNorm3 n,
    input Fixed3 i,    
    input Fixed eta,  

    output Fixed3 reflect,
    output Fixed3 refract,
    output logic valid
    );

    // Compute reflection direction
    ReflectionDir REFLECTION(
        .n(n),
        .i(i),    
        .r(reflect)
    );    

    // Compute refraction direction
    RefractionDir REFRACTION(
        .clk(clk),    
        .resetn(resetn),  
        .strobe(strobe),  
        .n(n),
        .i(i),    
        .eta(eta),    
        .r(refract),
        .valid(valid)
    );

endmodule

//-------------------------------------------------------------------
// Prepare output data for fragment. 
// Output final color of fragment or reflection/refraction data for
// recursive bounce.
//-------------------------------------------------------------------    
module _ShadeOutput (      
    input clk,

    input ShadeState state,    
    input ShadowOutputData input_data,
    input RGB8 color,

    output ShadeOutputData out,
    output SurfaceInputData ref_out
    );

    // Prepare output data for fragment 
    ShadeCombineOutput CO(      
        .clk(clk),
        .strobe(state == SS_Done),
        .input_data(input_data),
        .color(color),
        .out(out)
    );

    // Prepare output data for recursive bounce
    ShadeCombineRefOutput CRO(      
        .clk(clk),
        .strobe(state == SS_RefDone || state == SS_RefractDone),
        .input_data(input_data),
        .color(color),
        .out(ref_out)
    );
endmodule
//-------------------------------------------------------------------
// Shade stage compute the final output data of fragment or the
// relection/refraction data for recursive bounce.
//-------------------------------------------------------------------    
module Shade(   
    input clk,
    input resetn,    

    // controls...     
    input add_input,

    // inputs...
    input ShadowOutputData input_data,    
    input RenderState rs,          
    input logic output_fifo_full,

    // outputs...      
    // If the FIFO is full?
    output logic fifo_full,
    // If the output is ready?
    output logic valid,
    // Output data for fragment 
    output ShadeOutputData out,
    // If the reflection/refraction output is ready?    
    output logic ref_valid,
    // Output data for reflection/refraction
    output SurfaceInputData ref_out   
    );

    FixedNorm Diffuse;           
    Fixed Eta; 
    ShadeState State, NextState = SS_Init;
    ShadowOutputData Input, CurrentInput;

    logic Refraction_Strobe, Refraction_Valid;
    logic ColorDiv_Strobe, ColorDiv_Valid;

    RGB8 CurrentColor, FinalColor;    
    
    logic [15:0] TC[3];    
    logic [7:0] NumBounce;   
    Fixed3 ReflectionDir, RefractionDir;
    
    /*
    initial begin	        
        fifo_full <= 0;
        NextState <= SS_Init;
	end	   
    */

    always_ff @(posedge clk, negedge resetn) begin
        if (!resetn) begin
            fifo_full <= 0;
            NextState <= SS_Init;
        end
        else begin
            if (add_input) begin
                if (!fifo_full) begin                        
                    Input = input_data;
                    fifo_full = 1;                                            
                end               
            end                

            State = NextState;  
            case (State)
                (SS_Init): begin
                    valid <= 0;
                    ref_valid <= 0;
                    ColorDiv_Strobe <= 0;
                    if (fifo_full) begin                        
                        CurrentInput = Input;                  
                        fifo_full <= 0;
                        NextState <= SS_Combine;
                    end                                                            
                end                

                (SS_Combine): begin
                    NumBounce <= CurrentInput.BounceLevel + 1;
                    ColorDiv_Strobe <= 1;  
                    NextState <= SS_Surface;                                                                                
                end

                (SS_Surface): begin  
                    valid <= 0;
                    ref_valid <= 0;              
                    ColorDiv_Strobe <= 0;                 

                    if (ColorDiv_Valid) begin    
                        if (CurrentInput.BounceLevel >= rs.MaxBounceLevel) begin
                            valid <= 0;
                            ref_valid <= 0;
                            NextState <= SS_Done;     
                        end                                                  
                        else begin
                            case (CurrentInput.SurfaceType)  
                            `ifdef IMPLEMENT_REFLECTION
                                (ST_Metal): begin
                                    valid <= 0;
                                    ref_valid <= 0;                            
                                    NextState <= SS_RefDone;                   
                                end
                            `endif
                            `ifdef IMPLEMENT_REFRACTION
                                (ST_Dielectric): begin
                                    valid <= 0;
                                    ref_valid <= 0;                            
                                    Eta.Value <= 15728;
                                    Refraction_Strobe <= 1;
                                    NextState <= SS_RefractDir;
                                end
                            `endif                            
                                default : begin
                                    valid <= 0;
                                    ref_valid <= 0;
                                    NextState <= SS_Done;                               
                                end
                            endcase                 
                        end                                        
                    end
                end

                (SS_Done): begin
                    valid <= 1;
                    ref_valid <= 0;
                    NextState <= SS_Init;                                
                end

            `ifdef IMPLEMENT_REFLECTION
                (SS_RefDone): begin
                    if (!output_fifo_full) begin
                        ref_out.SurfaceRay.Dir <= ReflectionDir;
                        valid <= 0;
                        ref_valid <= 1;                        
                        NextState <= SS_Init;            
                    end                                        
                end
            `endif

            `ifdef IMPLEMENT_REFRACTION
                (SS_RefractDir): begin
                    valid <= 0;
                    ref_valid <= 0;                    
                    Refraction_Strobe <= 0;        
                    if (Refraction_Valid) begin
                        NextState <= SS_RefractDone;
                    end
                end

                (SS_RefractDone): begin                    
                    if (!output_fifo_full) begin                        
                        ref_out.SurfaceRay.Dir <= RefractionDir;
                        valid <= 0;
                        ref_valid <= 1;                        
                        NextState <= SS_Init;            
                    end                                        
                end
            `endif

                default: begin
                    valid <= 0;
                    ref_valid <= 0;
                    NextState <= SS_Init;
                end
            endcase            
        end        
    end   

    // Compute diffuse of fragment
    _FinalDiffuse DIFFUSE(        
        // Light direction
        .l(rs.Light[0].NormDir), 
        // Normal direction of fragment
        .n(CurrentInput.Normal),
        // Fragment of object or empty
        .hit(CurrentInput.SurfaceType != ST_None),
        // Fragment in shadow or not
        .shadow(CurrentInput.bShadow),   
        // Out : the diffuse value
        .o(Diffuse)
    );
    
    // Compute color of fragment
    _ComputeCurrentColor CURRENT_COLOR(
        // Surface type of fragment
        .surface(CurrentInput.SurfaceType),
        // Diffuse value of fragment
        .diffuse(Diffuse),
        // Material color of fragment
        .color(CurrentInput.Color),
        // Out : Current color = Material color * Diffuse
        .o(CurrentColor)
    );    

    // Combine the fragment color of current and last rays
    RGB8_Accu COMBINE_COLOR(
        // The result color of previous rays
        .c0(CurrentInput.LastColor),
        // The bounce level of current ray
        .a(CurrentInput.BounceLevel),
        // Fragment color of current ray
        .c1(CurrentColor),
        // Out : Combined color
        .o(TC)
    );

    // Compute the final color of fragment
    RGB8_Div_V2 FINAL_COLOR(        
		.clk(clk),
        .resetn(resetn),
		.strobe(ColorDiv_Strobe),
        // Combined color of fragment
		.a(TC), 
        // Total number of bounce
        .b(NumBounce), 
        // Out : If the result is ready
		.valid(ColorDiv_Valid),
        // Out : The final color of fragment
		.q(FinalColor)
	);    

    // Compute reflection/refraction direction
    _ReflectionAndRefractionDir REF_DIR(
        .clk(clk),    
        .resetn(resetn),  
        .strobe(Refraction_Strobe),  
        .n(CurrentInput.Normal),
        .i(CurrentInput.ViewDir),    
        .eta(Eta),    
        .reflect(ReflectionDir),
        .refract(RefractionDir),
        .valid(Refraction_Valid)
    );    

    // Prepare output data for fragment 
    _ShadeOutput SHDER_OUTPUT(
        .clk(clk),
        .state(NextState),    
        .input_data(CurrentInput),
        .color(FinalColor),
        .out(out),
        .ref_out(ref_out)
    );
    
endmodule