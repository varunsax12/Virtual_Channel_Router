// Description: VC Separable allocator testbench
// Reference: M06-RouterMicroarchitecture in ECE6115, Prof. Tushar Krishna
// File Details
//    Author: Sandilya Balemarthy

`timescale 10ns/1ns

module tb_vc_allocator;
    parameter NUM_PORTS = 5;
    parameter NUM_VCS = 4;
    reg clk, reset;
    reg [NUM_PORTS-1:0] dst_port [NUM_VCS*NUM_PORTS-1:0];
    reg [NUM_VCS*NUM_PORTS-1:0] vc_availability;
    wire [NUM_VCS*NUM_PORTS-1:0] allocated_op_vcs [NUM_VCS*NUM_PORTS-1:0];

    // Waveform compatible
    wire [NUM_VCS*NUM_PORTS-1:0] [NUM_PORTS-1:0] wv_dst_ports;
    wire [NUM_VCS*NUM_PORTS-1:0] [NUM_VCS*NUM_PORTS-1:0] wv_allocated_op_vcs;

    vc_allocator #(.NUM_PORTS(NUM_PORTS),.NUM_VCS(NUM_VCS)) vcasep (.clk(clk), 
    .reset(reset), .dst_port(dst_port), .vc_availability(vc_availability),
    .allocated_op_vcs(allocated_op_vcs));

    for(genvar i=0; i<NUM_PORTS; i++) begin
        for(genvar j=0; j<NUM_VCS; j++) begin
            assign wv_allocated_op_vcs[i*NUM_VCS+j] = allocated_op_vcs[i*NUM_VCS+j];
            assign wv_dst_ports[i*NUM_VCS+j] = dst_port[i*NUM_VCS+j];
        end
    end

    initial begin
        #5000 $finish;
    end

    always @(posedge clk) begin
        for (int i = 0; i < NUM_PORTS; ++i) begin
            for (int j = 0; j < NUM_VCS; ++j) begin
                $display ("Time = %0d, Port=%0d, VC=%0d, available=%0b, allocated=%0b", $time, i, j, vcasep.available_op_vcs[i*NUM_VCS+j], vcasep.allocated_op_vcs[i*NUM_VCS+j]);
            end
        end
        $display("\n\n");
    end

    initial begin
        $dumpfile("tb_vc_allocator_separable.vcd");
        $dumpvars;
        clk = 0;
        @(negedge clk) reset = 0;
        @(negedge clk) reset = 1;
        @(negedge clk) reset = 0;
        foreach(dst_port[i]) begin
            dst_port[i] = 1 << $urandom%5;
        end
        foreach(vc_availability[i]) begin
            vc_availability[i] = 1;
        end
        #20
        @(negedge clk) begin
            vc_availability[0] = 0;
        end
    end

    always begin
        #5 clk = !clk;
    end

endmodule
