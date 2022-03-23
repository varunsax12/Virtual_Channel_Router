// Testbench
// File Details
//    Author: Varun Saxena
//    GT id: 903562211

`timescale 10ns/1ps

module tb_select_vc();

    localparam NUM_VC = 4;
    localparam NUM_PORTS = 4;
    localparam PORT_BITS = $clog2(NUM_PORTS);
    localparam VC_BITS = $clog2(NUM_VC);

    logic [PORT_BITS-1:0] vc_direction [NUM_VC-1:0];
    logic [PORT_BITS-1:0] sel_direction;
    logic [VC_BITS-1:0]  vc_index;
    logic clk, reset;

    select_vc #(
        .NUM_VC(NUM_VC),
        .NUM_PORTS(NUM_PORTS)
    ) uut (
        .clk(clk),
        .reset(reset),
        .vc_direction(vc_direction),
        .sel_direction(sel_direction),
        .vc_index(vc_index)
    );

    always begin
        clk = 1; #10;
        clk = 0; #10;
    end

    initial begin
        @(negedge clk) reset = 1;
        @(negedge clk) reset = 0;
        vc_direction[0] = 2'b00;
        vc_direction[1] = 2'b00;
        vc_direction[2] = 2'b10;
        vc_direction[3] = 2'b10;
        sel_direction = 2'b10;
        #100;
        $display("%d", vc_index);
        $finish;
    end

endmodule