// Description: Separable allocator testbench
// Reference: M06-RouterMicroarchitecture in ECE6115, Prof. Tushar Krishna
// File Details
//    Author: Sandilya Balemarthy
//    GT id: 903482005

`timescale 10ns/1ns

module tb_allocator_separable;
  parameter NRS = 3;
  parameter NRQ = 4;
  reg clk, rstn;
  reg [NRS-1:0] requests[NRQ-1:0];
  wire [NRQ-1:0] grants[NRS-1:0];
  
  allocator_separable #(.NUM_REQS(NRQ), .NUM_RESS(NRS)) spa(.clk(clk), .reset(rstn), .requests(requests), .grants(grants));
  
  initial begin
    #500 $finish;
  end
  
  initial begin
    $dumpfile("tb_allocator_separable.vcd");
    $dumpvars;
    clk = 0;
    @(negedge clk) rstn = 0;
    @(negedge clk) rstn = 1;
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