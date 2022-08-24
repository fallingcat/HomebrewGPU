
module SDCmdCtrl #(
    parameter logic[14:0] TIMEOUT_CYCLES = 999
)(
    input  logic clk, rst_n,
    // user input signal
    input  logic start,
    input  logic [ 15:0] precycles,
    input  logic [ 15:0] clkdiv,
    input  logic [  5:0] cmd,
    input  logic [ 31:0] arg,
    // user output signal
    output logic [ 31:0] resparg,
    output logic [127:0] resparg_long,
    output logic busy, done, timeout, syntaxerr,
    // SD CLK
    output logic sdclk,
    // 1bit SD CMD
    output logic sdcmdoe, sdcmdout, 
    input  logic sdcmdin
);
initial begin {busy,done,timeout,syntaxerr} = '0;  end
initial begin sdclk = '0;  sdcmdoe  = '0;   sdcmdout = '1;  end

function automatic void CalcCrc7(ref [6:0] crc, input inbit);
    crc = {crc[5:0],crc[6]^inbit} ^ {3'b0,crc[6]^inbit,3'b0};
endfunction

struct packed{
    logic [ 3:0]  pre;  // 51:48
    logic [ 1:0]   st;  // 47:46
    logic [ 5:0]  cmd;  // 45:40
    logic [31:0]  arg;  // 39: 8
    logic [ 6:0]  crc;  //  7: 1
    logic        stop;  //  0: 0
} request='0;   // request = 52bit  from 51 down to 0

logic [134:0] response = '0;
wire  response_t;
wire  [  5:0] response_cmd;
assign {response_t, response_cmd, resparg_long} = response;
assign resparg = response[127:96];

logic  [15:0] clkdivlatch=16'd16;
logic  [15:0] precyclesr='0, precycler ='0, reqcycler ='0, waitcycle='0, rescycler ='0;
logic  [31:0] clkdivr='0, clkcnt='0;

always @ (posedge clk or negedge rst_n)
    if(~rst_n) begin
        clkdivlatch=16'd16;
        {clkdivr,clkcnt} = '0;
        {precyclesr,precycler,reqcycler,waitcycle,rescycler}  ='0;
        {sdclk, sdcmdoe, sdcmdout} = 3'b001;
        request = '0;
        response= '0;
        {busy,done,timeout,syntaxerr}= '0;
    end else begin
        if(busy) begin
            if(done) {busy,done,timeout,syntaxerr} = '0;
        end else if(start) begin
            clkdivlatch = clkdiv;
            precyclesr = precycles>2 ? precycles : 16'd2;
            request.pre  = '1;  request.st   = 2'b01;  request.cmd  = cmd;  request.arg  = arg;  request.crc  = '0;  request.stop = '1;
            busy    = '1;
            {done,timeout,syntaxerr} = '0;
        end
        if(clkcnt==0) begin
            clkdivr = {16'h0, clkdivlatch};
            if(precyclesr>0) begin
                precycler = precyclesr; reqcycler = 52;  rescycler = 135; waitcycle = TIMEOUT_CYCLES+16'd2;
                precyclesr=  '0;
            end
        end
        if(clkcnt == clkdivr) begin
            {sdclk, sdcmdoe, sdcmdout} = 3'b001;
            if(precycler>0)
                precycler--;
            else if(reqcycler>0) begin
                reqcycler--;
                {sdcmdoe,sdcmdout} = {1'b1,request[reqcycler]};
                if(reqcycler>=8 && reqcycler<48) CalcCrc7(request.crc, sdcmdout);
            end
        end else if(clkcnt == 2*clkdivr+1) begin
            sdclk = 1'b1;
            if(precycler==0 && reqcycler==0) begin
                if(waitcycle>TIMEOUT_CYCLES)
                    waitcycle--;
                else if(waitcycle>0) begin
                    waitcycle--;
                    if(~sdcmdin)
                        waitcycle = 0;
                    else if(waitcycle==0) begin
                        rescycler = 0;
                        {done,timeout} = '1;
                    end
                end else if(rescycler>0) begin
                    rescycler--;
                    response[rescycler] = sdcmdin;
                    if(rescycler==0) begin
                        done    = '1;
                        if(response_t || (response_cmd!=request.cmd && response_cmd!=6'h3f && response_cmd!=6'h0) )  syntaxerr=1'b1;
                    end
                end
            end
        end
        clkcnt = (clkcnt<2*clkdivr+1) ? clkcnt+1 : 0;
    end
endmodule
