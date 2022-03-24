// Description: Router top testbench
// File Details
//    Author: Varun Saxena
//    GT id: 903562211

`timescale 10ns/1ns

module tb_vc_allocator;
    parameter NUM_PORTS = 5;
    parameter NUM_VCS = 4;
    parameter PORT_BITS = $clog2(NUM_PORTS);
    parameter VC_BITS = $clog2(NUM_VCS);
    reg clk, rstn;
    reg [NUM_PORTS-1:0] dst_port [NUM_VCS*NUM_PORTS-1:0];
    reg [NUM_VCS*NUM_PORTS-1:0] vc_availability;
    wire [NUM_VCS*NUM_PORTS-1:0] allocated_ip_vcs [NUM_VCS*NUM_PORTS-1:0];
    logic   [VC_BITS-1:0]          vc_index [NUM_PORTS-1:0];
    logic   [NUM_PORTS-1:0]        vc_read_valid;

    // Waveform compatible
    wire [NUM_VCS*NUM_PORTS-1:0] [NUM_PORTS-1:0] wv_dst_ports;
    wire [NUM_VCS*NUM_PORTS-1:0] [NUM_VCS*NUM_PORTS-1:0] wv_allocated_ip_vcs;

    router_top #(
        .NUM_PORTS(NUM_PORTS),
        .NUM_VC(NUM_VCS)
    ) rt (
        .clk(clk),
        .reset(rstn),
        .dst_port(dst_port),
        .vc_availability(vc_availability),
        .vc_index(vc_index),
        .vc_read_valid(vc_read_valid)
    );

    for(genvar i=0; i<NUM_PORTS; i++) begin
        for(genvar j=0; j<NUM_VCS; j++) begin
            assign wv_allocated_ip_vcs[i*NUM_VCS+j] = allocated_ip_vcs[i*NUM_VCS+j];
            assign wv_dst_ports[i*NUM_VCS+j] = dst_port[i*NUM_VCS+j];
        end
    end

    initial begin
        #5000 $finish;
    end

    initial begin
        $dumpfile("test.vcd");
        $dumpvars;
        clk = 0;
        @(negedge clk) rstn = 0;
        @(negedge clk) rstn = 1;
        foreach(dst_port[i]) begin
            if(i==0 || i==1)
                if(i==0)
                    dst_port[i] = 1; //00001
                else
                    dst_port[i] = 8; //00010
            else
                dst_port[i] = 0;
        end
        foreach(vc_availability[i]) begin
            vc_availability[i] = 1;
        end
        #20
        @(negedge clk) begin
            vc_availability[0] = 0;
        end
        for (int i = 0; i < NUM_PORTS; ++i) begin
            for (int j = 0; j < NUM_VCS; ++j) begin
                $display("Port req, Port = %d, VC = %d, %b", i, j, dst_port[i*NUM_VCS+j]);
            end
        end
        for (int i = 0; i < NUM_PORTS; ++i) begin
            for (int j = 0; j < NUM_VCS; ++j) begin
                $display("VC alloc, %d, %b", i, rt.allocated_ip_vcs[i*NUM_VCS+j]);
            end
        end
        for (int i = 0; i < NUM_PORTS; ++i) begin
            for (int j = 0; j < NUM_VCS; ++j) begin
                $display("VC alloc..2, %d, %b", i, rt.vc_grants[i*NUM_VCS+j]);
            end
        end
        for (int i = 0; i < NUM_PORTS; ++i) begin
            $display("SAlloc, %d, %b", i, rt.allocated_ports[i]);
        end
        for (int i = 0; i < NUM_PORTS; ++i) begin
            $display("vc index = %d, %b, %b", i, vc_index[i], vc_read_valid[i]);
        end
        $finish;
        //#20
        //foreach(dst_port[i]) begin
        //    dst_port[i] = 0;
        //end
        //foreach(vc_availability[i]) begin
        //    vc_availability[i] = 0;
        //end
    end

    always begin
        #5 clk = !clk;
    end

endmodule
