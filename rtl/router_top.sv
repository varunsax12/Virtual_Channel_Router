// Description: Module for the router top
// File Details
//    Author: Varun Saxena
//    GT id: 903562211

module router_top #(
    parameter NUM_PORTS = 5,
    parameter NUM_VC    = 4,
    parameter NUM_ROUTERS = 16,
    parameter ROUTER_PER_ROW = 4,
    parameter ROUTER_ID = 0,
    parameter ROUTER_ID_BITS = $clog2(NUM_ROUTERS),
    parameter PORT_BITS = $clog2(NUM_PORTS),
    parameter VC_BITS = $clog2(NUM_VC)
) (
    input  logic   clk, reset,
    input  logic   [NUM_VC*NUM_PORTS-1:0] vc_availability,
    output logic   [VC_BITS-1:0]          vc_index [NUM_PORTS-1:0],
    output logic   [NUM_PORTS-1:0]        vc_read_valid
);

    /************************************
    *          VC                       *
    ************************************/
    reg [`FLIT_DATA_WIDTH-1:0]      vc_buffer [NUM_PORTS-1:0][NUM_VC-1:0];


    /************************************
    *          Route compute            *
    ************************************/

    logic   [NUM_PORTS-1:0]        dst_port [NUM_VC*NUM_PORTS-1:0];

    localparam DIR_BITS = 3; // N, S, W, E, Eject
    localparam DIR_ONE_HOT = 2**DIR_BITS;
    for (genvar i = 0; i < NUM_PORTS; ++i) begin
        for (genvar j = 0; j < NUM_VC; ++j) begin
            logic [DIR_BITS-1:0] vc_direction;
            route_compute # (
                .NUM_ROUTERS(NUM_ROUTERS),
                .ROUTER_PER_ROW(ROUTER_PER_ROW)
            ) rc (
                .current_router(ROUTER_ID_BITS'(ROUTER_ID)),
                .dest_router(vc_buffer[i][j][`FLIT_DATA_WIDTH-1-:ROUTER_ID_BITS]),
                .direction(vc_direction)
            );

            // One hot encode the direction
            logic [DIR_ONE_HOT-1:0]  one_hot_direction;
            index_2_one_hot #(
                .NUM_BITS(DIR_BITS)
            ) dir2port (
                .index(vc_direction),
                .out_one_hot(one_hot_direction)
            );
            assign dst_port[i*NUM_VC+j] = one_hot_direction[NUM_PORTS-1:0];
        end
    end

    /************************************
    *       VC Allocation              *
    ************************************/

    // Output VC allocation
    logic [NUM_VC*NUM_PORTS-1:0] allocated_ip_vcs [NUM_VC*NUM_PORTS-1:0];
    vc_allocator #(
        .NUM_PORTS(NUM_PORTS),
        .NUM_VCS(NUM_VC)
    ) vca (
        .clk(clk),
        .reset(reset),
        .dst_port(dst_port),
        .vc_availability(vc_availability),
        .allocated_ip_vcs(allocated_ip_vcs)
    );

    logic   [NUM_PORTS-1:0]        vc_direction [NUM_PORTS-1:0][NUM_VC-1:0];
    // Convert the 2D array of dst port into 3D array splitting across i/p VC and port
    for (genvar i = 0; i < NUM_PORTS; ++i) begin
        assign vc_direction[i] = dst_port[(i+1)*NUM_VC-1-:NUM_VC];
    end

    /************************************
    *       Switch Allocation           *
    ************************************/

    logic [NUM_PORTS*NUM_VC-1:0][NUM_PORTS*NUM_VC-1:0] vc_grants;
    logic [NUM_PORTS-1:0]       port_req  [NUM_PORTS-1:0];
    logic [NUM_PORTS-1:0] allocated_ports [NUM_PORTS-1:0];
    // Conver the array struct between allocated_ip_vcs and vc_grants
    for (genvar i = 0; i < NUM_PORTS*NUM_VC; ++i) begin
        assign vc_grants[i] = allocated_ip_vcs[i];
    end
    vc_req_2_port_req #(
        .NUM_PORTS(NUM_PORTS),
        .NUM_VC(NUM_VC)
    ) req2port (
        .vc_grants(vc_grants),
        .port_req(port_req)
    );

    switch_allocator #(
        .NUM_PORTS(NUM_PORTS)
    ) sa (
        .clk(clk),
        .reset(reset),
        .port_requests(port_req),
        .allocated_ports(allocated_ports)
    );

    /************************************
    *       Buffer read                 *
    ************************************/
    for (genvar i = 0; i < NUM_PORTS; ++i) begin
        assign vc_read_valid[i] = |allocated_ports[i];
        select_vc #(
            .NUM_VC(NUM_VC),
            .NUM_PORTS(NUM_PORTS)
        ) svc (
            .clk(clk),
            .reset(reset),
            .vc_direction(vc_direction[i]),
            .sel_direction(allocated_ports[i]),
            .vc_index(vc_index[i])
        );
    end

endmodule