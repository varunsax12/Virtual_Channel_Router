// Description: VC Separable allocator testbench
// Reference: M06-RouterMicroarchitecture in ECE6115, Prof. Tushar Krishna
// File Details
//    Author: Sandilya Balemarthy
//    GT id: 903482005

`timescale 10ns/1ns

module tb_vc_allocator;
    parameter NUM_PORTS = 5;
    parameter NUM_VCS = 4;
    reg clk, rstn;
    reg [NUM_PORTS-1:0] dst_port [NUM_VCS*NUM_PORTS-1:0];
    reg [NUM_VCS*NUM_PORTS-1:0] vc_availability;
    wire [NUM_VCS*NUM_PORTS-1:0] allocated_ip_vcs [NUM_VCS*NUM_PORTS-1:0];

    // Waveform compatible
    wire [NUM_VCS*NUM_PORTS-1:0] [NUM_PORTS-1:0] wv_dst_ports;
    wire [NUM_VCS*NUM_PORTS-1:0] [NUM_VCS*NUM_PORTS-1:0] wv_allocated_ip_vcs;

    vc_allocator #(.NUM_PORTS(NUM_PORTS),.NUM_VCS(NUM_VCS)) vcasep (.clk(clk), 
    .reset(rstn), .dst_port(dst_port), .vc_availability(vc_availability),
    .allocated_ip_vcs(allocated_ip_vcs));

        for(genvar i=0; i<NUM_PORTS; i++) begin
            for(genvar j=0; j<NUM_VCS; j++) begin
                assign wv_allocated_ip_vcs[i*NUM_VCS+j] = allocated_ip_vcs[i*NUM_VCS+j];
                assign wv_dst_ports[i*NUM_VCS+j] = dst_port[i*NUM_VCS+j];
            end
        end

    initial begin
        #5000 $finish;
    end

    // initial begin
    //     //$monitor("requests[0]:%b dable[0]:%b, weight_mat[1][1]:%b",mta.requests[0], mta.dable[0],mta.weight_mat[1][1]);
    //     $monitor("\n\ntime:%0t,dst_port[0]:%b,dst_port[1]:%b,vc_availability=%b", $time,dst_port[0],dst_port[1],vc_availability,
    //     "\nvcasep.available_op_vcs[0] for ipvc0:%b,vcasep.available_op_vcs[1] for ipvc1:%b", vcasep.available_op_vcs[0], vcasep.available_op_vcs[1],
    //     "\nvcasep.allocated_ip_vcs[0] for opvc0:%b,vcasep.allocated_ip_vcs[1] for opvc1:%b", vcasep.allocated_ip_vcs[0], vcasep.allocated_ip_vcs[1],
    //     "\nvcasep.allocated_ip_vcs[2] for opvc2:%b,vcasep.allocated_ip_vcs[3] for opvc3:%b", vcasep.allocated_ip_vcs[2], vcasep.allocated_ip_vcs[3],
    //     "\nvcasep.allocated_ip_vcs[4] for opvc4:%b,vcasep.allocated_ip_vcs[5] for opvc5:%b", vcasep.allocated_ip_vcs[4], vcasep.allocated_ip_vcs[5],
    //     "\nvcasep.allocated_ip_vcs[6] for opvc6:%b,vcasep.allocated_ip_vcs[7] for opvc7:%b", vcasep.allocated_ip_vcs[6], vcasep.allocated_ip_vcs[7],
    //     "\nvcasep.allocated_ip_vcs[8] for opvc8:%b,vcasep.allocated_ip_vcs[9] for opvc9:%b", vcasep.allocated_ip_vcs[8], vcasep.allocated_ip_vcs[9],
    //     "\nvcasep.allocated_ip_vcs[10] for opvc10:%b,vcasep.allocated_ip_vcs[11] for opvc11:%b", vcasep.allocated_ip_vcs[10], vcasep.allocated_ip_vcs[11],
    //     "\nvcasep.allocated_ip_vcs[12] for opvc12:%b,vcasep.allocated_ip_vcs[13] for opvc13:%b", vcasep.allocated_ip_vcs[12], vcasep.allocated_ip_vcs[13],
    //     "\nvcasep.allocated_ip_vcs[14] for opvc14:%b,vcasep.allocated_ip_vcs[15] for opvc15:%b", vcasep.allocated_ip_vcs[14], vcasep.allocated_ip_vcs[15],
    //     "\nvcasep.allocated_ip_vcs[16] for opvc16:%b,vcasep.allocated_ip_vcs[17] for opvc17:%b", vcasep.allocated_ip_vcs[16], vcasep.allocated_ip_vcs[17],
    //     "\nvcasep.allocated_ip_vcs[18] for opvc18:%b,vcasep.allocated_ip_vcs[19] for opvc19:%b", vcasep.allocated_ip_vcs[18], vcasep.allocated_ip_vcs[19]);
    // end

    always @(posedge clk) begin
        for (int i = 0; i < NUM_PORTS; ++i) begin
            for (int j = 0; j < NUM_VCS; ++j) begin
                $display ("Time = %d, Port=%d, VC=%d, available=%b, allocated=%b", $time, i, j, vcasep.available_op_vcs[i*NUM_VCS+j], vcasep.allocated_ip_vcs[i*NUM_VCS+j]);
            end
        end
        $display("\n\n");
    end

    initial begin
        $dumpfile("tb_vc_allocator_separable.vcd");
        $dumpvars;
        clk = 0;
        @(negedge clk) rstn = 0;
        @(negedge clk) rstn = 1;
        @(negedge clk) rstn = 0;
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
