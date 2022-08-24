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

`include "../Types.sv"
`include "../Math/Fixed.sv"
`include "../Math/Fixed3.sv"
`include "../Math/FixedNorm.sv"
`include "../Math/FixedNorm3.sv"

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module QueryPrimitiveAABB (   
    input [31:0] s,
    input [95:0] a,
    output AABB out
    );      
    Fixed S;  
    Fixed3 A;

    always_comb begin
        S.Value <= s;        
        A.Dim[0].Value <= a[95:64];
        A.Dim[1].Value <= a[63:32];
        A.Dim[2].Value <= a[31:0];        
    end

    Fixed3_SubOffset MIN(A, S, out.Min);
    Fixed3_AddOffset MAX(A, S, out.Max);    
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module QueryPrimitiveColor (   
    input [23:0] a,
    output RGB8 out
    );

    always_comb begin
        out.Channel[0] <= a[23:16];
        out.Channel[1] <= a[15:8];
        out.Channel[2] <= a[7:0];
    end
    
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module QueryPrimitiveSurafceType (   
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] i,
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] bound,    
    output logic `VOXEL_INDEX vi,      
    output SurfaceType out
    );

    always_comb begin
        if (i < bound && i < `BVH_PRIMITIVE_RAW_DATA_SIZE) begin
            vi <=  i;
        end
        else begin
            vi <= `NULL_VOXEL_INDEX;  
        end

        //if (i >= (`BVH_MODEL_RAW_DATA_SIZE + 1)) begin                    
        //if (i >= (`BVH_MODEL_RAW_DATA_SIZE)) begin                    
        if (i == (`BVH_MODEL_RAW_DATA_SIZE + 1)) begin                    
            //out <= ST_Metal;
            //out <= ST_Lambertian;            
            out <= ST_Dielectric;
        end 
        //else if (i == (`BVH_MODEL_RAW_DATA_SIZE) || i == (`BVH_MODEL_RAW_DATA_SIZE + 2)) begin                    
        else if (i == (`BVH_MODEL_RAW_DATA_SIZE + 2)) begin                    
            out <= ST_Metal;
            //out <= ST_Lambertian;            
            //out <= ST_Dielectric;
        end 
        else begin
            out <= ST_Lambertian;
        end                
    end           
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module PostQueryPrimitive (   
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] i,
    input Fixed3 offset,
    input AABB aabb,    
    output AABB out_aabb
    );
    Fixed3 FinalOffset;    

    always_comb begin       
        if (i < `BVH_MODEL_RAW_DATA_SIZE) begin          
            FinalOffset <= offset;            
        end
        else begin
            FinalOffset <= _Fixed3(FixedZero(), FixedZero(), FixedZero());
        end
    end
    
    Fixed3_Add A0(aabb.Min, FinalOffset, out_aabb.Min);
    Fixed3_Add A1(aabb.Max, FinalOffset, out_aabb.Max);
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module QueryPrimitive (   
    input [151:0] raw,    
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] i,
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] bound,    
    input Fixed3 offset,    
    output BVH_Primitive p
    );    

    AABB TempAABB;

    QueryPrimitiveAABB QUERY_AABB(
        .s(raw[55:24]),
        .a(raw[151:56]),
        .out(TempAABB)
    );

    QueryPrimitiveColor QUERY_COLOR(
        .a(raw[23:0]),
        .out(p.Color)
    );

    QueryPrimitiveSurafceType QUERY_ST(
        .i(i),
        .bound(bound),
        .vi(p.VI),
        .out(p.SurfaceType)
    );

    PostQueryPrimitive QUERY_POST(
        .i(i),
        .offset(offset),
        .aabb(TempAABB),
        .out_aabb(p.Aabb)
    );     
endmodule
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module DecodeBVHLeafIndex (   
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
module QueryBVHLeaf (   
    input [231:0] raw,
    input valid,
    input Fixed3 offset,
    output BVH_Leaf leaf
    );
    AABB Aabb;

    always_comb begin
        if (valid) begin                    
            `ifdef BVH_LEAF_AABB_TEST    
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
            leaf.StartPrimitive <= 0;
            leaf.NumPrimitives <= 0;	
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
//-------------------------------------------------------------------
//
//-------------------------------------------------------------------    
module QueryBVHNode (   
    input [223:0] node_raw,
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
//
//-------------------------------------------------------------------    
module BVHStructure (   
    input clk,	    
    input resetn, 
    // SD signals -----------------------------------------
	input sd_clk,
    output logic SD_SCK,
    inout SD_CMD,
    input [3:0] SD_DAT,	
	// UART tx signal -------------------------------------
    output logic UART_RXD_OUT,
    // Memory signals --------------------------------------
    output MemoryReadRequest mem_r_req,
    output MemoryWriteRequest mem_w_req,
    input MemoryReadData read_data,     
    // Controls ---------------------------------------------
    output logic init_done,    
    input BVHQueryMode mode,
    input Fixed3 offset, 
    // Query Node ---------------------------------------------
    input [`BVH_NODE_INDEX_WIDTH-1:0] node_index_0, 
    input [`BVH_NODE_INDEX_WIDTH-1:0] node_index_1, 
    output BVH_Node node_0,
    output BVH_Node node_1,
    output BVH_Leaf leaf_0[2],
    output BVH_Leaf leaf_1[2],
    // Query Primitive
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] prim_index_0,
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] prim_index_1,
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] prim_bound_0,
    input [`BVH_PRIMITIVE_INDEX_WIDTH-1:0] prim_bound_1,
    output BVH_Primitive p0[`BVH_AABB_TEST_UNIT_SIZE],
    output BVH_Primitive p1[`BVH_AABB_TEST_UNIT_SIZE]    
    );

    logic SDReadDataValid;
    logic [7:0] SDReadData;

    logic [255:0] WriteData;

    logic [223:0] NodeRawData[`BVH_NODE_RAW_DATA_SIZE];    
    logic [6:0] ByteOffset = 28, NodeIndex = 0;        

    logic [231:0] LeafRawData[`BVH_LEAF_RAW_DATA_SIZE];
    logic [`BVH_NODE_INDEX_WIDTH-1:0] LeafIndex[4];

    logic [151:0] PrimitiveRawData[`BVH_PRIMITIVE_RAW_DATA_SIZE];         
    Fixed Scale[6];    


    assign mem_w_req.WriteStrobe = 0;

    //-------------------------------------------------------------------
    //
    //-------------------------------------------------------------------    
    function AddReflectiveBoxAndGroundPrimitive();
        // Ground ----
        Scale[0] = _Fixed(256);
        Scale[1] = _Fixed(-256);        

        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE][151:120] = `FIXED_ZERO;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE][119:88]  = Scale[1].Value;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE][87:56]   = `FIXED_ZERO;
        
        //`ifdef TEST_RAY_CORE
        //    Scale = _Fixed(2);
        //`else
            //Scale[0] = _Fixed(256);
        //`endif
        
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE][55:24]   = Scale[0].Value;

        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE][23:16]   = 100;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE][15:8]    = 225;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE][7:0]     = 100;	        

        Scale[0] = _Fixed(10);        
        Scale[1] = _Fixed(13);        

        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 1][151:120]     = `FIXED_ZERO;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 1][119:88]      = Scale[1].Value;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 1][87:56]       = `FIXED_ZERO;
        
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 1][55:24]       = Scale[0].Value;
        
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 1][23:16]       = 255;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 1][15:8]        = 255;//155;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 1][7:0]         = 145;//155;

        Scale[0] = _Fixed(20);        
        Scale[1] = _Fixed(60);                                 

        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 2][151:120]     = `FIXED_ZERO;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 2][119:88]      = Scale[0].Value;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 2][87:56]       = Scale[1].Value;
        
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 2][55:24]       = Scale[0].Value;

        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 2][23:16]       = 255;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 2][15:8]        = 100;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 2][7:0]         = 125;	  	        

        /*
        // ReflectiveBox ----
        Scale = _Fixed(12);        

        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 1][151:120]     = `FIXED_ZERO;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 1][119:88]      = Scale.Value;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 1][87:56]       = `FIXED_ZERO;
        
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 1][55:24]       = Scale.Value;
        
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 1][23:16]       = 255;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 1][15:8]        = 255;//155;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 1][7:0]         = 145;//155;	        

        Scale = _Fixed(8);        
        Scale2 = _Fixed(-10);                         
        Scale3 = _Fixed(-37);

        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 2][151:120]     = Scale2.Value;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 2][119:88]      = Scale.Value;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 2][87:56]       = Scale3.Value;
        
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 2][55:24]       = Scale.Value;

        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 2][23:16]       = 255;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 2][15:8]        = 100;
        PrimitiveRawData[`BVH_MODEL_RAW_DATA_SIZE + 2][7:0]         = 125;	                
        */
    endfunction 

    initial begin	
        $readmemh(`BVH_NODES_PATH, NodeRawData);                
        ByteOffset <= 28;
        NodeIndex <= 0;
        //NodeRawData[0] <= 0;

        $readmemh(`BVH_LEAVES_PATH, LeafRawData);	        

        $readmemh(`BVH_PRIMITIVE_PATH, PrimitiveRawData);
        AddReflectiveBoxAndGroundPrimitive();
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

    QueryBVHNode QUERY_NODE_0(   
        .node_raw(NodeRawData[node_index_0]),
        .offset(offset),                
        .node(node_0)    
    );
    QueryBVHNode QUERY_NODE_1(   
        .node_raw(NodeRawData[node_index_1]),
        .offset(offset),                
        .node(node_1)    
    );

    DecodeBVHLeafIndex DECODER_0(
        .index(node_0.Nodes[0]),         
        .leaf_index(LeafIndex[0])
    );  
    DecodeBVHLeafIndex DECODER_1(
        .index(node_0.Nodes[1]),         
        .leaf_index(LeafIndex[1])
    );
    DecodeBVHLeafIndex DECODER_2(
        .index(node_1.Nodes[0]),         
        .leaf_index(LeafIndex[2])
    );
    DecodeBVHLeafIndex DECODER_3(
        .index(node_1.Nodes[1]),         
        .leaf_index(LeafIndex[3])
    );

    QueryBVHLeaf QUERY_LEAF_00(
        .raw(LeafIndex[0][`BVH_NODE_INDEX_WIDTH-1] ? LeafRawData[0] : LeafRawData[LeafIndex[0]]),
        .valid(~LeafIndex[0][`BVH_NODE_INDEX_WIDTH-1]),
        .offset(offset),
        .leaf(leaf_0[0])
    );
    
    QueryBVHLeaf QUERY_LEAF_01(
        .raw(LeafIndex[1][`BVH_NODE_INDEX_WIDTH-1] ? LeafRawData[0] : LeafRawData[LeafIndex[1]]),
        .valid(~LeafIndex[1][`BVH_NODE_INDEX_WIDTH-1]),
        .offset(offset),
        .leaf(leaf_0[1])
    );    
      
    QueryBVHLeaf QUERY_LEAF_10(
        .raw(LeafIndex[2][`BVH_NODE_INDEX_WIDTH-1] ? LeafRawData[0] : LeafRawData[LeafIndex[2]]),
        .valid(~LeafIndex[2][`BVH_NODE_INDEX_WIDTH-1]),
        .offset(offset),
        .leaf(leaf_1[0])
    );
    
    QueryBVHLeaf QUERY_LEAF_11(
        .raw(LeafIndex[3][`BVH_NODE_INDEX_WIDTH-1] ? LeafRawData[0] : LeafRawData[LeafIndex[3]]),
        .valid(~LeafIndex[3][`BVH_NODE_INDEX_WIDTH-1]),
        .offset(offset),
        .leaf(leaf_1[1])
    );       

    generate
        for (genvar i = 0; i < `BVH_AABB_TEST_UNIT_SIZE; i = i + 1) begin : QUERY_PRIM
            QueryPrimitive QUERY_PRIM_0(   
                .raw(PrimitiveRawData[prim_index_0 + i]),    
                .i(prim_index_0 + i),
                .bound(prim_bound_0),    
                .offset(offset),    
                .p(p0[i])
            ); 

            QueryPrimitive QUERY_PRIM_1(   
                .raw(PrimitiveRawData[prim_index_1 + i]),    
                .i(prim_index_1 + i),
                .bound(prim_bound_1),    
                .offset(offset),    
                .p(p1[i])
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