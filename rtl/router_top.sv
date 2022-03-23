// Description: Module for the router top

module router_top #(
    parameter NUM_PORTS = 5,
    parameter NUM_VC    = 4,
    parameter PORT_BITS = $clog2(NUM_PORTS),
    parameter VC_BITS = $clog2(NUM_VC)
) (
    input  logic   clk, reset,
    input  logic   [NUM_PORTS-1:0]        dst_port [NUM_VC*NUM_PORTS-1:0],
    input  logic   [NUM_VC*NUM_PORTS-1:0] vc_availability,
    input  logic   [PORT_BITS-1:0]        vc_direction [NUM_VC-1:0],
    output logic   [VC_BITS-1:0]          vc_index [NUM_PORTS-1:0]
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


    /************************************
    *       Switch Allocation           *
    ************************************/

    logic [NUM_PORTS*NUM_VC-1:0][NUM_PORTS*NUM_VC-1:0] vc_grants;
    logic [NUM_PORTS-1:0]       port_req  [NUM_PORTS-1:0];
    logic [NUM_PORTS-1:0] allocated_ports [NUM_PORTS-1:0];
    assign vc_grants = {<<{allocated_ip_vcs}};
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
        // Convert the allocated port into a direction
        logic [PORT_BITS-1:0] sel_direction;
        one_hot_2_index #(
            .NUM_BITS(NUM_PORTS)
        ) port2dir (
            .one_hot_input(allocated_ports[i]),
            .output_index(sel_direction)
        );

        select_vc #(
            .NUM_VC(NUM_VC),
            .NUM_PORTS(NUM_PORTS)
        ) svc (
            .clk(clk),
            .reset(reset),
            .vc_direction(vc_direction),
            .sel_direction(sel_direction),
            .vc_index(vc_index[i])
        );
    end

endmodule