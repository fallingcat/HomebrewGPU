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
    aabb_fifo.Groups[aabb_fifo.Bottom].PrimType = PT_AABB;
    aabb_fifo.Groups[aabb_fifo.Bottom].StartPrimitive = `BVH_GLOBAL_PRIMITIVE_START_IDX;
    aabb_fifo.Groups[aabb_fifo.Bottom].NumPrimitives = 3;		    
    aabb_fifo.Bottom = aabb_fifo.Bottom + 1;

    sphere_fifo.Groups[sphere_fifo.Bottom].PrimType = PT_Sphere;
    sphere_fifo.Groups[sphere_fifo.Bottom].StartPrimitive = 0;
    sphere_fifo.Groups[sphere_fifo.Bottom].NumPrimitives = 1;		    
    sphere_fifo.Bottom = sphere_fifo.Bottom + 1;   
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

    sphere_fifo.Top <= 0;
    sphere_fifo.Bottom <= 0;
endfunction    
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function void PrimitiveFIFO_QueuePrimitiveGroup(
    input valid,
    input PrimitiveType t,
    input  [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start[2],
    input  [`BVH_PRIMITIVE_AMOUNT_WIDTH-1:0] num[2],
    inout PrimitiveGroupFIFO fifo
    );
    if (valid) begin
        for (int i = 0; i < 2; i = i + 1) begin
            if (num[i] > 0) begin
                fifo.Groups[fifo.Bottom].PrimType = t;
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
function void _PrimitiveFIFO_AABB_DequeuePrimitiveGroup(
    inout PrimitiveGroupFIFO fifo
    );
    fifo.StartPrimitiveIndex = fifo.Groups[fifo.Top].StartPrimitive;                
    fifo.AlignedNumPrimitives = fifo.Groups[fifo.Top].NumPrimitives;
    fifo.RealEndPrimitiveIndex = fifo.StartPrimitiveIndex + fifo.AlignedNumPrimitives;

    if (`AABB_TEST_UNIT_SIZE_WIDTH >= 1) begin
        if (fifo.AlignedNumPrimitives[`AABB_TEST_UNIT_SIZE_WIDTH-1:0] != 0) begin
            fifo.AlignedNumPrimitives = (((fifo.AlignedNumPrimitives >> `AABB_TEST_UNIT_SIZE_WIDTH) + 1) << `AABB_TEST_UNIT_SIZE_WIDTH);
        end
    end

    fifo.EndPrimitiveIndex = fifo.StartPrimitiveIndex + fifo.AlignedNumPrimitives;        
    fifo.Top = fifo.Top + 1;        
endfunction    
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function void _PrimitiveFIFO_AABB_NextPrimitiveData(
    inout PrimitiveGroupFIFO fifo
    );    
    fifo.StartPrimitiveIndex = fifo.StartPrimitiveIndex + `AABB_TEST_UNIT_SIZE;       
endfunction    
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------   
function void _PrimitiveFIFO_AABB_Fetch(
    output logic empty,
    inout PrimitiveGroupFIFO fifo    
    );
    if (fifo.StartPrimitiveIndex >= fifo.EndPrimitiveIndex) begin	                        		                             
        if (fifo.Top != fifo.Bottom) begin
            // Dequeue next primitive group
            empty = 0;            
            _PrimitiveFIFO_AABB_DequeuePrimitiveGroup(fifo);
        end
        else begin
            // All possible hit primitives are processed, FIFO is empty.
            empty = 1;
        end               
    end
    // If there still are primitives in FIFO, fetch next primitives.
    else begin                        
        empty = 0;        
        _PrimitiveFIFO_AABB_NextPrimitiveData(fifo);
    end    
endfunction
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function void _PrimitiveFIFO_Sphere_DequeuePrimitiveGroup(
    inout PrimitiveGroupFIFO fifo
    );
    fifo.StartPrimitiveIndex = fifo.Groups[fifo.Top].StartPrimitive;                
    fifo.AlignedNumPrimitives = fifo.Groups[fifo.Top].NumPrimitives;
    fifo.RealEndPrimitiveIndex = fifo.StartPrimitiveIndex + fifo.AlignedNumPrimitives;

    if (`SPHERE_TEST_UNIT_SIZE_WIDTH >= 1) begin
        if (fifo.AlignedNumPrimitives[`SPHERE_TEST_UNIT_SIZE_WIDTH-1:0] != 0) begin
            fifo.AlignedNumPrimitives = (((fifo.AlignedNumPrimitives >> `SPHERE_TEST_UNIT_SIZE_WIDTH) + 1) << `SPHERE_TEST_UNIT_SIZE_WIDTH);
        end
    end

    fifo.EndPrimitiveIndex = fifo.StartPrimitiveIndex + fifo.AlignedNumPrimitives;        
    fifo.Top = fifo.Top + 1;        
endfunction    
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
function void _PrimitiveFIFO_Sphere_NextPrimitiveData(
        inout PrimitiveGroupFIFO fifo
    );    
    fifo.StartPrimitiveIndex = fifo.StartPrimitiveIndex + `SPHERE_TEST_UNIT_SIZE;       
endfunction    
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------   
function void _PrimitiveFIFO_Sphere_Fetch(
    output logic empty,
    inout PrimitiveGroupFIFO fifo    
    );
    if (fifo.StartPrimitiveIndex >= fifo.EndPrimitiveIndex) begin	                        		                             
        if (fifo.Top != fifo.Bottom) begin
            // Dequeue next primitive group
            empty = 0;            
            _PrimitiveFIFO_Sphere_DequeuePrimitiveGroup(fifo);
        end
        else begin
            // All possible hit primitives are processed, FIFO is empty.
            empty = 1;
        end               
    end
    // If there still are primitives in FIFO, fetch next primitives.
    else begin                        
        empty = 0;        
        _PrimitiveFIFO_Sphere_NextPrimitiveData(fifo);
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

    _PrimitiveFIFO_AABB_Fetch(Empty[0], aabb_fifo);
    _PrimitiveFIFO_Sphere_Fetch(Empty[1], sphere_fifo);

    empty = Empty[0] && Empty[1];
endfunction

`endif