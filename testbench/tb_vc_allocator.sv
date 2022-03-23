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
    
    vc_allocator #(.NUM_PORTS(NUM_PORTS),.NUM_VCS(NUM_VCS)) vcasep (.clk(clk), 
    .reset(rstn), .dst_port(dst_port), .vc_availability(vc_availability),
    .allocated_ip_vcs(allocated_ip_vcs));

    initial begin
        #500 $finish;
    end

    initial begin
        //$monitor("requests[0]:%b dable[0]:%b, weight_mat[1][1]:%b",mta.requests[0], mta.dable[0],mta.weight_mat[1][1]);
        $monitor("\n\ndst_port[0]:%b,vc_availability=%b,vcasep.available_op_vcs[0]:%b,vcasep.available_op_vcs[1]:%b,vcasep.allocated_ip_vcs[0]:%b,vcasep.allocated_ip_vcs[1]:%b",dst_port[0],vc_availability,vcasep.available_op_vcs[0],vcasep.available_op_vcs[1],vcasep.allocated_ip_vcs[0],vcasep.allocated_ip_vcs[1]);
    end

    initial begin
        $dumpfile("tb_vc_allocator_separable.vcd");
        $dumpvars;
        clk = 0;
        @(negedge clk) rstn = 0;
        @(negedge clk) rstn = 1;
        foreach(dst_port[i]) begin
            if(i==0 || i==1)
                dst_port[i] = 3;
            else
                dst_port[i] = 0;
        end
        foreach(vc_availability[i]) begin
            vc_availability[i] = 1;
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
