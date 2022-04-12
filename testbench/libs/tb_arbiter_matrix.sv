// Description: Matrix arbiter testbench
// Reference: M06-RouterMicroarchitecture in ECE6115, Prof. Tushar Krishna
// File Details
//    Author: Sandilya Balemarthy
//    GT id: 903482005

`timescale 10ns/1ns

module tb_arbiter_matrix;
    reg clk, reset;
    reg [2:0] requests;
    wire [2:0] grants;
    parameter NR = 3;
    
    arbiter_matrix #(.NUM_REQS(NR)) mta(.clk(clk), .reset(reset), .requests(requests), .grants(grants));
    
    initial begin
        #500 $finish;
    end
  
    initial begin
        //$monitor("requests[0]:%b dable[0]:%b, weight_mat[1][1]:%b",mta.requests[0], mta.dable[0],mta.weight_mat[1][1]);
        $monitor("\n\ngrants[0]:%b, grants[1]:%b, grants[2]:%b, time:%0t\nrequests[0]:%b, requests[1]:%b, requests[2]:%b, time:%0t\ndable[0]:%b, dable[1]:%b, dable[2]:%b, time:%0t\nweight_mat[0][0]:%b,weight_mat[0][1]:%b,weight_mat[0][2]:%b,\nweight_mat[1][0]:%b,weight_mat[1][1]:%b,weight_mat[1][2]:%b,\nweight_mat[2][0]:%b,weight_mat[2][1]:%b,weight_mat[2][2]:%b,time:%0t\n\n",grants[0],grants[1],grants[2],$time,requests[0],requests[1],requests[2],$time,mta.dable[0],mta.dable[1],mta.dable[2],$time,mta.weight_mat[0][0],mta.weight_mat[0][1],mta.weight_mat[0][2],mta.weight_mat[1][0],mta.weight_mat[1][1],mta.weight_mat[1][2],mta.weight_mat[2][0],mta.weight_mat[2][1],mta.weight_mat[2][2],$time);
    end
  
    initial begin
        $dumpfile("tb_arbiter_matrix.vcd");
        $dumpvars;
        clk = 0;
        @(negedge clk) reset = 1;
        @(negedge clk) reset = 0;
        requests = 7;
        #20
        requests = 3;
        #20
        requests = 5;
        #20
        requests = 0;
    end
  
    always begin
        #5 clk = !clk;
    end  
endmodule