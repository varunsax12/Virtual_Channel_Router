// Testbench
// File Details
//    Author: Varun Saxena

`timescale 10ns/1ps

module tb_priority_encoder ();

    localparam NUM_INPUTS = 4;
    localparam NUM_BITS   = $clog2(NUM_INPUTS);
    reg[NUM_INPUTS-1:0]   in_signals;
    reg [NUM_BITS-1:0]    out_index;

    priority_encoder #(
        .NUM_INPUTS(NUM_INPUTS)
    ) uut (
        .in_signals(in_signals),
        .out_index(out_index)
    );

    initial begin
        in_signals = 4'b0110;
        #10;
        $display("Index = %d", out_index);
    end

endmodule