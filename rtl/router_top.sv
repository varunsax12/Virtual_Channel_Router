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
    // Standard signals
    input  logic   clk, reset,

    // Input flits
    input logic    [`FLIT_DATA_WIDTH-1:0] input_data [NUM_PORTS-1:0],
    input logic    [NUM_PORTS-1:0]        input_valid,

    // Signals from downstream routers for each non-local port
    input logic  [NUM_PORTS-2:0] dwnstr_router_increment,

    // Router output
    output logic [NUM_PORTS-2:0] upstr_router_increment,
    output logic [`FLIT_DATA_WIDTH-1:0] out_data [NUM_PORTS-1:0],
    output logic [NUM_PORTS-1:0]        out_valid
);

    /************************************
    *          VC                       *
    ************************************/
    // VC buffers
    reg [`FLIT_DATA_WIDTH-1:0]        vc_buffer [NUM_PORTS-1:0][NUM_VC-1:0];
    // Valid signal (also used as empty signal using bitwise not)
    reg  [NUM_VC-1:0]                 vc_valid  [NUM_PORTS-1:0];
    wire [NUM_VC-1:0]                 vc_empty  [NUM_PORTS-1:0];

    // Generate empty signals
    for (genvar i = 0; i < NUM_PORTS; ++i) begin
        assign vc_empty[i] = ~vc_valid[i];
    end

    // Keep a track of the first empty VC per PORT
    logic [VC_BITS-1:0]   empty_vc_index [NUM_PORTS-1:0];
    for (genvar i = 0; i < NUM_PORTS; ++i) begin
        priority_encoder #(
            .NUM_INPUTS(NUM_VC)
        ) empty_vc_encoder (
            .in_signals(vc_empty[i]),
            .out_index(empty_vc_index[i])
        );
    end


    /************************************
    *          Buffer write             *
    ************************************/
    for (genvar i = 0; i < NUM_PORTS; ++i) begin
        always @(posedge clk) begin
            if (reset) begin
                // Clear the VCs
                vc_valid[i] <= 0;
            end
            // assign the incoming flits to the correct buffers
            else begin
                if (input_valid[i]) begin
                    // Write the input flit data
                    vc_buffer[i][empty_vc_index[i]] <= input_data[i];
                    vc_valid[i][empty_vc_index[i]] <= 1;
                end
            end
        end
    end

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
            assign dst_port[i*NUM_VC+j] = vc_valid[i][j] ? one_hot_direction[NUM_PORTS-1:0] : 0;
        end
    end

    logic   [NUM_PORTS-1:0]        vca_dst_port [NUM_VC*NUM_PORTS-1:0];
    // TODO: Create enable signal for stalls
    pipe_register #(
        .DATAW(NUM_PORTS),
        .ARRAY_DEPTH(NUM_VC*NUM_PORTS)
    ) rc2va (
        // Standard inputs
        .clk(clk),
        .reset(reset),
        .enable(1'b1),
        .in_data(dst_port),
        .out_data(vca_dst_port)
    );

    /************************************
    *       VC Availability             *
    ************************************/

    logic [NUM_VC*NUM_PORTS-1:0] vc_availability;
    logic [NUM_VC*NUM_PORTS-1:0] allocated_ip_vcs [NUM_VC*NUM_PORTS-1:0];
    logic [NUM_PORTS-1:0] sa_allocated_ports [NUM_PORTS-1:0];
    
    // Computes VC Availability based on down stream router increments and current router assignees
    vc_availability #(
        .NUM_PORTS(NUM_PORTS),
        .NUM_VCS(NUM_VC)
    ) vcavail (
        .clk(clk),
        .reset(reset),
        .vca_dst_port(vca_dst_port),
        .dwnstr_router_increment(dwnstr_router_increment), 
        .sa_allocated_ports(sa_allocated_ports),
        .allocated_ip_vcs(allocated_ip_vcs), 
        .vc_availability(vc_availability), 
        .upstr_router_increment(upstr_router_increment)
    );

    /************************************
    *       VC Allocation              *
    ************************************/

    // Output VC allocation
    vc_allocator #(
        .NUM_PORTS(NUM_PORTS),
        .NUM_VCS(NUM_VC)
    ) vca (
        .clk(clk),
        .reset(reset),
        .dst_port(vca_dst_port),
        .vc_availability(vc_availability),
        .allocated_ip_vcs(allocated_ip_vcs)
    );

    logic [NUM_VC*NUM_PORTS-1:0] sa_allocated_ip_vcs [NUM_VC*NUM_PORTS-1:0];
    // TODO: Create enable signal for stalls
    pipe_register #(
        .DATAW(NUM_VC*NUM_PORTS),
        .ARRAY_DEPTH(NUM_VC*NUM_PORTS)
    ) va2sa_aiv (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),
        .in_data(allocated_ip_vcs),
        .out_data(sa_allocated_ip_vcs)
    );
    logic   [NUM_PORTS-1:0]        sa_dst_port [NUM_VC*NUM_PORTS-1:0];
    // TODO: Create enable signal for stalls
    pipe_register #(
        .DATAW(NUM_PORTS),
        .ARRAY_DEPTH(NUM_VC*NUM_PORTS)
    ) va2sa_dst_port (
        // Standard inputs
        .clk(clk),
        .reset(reset),
        .enable(1'b1),
        .in_data(vca_dst_port),
        .out_data(sa_dst_port)
    );

    /************************************
    *       Switch Allocation           *
    ************************************/



    logic [NUM_PORTS*NUM_VC-1:0][NUM_PORTS*NUM_VC-1:0] vc_grants;
    logic [NUM_PORTS-1:0]       port_req  [NUM_PORTS-1:0];
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
        .allocated_ports(sa_allocated_ports)
    );

    logic [NUM_PORTS-1:0] br_allocated_ports [NUM_PORTS-1:0];
    // TODO: Create enable signal for stalls
    pipe_register #(
        .DATAW(NUM_PORTS),
        .ARRAY_DEPTH(NUM_PORTS)
    ) sa2br_ap (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),
        .in_data(sa_allocated_ports),
        .out_data(br_allocated_ports)
    );

    logic   [NUM_PORTS-1:0]        br_dst_port [NUM_VC*NUM_PORTS-1:0];
    // TODO: Create enable signal for stalls
    pipe_register #(
        .DATAW(NUM_PORTS),
        .ARRAY_DEPTH(NUM_VC*NUM_PORTS)
    ) sa2br_dst_port (
        // Standard inputs
        .clk(clk),
        .reset(reset),
        .enable(1'b1),
        .in_data(sa_dst_port),
        .out_data(br_dst_port)
    );

    /************************************
    *       Buffer read                 *
    ************************************/

    logic   [NUM_PORTS-1:0]        br_vc_direction [NUM_PORTS-1:0][NUM_VC-1:0];
    // Convert the 2D array of dst port into 3D array splitting across i/p VC and port
    for (genvar i = 0; i < NUM_PORTS; ++i) begin
        assign br_vc_direction[i] = br_dst_port[(i+1)*NUM_VC-1-:NUM_VC];
    end

    // To denote if the data from a port is being read (based on allocation)
    logic   [NUM_PORTS-1:0]        vc_read_valid;

    // VC index to read per port
    logic   [VC_BITS-1:0]          vc_index [NUM_PORTS-1:0];

    for (genvar i = 0; i < NUM_PORTS; ++i) begin
        assign vc_read_valid[i] = |br_allocated_ports[i];
        select_vc #(
            .NUM_VC(NUM_VC),
            .NUM_PORTS(NUM_PORTS)
        ) svc (
            .clk(clk),
            .reset(reset),
            .vc_direction(br_vc_direction[i]),
            .sel_direction(br_allocated_ports[i]),
            .vc_index(vc_index[i])
        );
    end

    // Invalidate or clear the VC being sent out
    // Done at negedge of clk to avoid race condition
    for (genvar i = 0; i < NUM_PORTS; ++i) begin
        always @(negedge clk) begin
            if (vc_read_valid[i]) begin
                vc_valid[i][vc_index[i]] <= 0;
            end
        end
    end

    // Read buffers
    reg [`FLIT_DATA_WIDTH-1:0]  out_buffer_data_per_port [NUM_PORTS-1:0];
    for (genvar i = 0; i < NUM_PORTS; ++i) begin
        always @(posedge clk) begin
            if (vc_read_valid[i]) begin
                out_buffer_data_per_port[i] <= vc_buffer[i][vc_index[i]];
            end
        end
    end

    logic [NUM_PORTS-1:0] st_allocated_ports [NUM_PORTS-1:0];
    // TODO: Create enable signal for stalls
    pipe_register #(
        .DATAW(NUM_PORTS),
        .ARRAY_DEPTH(NUM_PORTS)
    ) br2st_ap (
        // Standard inputs
        .clk(clk),
        .reset(reset),
        .enable(1'b1),
        .in_data(br_allocated_ports),
        .out_data(st_allocated_ports)
    );
    // To denote if the data from a port is being read (based on allocation)
    logic   [NUM_PORTS-1:0]        st_vc_read_valid;
    always @(posedge clk) begin
        if (reset) begin
            st_vc_read_valid <= 0;
        end
        else begin
            st_vc_read_valid <= vc_read_valid;
        end
    end

    /************************************
    *       Switch traversal            *
    ************************************/
    crossbar #(
        .NUM_PORTS(NUM_PORTS)
    ) cxb (
        .in_vc_data(out_buffer_data_per_port),
        .vc_mapping(st_allocated_ports),
        .valid(st_vc_read_valid),
        .out_data(out_data),
        .out_valid(out_valid)
    );

endmodule