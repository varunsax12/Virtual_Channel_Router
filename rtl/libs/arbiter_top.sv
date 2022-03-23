// Description: Top module to select arbiter type

`include "VR_define.vh"

module arbiter_top #(
  parameter NUM_REQS = 3
) (
  // Standard
  input wire                 clk,
  input wire                 reset,
  // Requests to the arbiter
  input wire  [NUM_REQS-1:0] requests,
  // Grants from the arbiter
  output wire [NUM_REQS-1:0] grants
);

    if (`ARBITER_TYPE == `ROUND_ROBIN_ARBITER) begin
        arbiter_round_robin #(
            .NUM_REQS(NUM_REQS)
        ) arbiter (
            .clk(clk),
            .reset(reset),
            .requests(requests),
            .grants(grants)
        );
    end
    else begin
        arbiter_matrix #(
            .NUM_REQS(NUM_REQS)
        ) arbiter (
            .clk(clk),
            .reset(reset),
            .requests(requests),
            .grants(grants)
        );
    end

endmodule