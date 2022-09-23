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
module _DecodeBVHLeafIndex (
    input clk,
    input [`BVH_NODE_INDEX_WIDTH-1:0] index,         
    output logic [`BVH_NODE_INDEX_WIDTH-1:0] leaf_index
    );

    always_comb begin
        if (index[`BVH_NODE_INDEX_WIDTH-1] == 0) begin                    
            leaf_index[`BVH_NODE_INDEX_WIDTH-1] <= 1;
        end
        else begin                                    
            leaf_index <= ~index;                
        end        
    end
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module _QueryBVHLeaf (   
    input clk,
    input [`BVH_LEAF_RAW_DATA_WIDTH-1:0] raw,
    input valid,
    input Fixed3 offset,
    output BVH_Leaf leaf
    );
    AABB Aabb;

    always_comb begin
        if (valid) begin                    
            `ifdef IMPLEMENT_BVH_LEAF_AABB_TEST    
                Aabb.Min.Dim[0].Value <= raw[231:200];
                Aabb.Min.Dim[1].Value <= raw[199:168];
                Aabb.Min.Dim[2].Value <= raw[167:136];
                Aabb.Max.Dim[0].Value <= raw[135:104];
                Aabb.Max.Dim[1].Value <= raw[103:72];
                Aabb.Max.Dim[2].Value <= raw[71:40];            
            `endif

            leaf.StartPrimitive <= raw[39:8];
            leaf.NumPrimitives <= raw[7:0];	
        end
        else begin
            leaf.StartPrimitive <= `NULL_PRIMITIVE_INDEX;
            leaf.NumPrimitives <= 0;	
        end        
    end

    `ifdef IMPLEMENT_BVH_LEAF_AABB_TEST    
        OffsetAABB OFFSET_AABB(
            .offset(offset),
            .aabb(Aabb),
            .out_aabb(leaf.Aabb)
        );    
    `endif
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module _QueryBVHNode (   
    input clk,
    input [`BVH_NODE_RAW_DATA_WIDTH-1:0] node_raw,
    input Fixed3 offset,    
    output BVH_Node node
    );
    AABB Aabb;
    
    always_comb begin
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
endmodule
//-------------------------------------------------------------------
// BVH structure module. 
// Store BVH data and resposible for primitive data query 
// from other modules.
//-------------------------------------------------------------------    
module BVHStructure (   
    input clk,	    
    input resetn, 
    // SD signals -----------------------------------------
	input sd_clk,
    output logic SD_SCK,
    inout SD_CMD,
    input [3:0] SD_DAT,	
	// Debug data -------------------------------------
    output DebugData debug_data,
    // Memory signals --------------------------------------
    output MemoryReadRequest mem_r_req,
    output MemoryWriteRequest mem_w_req,
    input MemoryReadData read_data,     
    // Controls ---------------------------------------------
    output logic init_done,    
    input BVHQueryMode mode,
    input Fixed3 offset, 
    // Query Node ---------------------------------------------
    input [`BVH_NODE_INDEX_WIDTH-1:0] node_index_0[`RAY_CORE_SIZE], 
    input [`BVH_NODE_INDEX_WIDTH-1:0] node_index_1[`RAY_CORE_SIZE], 
    output BVH_Node node_0[`RAY_CORE_SIZE],
    output BVH_Node node_1[`RAY_CORE_SIZE],
    output BVH_Leaf leaf_0[`RAY_CORE_SIZE][2],
    output BVH_Leaf leaf_1[`RAY_CORE_SIZE][2]
    // Query Primitive
    //input PrimitiveType prim_type_0,
    //input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] prim_index_0,
    //input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] prim_bound_0,    
    //input PrimitiveType prim_type_1,
    //input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] prim_index_1,    
    //input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] prim_bound_1,
    //output Primitive_AABB p0[`AABB_TEST_UNIT_SIZE],
    //output Primitive_AABB p1[`AABB_TEST_UNIT_SIZE]    
    //output Primitive_Sphere ps0[`SPHERE_TEST_UNIT_SIZE],
    //output Primitive_Sphere ps1[`SPHERE_TEST_UNIT_SIZE]    
    );

    logic SDReadDataValid;
    logic [7:0] SDReadData;

    logic [255:0] WriteData;

    logic [`BVH_NODE_RAW_DATA_WIDTH-1:0] NodeRawData[`BVH_NODE_RAW_DATA_SIZE];       
    logic [`BVH_LEAF_RAW_DATA_WIDTH-1:0] LeafRawData[`BVH_LEAF_RAW_DATA_SIZE];

    logic [6:0] ByteOffset = 28, NodeIndex = 0;        
    logic [`BVH_NODE_INDEX_WIDTH-1:0] LeafIndex[`RAY_CORE_SIZE][4];
    
    initial begin	
        $readmemh(`BVH_NODES_PATH, NodeRawData);                
        ByteOffset <= 28;
        NodeIndex <= 0;
        //NodeRawData[0] <= 0;

        $readmemh(`BVH_LEAVES_PATH, LeafRawData);	        
	end		
    
    /*
    always @(posedge sd_clk, negedge resetn) begin
        if (!resetn) begin  
            init_done <= 0;
            ByteOffset <= 28;
            NodeIndex <= 0;
            NodeRawData[0] <= 0;            
        end
        else begin                 
            if (SDReadDataValid) begin
                init_done <= 0;
                ByteOffset = ByteOffset - 1;                
                NodeRawData[NodeIndex] = NodeRawData[NodeIndex] | ({{216'b0}, SDReadData} << (ByteOffset * 8));                                              
                if (ByteOffset == 0) begin
                    WriteData = NodeRawData[NodeIndex];

                    //mem_w_req.WriteAddress = `BVH_NODE_ADDR + (NodeIndex * 256 / DQ_WIDTH) + (APP_DATA_WIDTH / DQ_WIDTH);                    
                    //mem_w_req.WriteData = Cache[CurrentCacheWriteElement.CacheSet];
                    //mem_w_req.BlockCount = 2;
                    //mem_w_req.WriteStrobe <= 1;


                    ByteOffset = 28;
                    NodeIndex = NodeIndex + 1;
                    NodeRawData[NodeIndex] = 0;                    
                end
            end
            else begin                
                init_done <= 1;
            end
        end
    end  
    */

    generate
        for (genvar c = 0; c < `RAY_CORE_SIZE; c = c + 1) begin : CORE_BVH			
            _QueryBVHNode QUERY_NODE_0(   
                .node_raw(NodeRawData[node_index_0[c]]),
                .offset(offset),                
                .node(node_0[c])    
            );
            _QueryBVHNode QUERY_NODE_1(   
                .node_raw(NodeRawData[node_index_1[c]]),
                .offset(offset),                
                .node(node_1[c])    
            );

            _DecodeBVHLeafIndex DECODER_0(
                .index(node_0[c].Nodes[0]),         
                .leaf_index(LeafIndex[c][0])
            );  
            _DecodeBVHLeafIndex DECODER_1(
                .index(node_0[c].Nodes[1]),         
                .leaf_index(LeafIndex[c][1])
            );
            _DecodeBVHLeafIndex DECODER_2(
                .index(node_1[c].Nodes[0]),         
                .leaf_index(LeafIndex[c][2])
            );
            _DecodeBVHLeafIndex DECODER_3(
                .index(node_1[c].Nodes[1]),         
                .leaf_index(LeafIndex[c][3])
            );

            _QueryBVHLeaf QUERY_LEAF_00(
                .raw(LeafIndex[c][0][`BVH_NODE_INDEX_WIDTH-1] ? LeafRawData[0] : LeafRawData[LeafIndex[c][0]]),
                .valid(~LeafIndex[c][0][`BVH_NODE_INDEX_WIDTH-1]),
                .offset(offset),
                .leaf(leaf_0[c][0])
            );
            
            _QueryBVHLeaf QUERY_LEAF_01(
                .raw(LeafIndex[c][1][`BVH_NODE_INDEX_WIDTH-1] ? LeafRawData[0] : LeafRawData[LeafIndex[c][1]]),
                .valid(~LeafIndex[c][1][`BVH_NODE_INDEX_WIDTH-1]),
                .offset(offset),
                .leaf(leaf_0[c][1])
            );    
            
            _QueryBVHLeaf QUERY_LEAF_10(
                .raw(LeafIndex[c][2][`BVH_NODE_INDEX_WIDTH-1] ? LeafRawData[0] : LeafRawData[LeafIndex[c][2]]),
                .valid(~LeafIndex[c][2][`BVH_NODE_INDEX_WIDTH-1]),
                .offset(offset),
                .leaf(leaf_1[c][0])
            );
            
            _QueryBVHLeaf QUERY_LEAF_11(
                .raw(LeafIndex[c][3][`BVH_NODE_INDEX_WIDTH-1] ? LeafRawData[0] : LeafRawData[LeafIndex[c][3]]),
                .valid(~LeafIndex[c][3][`BVH_NODE_INDEX_WIDTH-1]),
                .offset(offset),
                .leaf(leaf_1[c][1])
            );       
        end
    endgenerate

    /*
    SDFileReader #(
        .FILE_NAME("chr_sword.vox.bvh.nodes.bin"),      // file to read, ignore Upper and Lower Case
                                                        // For example, if you want to read a file named HeLLo123.txt in the SD card,
                                                        // the parameter here can be hello123.TXT, HELLO123.txt or HEllo123.Txt                       
        .CLK_DIV(1)                                     // because clk=100MHz, CLK_DIV is set to 2
                                                        // see SDFileReader.sv for detail
    ) SD_FILE_READER (
        .clk(sd_clk),
        .rst_n(resetn),                                 // rst_n active low, re-scan and re-read SDcard by reset
    
        // signals connect to SD bus
        .sdclk(SD_SCK),
        .sdcmd(SD_CMD),
        .sddat(SD_DAT),
    
        // display information on 12bit LED
        //.sdcardstate    ( LED[ 3: 0]     ),
        //.sdcardtype     ( LED[ 5: 4]     ),  // 0=Unknown, 1=SDv1.1 , 2=SDv2 , 3=SDHCv2
        //.fatstate       ( LED[10: 8]     ),  // 3'd6 = DONE
        //.filesystemtype ( LED[13:12]     ),  // 0=Unknown, 1=invalid, 2=FAT16, 3=FAT32
        //.file_found     ( LED[15   ]     ),  // 0=file not found, 1=file found
    
        // file content output interface
        .outreq(SDReadDataValid),
        .outbyte(SDReadData)
    );

	uart_tx #(
    	.UART_CLK_DIV(434),     // UART baud rate = clk freq/(2*UART_TX_CLK_DIV)
                           	    // modify UART_TX_CLK_DIV to change the UART baud
                           	    // for example, when clk=100MHz, UART_TX_CLK_DIV=868, then baud=100MHz/(2*868)=115200
                           	    // 115200 is a typical SPI baud rate for UART                                        
    	.FIFO_ASIZE(12),        // UART TX buffer size=2^FIFO_ASIZE bytes, Set it smaller if your FPGA doesn't have enough BRAM
    	.BYTE_WIDTH(1),
    	.MODE(2)
	) UART_TX(
    	.clk(sd_clk),
    	.rst_n(resetn),    
    	.wreq(SDReadDataValid),
    	.wgnt(),
    	.wdata(SDReadData),    
    	.o_uart_tx(UART_RXD_OUT)
	);
    */        

endmodule