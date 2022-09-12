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
// Do BVH traversal and find the primitives which may have possible hit.
// Then use Ray unit to find the closest hit.
// Finally get the hiy position, normal, color, material, etc. data.
//-------------------------------------------------------------------    
module PrimitiveFIFO (    
    input clk,
    input resetn,  

    input reset,  

    input push,
    input PrimitiveType prim_type,
    input logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start_prim[2],    
    input logic [`BVH_PRIMITIVE_AMOUNT_WIDTH-1:0] num_prim[2],       

    output DebugData debug_data,    

    input pop,        
    output PrimitiveQueryData primitive_query,
    output logic empty
    );       
    
    // Store the primitive groups data. Each group present a range of primitives
    // which may have possible hit.
    PrimitiveGroupFIFO PrimitiveFIFO;	
    PrimitiveType CurrentPrimitiveType;
	logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] StartPrimitiveIndex, EndPrimitiveIndex, RealEndPrimitiveIndex, AlignedNumPrimitives;            
    
    assign primitive_query.PrimType = CurrentPrimitiveType;
    assign primitive_query.StartIndex = StartPrimitiveIndex;
    assign primitive_query.EndIndex = EndPrimitiveIndex;
    assign empty = ((PrimitiveFIFO.Top == PrimitiveFIFO.Bottom) && (StartPrimitiveIndex >= EndPrimitiveIndex));

    //assign debug_data.Number[0] = EndPrimitiveIndex;
    //assign debug_data.Number[1] = StartPrimitiveIndex;
    //assign debug_data.LED[1] = !empty;
    //assign debug_data.LED[2] = reset;    
    //assign debug_data.LED[3] = push;
    //assign debug_data.LED[4] = pop;


    //-------------------------------------------------------------------
    //
    //-------------------------------------------------------------------    
    function void QueueGlobalPrimitives();
        /*
        PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].PrimType = PT_Sphere;
        PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].StartPrimitive = 0;
        PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].NumPrimitives = 1;		    
        PrimitiveFIFO.Bottom = PrimitiveFIFO.Bottom + 1;
        */
        
        PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].PrimType = PT_AABB;
        PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].StartPrimitive = `BVH_GLOBAL_PRIMITIVE_START_IDX;
        PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].NumPrimitives = 3;		    
        PrimitiveFIFO.Bottom = PrimitiveFIFO.Bottom + 1;
    endfunction        
    //-------------------------------------------------------------------
    //
    //-------------------------------------------------------------------    
    function void QueuePrimitiveGroup;	
        for (int i = 0; i < 2; i = i + 1) begin
            if (num_prim[i] > 0) begin
                PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].PrimType = prim_type;
                PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].StartPrimitive = start_prim[i];
                PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].NumPrimitives = num_prim[i];		    
                PrimitiveFIFO.Bottom = PrimitiveFIFO.Bottom + 1;
            end            
        end                        
	endfunction
    //-------------------------------------------------------------------
    //
    //-------------------------------------------------------------------    
	function void DequeuePrimitiveGroup;		
        CurrentPrimitiveType = PrimitiveFIFO.Groups[PrimitiveFIFO.Top].PrimType; 
		StartPrimitiveIndex = PrimitiveFIFO.Groups[PrimitiveFIFO.Top].StartPrimitive;                
        AlignedNumPrimitives = PrimitiveFIFO.Groups[PrimitiveFIFO.Top].NumPrimitives;
        RealEndPrimitiveIndex = StartPrimitiveIndex + AlignedNumPrimitives;

        if (`AABB_TEST_UNIT_SIZE_WIDTH >= 1) begin
            if (AlignedNumPrimitives[`AABB_TEST_UNIT_SIZE_WIDTH-1:0] != 0) begin
                AlignedNumPrimitives = (((AlignedNumPrimitives >> `AABB_TEST_UNIT_SIZE_WIDTH) + 1) << `AABB_TEST_UNIT_SIZE_WIDTH);
            end
        end

		EndPrimitiveIndex = StartPrimitiveIndex + AlignedNumPrimitives;        
		PrimitiveFIFO.Top = PrimitiveFIFO.Top + 1;        
	endfunction    
    //-------------------------------------------------------------------
    //
    //-------------------------------------------------------------------    
	function void NextPrimitiveData;
        StartPrimitiveIndex = StartPrimitiveIndex + `AABB_TEST_UNIT_SIZE;       
	endfunction    
    //-------------------------------------------------------------------
    //
    //-------------------------------------------------------------------       
    
    always_ff @(posedge clk, negedge resetn) begin
        if (!resetn) begin
            StartPrimitiveIndex = 0;
            EndPrimitiveIndex = 0;                             
            RealEndPrimitiveIndex = 0;         

            PrimitiveFIFO.Top = 0;			
            PrimitiveFIFO.Bottom = 0;	
        end
        else begin                          
            if (reset) begin                
                StartPrimitiveIndex = 0;
                EndPrimitiveIndex = 0;                             
                RealEndPrimitiveIndex = 0;         

                PrimitiveFIFO.Top = 0;			
                PrimitiveFIFO.Bottom = 0;			                        
                QueueGlobalPrimitives();
            end
            else begin
                if (push) begin
                    QueuePrimitiveGroup();
                end

                if (pop) begin
                    // If there are no primitives need to be processed
                    if (StartPrimitiveIndex >= EndPrimitiveIndex) begin	                        		                             
                        if (PrimitiveFIFO.Top != PrimitiveFIFO.Bottom) begin
                            // Dequeue possible hit primitives for closest hit test.
                            DequeuePrimitiveGroup();                                    
                        end                          
                    end
                    else begin
                        NextPrimitiveData();                                                                                
                    end            
                end            
            end
        end        
    end         
endmodule
