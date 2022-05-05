// Testbench for round robin arbiter
// File Details
//    Author: Varun Saxena

`timescale 10ns/1ns

module tb_allocator_wavefront();

    localparam NUM_REQS = 4;
    localparam NUM_RESS = NUM_REQS;
    logic clk, reset;
    logic [NUM_REQS-1:0] requests [NUM_REQS-1:0];
    logic [NUM_REQS-1:0] grant [NUM_RESS-1:0];

    allocator_wavefront #(
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
        $monitor("Time=%0d, Requests = %b %b %b %b, Grants = %b %b %b %b", $time, requests[0], requests[1], requests[2], requests[3], grant[0], grant[1], grant[2], grant[3]);
        @(negedge clk); reset = 1;
        @(negedge clk); reset = 0;
        requests[0] = 15;
        requests[1] = 7;
        requests[2] = 7;
        requests[3] = 15;

        #100;
        $finish;
    end

endmodule