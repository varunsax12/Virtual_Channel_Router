// Description: Module to compute the new vc_availability and upstream signals
// Reference: M06-RouterMicroarchitecture in ECE6115, Prof. Tushar Krishna
// File Details
//    Author: Sandilya Balemarthy

`timescale 10ns/1ns
`include "VR_define.vh"

/*
NOTES:
->ip buffers for each ip VC.
->ip buffer depth 
->min buffer depth: buffer turnaround time
    min need one buffer per VC.

->credits denote number of downstream flit buffers in output VC.

->Need to stop allowing vc_availability once the op VC has a fifo size of lesser than BUFFER_TURNAROUND_TIME
//Have buffer round trip parameter and use to set counter to 0.
//(if all VCs within port i have fifo size < round trip latency)
*/

module vc_availability #(
    parameter NUM_PORTS = 5,
    parameter NUM_VCS = 4,
    parameter BUFFER_DEPTH = 8,
    parameter CR_BITS = $clog2(BUFFER_DEPTH)+1
) (
    // Standard clock and reset signals
    input logic clk, 
    input logic reset,
    // Valid dst port signals
    input logic [NUM_VCS*NUM_PORTS-1:0]     vca_dst_valid,
    // Flit final destination ports as computed by route compute
    input logic  [NUM_PORTS-1:0]            vca_dst_port [NUM_VCS*NUM_PORTS-1:0],
    // Credits from down stream routers
    input logic                             dwnstr_credit_increment [NUM_PORTS-2:0][NUM_VCS-1:0],
    // Outports allocated for each ip port
    input logic  [NUM_PORTS-1:0]            sa_allocated_ports [NUM_PORTS-1:0],
    // Opport validity, used to verify the flits has crossed the switch traversal stage, critical for vc_availability
    input logic  [NUM_PORTS-1:0]            out_valid,
    // Opvcs allocated for each ip vcs
    input logic  [NUM_VCS*NUM_PORTS-1:0]    allocated_op_vcs [NUM_VCS*NUM_PORTS-1:0],
    // Latest vc availability based on down stream credit increments, allocated ports in the current router
    output logic [NUM_VCS*NUM_PORTS-1:0]    vc_availability,
    // Upstream credit increments based on flits released in current router
    output logic                            upstr_credit_increment [NUM_PORTS-2:0][NUM_VCS-1:0]
);
    // [clogs(fifo_depth)+1:0] credits [NUM_VCS-1:0];
    logic [CR_BITS-1:0] credits [NUM_PORTS-1:0] [NUM_VCS-1:0];

    // Credit system - (i - ip port requesting, ii - op port allocated)
    always_comb begin
        if(reset) begin
            // Re-initialize credits, signifies all VCs are available at the time of reset
            for(int i=0; i<NUM_PORTS; i=i+1) begin
                for(int j=0; j<NUM_VCS; j=j+1)
                    credits[i][j] = BUFFER_DEPTH;
            end
        end else begin

            // Credits and downstream credit decrement
            for(int i=0; i<NUM_PORTS; i=i+1) begin
                if(|sa_allocated_ports[i]) begin
                    for(int ii=0; ii<NUM_PORTS; ii=ii+1) begin
                        if(sa_allocated_ports[i][ii]) begin
                            // Decrement credits corresponding to op VC that was allocated, for local op VCs credits are always set to BUFFER DEPTH size.
                            if(ii!=0) begin
                                //Iterate over ip VC j of ip port i
                                for(int j=0; j<NUM_VCS; j=j+1) begin
                                    //Check for op VC jj allocated to ip VC j
                                    for(int jj=0; jj<NUM_VCS; jj=jj+1) begin
                                        if(allocated_op_vcs[i*NUM_VCS+j][ii*NUM_VCS+jj])
                                            credits[ii][jj] = credits[ii][jj] - 1; 
                                    end
                                end
                            end else begin
                                // For all local op VCs the credits are assumed to be empty.
                                for(int jj=0; jj<NUM_VCS; jj=jj+1)
                                    credits[ii][jj] = BUFFER_DEPTH;
                            end
                        end
                    end
                end
            end

            // Credits increment for each op VC
            for(int i=0; i<NUM_PORTS; i=i+1) begin
                if(i!=0) begin
                    for(int j=0; j<NUM_VCS; j=j+1) begin
                        if(dwnstr_credit_increment[i-1][j])
                            credits[i][j] = credits[i][j] + 1;
                    end
                end
            end
        end
    end

    // Upstream credit signal for each ip VC that has been allocated an op VC (this is indicated by sa_allocated_ports)
    for(genvar i=0; i<NUM_PORTS; i=i+1) begin
        if(i!=0) begin //For non-local ports
            for(genvar j=0; j<NUM_VCS; j=j+1) begin
                always_comb begin
                    if(|sa_allocated_ports[i]) begin
                        if(|allocated_op_vcs[i*NUM_VCS+j])
                            upstr_credit_increment[i-1][j] = 1;
                    end else begin
                        upstr_credit_increment[i-1][j] = 0;
                    end
                end
            end
        end
    end

    // Iterate over op port
    for(genvar ii=0; ii<NUM_PORTS; ii=ii+1) begin
        // Iterate over op VC
        for(genvar jj=0; jj<NUM_VCS; jj=jj+1) begin
            // Compute new vc_availability
            always_comb begin
                if(credits[ii][jj] == `ROUND_TRIP) begin
                    vc_availability[ii*NUM_VCS+jj] = 0;
                end else begin
                    vc_availability[ii*NUM_VCS+jj] = 1;
                end
            end
        end
    end

endmodule
