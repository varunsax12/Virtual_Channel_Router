// Description: Topology top testbench
// File Details
//    Author: Varun Saxena
//    GT id: 903562211

`timescale 10ns/1ns
`include "VR_define.vh"

module tb_topology();

    localparam ROW_COUNT = 5;
    localparam COL_COUNT = 5;
    localparam NUM_VC    = 4;
    localparam NUM_ROUTERS = ROW_COUNT * COL_COUNT;
    localparam ROUTER_ID_BITS = $clog2(NUM_ROUTERS);
    localparam VC_BITS = $clog2(NUM_VC);

    logic clk, reset;
    logic [NUM_ROUTERS-1:0]        nic_output_valid;
    logic [`FLIT_DATA_WIDTH-1:0]    nic_output_data     [NUM_ROUTERS-1:0];
    logic [NUM_ROUTERS-1:0]        nic_input_valid;
    logic [`FLIT_DATA_WIDTH-1:0]    nic_input_data      [NUM_ROUTERS-1:0];

    torus_topology #(
        .ROW_COUNT(ROW_COUNT),
        .COL_COUNT(COL_COUNT),
        .NUM_VC(NUM_VC)
    ) trt (
        .clk(clk),
        .reset(reset),
        .nic_output_valid(nic_output_valid),
        .nic_output_data(nic_output_data),
        .nic_input_valid(nic_input_valid),
        .nic_input_data(nic_input_data)
    );

    task display();
        $display("\n\n********************Time = %0d***********", $time);
        $display("\nInput data");
        for (int i = 0; i < NUM_ROUTERS; ++i) begin
            $display("\tRouter=%0d, Dest=%0d, valid=%b, data=%b", i, nic_output_data [i][`FLIT_DATA_WIDTH-VC_BITS-1-:ROUTER_ID_BITS], nic_output_valid[i], nic_output_data[i]);
        end
        $display("\nOutput data");
        for (int i = 0; i < NUM_ROUTERS; ++i) begin
            $display("\tRouter=%0d, valid=%b, data=%b", i, nic_input_valid[i], nic_input_data[i]);
        end
    endtask

    task clear_inputs();
        for (int i = 0; i < NUM_ROUTERS; ++i) begin
                nic_output_valid[i] = 0;
                nic_output_data [i] = 0;
        end
    endtask

    always @(negedge clk) begin
        display();
    end

    initial begin
        $dumpfile("test.vcd");
        $dumpvars;
        clk = 0;
        @(negedge clk) reset = 0;
        @(negedge clk) reset = 1;
        @(negedge clk) reset = 0;

        for (int j = 0; j < NUM_ROUTERS; ++j) begin
            @(negedge clk) clear_inputs();
            nic_output_valid[j] = 1;
            nic_output_data [j] = 0;
            nic_output_data [j][`FLIT_DATA_WIDTH-VC_BITS-1-:ROUTER_ID_BITS] |= $urandom()%NUM_ROUTERS;
            nic_output_data [j] |= $urandom()%2048; // create unique identifier to track the flit
        end
        @(negedge clk) clear_inputs();
        for (int j = 0; j < 100; ++j) begin
            @(negedge clk);
        end
        $finish;
    end

    always begin
        #10 clk = !clk;
    end

endmodule