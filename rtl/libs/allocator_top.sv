// Description: Top module to select allocator type

`include "VR_define.vh"

module allocator_top #(
    parameter NUM_REQS = 4,
    parameter NUM_RESS = NUM_REQS
) (
    // Standard
    input wire                 clk,
    input wire                 reset,
    // 'NUM_RESS' requests for each requestor (out of NUM_REQS)
    input wire  [NUM_RESS-1:0] requests [NUM_REQS-1:0],
    // 'NUM_REQS' grants for each resource (out of NUM_RESS)
    output wire [NUM_RESS-1:0] grants [NUM_REQS-1:0]
);
    if (`ALLOCATOR_TYPE == `WAVEFRONT_ALLOCATOR) begin
        allocator_wavefront #(
            .NUM_REQS(NUM_REQS),
            .NUM_RESS(NUM_RESS)
        ) allocator (
            .clk(clk),
            .reset(reset),
            .requests(requests),
            .grants(grants)
        );
    end
    else begin
        allocator_separable #(
            .NUM_REQS(NUM_REQS),
            .NUM_RESS(NUM_RESS)
        ) allocator (
            .clk(clk),
            .reset(reset),
            .requests(requests),
            .grants(grants)
        );
    end

endmodule