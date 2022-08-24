
module SDDirParser(
    input  logic clk, rst_n,
    input  logic rvalid,
    input  logic [ 4:0] raddr,
    input  logic [ 7:0] rdata,
    
    output logic fready,
    //output logic [31:0] file_cluster, file_size,
    output logic [ 7:0] fnamelen,
    output logic [ 7:0] fname [52],
    output logic [15:0] fcluster,
    output logic [31:0] fsize
);

initial begin fready=1'b0; fnamelen=8'h0; fcluster=16'h0;  fsize=0; for(int i=0;i<52;i++)begin file_name[i]=8'h0; fname[i]=8'h0; end end

logic isshort=1'b0, islongok=1'b0, islong=1'b0, longvalid=1'b0;
logic [ 5:0] longno = 6'h0;
logic [ 7:0] lastchar = 8'h0;
logic [ 7:0] fdtnamelen=8'h0, sdtnamelen=8'h0;
logic [ 7:0] file_namelen = 8'h0;
logic [ 7:0] file_name [52];
logic [15:0] file_first_cluster = 16'h0;
logic [31:0] file_size = 0;

wire  [15:0] unicode  = {rdata, lastchar};

always @ (posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        fready=1'b0;  fnamelen=8'h0; file_namelen=8'h0;
        for(int i=0;i<52;i++) begin file_name[i]=8'h0; fname[i]=8'h0; end
        fcluster=16'h0;  fsize=0;
        
        {isshort, islongok, islong, longvalid} = 4'b0000;
        longno     = 6'h0;
        lastchar   = 8'h0;
        fdtnamelen = 8'h0;  sdtnamelen=8'h0;
        file_first_cluster=16'h0; file_size=0;
    end else begin
        fready=1'b0;  fnamelen=8'h0;
        for(int i=0;i<52;i++) fname[i]=8'h0;
        fcluster=16'h0;  fsize=0;
        
        if(rvalid) begin
            case(raddr)
            5'h1A : file_first_cluster[ 0+:8] = rdata;
            5'h1B : file_first_cluster[ 8+:8] = rdata;
            5'h1C :          file_size[ 0+:8] = rdata;
            5'h1D :          file_size[ 8+:8] = rdata;
            5'h1E :          file_size[16+:8] = rdata;
            5'h1F :          file_size[24+:8] = rdata;
            endcase
            
            if(raddr==5'h0) begin
                {islongok, isshort} = 2'b00;
                fdtnamelen = 8'h0;  sdtnamelen=8'h0;
                
                if(rdata!=8'hE5 && rdata!=8'h2E && rdata!=8'h00) begin
                    if(islong && longno==6'h1)
                        islongok = 1'b1;
                    else
                        isshort = 1'b1;
                end
                
                if(rdata[7]==1'b0 && ~islongok) begin
                    if(rdata[6]) begin
                        {islong,longvalid} = 2'b11;
                        longno = rdata[5:0];
                    end else if(islong) begin
                        if(longno>6'h1 && (rdata[5:0]+6'h1==longno) ) begin
                            islong = 1'b1;
                            longno = rdata[5:0];
                        end else begin
                            islong = 1'b0;
                        end
                    end else
                        islong = 1'b0;
                end else
                    islong = 1'b0;
            end else if(raddr==5'hB) begin
                if(rdata!=8'h0F)
                    islong = 1'b0;
                if(rdata!=8'h20)
                    {isshort, islongok} = 2'b00;
            end else if(raddr==5'h1F) begin
                if(islongok && longvalid || isshort) begin
                    fready = 1'b1;
                    fnamelen = file_namelen;
                    for(int i=0;i<52;i++) fname[i] = (i<file_namelen) ? file_name[i] : 8'h0;
                    fcluster = file_first_cluster;
                    fsize = file_size;
                end
            end
            
            if(islong) begin
                if(raddr>5'h0&&raddr<5'hB || raddr>=5'hE&&raddr<5'h1A || raddr>=5'h1C)begin
                    if(raddr<5'hB ? raddr[0] : ~raddr[0]) begin
                        lastchar = rdata;
                        fdtnamelen++;
                    end else begin
                        if(unicode==16'h0000) begin
                            file_namelen = fdtnamelen-8'd1 + (longno-8'd1)*8'd13;
                        end else if(unicode!=16'hFFFF) begin
                            if(unicode[15:8]==8'h0) begin
                                file_name[fdtnamelen-8'd1+(longno-8'd1)*8'd13] = (unicode[7:0]>="a" && unicode[7:0]<="z") ? unicode[7:0]&8'b11011111 : unicode[7:0]; 
                            end else begin
                                longvalid = 1'b0;
                            end
                        end
                    end
                end
            end 
            
            if(isshort) begin
                if(raddr<5'h8) begin
                    if(rdata!=8'h20) begin
                        file_name[sdtnamelen] = rdata;
                        sdtnamelen++;
                    end
                end else if(raddr<5'hB) begin
                    if(raddr==5'h8) begin
                        file_name[sdtnamelen] = ".";
                        sdtnamelen++;
                    end
                    if(rdata!=8'h20) begin
                        file_name[sdtnamelen] = rdata;
                        sdtnamelen++;
                    end
                end else if(raddr==5'hB) begin
                    file_namelen = sdtnamelen;
                end
            end
            
        end
    end
end


endmodule
