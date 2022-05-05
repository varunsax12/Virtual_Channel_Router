// Description: Acyclic Round robin arbiter
// Reference: M06-RouterMicroarchitecture in ECE6115, Prof. Tushar Krishna
// File Details
//    Author: Varun Saxena

`timescale 10ns/1ns

module arbiter_round_robin #(
    parameter NUM_REQS = 4
) (
    // Standard inputs
    input                    clk, reset,
    // Requests signal
    input [NUM_REQS-1:0]     requests,
    // Grant/g_priority calculated
    output [NUM_REQS-1:0]    grants
);

    wire [NUM_REQS-1:0]     g_priority;
    wire [2*NUM_REQS:0]     carry;
    wire [NUM_REQS-1:0]     rb_grant, fp_grant;

    assign carry[0] = 0;
    // Place the round_robin block
    for (genvar i = 0; i < NUM_REQS; ++i) begin
        request_block rb (
            .carry_in   (carry[i]),
            .g_priority (g_priority[i]),
            .request    (requests[i]),
            .grant      (rb_grant[i]),
            .carry_out  (carry[i+1])
        );
    end
    // Place the fixed g_priority block
    for (genvar i = 0; i < NUM_REQS; ++i) begin
        fixed_priorty_block fp (
            .carry_in   (carry[NUM_REQS+i]),
            .request    (requests[i]),
            .grant      (fp_grant[i]),
            .carry_out  (carry[NUM_REQS+i+1])
        );
    end
    // OR to generate the final grant signal
    for (genvar i = 0; i < NUM_REQS; ++i) begin
        assign grants[i] = rb_grant[i] | fp_grant[i];
    end

    priority_block #(
        .NUM_REQS       (NUM_REQS)
    ) pb (
        .clk            (clk),
        .reset          (reset),
        .grants         (grants),
        .g_priority     (g_priority)
    );

endmodule

// Priority calculation and storage block
module priority_block #(
    parameter NUM_REQS = 4
) (
    input                   clk, reset,
    input [NUM_REQS-1:0]    grants,
    output [NUM_REQS-1:0]   g_priority
);

    reg [NUM_REQS-1:0] g_priority_state;

    always @(posedge clk) begin
        if (reset)
            g_priority_state <= 1;
        else begin
            if (|grants)
                g_priority_state <= {grants[NUM_REQS-2:0], grants[NUM_REQS-1]};
            // else latch the old g_priority again 
        end
    end

    assign g_priority = g_priority_state;
endmodule

// Block to calculate the grant based on priority and request
module request_block (
    input carry_in, g_priority, request,
    output grant, carry_out
);
    assign grant     = (g_priority | carry_in) & request;
    assign carry_out = (g_priority | carry_in) & (!request);
endmodule

// Block to calculate the grant based on request
module fixed_priorty_block (
    input carry_in, request,
    output grant, carry_out
);
    assign carry_out = (carry_in & !request);
    assign grant     = carry_in & request;
endmodule
