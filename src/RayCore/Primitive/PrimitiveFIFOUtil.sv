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
`ifndef PRIMITIVE_FIO_UTIL
`define PRIMITIVE_FIO_UTIL

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function void PrimitiveFIFO_QueueGlobalPrimitives(
    inout PrimitiveGroupFIFO aabb_fifo,
    inout PrimitiveGroupFIFO sphere_fifo
    );
    aabb_fifo.Groups[0].StartPrimitive <= `BVH_GLOBAL_PRIMITIVE_START_IDX;
    aabb_fifo.Groups[0].NumPrimitives <= 3;		    
    aabb_fifo.Top <= 0;
    aabb_fifo.Bottom <= 1;

    sphere_fifo.Groups[0].StartPrimitive <= 0;
    sphere_fifo.Groups[0].NumPrimitives <= 1;		    
    sphere_fifo.Top <= 0;   
    sphere_fifo.Bottom <= 1;   
endfunction    
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function void PrimitiveFIFO_Reset(
    inout PrimitiveGroupFIFO aabb_fifo,
    inout PrimitiveGroupFIFO sphere_fifo
    );    
    aabb_fifo.Top <= 0;
    aabb_fifo.Bottom <= 1;
    aabb_fifo.StartPrimitiveIndex <= 0;
    aabb_fifo.EndPrimitiveIndex <= 0;

    sphere_fifo.Top <= 0;
    sphere_fifo.Bottom <= 1;
    sphere_fifo.StartPrimitiveIndex <= 0;
    sphere_fifo.EndPrimitiveIndex <= 0;
endfunction    
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function void PrimitiveFIFO_QueuePrimitiveGroup(
    input valid,    
    input  [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start[2],
    input  [`BVH_PRIMITIVE_AMOUNT_WIDTH-1:0] num[2],
    inout PrimitiveGroupFIFO fifo
    );
    if (valid) begin
        for (int i = 0; i < 2; i = i + 1) begin
            if (num[i] > 0) begin
                fifo.Groups[fifo.Bottom].StartPrimitive = start[i];
                fifo.Groups[fifo.Bottom].NumPrimitives = num[i];		    
                fifo.Bottom = fifo.Bottom + 1;                
            end
        end                        
    end
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------   
function void _PrimitiveFIFO_Fetch(
    output logic empty,
    input [4:0] fetch_step,
    inout PrimitiveGroupFIFO fifo    
    );
    if (fifo.StartPrimitiveIndex >= fifo.EndPrimitiveIndex) begin	                        		                             
        if (fifo.Top != fifo.Bottom) begin
            // Dequeue next primitive group
            empty = 0;            
            fifo.StartPrimitiveIndex = fifo.Groups[fifo.Top].StartPrimitive;                    
            fifo.EndPrimitiveIndex = fifo.StartPrimitiveIndex + fifo.Groups[fifo.Top].NumPrimitives;      
            fifo.Top = fifo.Top + 1;        
        end
        else begin
            // All possible hit primitives are processed, FIFO is empty.
            empty = 1;
        end               
    end
    // If there still are primitives in FIFO, fetch next primitives.
    else begin                        
        empty = 0;        
        fifo.StartPrimitiveIndex = fifo.StartPrimitiveIndex + fetch_step;       
    end    
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------   
function void PrimitiveFIFO_Fetch(
    output logic empty,
    inout PrimitiveGroupFIFO aabb_fifo,
    inout PrimitiveGroupFIFO sphere_fifo
    );
    logic Empty[2];

    _PrimitiveFIFO_Fetch(Empty[0], `AABB_TEST_UNIT_SIZE, aabb_fifo);
    _PrimitiveFIFO_Fetch(Empty[1], `SPHERE_TEST_UNIT_SIZE, sphere_fifo);

    empty = Empty[0] && Empty[1];
endfunction

`endif