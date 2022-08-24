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
`include "../Math/Fixed.sv"
`include "../Math/Fixed3.sv"
`include "../Math/FixedNorm.sv"
`include "../Math/FixedNorm3.sv"

//-------------------------------------------------------------------
// 
//-------------------------------------------------------------------    
module LightingDiffuse(
    input FixedNorm3 l,
    input FixedNorm3 n,
    input logic shadow,
    output FixedNorm o
    );

    logic Neg;
    FixedNorm D;  

    FixedNorm3_Dot A0(l, n, D);
    FixedNorm_Less A1(D, FixedNormZero(), Neg);

    assign o = (shadow || Neg) ? FixedNormZero() : D;

endmodule
//-------------------------------------------------------------------
// 
//-------------------------------------------------------------------    
module FinalDiffuse(
    input FixedNorm3 l,
    input FixedNorm3 n,
    input logic hit,
    input logic shadow,
    input SurfaceType surface,
    output FixedNorm o
    );

    FixedNorm Ambient;
    FixedNorm D, Diffuse;
    logic Over;

    initial begin
        Ambient.Value <= `FIXED_NORM_WIDTH'd4915; 
    end

    LightingDiffuse A0(l, n, shadow, D);
    FixedNorm_Add A1(D, Ambient, Diffuse);
    FixedNorm_Greater A2(Diffuse, FixedNormOne(), Over);

    assign o = (Over || !hit) ? FixedNormOne() : Diffuse;

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
    input logic `VOXEL_INDEX vi,
    output RGB8 out
    );
    logic [27:0] PX, PZ;

    always_ff @(posedge clk) begin    
        if (strobe) begin
            out <= color;        
            if (hit && vi == `BVH_MODEL_RAW_DATA_SIZE) begin
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
module ComputeCurrentColor(    
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
// 
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
// 
//-------------------------------------------------------------------    
module ReflectionDir(
    input FixedNorm3 n,
    input Fixed3 i,    
    output Fixed3 r
    );

    Fixed3 TN, NV;
    Fixed D, D2;

    always_comb begin
        TN <= FromFixedNorm3(n);
    end

    Fixed3_Dot A0(TN, i, D);
    Fixed_LSft A1(D, 6'd1, D2);
    Fixed3_Mul A2(D2, TN, NV);  
    Fixed3_Sub A3(i, NV, r);
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
                        if (Fixed_Less(d, FixedZero())) begin            
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
        .a(FixedOne()), 
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
                    if (Fixed_Less(K, FixedZero())) begin
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
endmodule 
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module ShaderCombineOutput (      
    input clk,
    input strobe,    
    input ShadowingOutputData input_data,
    input RGB8 color,
    output ShaderOutputData out
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
//
//-------------------------------------------------------------------    
module ShaderCombineRefOutput (      
    input clk,
    input strobe,    
    input ShadowingOutputData input_data,
    input RGB8 color,
    output RasterInputData out
    );
    always_ff @(posedge clk) begin
        if (strobe) begin
            out.x <= input_data.x;
            out.y <= input_data.y;
            out.LastColor <= color;
            out.BounceLevel <= input_data.BounceLevel + 1;   
            out.RasterRay.Orig <= input_data.HitPos;                        
            out.RasterRay.VI <= input_data.VI;
            
            case (input_data.SurfaceType)              
                (ST_Metal): begin
                    out.RasterRay.MinT <= _Fixed(0);
                    out.RasterRay.MaxT <= _Fixed(1000);         
                    //out.RasterRay.VI <= input_data.VI;
                end

                (ST_Dielectric): begin
                    out.RasterRay.MinT <= _Fixeds(2457); // 0.15f
                    out.RasterRay.MaxT <= _Fixed(1000);                                                                      
                    //out.RasterRay.VI <= `NULL_VOXEL_INDEX;
                end
            endcase         
        end
    end
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module Shader(   
    input clk,
    input resetn,    

    // controls...     
    input add_input,

    // inputs...
    input ShadowingOutputData input_data,    
    input RenderState rs,          
    input logic output_fifo_full,

    // outputs...      
    output logic fifo_full,
    output logic valid,
    output ShaderOutputData out,    
    output logic ref_valid,
    output RasterInputData ref_out   
    );

    FixedNorm Diffuse;           
    Fixed Eta; 
    ShaderState State, NextState = SS_Init;
    ShadowingOutputData Input, CurrentInput;

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
                        if (CurrentInput.BounceLevel >= rs.MaxBounceLevel ||
                            CurrentInput.SurfaceType == ST_None || CurrentInput.SurfaceType == ST_Lambertian) begin
                            valid <= 0;
                            ref_valid <= 0;
                            NextState <= SS_Done;                               
                        end
                        else begin                                                                        
                            valid <= 0;
                            ref_valid <= 0;                            
                            if (CurrentInput.SurfaceType == ST_Metal) begin
                                NextState <= SS_RefDone;                   
                            end
                            else begin
                                Eta.Value <= 15728;
                                Refraction_Strobe <= 1;
                                NextState <= SS_RefractDir;                    
                            end                                         
                        end                           
                    end
                end

                (SS_Done): begin
                    valid <= 1;
                    ref_valid <= 0;
                    NextState <= SS_Init;                                
                end

                (SS_RefDone): begin
                    if (!output_fifo_full) begin
                        ref_out.RasterRay.Dir <= ReflectionDir;
                        valid <= 0;
                        ref_valid <= 1;                        
                        NextState <= SS_Init;            
                    end                                        
                end

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
                        ref_out.RasterRay.Dir <= RefractionDir;
                        valid <= 0;
                        ref_valid <= 1;                        
                        NextState <= SS_Init;            
                    end                                        
                end

                default: begin
                    valid <= 0;
                    ref_valid <= 0;
                    NextState <= SS_Init;
                end
            endcase            
        end        
    end   

    FinalDiffuse DIFFUSE(
        .l(rs.Light[0].NormDir),
        .n(CurrentInput.Normal),
        .hit(CurrentInput.SurfaceType != ST_None),
        .shadow(CurrentInput.bShadow),
        .o(Diffuse)
    );

    // Compute the accumulated color for SS_Combine state 
    /*
    Fixed_RGB8_Mul CURRENT_COLOR(
        .a(Diffuse),
        .b(CurrentInput.Color),
        .o(CurrentColor)
    );
    */

    ComputeCurrentColor CURRENT_COLOR(
        .surface(CurrentInput.SurfaceType),
        .diffuse(Diffuse),
        .color(CurrentInput.Color),
        .o(CurrentColor)
    );    

    RGB8_Accu COMBINE_COLOR(
        .c0(CurrentInput.LastColor),
        .a(CurrentInput.BounceLevel),
        .c1(CurrentColor),
        .o(TC)
    );

    RGB8_Div_V2 FINAL_COLOR(        
		.clk(clk),
        .resetn(resetn),
		.strobe(ColorDiv_Strobe),
		.a(TC), 
        .b(NumBounce), 
		.valid(ColorDiv_Valid),
		.q(FinalColor)
	);    

    ReflectionDir REFLECTION(
        .n(CurrentInput.Normal),
        .i(CurrentInput.ViewDir),    
        .r(ReflectionDir)
    );
    
    RefractionDir REFRACTION(
        .clk(clk),    
        .resetn(resetn),  
        .strobe(Refraction_Strobe),  
        .n(CurrentInput.Normal),
        .i(CurrentInput.ViewDir),    
        .eta(Eta),    
        .r(RefractionDir),
        .valid(Refraction_Valid)
    );
    
    ShaderCombineOutput CO(      
        .clk(clk),
        .strobe(NextState == SS_Done),
        .input_data(CurrentInput),
        .color(FinalColor),
        .out(out)
    );

    ShaderCombineRefOutput CRO(      
        .clk(clk),
        .strobe(NextState == SS_RefDone || NextState == SS_RefractDone),
        .input_data(CurrentInput),
        .color(FinalColor),
        .out(ref_out)
    );
    
endmodule