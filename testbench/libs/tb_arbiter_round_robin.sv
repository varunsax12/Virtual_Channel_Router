// Testbench for round robin arbiter
// File Details
//    Author: Varun Saxena
//    GT id: 903562211

`timescale 10ns/1ns

module tb_arbiter_round_robin();

    localparam NUM_REQS = 4;
    logic clk, reset;
    logic [NUM_REQS-1:0] requests;
    logic [NUM_REQS-1:0] grant;

    arbiter_round_robin #(
        .NUM_REQS(NUM_REQS)
    ) uut (
        .clk(clk),
        .reset(reset),
        .requests(requests),
        .grants(grant)
    );

    always begin
        clk = 1; #10;
        clk = 0; #10;
    end

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, uut);
        $monitor("Time = %0d, Request = %b, Grants = %b", $time, requests, grant);
        @(negedge clk); reset = 1;
        @(negedge clk); reset = 0;
        requests = {NUM_REQS{1'b1}};

        #200;
        $finish;
    end

endmodule