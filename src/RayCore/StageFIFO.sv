`include "../Types.sv"

module FIFOCheck#(    
    parameter WIDTH = `STAGE_FIFO_SIZE_WIDTH,
    parameter SIZE = 2**WIDTH 
    )(
        input logic [WIDTH-1:0] top,
        input logic [WIDTH-1:0] bottom,
        output logic full
    );

    always_comb begin
        if (bottom > top) begin
            full <= (({1'b0, top} + SIZE - {1'b0, bottom}) == 1) ? 1 : 0; 
        end
        else begin
            full <= ((top - bottom) == 1) ? 1 : 0; 
        end        
    end    
endmodule