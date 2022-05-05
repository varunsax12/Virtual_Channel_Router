// Testbench
// File Details
//    Author: Varun Saxena

`timescale 10ns/1ps

module tb_one_hot_2_index ();

    localparam NUM_BITS = 4;
    localparam INDEX_SIZE = $clog2(NUM_BITS);
    logic [NUM_BITS-1:0] one_hot_input;
    logic [INDEX_SIZE-1:0] output_index;

    one_hot_2_index #(
        .NUM_BITS(NUM_BITS)
    ) uut (
        .one_hot_input(one_hot_input),
        .output_index(output_index)
    );

    initial begin
        one_hot_input = 8;
        #10;
        $display("%d", output_index);
        $finish;
    end

endmodule