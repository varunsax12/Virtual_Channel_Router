// Description: Module to compute to the out port direction
// File Details
//    Author: Varun Saxena

// Assumptions:
//  1. Mesh structure with DOR XY
//  2. Ejection logic calculated outside block

// TODO:
//  1. Simplify logic to remove modulo and division operation

`include "VR_define.vh"

module route_compute # (
    parameter NUM_ROUTERS    = 16,
    parameter ROUTER_PER_ROW = 4,
    parameter DIR_BITS       = 3,
    parameter ROUTER_ID_BITS = $clog2(NUM_ROUTERS)
) (
    input logic [ROUTER_ID_BITS-1:0]    current_router, dest_router,
    output logic [DIR_BITS-1:0]         direction
);

    logic signed [ROUTER_ID_BITS-1:0]  x_hops, y_hops;
    always_comb begin
        x_hops = (dest_router % ROUTER_PER_ROW - current_router % ROUTER_PER_ROW);
        y_hops = (dest_router / ROUTER_PER_ROW - current_router / ROUTER_PER_ROW);
        if (current_router == dest_router)  direction = `EJECT;
        else if (x_hops > 0)                direction = `EAST;
        else if (x_hops < 0)                direction = `WEST;
        else if (y_hops > 0)                direction = `NORTH;
        else  if (y_hops < 0)               direction = `SOUTH;
    end

endmodule