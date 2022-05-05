// Description: VC Separable allocator design
// Reference: M06-RouterMicroarchitecture in ECE6115, Prof. Tushar Krishna
// File Details
//    Author: Sandilya Balemarthy

`timescale 10ns/1ns

module vc_allocator #(
    parameter NUM_PORTS = 5,
    parameter NUM_VCS = 4
) (
    // Standard
    input wire clk, reset,
    input wire   [NUM_VCS*NUM_PORTS-1:0] dst_valid,
    input wire   [NUM_PORTS-1:0]         dst_port         [NUM_VCS*NUM_PORTS-1:0],
    input wire   [NUM_VCS*NUM_PORTS-1:0] vc_availability,
    output logic [NUM_VCS*NUM_PORTS-1:0] allocated_op_vcs [NUM_VCS*NUM_PORTS-1:0]
);
    // Compute potential target o/p VCs for each i/p VC based on the dst port for that i/p VC
    logic [NUM_VCS*NUM_PORTS-1:0] cand_op_vcs [NUM_VCS*NUM_PORTS-1:0];
    for(genvar i=0; i<NUM_PORTS; i=i+1) begin
        for(genvar j=0; j<NUM_VCS; j=j+1) begin
            for(genvar ii=0; ii<NUM_PORTS; ii=ii+1) begin
                for(genvar jj=0; jj<NUM_VCS; jj=jj+1) begin
                    //assign the dst port value for all cand_op_vcs for that o/p port ii
                    assign cand_op_vcs[i*NUM_VCS+j][ii*NUM_VCS+jj] = dst_port[i*NUM_VCS+j][ii] && dst_valid[i*NUM_VCS+j];
                end
            end
        end
    end

    // Bitwise AND of potential o/p VCs requested with vc_availability
    logic [NUM_VCS*NUM_PORTS-1:0] available_op_vcs [NUM_VCS*NUM_PORTS-1:0];
    for(genvar i=0; i<NUM_PORTS; i=i+1) begin
        for(genvar j=0; j<NUM_VCS; j=j+1) begin
            assign available_op_vcs[i*NUM_VCS+j] = cand_op_vcs[i*NUM_VCS+j] & vc_availability;
        end
    end

    // Feed the avaialble_op_vcs array of vectors to the allocator and obtain the allocated_ip_vcs array of vectors
    allocator_top #(
        .NUM_REQS   (NUM_PORTS*NUM_VCS),
        .NUM_RESS   (NUM_PORTS*NUM_VCS)
    ) atop(
        .clk        (clk),
        .reset      (reset),
        .requests   (available_op_vcs),
        .grants     (allocated_op_vcs)
    );

endmodule