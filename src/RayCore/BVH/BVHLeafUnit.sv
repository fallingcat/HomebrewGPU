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
module BVHLeafUnit (   
    input logic [`BVH_NODE_INDEX_WIDTH-1:0] index,     
    input Fixed3 offset,
    output BVH_Leaf leaf
    );
    logic [`BVH_NODE_INDEX_WIDTH-1:0] LeafIndex;
    logic [231:0] LeafRawData[`BVH_LEAF_RAW_DATA_SIZE];
    AABB Aabb;

    initial begin	
        $readmemh("E:/MyWork/HomebrewGPU/Prototype/HomebrewGPU/data/chr_sword.vox.bvh.leaves.txt", LeafRawData);	
        //$readmemh(`BVH_LEAVES_PATH, LeafRawData);	        
	end		

    always_comb begin
        if (index[`BVH_NODE_INDEX_WIDTH-1] == 0) begin                    
            leaf.StartPrimitive <= 0;
            leaf.NumPrimitives <= 0;	
        end
        else begin                                    
            LeafIndex = ~index;                

            `ifdef BVH_LEAF_AABB_TEST    
                Aabb.Min.Dim[0].Value <= LeafRawData[LeafIndex][231:200];
                Aabb.Min.Dim[1].Value <= LeafRawData[LeafIndex][199:168];
                Aabb.Min.Dim[2].Value <= LeafRawData[LeafIndex][167:136];
                Aabb.Max.Dim[0].Value <= LeafRawData[LeafIndex][135:104];
                Aabb.Max.Dim[1].Value <= LeafRawData[LeafIndex][103:72];
                Aabb.Max.Dim[2].Value <= LeafRawData[LeafIndex][71:40];            
            `endif

            leaf.StartPrimitive <= LeafRawData[LeafIndex][39:8];
            leaf.NumPrimitives <= LeafRawData[LeafIndex][7:0];	
        end        
    end

    `ifdef BVH_LEAF_AABB_TEST    
        OffsetAABB OFFSET_AABB(
            .offset(offset),
            .aabb(Aabb),
            .out_aabb(leaf.Aabb)
        );    
    `endif
endmodule
