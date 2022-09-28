`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/16 12:13:39
// Design Name: 
// Module Name: RayCoreTest
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
`include "Types.sv"

module HomebrewGPUTop(
    input CLK100MHZ,
	input CPU_RESETN,
	input BTNU,
    input BTND,
    input BTNL,
    input BTNR,

    // VGA outputs
    output VGA_HS,    
    output VGA_VS,
    output [3:0] VGA_R,
    output [3:0] VGA_G,
    output [3:0] VGA_B,
    
    // SD signals
    output logic SD_RESET,      // when SD_RESET = 0, SDcard power on    
    output logic SD_SCK,        // signals connect to SD bus
    inout SD_CMD,
    input logic [3:0] SD_DAT,

    // UART tx signal, connected to host-PC's UART-RXD, baud=115200
    output logic UART_RXD_OUT,

    // LED outputs
	output [15:0] LED,    

    // 7-Segments
    output CA,
    output CB,
    output CC,
    output CD,
    output CE,
    output CF,
    output CG,
    output DP,
    output [7:0] AN,

	// DDR2 chip signals
    inout [15:0] ddr2_dq,
    inout [1:0] ddr2_dqs_n,
    inout [1:0] ddr2_dqs_p,
    output [12:0] ddr2_addr,
    output [2:0] ddr2_ba,
    output ddr2_ras_n,
    output ddr2_cas_n,
    output ddr2_we_n,
    output [0:0] ddr2_ck_p,
    output [0:0] ddr2_ck_n,
    output [0:0] ddr2_cke,
    output [0:0] ddr2_cs_n,
    output [1:0] ddr2_dm,
    output [0:0] ddr2_odt	
    );
	
	logic CLK200MHZ, CLK80MHZ, CLK40MHZ, CLK50MHZ, CLK25MHZ, CLK12MHZ;
	logic Blank, CLK_GPU, CLK_FBR, CLK_MC;	
	logic `SCREEN_COORD x, y;		
	RGB8 FinalColor;	
    logic [15:0] KCyclePerFrame;    
    logic [7:0] Seg;	   
    logic [7:0] Digit;   
    logic SDReadDataValid;
    logic [7:0] SDReadData;
    DebugData DebugData;
		
	// Output Color
    assign VGA_R = Blank ? 0 : (FinalColor.Channel[0] >> 4);
	assign VGA_G = Blank ? 0 : (FinalColor.Channel[1] >> 4);
	assign VGA_B = Blank ? 0 : (FinalColor.Channel[2] >> 4);

    assign CA = Seg[7];
    assign CB = Seg[6];
    assign CC = Seg[5];
    assign CD = Seg[4];
    assign CE = Seg[3];
    assign CF = Seg[2];
    assign CG = Seg[1];
    assign DP = Seg[0];    
    assign AN = Digit;

    assign SD_RESET = 1'b0;

    assign LED = DebugData.LED;    

	//assign VGA_R = Blank ? 0 : (FinalColor.Channel[0] * 15) >> 8;
	//assign VGA_G = Blank ? 0 : (FinalColor.Channel[1] * 15) >> 8;
	//assign VGA_B = Blank ? 0 : (FinalColor.Channel[2] * 15) >> 8;		

    always_comb begin
        `ifdef GPU_CLK_100
            CLK_GPU <= CLK100MHZ;
        `elsif GPU_CLK_50
            //CLK_GPU = CLK40MHZ;//CLK50MHZ;
            CLK_GPU <= CLK50MHZ;
        `elsif GPU_CLK_25
            CLK_GPU <= CLK25MHZ;
        `elsif GPU_CLK_12
            CLK_GPU <= CLK12MHZ;
        `else
            CLK_GPU <= CLK25MHZ;
            //CLK_GPU <= CLK12MHZ;
        `endif        
        //CLK_MC = CLK_GPU;        
        CLK_MC = CLK25MHZ;                
        CLK_FBR = CLK25MHZ;

        //CLK_MC = CLK_GPU;        
        //CLK_FBR = CLK_GPU;        

        //CLK_MC <= CLK100MHZ; 
        //CLK_FBR <= CLK100MHZ;
    end

    ClockWizard ClkWiz (
        .clk_in1(CLK100MHZ),
        .resetn(CPU_RESETN),        
        .clk_200(CLK200MHZ)
    );    
    
    ClockDivider Div50M(
        .clk(CLK100MHZ),
        .o_clk(CLK50MHZ)
    );

    ClockDivider Div25M(
        .clk(CLK50MHZ),
        .o_clk(CLK25MHZ)
    );

    ClockDivider Div12M(
        .clk(CLK25MHZ),
        .o_clk(CLK12MHZ)
    );

    VGA_640x480_25M_Clk VGA_SYNC(
	    .clk(CLK25MHZ), 
	    .hs(VGA_HS), 
	    .vs(VGA_VS), 
	    .current_x(x), 
	    .current_y(y), 
	    .blank(Blank)
	);	    

	HomebrewGPU GPU(
		.clk(CLK_GPU),        
        .clk_vga(CLK_FBR),	
        .clk_mc(CLK_MC),	
		.clk_mem(CLK200MHZ),        
        .resetn(CPU_RESETN),
        .hsync(VGA_HS),
		.vsync(VGA_VS),		
        .blank(Blank),

        .up(BTNU),
        .down(BTND),
        .left(BTNL),
        .right(BTNR),

        .sd_clk(CLK50MHZ),
        .SD_SCK(SD_SCK),
        .SD_CMD(SD_CMD),
        .SD_DAT(SD_DAT),

        .x(x), 
		.y(y), 
		.color(FinalColor),		

        .debug_data(DebugData),
		.ddr2_cs_n(ddr2_cs_n),
        .ddr2_addr(ddr2_addr),
        .ddr2_ba(ddr2_ba),
        .ddr2_we_n(ddr2_we_n),
        .ddr2_ras_n(ddr2_ras_n),
        .ddr2_cas_n(ddr2_cas_n),
        .ddr2_ck_n(ddr2_ck_n),
        .ddr2_ck_p(ddr2_ck_p),
        .ddr2_cke(ddr2_cke),
        .ddr2_dq(ddr2_dq),
        .ddr2_dqs_n(ddr2_dqs_n),
        .ddr2_dqs_p(ddr2_dqs_p),
        .ddr2_dm(ddr2_dm),
        .ddr2_odt(ddr2_odt)
	);	    

    HexDisplay_7_Seg DISPLAY_SEG(
        .clk(CLK_GPU),
        //.number(KCyclePerFrame),        
        .number_0(DebugData.Number[0]),
        .number_1(DebugData.Number[1]),
        .seg(Seg),
        .digit(Digit)
    );

    /*
    uart_tx #(
    	.UART_CLK_DIV(434),     // UART baud rate = clk freq/(2*UART_TX_CLK_DIV)
                           	    // modify UART_TX_CLK_DIV to change the UART baud
                           	    // for example, when clk=100MHz, UART_TX_CLK_DIV=868, then baud=100MHz/(2*868)=115200
                           	    // 115200 is a typical SPI baud rate for UART                                        
    	.FIFO_ASIZE(12),        // UART TX buffer size=2^FIFO_ASIZE bytes, Set it smaller if your FPGA doesn't have enough BRAM
    	.BYTE_WIDTH(1),
    	.MODE(2)
	) UART_TX(
    	.clk(CLK50MHZ),
    	.rst_n(resetn),    
    	.wreq(DebugData.UARTDataValid),
    	.wgnt(),
    	.wdata(DebugData.UARTData),    
    	.o_uart_tx(UART_RXD_OUT)
	);
    */

    /*
    // For input and output definitions of this module, see SDFileReader.sv
    SDFileReader #(
        .FILE_NAME      ( "chr_sword.vox.bvh.leaves.bin"  ),  // file to read, ignore Upper and Lower Case
                                                             // For example, if you want to read a file named HeLLo123.txt in the SD card,
                                                             // the parameter here can be hello123.TXT, HELLO123.txt or HEllo123.Txt
                                         
        .CLK_DIV        ( 1              )   // because clk=100MHz, CLK_DIV is set to 2
                                              // see SDFileReader.sv for detail
    ) SD_FILE_READER (
        .clk            ( CLK50MHZ      ),
        .rst_n          ( CPU_RESETN         ),  // rst_n active low, re-scan and re-read SDcard by reset
    
        // signals connect to SD bus
        .sdclk          ( SD_SCK         ),
        .sdcmd          ( SD_CMD         ),
        .sddat          ( SD_DAT         ),
    
        // display information on 12bit LED
        //.sdcardstate    ( LED[ 3: 0]     ),
        //.sdcardtype     ( LED[ 5: 4]     ),  // 0=Unknown, 1=SDv1.1 , 2=SDv2 , 3=SDHCv2
        //.fatstate       ( LED[10: 8]     ),  // 3'd6 = DONE
        //.filesystemtype ( LED[13:12]     ),  // 0=Unknown, 1=invalid, 2=FAT16, 3=FAT32
        //.file_found     ( LED[15   ]     ),  // 0=file not found, 1=file found
    
        // file content output interface
        .outreq         ( SDReadDataValid ),
        .outbyte        ( SDReadData )
    );

    uart_tx #(
    	.UART_CLK_DIV(434),     // UART baud rate = clk freq/(2*UART_TX_CLK_DIV)
                           	    // modify UART_TX_CLK_DIV to change the UART baud
                           	    // for example, when clk=100MHz, UART_TX_CLK_DIV=868, then baud=100MHz/(2*868)=115200
                           	    // 115200 is a typical SPI baud rate for UART                                        
    	.FIFO_ASIZE(12),        // UART TX buffer size=2^FIFO_ASIZE bytes, Set it smaller if your FPGA doesn't have enough BRAM
    	.BYTE_WIDTH(1),
    	.MODE(2)
	) UART_TX_UNIT(
    	.clk(CLK50MHZ),
    	.rst_n(CPU_RESETN),    
    	.wreq(SDReadDataValid),
    	.wgnt(),
    	.wdata(SDReadData),    
    	.o_uart_tx(UART_RXD_OUT)
	);        
    */
	
endmodule
