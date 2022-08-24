
module SDReader # (
    parameter  CLK_DIV = 1, // when clk = 0~25MHz   , set CLK_DIV to 0,
                            // when clk = 25~50MHz  , set CLK_DIV to 1,
                            // when clk = 50~100MHz , set CLK_DIV to 2,
                            // when clk = 100~200MHz, set CLK_DIV to 3,
                            // when clk = 200~400MHz, set CLK_DIV to 4,
                            // ......
    parameter  SIMULATION = 0
) (
    // clock
    input  logic         clk,
    // rst_n active-low
    input  logic         rst_n,
    // SDcard signals (connect to SDcard)
    output logic         sdclk,
    inout                sdcmd,
    input  logic [ 3:0]  sddat,
    // show card status
    output logic [ 1:0]  card_type,
    output logic [ 3:0]  card_stat,
    // user read sector command interface
    input  logic         rstart, 
    input  logic [31:0]  rsector_no,
    output logic         rbusy,
    output logic         rdone,
    // sector data output interface
    output logic outreq,
    output logic [ 8:0]  outaddr,  // outaddr from 0 to 511, because the sector size is 512
    output logic [ 7:0]  outbyte
);

localparam  SLOWCLKDIV = SIMULATION ? 16'd1 : ( (16'd1<<CLK_DIV)*16'd35 ),
            FASTCLKDIV = SIMULATION ? 16'd0 : ( (16'd1<<CLK_DIV) ),
            CMDTIMEOUT = SIMULATION ?15'd100:15'd500 ,    // according to SD datasheet, Ncr(max) = 64 clock cycles, so 500 cycles is enough
            DATTIMEOUT = SIMULATION ?  'd200:  'd1000000; // according to SD datasheet, 1ms is enough to wait for DAT result, here, we set timeout to 1000000 clock cycles = 80ms (when SDCLK=12.5MHz)

// 1bit SD CMD
logic sdcmdoe, sdcmdout;

assign sdcmd = sdcmdoe ? sdcmdout : 1'bz;
wire sdcmdin = sdcmdoe ? 1'b1 : sdcmd;

wire   sddat0 = sddat[0];  // only use 1bit mode of SDDAT

logic start=1'b0;
logic [ 15:0] precycles='0, clkdiv=16'd50;
logic [  5:0] cmd = '0;
logic [ 31:0] rsectoraddr='0;
logic [ 31:0] arg = '0, resparg;
logic [127:0] resparg_long;
logic busy, done, timeout, syntaxerr;

enum {CMD0, CMD8, CMD55_41, ACMD41, CMD2, CMD3, CMD7, CMD16, IDLE, READING, READING2} sdstate = CMD0;
enum {UNKNOWN, SDv1, SDv2, SDHCv2, SDv1Maybe} cardtype = UNKNOWN;
logic [ 15:0] rca = '0;

assign rbusy = (sdstate!=IDLE) | rdone;
logic sdclkl = 1'b0;
enum {RWAIT, RDURING, RTAIL, RDONE, RTIMEOUT} rstate = RWAIT;
logic [31:0] ridx = 0;
wire  [ 2:0] rlsb = 3'd7 - ridx[2:0];

assign card_stat =  sdstate[3:0];
assign card_type = cardtype[1:0];

SDCmdCtrl #(CMDTIMEOUT) sd_cmd_ctrl_inst ( .* );

