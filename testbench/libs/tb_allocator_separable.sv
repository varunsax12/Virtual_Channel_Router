// Description: Separable allocator testbench
// Reference: M06-RouterMicroarchitecture in ECE6115, Prof. Tushar Krishna
// File Details
//    Author: Sandilya Balemarthy

`timescale 10ns/1ns

module tb_allocator_separable;
    parameter NRS = 4;
    parameter NRQ = 4;
    reg clk, reset;
    reg [NRS-1:0] requests[NRQ-1:0];
    wire [NRS-1:0] grants[NRQ-1:0];
    
    allocator_separable #(.NUM_REQS(NRQ), .NUM_RESS(NRS)) spa(.clk(clk), .reset(reset), .requests(requests), .grants(grants));
    
    initial begin
        #500 $finish;
    end
    
    initial begin
        $dumpfile("tb_allocator_separable.vcd");
        $dumpvars;
        $monitor("grants[0]:%b grants[1]:%b grants[2]:%b grants[3]:%b\nrequests[0]:%b,requests[1]:%b,requests[2]:%b,requests[3]:%b\n",
        grants[0],grants[1],grants[2],grants[3],requests[0],requests[1],requests[2],requests[3]);

        clk = 0;
        @(negedge clk) reset = 1;
        @(negedge clk) reset = 0;
        foreach(requests[i])
            requests[i] = 0;
        //Pattern-1
        requests[0] = 7;
        requests[1] = 5;
        requests[2] = 4;
        requests[3] = 5;
        #20
        //Pattern-2
        requests[0] = 7;
        requests[1] = 7;
        requests[2] = 7;
        requests[3] = 7;
        #20
        //Pattern-3
        requests[0] = 5;
        requests[1] = 5;
        requests[2] = 5;
        requests[3] = 5;
        #20
        foreach(requests[i])
            requests[i] = 0;
    end
    
    always begin
        #5 clk = !clk;
    end  
endmodule