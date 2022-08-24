`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/14 18:02:24
// Design Name: 
// Module Name: 
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
`ifndef GLOBAL_FUNCTIONS_SV
`define GLOBAL_FUNCTIONS_SV

/*
function logic IsFIFOFull #(    
    parameter WIDTH = `STAGE_FIFO_SIZE_WIDTH,
    parameter SIZE = 2**WIDTH 
    )(
        input [WIDTH-1:0] top,
        input [WIDTH-1:0] bottom
    );

    if (bottom > top) begin
        IsFIFOFull = (({1'b0, top} + SIZE - {1'b0, bottom}) == 1) ? 1 : 0; 
    end
    else begin
        IsFIFOFull = ((top - bottom) == 1) ? 1 : 0; 
    end
endfunction
*/

function NextBVHPrimitiveData;
    FetchStart = StartPrimitiveIndex;
    StartPrimitiveIndex = StartPrimitiveIndex + `BVH_AABB_TEST_UNIT_SIZE;       
endfunction

function QueuePrimitiveGroup;	
    for (int i = 0; i < 2; i = i + 1) begin
        if (LeafNumPrim[i] > 0) begin
            PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].StartPrimitive = LeafStartPrim[i];
            PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].NumPrimitives = LeafNumPrim[i];		    
            PrimitiveFIFO.Bottom = PrimitiveFIFO.Bottom + 1;
        end            
    end        
endfunction    

function DequeuePrimitiveGroup;		
    StartPrimitiveIndex = PrimitiveFIFO.Groups[PrimitiveFIFO.Top].StartPrimitive;                
    AlignedNumPrimitives = PrimitiveFIFO.Groups[PrimitiveFIFO.Top].NumPrimitives;
    RealEndPrimitiveIndex = StartPrimitiveIndex + AlignedNumPrimitives;

    if (`BVH_AABB_TEST_UNIT_SIZE_WIDTH >= 1) begin
        if (AlignedNumPrimitives[`BVH_AABB_TEST_UNIT_SIZE_WIDTH-1:0] != 0) begin
            AlignedNumPrimitives = (((AlignedNumPrimitives >> `BVH_AABB_TEST_UNIT_SIZE_WIDTH) + 1) << `BVH_AABB_TEST_UNIT_SIZE_WIDTH);
        end
    end

    EndPrimitiveIndex = StartPrimitiveIndex + AlignedNumPrimitives;        
    PrimitiveFIFO.Top = PrimitiveFIFO.Top + 1;        
endfunction    

function QueueReflectiveBoxAndGround();
    PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].StartPrimitive = `BVH_MODEL_RAW_DATA_SIZE;
    PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].NumPrimitives = 3;		    
    PrimitiveFIFO.Bottom = PrimitiveFIFO.Bottom + 1;
endfunction

`endif
