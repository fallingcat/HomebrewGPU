`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/15 12:17:03
// Design Name: 
// Module Name: Fixed_Sqrt
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
`include "Fixed.sv"

module Fixed_SqrtV2 (
    input logic clk,    
    input logic strobe,
    input Fixed rad,
    output logic valid,    
    output Fixed root    
    );
    logic [47:0] A;
    logic [23:0] RootOut;

    assign root.Value = (RootOut >> 1);

    always_comb begin       
        A = (rad.Value << 16);
    end

    Sqrt SQT(
        //.aclk(clk),
        .s_axis_cartesian_tvalid(strobe),
        .s_axis_cartesian_tdata(A),
        .m_axis_dout_tvalid(valid),
        .m_axis_dout_tdata(RootOut)
    );    
endmodule


module Fixed_Sqrt #(
    parameter WIDTH = `FIXED_WIDTH,
    parameter STEP = 4
    ) (
    input logic clk,    
    input logic strobe,
    input Fixed rad,
    output logic valid,    
    output Fixed root    
    );

    logic [WIDTH-1:0] x, x_next;    // radicand copy
    logic [WIDTH-1:0] q, q_next;    // intermediate root (quotient)
    logic [WIDTH+1:0] ac, ac_next;  // accumulator (2 bits wider)
    logic [WIDTH+1:0] test_res;     // sign test result (2 bits wider)

    localparam ITER = WIDTH >> 1;   // iterations are half radicand width
    logic [$clog2(ITER)-1:0] i;     // iteration counter

    State CurrentState = State_Ready;   	

    function Compute;
        test_res = ac - {q, 2'b01};
        if (test_res[WIDTH + 1] == 0) begin  // test_res ≥0? (check MSB)
            {ac_next, x_next} = {test_res[WIDTH-1:0], x, 2'b0};
            q_next = {q[WIDTH-2:0], 1'b1};
        end else begin
            {ac_next, x_next} = {ac[WIDTH-1:0], x, 2'b0};
            q_next = q << 1;
        end
    endfunction    

    always_ff @(posedge clk) begin        
        case (CurrentState)
            default: begin
                CurrentState = State_Ready;   	
            end        

            (State_Ready): begin
                valid = 0;                
                if (strobe) begin
                    i = 0;
                    q = 0;
                    {ac, x} = {{WIDTH{1'b0}}, rad.Value, 2'b0};                    
                    CurrentState = State_Busy;
                end     
            end

            (State_Busy): begin
                for (integer loop = 0; loop < STEP; loop = loop + 1) begin
                    Compute();
                    if (i == ITER-1) begin  // we're done                    
                        root.Value = (q_next << `FIXED_FRAC_HALF_WIDTH);
                        //rem <= ac_next[WIDTH+1:2];  // undo final shift
                        CurrentState = State_Done;
                    end else begin  // next iteration                        
                        i = i + 1;
                        x = x_next;
                        ac = ac_next;
                        q = q_next;                        
                    end                
                end
            end

            (State_Done): begin
                valid = 1;     
                CurrentState = State_Ready;           
            end
        endcase
    end
endmodule
