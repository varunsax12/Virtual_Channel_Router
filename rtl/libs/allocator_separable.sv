// Description: Separable allocator design
// Reference: M06-RouterMicroarchitecture in ECE6115, Prof. Tushar Krishna
// File Details
//    Author: Sandilya Balemarthy
//    GT id: 903482005

`timescale 10ns/1ns

module allocator_separable #(
    parameter NUM_REQS = 4,
    parameter NUM_RESS = 3
) (
    // Standard
    input wire                 clk,
    input wire                 reset,
    // 'NUM_RESS' requests for each requestor (out of NUM_REQS)
    input wire  [NUM_RESS-1:0] requests [NUM_REQS-1:0],
    // 'NUM_REQS' grants for each resource (out of NUM_RESS)
    output wire [NUM_RESS-1:0] grants   [NUM_REQS-1:0]
);

    // Input port grants
    logic [NUM_RESS-1:0] ip_grants      [NUM_REQS-1:0];
    // Transform input port grants to the output port requestor format
    logic [NUM_REQS-1:0] bunch_ip_grants[NUM_RESS-1:0];

    // First stage: Choose one VC per input port
    for(genvar i=0; i<NUM_REQS; i++) begin
        arbiter_top #(
            .NUM_REQS   (NUM_RESS)
        ) select_vc (
            .clk        (clk),
            .reset      (reset),
            .requests   (requests[i]),
            .grants     (ip_grants[i])
        );
    end
  
    // Bunch input port grants
    for(genvar i=0; i<NUM_RESS; i++) begin
        for(genvar j=0; j<NUM_REQS; j++) begin
            assign bunch_ip_grants[i][j] = ip_grants[j][i];
        end
    end
  
    // Second stage: Choose one input port per output port
    logic [NUM_REQS-1:0] bunch_op_grants [NUM_RESS-1:0];
    for(genvar i=0; i<NUM_RESS; i++) begin
        arbiter_top #(
            .NUM_REQS   (NUM_REQS)
        ) select_ip (
            .clk        (clk),
            .reset      (reset),
            .requests   (bunch_ip_grants[i]),
            .grants     (bunch_op_grants[i])
        );
    end

    // Re-arrange block
    for(genvar i=0; i<NUM_REQS; i=i+1) begin : grantstop
        for(genvar j=0; j<NUM_RESS; j=j+1) begin : grantsbottom
            assign grants[i][j] = bunch_op_grants[j][i];
        end
    end

endmodule
