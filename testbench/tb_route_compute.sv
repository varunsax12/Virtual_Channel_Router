// Testbench
// File Details
//    Author: Varun Saxena
//    GT id: 903562211

`timescale 10ns/1ps

module tb_route_compute();

    localparam NUM_ROUTERS = 16;
    localparam ROUTER_PER_ROW = 4;
    localparam ROUTER_ID_BITS = $clog2(NUM_ROUTERS);

    logic [ROUTER_ID_BITS-1:0]    current_router, dest_router;
    logic [1:0]                   direction;

    route_compute # (
        .NUM_ROUTERS(NUM_ROUTERS),
        .ROUTER_PER_ROW(ROUTER_PER_ROW)
    ) uut (
        .current_router(current_router),
        .dest_router(dest_router),
        .direction(direction)
    );

    initial begin
        current_router = 5;
        dest_router = 8;
        #10;
        $display("%b", direction);
    end

endmodule