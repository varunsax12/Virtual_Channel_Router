// Description: Router top testbench
// File Details
//    Author: Varun Saxena
//    GT id: 903562211

`timescale 10ns/1ns

`include "VR_define.vh"

module tb_vc_allocator;
    parameter NUM_PORTS = 5;
    parameter NUM_VCS = 4;
    parameter PORT_BITS = $clog2(NUM_PORTS);
    parameter VC_BITS = $clog2(NUM_VCS);
    reg clk, rstn;
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
        .vc_availability(vc_availability),
        .vc_index(vc_index),
        .vc_read_valid(vc_read_valid)
    );

    // for(genvar i=0; i<NUM_PORTS; i++) begin
    //     for(genvar j=0; j<NUM_VCS; j++) begin
    //         assign wv_allocated_ip_vcs[i*NUM_VCS+j] = allocated_ip_vcs[i*NUM_VCS+j];
    //         assign wv_dst_ports[i*NUM_VCS+j] = dst_port[i*NUM_VCS+j];
    //     end
    // end

    // initial begin
    //     //$monitor("requests[0]:%b dable[0]:%b, weight_mat[1][1]:%b",mta.requests[0], mta.dable[0],mta.weight_mat[1][1]);
    //     $monitor("\n\ntime:%0t,dst_port[0]:%b,dst_port[1]:%b,vc_availability=%b", $time,rt.dst_port[0],rt.dst_port[1],vc_availability,
    //     "\nrt.vca.available_op_vcs[0] for ipvc0:%b,rt.vca.available_op_vcs[1] for ipvc1:%b", rt.vca.available_op_vcs[0], rt.vca.available_op_vcs[1],
    //     "\nrt.vca.allocated_ip_vcs[0] for opvc0:%b,rt.vca.allocated_ip_vcs[1] for opvc1:%b", rt.vca.allocated_ip_vcs[0], rt.vca.allocated_ip_vcs[1],
    //     "\nrt.vca.allocated_ip_vcs[2] for opvc2:%b,rt.vca.allocated_ip_vcs[3] for opvc3:%b", rt.vca.allocated_ip_vcs[2], rt.vca.allocated_ip_vcs[3],
    //     "\nrt.vca.allocated_ip_vcs[4] for opvc4:%b,rt.vca.allocated_ip_vcs[5] for opvc5:%b", rt.vca.allocated_ip_vcs[4], rt.vca.allocated_ip_vcs[5],
    //     "\nrt.vca.allocated_ip_vcs[6] for opvc6:%b,rt.vca.allocated_ip_vcs[7] for opvc7:%b", rt.vca.allocated_ip_vcs[6], rt.vca.allocated_ip_vcs[7],
    //     "\nrt.vca.allocated_ip_vcs[8] for opvc8:%b,rt.vca.allocated_ip_vcs[9] for opvc9:%b", rt.vca.allocated_ip_vcs[8], rt.vca.allocated_ip_vcs[9],
    //     "\nrt.vca.allocated_ip_vcs[10] for opvc10:%b,rt.vca.allocated_ip_vcs[11] for opvc11:%b", rt.vca.allocated_ip_vcs[10], rt.vca.allocated_ip_vcs[11],
    //     "\nrt.vca.allocated_ip_vcs[12] for opvc12:%b,rt.vca.allocated_ip_vcs[13] for opvc13:%b", rt.vca.allocated_ip_vcs[12], rt.vca.allocated_ip_vcs[13],
    //     "\nrt.vca.allocated_ip_vcs[14] for opvc14:%b,rt.vca.allocated_ip_vcs[15] for opvc15:%b", rt.vca.allocated_ip_vcs[14], rt.vca.allocated_ip_vcs[15],
    //     "\nrt.vca.allocated_ip_vcs[16] for opvc16:%b,rt.vca.allocated_ip_vcs[17] for opvc17:%b", rt.vca.allocated_ip_vcs[16], rt.vca.allocated_ip_vcs[17],
    //     "\nrt.vca.allocated_ip_vcs[18] for opvc18:%b,rt.vca.allocated_ip_vcs[19] for opvc19:%b", rt.vca.allocated_ip_vcs[18], rt.vca.allocated_ip_vcs[19]);
    // end

    initial begin
        $dumpfile("test.vcd");
        $dumpvars;
        clk = 0;
        @(negedge clk) rstn = 0;
        @(negedge clk) rstn = 1;
        @(negedge clk) rstn = 0;
        // foreach(dst_port[i]) begin
        //     if(i==0 || i==1)
        //         if(i==0)
        //             dst_port[i] = 1; //00001
        //         else
        //             dst_port[i] = 8; //00010
        //     else
        //         dst_port[i] = 0;
        // end
        for (int i = 0; i < NUM_PORTS; ++i) begin
            for (int j = 0; j < NUM_VCS; ++j) begin
                rt.vc_buffer[i][j][`FLIT_DATA_WIDTH-1-:4] = $urandom%16;
                $display("Port = %d, VC = %d, dest = %d", i, j, rt.vc_buffer[i][j][`FLIT_DATA_WIDTH-1-:4]);
            end
        end
        foreach(vc_availability[i]) begin
            vc_availability[i] = 1;
        end
        for (int i = 0; i < 10; ++i) begin
            @(negedge clk);
            // @(negedge clk) begin
            //     vc_availability[0] = 0;
            // end
            for (int i = 0; i < NUM_PORTS; ++i) begin
                for (int j = 0; j < NUM_VCS; ++j) begin
                    $display("Port req, Port = %d, VC = %d, %b", i, j, rt.dst_port[i*NUM_VCS+j]);
                end
            end
            for (int i = 0; i < NUM_PORTS; ++i) begin
                for (int j = 0; j < NUM_VCS; ++j) begin
                    $display("VC alloc, %d, %b, %b", i, rt.vca.available_op_vcs[i*NUM_VCS+j], rt.allocated_ip_vcs[i*NUM_VCS+j]);
                end
            end
            for (int i = 0; i < NUM_PORTS; ++i) begin
                for (int j = 0; j < NUM_VCS; ++j) begin
                    $display("VC alloc..2, %d, %b", i, rt.vc_grants[i*NUM_VCS+j]);
                end
            end
            for (int i = 0; i < NUM_PORTS; ++i) begin
                $display("req2port , %d, %b", i, rt.port_req[i]);
            end
            for (int i = 0; i < NUM_PORTS; ++i) begin
                $display("SAlloc, %d, %b", i, rt.allocated_ports[i]);
            end
            for (int i = 0; i < NUM_PORTS; ++i) begin
                $display("vc index = %d, %b, %b", i, vc_index[i], vc_read_valid[i]);
            end
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
