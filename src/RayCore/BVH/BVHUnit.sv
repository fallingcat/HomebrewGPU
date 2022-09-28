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
//
//-------------------------------------------------------------------    
module ProcessBVHChildLeaf (   
    input visible,    
    input BVH_Leaf leaf,    
    // outputs...
    output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start_prim,    
    output logic [`BVH_PRIMITIVE_AMOUNT_WIDTH-1:0] num_prim    
    );

    always_comb begin
        if (visible) begin
            start_prim <= leaf.StartPrimitive;
            num_prim <= leaf.NumPrimitives;                                                                            
        end      
        else begin
            start_prim <= 0;
            num_prim <= 0;
        end
    end
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module ProcessNode (   
    input visible,
    input BVH_Node node,    
    output logic [`BVH_NODE_INDEX_WIDTH-1:0] nodes[2]        
    );

    always_comb begin
        if (visible) begin            
           if (node.Nodes[0][`BVH_NODE_INDEX_WIDTH-1] == 0) begin
               nodes[0] <= node.Nodes[0];
           end
           else begin
               nodes[0] <= {`BVH_NODE_INDEX_WIDTH{1'b1}};
           end
           if (node.Nodes[1][`BVH_NODE_INDEX_WIDTH-1] == 0) begin
               nodes[1] <= node.Nodes[1];
           end
           else begin
               nodes[1] <= {`BVH_NODE_INDEX_WIDTH{1'b1}};
           end
        end
        else begin
            nodes[0] <= {`BVH_NODE_INDEX_WIDTH{1'b1}};
            nodes[1] <= {`BVH_NODE_INDEX_WIDTH{1'b1}};
        end
    end
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module ProcessNodeLeaf (   
    input visible,
    input BVH_Leaf leaf[2],        
    output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start_prim[2],    
    output logic [`BVH_PRIMITIVE_AMOUNT_WIDTH-1:0] num_prim[2]    
    );
    
    ProcessBVHChildLeaf CHILD0(
        .visible(visible),
        .leaf(leaf[0]),    
        // outputs...
        .start_prim(start_prim[0]),    
        .num_prim(num_prim[0])    
    );      

    ProcessBVHChildLeaf CHILD1(
        .visible(visible),
        .leaf(leaf[1]),    
        // outputs...
        .start_prim(start_prim[1]),    
        .num_prim(num_prim[1])    
    );             
endmodule

//-------------------------------------------------------------------
// BVH traversal unit.
// Output the leaf primitive data when find visible leaf.
// Output 0 primitives when there is no visible leaf.
//-------------------------------------------------------------------    
module DebugBVHUnit (    
    input clk,	    
    input resetn, 

    // controls...   
    input strobe,    
    input restart_strobe,

    // inputs...    
    input Fixed3 offset,
    input Ray r,
    //input logic [223:0] node_raw,    
    input BVH_Node node,    
    input BVH_Leaf leaf[2],    

    // outputs...
    output logic valid,
    output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start_prim[2],    
    output logic [`BVH_PRIMITIVE_AMOUNT_WIDTH-1:0] num_prim[2],    
    output logic finished,
    output logic [`BVH_NODE_INDEX_WIDTH-1:0] node_index
    );

    BVHUnitState State, NextState = BUS_Init;   

    logic [`BVH_NODE_INDEX_WIDTH-1:0] NodeStack[`BVH_NODE_STACK_SIZE];
    logic [`BVH_NODE_STACK_SIZE_WIDTH:0] NodeStackBottom;
    logic [`BVH_NODE_INDEX_WIDTH-1:0] CurrentNodeIndex;    
    
    logic NodeVisible;        
    logic ChildNodeVisible[2];   
    logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] StartIndex, NextStart = 0;
    logic [`BVH_PRIMITIVE_AMOUNT_WIDTH-1:0] NumPrim;
    
    assign node_index       = CurrentNodeIndex;
    assign start_prim[0]    = StartIndex;
    assign num_prim[0]      = NumPrim;
    assign start_prim[1]    = 0;    
    assign num_prim[1]      = 0;

    always @(posedge clk, negedge resetn) begin
        if (!resetn) begin
            NextState <= BUS_Init;
        end
        else begin
            if (restart_strobe) begin
                NextState <= BUS_Init;                    
            end                                

            State = NextState;

            case (State)
                (BUS_Init): begin        
                    StartIndex = 0;
                    NextStart = 0;
                    NumPrim = 0;                    
                    valid <= 0;
                    finished <= 1;                
                    if (strobe) begin 
                        finished <= 0;
                        NextState <= BUS_GetNode;                                    
                    end
                end       

                (BUS_GetNode) : begin      
                    StartIndex = NextStart;    
                    if (StartIndex >=`BVH_MODEL_RAW_DATA_SIZE) begin
                        finished <= 1;         
                        valid <= 0;               
                        NextState <= BUS_Done;                                    
                    end
                    else begin
                        NumPrim = StartIndex + 6;
                        if ((StartIndex + NumPrim) >= `BVH_MODEL_RAW_DATA_SIZE) begin
                            NumPrim = `BVH_MODEL_RAW_DATA_SIZE - StartIndex;
                        end
                        NextStart = StartIndex + 6;                                            
                        finished <= 0; 
                        valid <= 1;
                    end                   
                end        
                
                (BUS_Done): begin      
                    StartIndex = 0;
                    NextStart = 0;
                    NumPrim = 0;

                    finished <= 1;
                    valid <= 0;
                end

                default: begin
                    NextState <= BUS_Init;
                end                        
            endcase       
        end                
    end       	                            
endmodule

//-------------------------------------------------------------------
// BVH traversal unit.
// Output the leaf primitive data when find visible leaf.
// Output 0 primitives when there is no visible leaf.
//-------------------------------------------------------------------    
module BVHUnit (    
    input clk,	    
    input resetn, 

    // controls...   
    input strobe,    
    input restart_strobe,

    // inputs...    
    input Fixed3 offset,
    input Ray r,
    //input logic [223:0] node_raw,    
    input BVH_Node node,    
    input BVH_Leaf leaf[2],    

    // outputs...
    output logic valid,
    output logic [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] start_prim[2],    
    output logic [`BVH_PRIMITIVE_AMOUNT_WIDTH-1:0] num_prim[2],    
    output logic finished,
    output logic [`BVH_NODE_INDEX_WIDTH-1:0] node_index
    );

    BVHUnitState State, NextState = BUS_Init;   

    logic [`BVH_NODE_INDEX_WIDTH-1:0] NodeStack[`BVH_NODE_STACK_SIZE];
    logic [`BVH_NODE_STACK_SIZE_WIDTH:0] NodeStackBottom;
    logic [`BVH_NODE_INDEX_WIDTH-1:0] CurrentNodeIndex;    
    
    logic NodeVisible;        
    logic ChildNodeVisible[2];   
    
    assign node_index = CurrentNodeIndex;

`ifdef IMPLEMENT_BVH_TRAVERSAL
    //-------------------------------------------------------------------
    //
    //-------------------------------------------------------------------    
    function PushNode(		        
		input [`BVH_NODE_INDEX_WIDTH-1:0] i
		);
        NodeStack[NodeStackBottom] = i;
        NodeStackBottom = NodeStackBottom + 1;
	endfunction
    
    //-------------------------------------------------------------------
    //
    //-------------------------------------------------------------------    
    function PopNode;        
        NodeStackBottom = NodeStackBottom - 1;
        CurrentNodeIndex = NodeStack[NodeStackBottom];        
	endfunction    

    //-------------------------------------------------------------------
    //
    //-------------------------------------------------------------------        
    always @(posedge clk, negedge resetn) begin
        if (!resetn) begin
            NextState <= BUS_Init;
        end
        else begin
            if (restart_strobe) begin
                NextState <= BUS_Init;                    
            end                                

            State = NextState;

            case (State)
                (BUS_Init): begin        
                    start_prim[0] <= `BVH_NULL_PRIMITIVE_INDEX;
                    num_prim[0] <= 0;
                    start_prim[1] <= `BVH_NULL_PRIMITIVE_INDEX;                    
                    num_prim[1] <= 0;
                    valid <= 0;
                    finished <= 1;                
                    if (strobe) begin 
                        finished <= 0;
                        NodeStackBottom <= 0;                                         
                        CurrentNodeIndex <= 0;                                                
                        NextState <= BUS_ProcessNode;                                    
                    end
                end               
                
                (BUS_GetNode) : begin
                    //start_prim[0] <= `BVH_NULL_PRIMITIVE_INDEX;
                    //num_prim[0] <= 0;
                    //start_prim[1] <= `BVH_NULL_PRIMITIVE_INDEX;                    
                    //num_prim[1] <= 0; 
                    valid <= 0;
                    finished <= 0; 

                    if (restart_strobe) begin
                        finished <= 1;                        
                        NextState <= BUS_Init;                    
                    end        
                    else begin
                        if (NodeStackBottom != 0) begin                    
                            PopNode();    
                            NextState <= BUS_ProcessNode;                    
                        end
                        else begin                                      
                            finished <= 1;                  
                            NextState <= BUS_Done;
                        end                                         
                    end
                end

                (BUS_ProcessNode): begin
                `ifdef IMPLEMENT_BVH_LEAF_AABB_TEST    
                    if (NodeVisible) begin    
                        valid <= 0;                      
                        if (node.Nodes[0][`BVH_NODE_INDEX_WIDTH-1] == 0) begin
                            PushNode(node.Nodes[0]);                            
                            start_prim[0] <= `BVH_NULL_PRIMITIVE_INDEX;
                            num_prim[0] <= 0;                                      
                        end 
                        else begin
                            if (ChildNodeVisible[0]) begin                            
                                start_prim[0] <= leaf[0].StartPrimitive;
                                num_prim[0] <= leaf[0].NumPrimitives;
                                valid <= 1;
                            end
                            else begin
                                start_prim[0] <= `BVH_NULL_PRIMITIVE_INDEX;
                                num_prim[0] <= 0;                                    
                            end                            
                        end

                        if (node.Nodes[1][`BVH_NODE_INDEX_WIDTH-1] == 0) begin
                            PushNode(node.Nodes[1]);
                            start_prim[1] <= `BVH_NULL_PRIMITIVE_INDEX;
                            num_prim[1] <= 0;                                                            
                        end 
                        else begin
                            if (ChildNodeVisible[1]) begin                            
                                start_prim[1] <= leaf[1].StartPrimitive;
                                num_prim[1] <= leaf[1].NumPrimitives;                                
                                valid <= 1;
                            end
                            else begin
                                start_prim[1] <= `BVH_NULL_PRIMITIVE_INDEX;
                                num_prim[1] <= 0;                                    
                            end                            
                        end
                    end    
                    else begin
                        start_prim[0] <= `BVH_NULL_PRIMITIVE_INDEX;
                        num_prim[0] <= 0;                                                                            
                        start_prim[1] <= `BVH_NULL_PRIMITIVE_INDEX;
                        num_prim[1] <= 0;
                        valid <= 0;
                    end              
                `else
                    if (NodeVisible) begin       
                        if (node.Nodes[0][`BVH_NODE_INDEX_WIDTH-1] == 0) begin
                            PushNode(node.Nodes[0]);                            
                        end
                        if (node.Nodes[1][`BVH_NODE_INDEX_WIDTH-1] == 0) begin
                            PushNode(node.Nodes[1]);                            
                        end

                        start_prim[0] <= leaf[0].StartPrimitive;
                        num_prim[0] <= leaf[0].NumPrimitives;
                        start_prim[1] <= leaf[1].StartPrimitive;
                        num_prim[1] <= leaf[1].NumPrimitives;
                        valid <= 1;
                    end    
                    else begin
                        start_prim[0] <= `BVH_NULL_PRIMITIVE_INDEX;
                        num_prim[0] <= 0;                                                                            
                        start_prim[1] <= `BVH_NULL_PRIMITIVE_INDEX;
                        num_prim[1] <= 0;
                        valid <= 0;
                    end     
                `endif
                    NextState <= BUS_GetNode;
                end                
                
                (BUS_Done): begin      
                    start_prim[0] <= `BVH_NULL_PRIMITIVE_INDEX;
                    num_prim[0] <= 0;
                    start_prim[1] <= `BVH_NULL_PRIMITIVE_INDEX;                     
                    num_prim[1] <= 0;  
                    valid <= 0;
                    finished <= 1;                    
                end

                default: begin
                    start_prim[0] <= `BVH_NULL_PRIMITIVE_INDEX;
                    num_prim[0] <= 0;
                    start_prim[1] <= `BVH_NULL_PRIMITIVE_INDEX;                     
                    num_prim[1] <= 0;  
                    NextState <= BUS_Init;
                end                        
            endcase       
        end                
    end       	          

    AABBTest AABB_NODE_TEST(
        .r(r),        
        .aabb(node.Aabb),
        .hit(NodeVisible)
    );
    
    `ifdef IMPLEMENT_BVH_LEAF_AABB_TEST    
        AABBTest AABB_LEAF_TEST0(
            .r(r),            
            .aabb(leaf[0].Aabb),
            .hit(ChildNodeVisible[0])
        );              

        AABBTest AABB_LEAF_TEST1(
            .r(r),            
            .aabb(leaf[1].Aabb),
            .hit(ChildNodeVisible[1])
        );                    
    `endif    
`else
    always @(posedge clk, negedge resetn) begin
        if (!resetn) begin
            NextState <= BUS_Init;
        end
        else begin
            if (restart_strobe) begin
                NextState <= BUS_Init;                    
            end                                

            State = NextState;

            case (State)
                (BUS_Init): begin        
                    start_prim[0] <= 0;
                    start_prim[1] <= 0;
                    num_prim[0] <= 0;
                    num_prim[1] <= 0;
                    valid <= 0;
                    finished <= 1;                
                    if (strobe) begin 
                        finished <= 0;
                        NextState <= BUS_GetNode;                                    
                    end
                end       

                (BUS_GetNode) : begin
                    start_prim[0] <= 0;
                    start_prim[1] <= 0;
                    num_prim[0] <= 0;
                    num_prim[0] <= `BVH_MODEL_RAW_DATA_SIZE;                    
                    num_prim[1] <= 0; 
                    finished <= 0; 
                    valid <= 1;
                    NextState <= BUS_Done;                                    
                end        
                
                (BUS_Done): begin      
                    start_prim[0] <= 0;
                    start_prim[1] <= 0; 
                    num_prim[0] <= 0;
                    num_prim[1] <= 0;  
                    finished <= 1;
                    valid <= 0;                    
                end

                default: begin
                    NextState <= BUS_Init;
                end                        
            endcase       
        end                
    end       	                            
`endif

endmodule