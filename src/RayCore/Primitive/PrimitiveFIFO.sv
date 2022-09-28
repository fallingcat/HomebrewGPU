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
    input logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start_prim[2],    
    input logic [`BVH_PRIMITIVE_AMOUNT_WIDTH-1:0] num_prim[2],       

    output DebugData debug_data,    

    input pop,        
    output PrimitiveQueryData primitive_query,
    output logic empty
    );       
    
    PrimitiveFIFOState State, NextState = PFS_Done;
    // Store the primitive groups data. Each group present a range of primitives
    // which may have possible hit.
    PrimitiveGroupFIFO PrimitiveFIFO;	
    PrimitiveType CurrentPrimitiveType;
	logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] StartPrimitiveIndex, EndPrimitiveIndex, RealEndPrimitiveIndex, AlignedNumPrimitives;            
    
    assign primitive_query.StartIndex = StartPrimitiveIndex;
    assign primitive_query.EndIndex = EndPrimitiveIndex;
    //assign empty = ((PrimitiveFIFO.Top == PrimitiveFIFO.Bottom) && (StartPrimitiveIndex >= EndPrimitiveIndex));

    //assign debug_data.Number[0] = EndPrimitiveIndex;
    assign debug_data.Number[1] = StartPrimitiveIndex;

    assign debug_data.LED[0] = !empty;
    assign debug_data.LED[1] = reset;    
    assign debug_data.LED[2] = (State == PFS_Working);
    //assign debug_data.LED[4] = pop;


    //-------------------------------------------------------------------
    //
    //-------------------------------------------------------------------    
    function void _QueueGlobalPrimitives();
        /*
        PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].PrimType = PT_Sphere;
        PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].StartPrimitive = 0;
        PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].NumPrimitives = 1;		    
        PrimitiveFIFO.Bottom = PrimitiveFIFO.Bottom + 1;
        */
        
        PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].StartPrimitive = `BVH_GLOBAL_PRIMITIVE_START_IDX;
        PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].NumPrimitives = 3;		    
        PrimitiveFIFO.Bottom = PrimitiveFIFO.Bottom + 1;
    endfunction        
    //-------------------------------------------------------------------
    //
    //-------------------------------------------------------------------    
    function void _QueuePrimitiveGroup;	
        for (int i = 0; i < 2; i = i + 1) begin
            if (num_prim[i] > 0) begin
                PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].StartPrimitive = start_prim[i];
                PrimitiveFIFO.Groups[PrimitiveFIFO.Bottom].NumPrimitives = num_prim[i];		    
                PrimitiveFIFO.Bottom = PrimitiveFIFO.Bottom + 1;
            end            
        end                        
	endfunction
    //-------------------------------------------------------------------
    //
    //-------------------------------------------------------------------    
	function void _DequeuePrimitiveGroup;		
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
	function void _NextPrimitiveData;
        StartPrimitiveIndex = StartPrimitiveIndex + `AABB_TEST_UNIT_SIZE;       
	endfunction    
    
    initial begin
        PrimitiveFIFO.Top = 0;
        PrimitiveFIFO.Bottom = 0;
        _QueueGlobalPrimitives();
    end

    always_ff @(posedge clk, negedge resetn) begin
        if (!resetn) begin
            StartPrimitiveIndex <= 0;
            EndPrimitiveIndex <= 0;                             
            RealEndPrimitiveIndex <= 0;         

            PrimitiveFIFO.Top <= 0;			
            PrimitiveFIFO.Bottom <= 0;	

            NextState = PFS_Done;

            empty <= 0;
        end
        else begin      
            if (reset) begin   
                StartPrimitiveIndex = 0;
                EndPrimitiveIndex = 0;         
                RealEndPrimitiveIndex = 0;         

                PrimitiveFIFO.Top = 0;			
                PrimitiveFIFO.Bottom = 0;

                _QueueGlobalPrimitives();                        
                NextState = PFS_Working;
            end     

            if (push) begin
                _QueuePrimitiveGroup();
            end            

            State = NextState;
            case (State)
                (PFS_Init): begin
                    empty <= 0;                                    
                    NextState <= PFS_Working;                    
                end

                (PFS_Working): begin
                    empty <= 0;
                    
                    if (pop) begin
                        // If there are no primitives need to be processed
                        if (StartPrimitiveIndex >= EndPrimitiveIndex) begin	                        		                             
                            if (PrimitiveFIFO.Top != PrimitiveFIFO.Bottom) begin
                                // Dequeue possible hit primitives for closest hit test.
                                _DequeuePrimitiveGroup();                                    
                            end
                            else begin
                                empty <= 1;

                                StartPrimitiveIndex = 0;
                                EndPrimitiveIndex = 0;                             
                                RealEndPrimitiveIndex = 0;         

                                NextState <= PFS_Done;
                            end                          
                        end
                        else begin
                            _NextPrimitiveData();                                                                                
                        end                           
                    end
                end

                (PFS_Done): begin
                    empty <= 1;                    

                    StartPrimitiveIndex = 0;
                    EndPrimitiveIndex = 0;                             
                    RealEndPrimitiveIndex = 0;        

                    PrimitiveFIFO.Top = 0;			
                    PrimitiveFIFO.Bottom = 0;			                                                                  
                end
            endcase          
        end        
    end         
endmodule
