// Description: Module for the router top
// File Details
//    Author: Varun Saxena
//    GT id: 903562211

module router_top #(
    parameter NUM_PORTS = 5,
    parameter NUM_VC    = 4,
    parameter PORT_BITS = $clog2(NUM_PORTS),
    parameter VC_BITS = $clog2(NUM_VC)
) (
    input  logic   clk, reset,
    input  logic   [NUM_PORTS-1:0]        dst_port [NUM_VC*NUM_PORTS-1:0],
    input  logic   [NUM_VC*NUM_PORTS-1:0] vc_availability,
    output logic   [VC_BITS-1:0]          vc_index [NUM_PORTS-1:0],
    output logic   [NUM_PORTS-1:0]        vc_read_valid
);

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