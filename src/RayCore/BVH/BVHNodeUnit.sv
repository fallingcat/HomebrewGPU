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
module BVHNodeUnit (   
    //input logic [`BVH_NODE_INDEX_WIDTH-1:0] index, 
    input logic [223:0] node_raw,
    input Fixed3 offset,    
    output BVH_Node node,
    output BVH_Leaf leaf[2]    
    );
    AABB Aabb;
    //logic [223:0] NodeRawData[`BVH_NODE_RAW_DATA_SIZE];    

    initial begin	
        //$readmemh("E:/MyWork/HomebrewGPU/Prototype/HomebrewGPU/data/chr_sword.vox.bvh.nodes.txt", NodeRawData);        
        //$readmemh(`BVH_NODES_PATH, NodeRawData);                
	end		
    
    always_comb begin
        /*
        Aabb.Min.Dim[0].Value <= NodeRawData[index][223:192];
		Aabb.Min.Dim[1].Value <= NodeRawData[index][191:160];
		Aabb.Min.Dim[2].Value <= NodeRawData[index][159:128];
        Aabb.Max.Dim[0].Value <= NodeRawData[index][127:96];
		Aabb.Max.Dim[1].Value <= NodeRawData[index][95:64];
		Aabb.Max.Dim[2].Value <= NodeRawData[index][63:32];

        node.Nodes[0] <= NodeRawData[index][31:16];
        node.Nodes[1] <= NodeRawData[index][15:0];		        
        */

        Aabb.Min.Dim[0].Value <= node_raw[223:192];
		Aabb.Min.Dim[1].Value <= node_raw[191:160];
		Aabb.Min.Dim[2].Value <= node_raw[159:128];
        Aabb.Max.Dim[0].Value <= node_raw[127:96];
		Aabb.Max.Dim[1].Value <= node_raw[95:64];
		Aabb.Max.Dim[2].Value <= node_raw[63:32];

        node.Nodes[0] <= node_raw[31:16];
        node.Nodes[1] <= node_raw[15:0];		        
    end

    OffsetAABB OFFSET_AABB(
        .offset(offset),
        .aabb(Aabb),
        .out_aabb(node.Aabb)
    );

    BVHLeafUnit LEAF0(
        .index(node.Nodes[0]),
        .offset(offset),
        .leaf(leaf[0])
    );

    BVHLeafUnit LEAF1(
        .index(node.Nodes[1]),
        .offset(offset),
        .leaf(leaf[1])
    );
endmodule