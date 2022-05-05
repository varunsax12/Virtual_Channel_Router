// Description: Module for tb fifo
// File Details
//    Author: Varun Saxena

`timescale 10ns/1ps

`include "VR_define.vh"

module tb_fifo();

    logic clk, reset, push, pop, empty, full;
    logic [`FLIT_DATA_WIDTH-1:0]    indata, outdata;

    fifo uut(
        .clk(clk),
        .reset(reset),
        .push(push),
        .pop(pop),
        .empty(empty),
        .full(full),
        .indata(indata),
        .outdata(outdata)
    );

    always begin
        clk = 1; #10;
        clk = 0; #10;
    end

    initial begin
        $dumpfile("test.vcd");
        $dumpvars;
        @(negedge clk) reset = 1;
        @(negedge clk) reset = 0;
        for (int i = 0; i < 8; ++i) begin
            @(negedge clk) push = 1; indata = i;
        end
        @(negedge clk) push = 0;
        for (int i = 0; i < 8; ++i) begin
            @(negedge clk) pop = 1;
            @(posedge clk) $display("FIFO out data = %d\n", outdata);
        end
        $finish;
    end

endmodule