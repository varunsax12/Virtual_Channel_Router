// Description: Module to select one VC for a given outport
// File Details
//    Author: Varun Saxena
//    GT id: 903562211

`include "VR_define.vh"

module select_vc #(
    parameter NUM_VC = 4,
    parameter NUM_PORTS = 4,
    parameter PORT_BITS = $clog2(NUM_PORTS),
    parameter VC_BITS = $clog2(NUM_VC)
) (
    // Standard inputs
    input logic clk, reset,
    // Out direction of each VC
    input logic [NUM_PORTS-1:0] vc_direction [NUM_VC-1:0],
    // Selected direction for this input port
    input logic [NUM_PORTS-1:0] sel_direction,
    // Index of VC to dispatch
    output logic [VC_BITS-1:0]  vc_index
);

    // Mask array for VCs with same direction as sel_direction
    logic [NUM_VC-1:0] mask;
    for (genvar i = 0; i < NUM_VC; ++i) begin
        assign mask[i] = vc_direction[i] == sel_direction;
    end

    generate
        if (`SELECT_VC_ARBITRATE == 1) begin
            // Arbitrate for a single VC
            logic [NUM_VC-1:0] one_hot_index;
            arbiter_top #(
                .NUM_REQS   (NUM_VC)
            ) mask_ab (
                .clk        (clk),
                .reset      (reset),
                .requests   (mask),
                .grants     (one_hot_index)
            );

            // Convert the one hot index into index
            one_hot_2_index #(
                .NUM_BITS       (NUM_VC)
            ) vc_index (
                .one_hot_input  (one_hot_index),
                .output_index   (vc_index)
            );
        end
        else begin
            // Use encoder to select value
            // Used for lesser area
            always_comb begin
                for (int i = 0; i < NUM_VC; ++i) begin
                    if (mask[i] == 1) begin
                        vc_index = i;
                    end
                end
            end
        end
    endgenerate

endmodule