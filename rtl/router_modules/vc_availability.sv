// Description: Module to compute the new vc_availability and upstream signals
// Reference: M06-RouterMicroarchitecture in ECE6115, Prof. Tushar Krishna
// File Details
//    Author: Sandilya Balemarthy
//    GT id: 903482005

`timescale 10ns/1ns

module vc_availability #(
    parameter NUM_PORTS = 5,
    parameter NUM_VCS = 4
) (
    // Standard clock and reset signals
    input logic clk, 
    input logic reset,
    // Valid dst port signals
    input logic [NUM_VCS*NUM_PORTS-1:0]     vca_dst_valid,
    // Flit final destination ports as computed by route compute
    input logic  [NUM_PORTS-1:0]            vca_dst_port [NUM_VCS*NUM_PORTS-1:0],
    // Credits from down stream routers
    input logic  [NUM_PORTS-2:0]            dwnstr_credit_increment,
    // Outports allocated for each ip port
    input logic  [NUM_PORTS-1:0]            sa_allocated_ports [NUM_PORTS-1:0],
    // Opport validity, used to verify the flits has crossed the switch traversal stage, critical for vc_availability
    input logic  [NUM_PORTS-1:0]            out_valid,
    // Opvcs allocated for each ip vcs
    input logic  [NUM_VCS*NUM_PORTS-1:0]    allocated_op_vcs [NUM_VCS*NUM_PORTS-1:0],
    // Latest vc availability based on down stream credit increments, allocated ports in the current router
    output logic [NUM_VCS*NUM_PORTS-1:0]    vc_availability,
    // Upstream credit increments based on flits released in current router
    output logic [NUM_PORTS-2:0]            upstr_credit_increment
);

    parameter VC_BITS = $clog2(NUM_VCS)+1;
    logic [VC_BITS-1:0] credits [NUM_PORTS-1:0];
 
    // Credit system - (i - ip port requesting, ii - op port allocated)
    always_comb begin
        if(reset) begin
            // Re-initialize credits, signifies all VCs are available at the time of reset
            for(int ii=0; ii<NUM_PORTS; ii=ii+1)
                credits[ii] = NUM_VCS;
        end else begin
            //Initialize upstr credit increment:
            for(int i=0; i<NUM_PORTS; i=i+1) begin
                if(i!=0)
                    upstr_credit_increment[i-1] = 0;
            end
            
            // Credit decrement
            for(int i=0; i<NUM_PORTS; i=i+1) begin
                if(|sa_allocated_ports[i]) begin
                    for(int ii=0; ii<NUM_PORTS; ii=ii+1) begin
                        if(sa_allocated_ports[i][ii]) begin
                            // Upstream credits for ip ports that have been allocated an op port
                            //For non-local ports, send an increment on allocation
                            if(i!=0)
                                upstr_credit_increment[i-1] = 1;
                            
                            // Downstream credit decrement when an allocation is made
                            //&& |(vca_dst_valid[i*NUM_VCS+:NUM_VCS])
                            if(ii!=0) begin
                                credits[ii] = credits[ii] - 1;
                            end else begin
                                credits[ii] = NUM_VCS; //Always full for local credits, infinite drain
                            end
                        end
                    end
                end                    
            end

            // Credit increment
            for(int ii=0; ii<NUM_PORTS; ii=ii+1) begin
                if(dwnstr_credit_increment[ii])
                    credits[ii] = credits[ii] + 1;
            end
        end
    end

    logic [2**VC_BITS-1:0] credits_one_hot [NUM_PORTS-1:0];    
    // Compute new vc_availability
    for(genvar ii=0; ii<NUM_PORTS; ii=ii+1) begin
        index_2_one_hot #(
            .NUM_BITS              (VC_BITS)
        ) idx2oh (
            .index(credits[ii]),
            .out_one_hot(credits_one_hot[ii])
        );
    end

    logic [NUM_VCS-1:0] vcs_per_port [NUM_PORTS-1:0];
    logic counter;
    always_comb begin
        for(int i=0; i<NUM_PORTS; i=i+1) begin
            counter = 0;
            for(int j=0; j<NUM_VCS; j=j+1) begin
                if(credits_one_hot[i][j] && (counter==0)) begin
                    counter = 1;
                end

                if(counter==0) begin
                    vcs_per_port[i][j] = 1;
                end else begin
                    vcs_per_port[i][j] = 0;
                end
            end
        end
    end

    // Compute new vc_availability
    for(genvar ii=0; ii<NUM_PORTS; ii=ii+1) begin   
        assign vc_availability[ii*NUM_VCS+:NUM_VCS] = vcs_per_port[ii];
    end

endmodule
