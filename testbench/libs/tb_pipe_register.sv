// Testbench
// File Details
//    Author: Varun Saxena

`timescale 10ns/1ps

module tb_pipe_register ();

    logic clk, reset, enable;
    localparam DATAW = 4;
    logic [DATAW-1:0] in_data, out_data;

    pipe_register #(
        .DATAW(DATAW)
    ) uut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .in_data(in_data),
        .out_data(out_data)
    );

    always begin
        clk = 1; #10;
        clk = 0; #10;
    end

    initial begin
        $monitor("Time=%d, reset=%b, enable=%b, in_data=%b, out_data=%b", $time, reset, enable, in_data, out_data);
        @(negedge clk) reset = 1;
        @(negedge clk) reset = 0;
        in_data = 4'hF;
        enable = 1;
        @(negedge clk) reset = 1;
        #50;
        $finish;

    end

endmodule