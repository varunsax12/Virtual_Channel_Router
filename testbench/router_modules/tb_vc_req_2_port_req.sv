// Testbench for mapper between VC alloc and SA
// File Details
//    Author: Varun Saxena

`timescale 10ns/1ps

module tb_vc_req_2_port_req();

    localparam NUM_PORTS = 2;
    localparam NUM_VC    = 2;
    logic [NUM_PORTS*NUM_VC-1:0][NUM_PORTS*NUM_VC-1:0] vc_grants;
    logic [NUM_PORTS-1:0]       port_req  [NUM_PORTS-1:0];

    vc_req_2_port_req #(
        .NUM_PORTS(NUM_PORTS),
        .NUM_VC(NUM_VC)
    ) uut (
        .vc_grants(vc_grants),
        .port_req(port_req)
    );

    initial begin
        $dumpfile("test.vcd");
        $dumpvars;
        vc_grants[0] = 1;
        vc_grants[1] = 4;
        vc_grants[2] = 2;
        vc_grants[3] = 8;
        for (int i = 0; i < NUM_PORTS*NUM_VC; ++i) begin
            // vc_grants[i] = 2**i;
            $display("In, %d, %b", i, vc_grants[i]);
        end
        #100;
        for (int i = 0; i < NUM_PORTS; ++i) begin
            $display("Out, %d, %b", i, port_req[i]);
        end
        $finish;
    end

endmodule