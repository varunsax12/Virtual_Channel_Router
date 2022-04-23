// Description: Module for the switch allocator.
// Inputs: Which output ports do all VCs in the input port ask for
// File Details
//    Author: Varun Saxena
//    GT id: 903562211

module switch_allocator #(
    parameter NUM_PORTS = 4
) (
    input logic clk, reset,
    input logic [NUM_PORTS-1:0]  port_requests[NUM_PORTS-1:0],
    output logic [NUM_PORTS-1:0] allocated_ports[NUM_PORTS-1:0]
);

    allocator_top #(
        .NUM_REQS   (NUM_PORTS)
    ) sw_alloc (
        .clk        (clk),
        .reset      (reset),
        .requests   (port_requests),
        .grants     (allocated_ports)
    );

endmodule