task automatic set_cmd(input _start, input[15:0] _precycles='0, input[15:0] _clkdiv=SLOWCLKDIV, input[5:0] _cmd='0, input[31:0] _arg='0 );
    start     = _start;
    precycles = _precycles;
    clkdiv    = _clkdiv;
    cmd       = _cmd;
    arg       = _arg;
endtask

always @ (posedge clk or negedge rst_n)
    if(~rst_n) begin
        set_cmd(0);
        rdone     = 1'b0;
        rsectoraddr='0;
        sdstate   = CMD0;
        cardtype  = UNKNOWN;
        rca       = '0;
    end else begin
        set_cmd(0);
        rdone     = 1'b0;
        if(sdstate==READING2) begin
            if(rstate==RTIMEOUT)   begin set_cmd(1, 16 , FASTCLKDIV, 17, rsectoraddr); sdstate=READING; end
            else if(rstate==RDONE) begin rdone = 1'b1;                                 sdstate=   IDLE; end
        end else if(busy) begin
            if(done) begin
                case(sdstate)
                CMD0    : sdstate = CMD8;
                CMD8    : if(timeout) begin
                              cardtype = SDv1Maybe;
                              sdstate  = CMD55_41;
                          end else if(~syntaxerr && resparg[7:0]==8'haa)
                              sdstate  = CMD55_41;
                CMD55_41: if(~timeout && ~syntaxerr) sdstate = ACMD41;
                ACMD41  : if(~timeout && ~syntaxerr && resparg[31]) begin
                              cardtype = (cardtype==SDv1Maybe) ? SDv1 : (resparg[30] ? SDHCv2 : SDv2);
                              sdstate = CMD2;
                          end else
                              sdstate  = CMD55_41;
                CMD2    : if(~timeout && ~syntaxerr) sdstate = CMD3;
                CMD3    : if(~timeout && ~syntaxerr) begin
                              rca = resparg[31:16];
                              sdstate = CMD7;
                          end
                CMD7    : if(~timeout && ~syntaxerr) sdstate = CMD16;
                CMD16   : if(~timeout && ~syntaxerr) sdstate = IDLE;
                READING : if(~timeout && ~syntaxerr) sdstate = READING2;
                          else set_cmd(1, 128 , FASTCLKDIV, 17, rsectoraddr);
                endcase
            end
        end else begin
                case(sdstate)
                CMD0    : set_cmd(1, SIMULATION?16:99999, SLOWCLKDIV,  0, 'h00000000);
                CMD8    : set_cmd(1, 20    , SLOWCLKDIV,  8, 'h000001aa);
                CMD55_41: set_cmd(1, 20    , SLOWCLKDIV, 55, 'h00000000);
                ACMD41  : set_cmd(1, 20    , SLOWCLKDIV, 41, 'hc0100000);
                CMD2    : set_cmd(1, 20    , SLOWCLKDIV,  2, 'h00000000);
                CMD3    : set_cmd(1, 20    , SLOWCLKDIV,  3, 'h00000000);
                CMD7    : set_cmd(1, 20    , SLOWCLKDIV,  7,{rca,16'h0});
                CMD16   : set_cmd(1, SIMULATION?20:99999 , FASTCLKDIV, 16, 'h00000200);
                IDLE    : if(rstart & ~rbusy) begin 
                            rsectoraddr = (cardtype==SDHCv2) ? rsector_no : (rsector_no*512);
                            set_cmd(1, 32 , FASTCLKDIV, 17, rsectoraddr); sdstate=READING; end
                endcase
        end
    end

always @ (posedge clk or negedge rst_n)
    if(~rst_n) begin
        sdclkl <= 1'b0; rstate=RWAIT; outreq=1'b0; ridx='0; outaddr='0; outbyte='0;
    end else begin
        sdclkl <= sdclk; outreq=1'b0; outaddr='0;
        if(sdstate!=READING && sdstate!=READING2) begin
            rstate=RWAIT; ridx=0;
        end else if(~sdclkl & sdclk)
            case(rstate)
                RWAIT  : if(~sddat0) begin
                              rstate=RDURING; ridx=0;
                         end else if((++ridx)>DATTIMEOUT) rstate=RTIMEOUT;
                RDURING: begin
                             outbyte[rlsb] = sddat0;
                             if(rlsb==3'd0) begin outreq=1; outaddr=ridx[11:3]; end
                             if((++ridx)>=512*8) begin rstate=RTAIL; ridx=0; end
                         end
                RTAIL  : if((++ridx)>=8*8) rstate=RDONE;
            endcase
    end

endmodule

