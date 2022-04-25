// Description: Module for the router top
// File Details
//    Author: Varun Saxena
//    GT id: 903562211

module router_top #(
    parameter NUM_PORTS      = 5,
    parameter NUM_VC         = 4,
    parameter NUM_ROUTERS    = 16,
    parameter ROUTER_PER_ROW = 4,
    parameter ROUTER_ID      = 0,
    parameter ROUTER_ID_BITS = $clog2(NUM_ROUTERS),
    parameter PORT_BITS      = $clog2(NUM_PORTS),
    parameter VC_BITS        = $clog2(NUM_VC)
) (
    // Standard signals
    input  logic   clk, reset,

    // Input flits
    input logic     [`FLIT_DATA_WIDTH-1:0]  input_data [NUM_PORTS-1:0],
    input logic     [NUM_PORTS-1:0]         input_valid,

    // Signals from downstream routers for each non-local port
    input logic     [NUM_PORTS-2:0]         dwnstr_router_increment,

    // Router output
    output logic    [NUM_PORTS-2:0]         upstr_router_increment,
    output logic    [`FLIT_DATA_WIDTH-1:0]  out_data [NUM_PORTS-1:0],
    output logic    [NUM_PORTS-1:0]         out_valid
);

    /************************************
    *          VC                       *
    ************************************/
    // VC buffers
    wire [NUM_PORTS-1:0][NUM_VC-1:0][`FLIT_DATA_WIDTH-1:0]        vc_indata, vc_outdata;
    // Valid signal (also used as empty signal using bitwise not)
    wire [NUM_PORTS-1:0][NUM_VC-1:0]    vc_valid, vc_empty, vc_full, vc_pop, vc_push;

    // Generate valid signals
    for (genvar i = 0; i < NUM_PORTS; ++i) begin : vc_valid_signal
        assign vc_valid[i] = ~vc_empty[i];
    end

    for (genvar i = 0; i < NUM_PORTS; ++i) begin : vc_fifo_i
        for (genvar j = 0; j < NUM_VC; ++j) begin : vc_fifo_j
            fifo #(
                .DATA_WIDTH(`FLIT_DATA_WIDTH)
            ) vc_buffer_fifo (
                .clk(clk),
                .reset(reset),
                .push(vc_push[i][j]),
                .pop(vc_pop[i][j]),
                .indata(vc_indata[i][j]),
                .outdata(vc_outdata[i][j]),
                .empty(vc_empty[i][j]),
                .full(vc_full[i][j])
            );
        end
    end

    // Keep a track of the first empty VC per PORT
    logic [VC_BITS-1:0]   empty_vc_index [NUM_PORTS-1:0];
    for (genvar i = 0; i < NUM_PORTS; ++i) begin : vc_empty_index
        priority_encoder #(
            .NUM_INPUTS (NUM_VC)
        ) empty_vc_encoder (
            .in_signals (vc_empty[i]),
            .out_index  (empty_vc_index[i])
        );
    end


    /************************************
    *          Buffer write             *
    ************************************/
    for (genvar i = 0; i < NUM_PORTS; ++i) begin : bw_i
        for (genvar j = 0; j < NUM_VC; ++j) begin : bw_j
            assign vc_push[i][j] = (j==empty_vc_index[i]) ? input_valid[i] : 0;
            assign vc_indata[i][j] = (j==empty_vc_index[i]) ? input_data[i] : 0;
        end
    end

    /************************************
    *          Route compute            *
    ************************************/

    logic   [NUM_PORTS-1:0]        rc_dst_port [NUM_VC*NUM_PORTS-1:0];

    localparam DIR_BITS    = 3; // N, S, W, E, Eject
    localparam DIR_ONE_HOT = 2**DIR_BITS;
    for (genvar i = 0; i < NUM_PORTS; ++i) begin : rc_i
        for (genvar j = 0; j < NUM_VC; ++j) begin : rc_j
            logic [DIR_BITS-1:0] rc_vc_direction;
            route_compute # (
                .NUM_ROUTERS    (NUM_ROUTERS),
                .ROUTER_PER_ROW (ROUTER_PER_ROW)
            ) rc (
                .current_router (ROUTER_ID_BITS'(ROUTER_ID)),
                .dest_router    (vc_outdata[i][j][`FLIT_DATA_WIDTH-1-:ROUTER_ID_BITS]),
                .direction      (rc_vc_direction)
            );

            // One hot encode the direction
            logic [DIR_ONE_HOT-1:0] rc_one_hot_direction;
            index_2_one_hot #(
                .NUM_BITS   (DIR_BITS)
            ) dir2port (
                .index      (rc_vc_direction),
                .out_one_hot(rc_one_hot_direction)
            );
            assign rc_dst_port[i*NUM_VC+j] = vc_valid[i][j] ? rc_one_hot_direction[NUM_PORTS-1:0] : 0;
        end
    end

    logic   [NUM_PORTS-1:0]        vca_dst_port [NUM_VC*NUM_PORTS-1:0];

    for (genvar i = 0; i < NUM_VC*NUM_PORTS; ++i) begin : pipe_rc
        pipe_register_1D #(
            .DATAW      (NUM_PORTS)
        ) rc2va (
            .clk        (clk),
            .reset      (reset),
            .enable     (1'b1),
            .in_data    (rc_dst_port[i]),
            .out_data   (vca_dst_port[i])
        );
    end


    /************************************
    *       VC Availability             *
    ************************************/

    logic [NUM_VC*NUM_PORTS-1:0] vca_vc_availability;
    logic [NUM_VC*NUM_PORTS-1:0] vca_allocated_ip_vcs [NUM_VC*NUM_PORTS-1:0];
    logic [NUM_PORTS-1:0]        vca_allocated_ports  [NUM_PORTS-1:0];
    
    // Computes VC Availability based on down stream router increments and current router assignees
    vc_availability #(
        .NUM_PORTS              (NUM_PORTS),
        .NUM_VCS                (NUM_VC)
    ) vcavail (
        .clk                    (clk),
        .reset                  (reset),
        .vca_dst_port           (vca_dst_port),
        .dwnstr_router_increment(dwnstr_router_increment), 
        .sa_allocated_ports     (vca_allocated_ports),
        .out_valid              (out_valid),
        .allocated_ip_vcs       (vca_allocated_ip_vcs), 
        .vc_availability        (vca_vc_availability), 
        .upstr_router_increment (upstr_router_increment)
    );

    /************************************
    *       VC Allocation              *
    ************************************/

    // Output VC allocation
    vc_allocator #(
        .NUM_PORTS          (NUM_PORTS),
        .NUM_VCS            (NUM_VC)
    ) vca (
        .clk                (clk),
        .reset              (reset),
        .dst_port           (vca_dst_port),
        .vc_availability    (vca_vc_availability),
        .allocated_ip_vcs   (vca_allocated_ip_vcs)
    );

    logic [NUM_VC*NUM_PORTS-1:0] sa_allocated_ip_vcs [NUM_VC*NUM_PORTS-1:0];
    logic   [NUM_PORTS-1:0]       sa_dst_port [NUM_VC*NUM_PORTS-1:0];
    
    for (genvar i = 0; i < NUM_VC*NUM_PORTS; ++i) begin : pipe_vca
        pipe_register_1D #(
            .DATAW      (NUM_VC*NUM_PORTS)
        ) va2sa_aiv (
            .clk        (clk),
            .reset      (reset),
            .enable     (1'b1),
            .in_data    (vca_allocated_ip_vcs[i]),
            .out_data   (sa_allocated_ip_vcs[i])
        );

        pipe_register_1D #(
            .DATAW          (NUM_PORTS)
        ) va2sa_dst_port (
            .clk            (clk),
            .reset          (reset),
            .enable         (1'b1),
            .in_data        (vca_dst_port[i]),
            .out_data       (sa_dst_port[i])
        );
    end

    /************************************
    *       Switch Allocation           *
    ************************************/

    logic [NUM_PORTS*NUM_VC-1:0][NUM_PORTS*NUM_VC-1:0]  sa_vc_grants;
    logic [NUM_PORTS-1:0]                               sa_port_req         [NUM_PORTS-1:0];
    logic [NUM_PORTS-1:0]                               sa_allocated_ports  [NUM_PORTS-1:0];
    // Conver the array struct between allocated_ip_vcs and vc_grants
    for (genvar i = 0; i < NUM_PORTS*NUM_VC; ++i) begin : sw_map
        assign sa_vc_grants[i] = sa_allocated_ip_vcs[i];
    end
    vc_req_2_port_req #(
        .NUM_PORTS      (NUM_PORTS),
        .NUM_VC         (NUM_VC)
    ) req2port (
        .vc_grants      (sa_vc_grants),
        .port_req       (sa_port_req)
    );

    switch_allocator #(
        .NUM_PORTS      (NUM_PORTS)
    ) sa (
        .clk            (clk),
        .reset          (reset),
        .port_requests  (sa_port_req),
        .allocated_ports(sa_allocated_ports)
    );

    assign vca_allocated_ports = sa_allocated_ports;

    logic [NUM_PORTS-1:0] br_allocated_ports [NUM_PORTS-1:0];
    logic   [NUM_PORTS-1:0] br_dst_port [NUM_VC*NUM_PORTS-1:0];

    for (genvar i = 0; i < NUM_PORTS; ++i) begin : pipe_swa_1
        pipe_register_1D #(
            .DATAW      (NUM_PORTS)
        ) sa2br_ap (
            .clk        (clk),
            .reset      (reset),
            .enable     (1'b1),
            .in_data    (sa_allocated_ports[i]),
            .out_data   (br_allocated_ports[i])
        );
    end

    for (genvar i = 0; i < NUM_VC*NUM_PORTS; ++i) begin : pipe_swa_2
        pipe_register_1D #(
            .DATAW      (NUM_PORTS)
        ) sa2br_dst_port (
            .clk        (clk),
            .reset      (reset),
            .enable     (1'b1),
            .in_data    (sa_dst_port[i]),
            .out_data   (br_dst_port[i])
        );
    end

    /************************************
    *       Buffer read                 *
    ************************************/

    logic   [NUM_PORTS-1:0] br_vc_direction [NUM_PORTS-1:0][NUM_VC-1:0];
    // Convert the 2D array of dst port into 3D array splitting across i/p VC and port
    for (genvar i = 0; i < NUM_PORTS; ++i) begin : br_dir
        assign br_vc_direction[i] = br_dst_port[(i+1)*NUM_VC-1-:NUM_VC];
    end

    // To denote if the data from a port is being read (based on allocation)
    logic   [NUM_PORTS-1:0] br_vc_read_valid;

    // VC index to read per port
    logic   [VC_BITS-1:0]   br_vc_index [NUM_PORTS-1:0];

    for (genvar i = 0; i < NUM_PORTS; ++i) begin : br_select_vc
        assign br_vc_read_valid[i] = |br_allocated_ports[i];
        select_vc #(
            .NUM_VC         (NUM_VC),
            .NUM_PORTS      (NUM_PORTS)
        ) svc (
            .clk            (clk),
            .reset          (reset),
            .vc_direction   (br_vc_direction[i]),
            .sel_direction  (br_allocated_ports[i]),
            .vc_index       (br_vc_index[i])
        );
    end

    // Read buffers
    logic [`FLIT_DATA_WIDTH-1:0]  st_out_buffer_data_per_port [NUM_PORTS-1:0];

    // Invalidate or clear the VC being sent out
    // Done at negedge of clk to avoid race condition
    for (genvar i = 0; i < NUM_PORTS; ++i) begin : br_pop_i
        for (genvar j = 0; j < NUM_VC; ++j) begin : br_pop_j
            assign vc_pop[i][j] = (j == br_vc_index[i]) ? br_vc_read_valid[i] : 0;
        end
        // assign st_out_buffer_data_per_port[i] = vc_outdata[i][br_vc_index[i]];
    end

    logic [NUM_PORTS-1:0] st_allocated_ports [NUM_PORTS-1:0];

    for (genvar i = 0; i < NUM_PORTS; ++i) begin: br_pipe_1
        pipe_register_1D #(
            .DATAW      (NUM_PORTS)
        ) br2st_ap (
            .clk        (clk),
            .reset      (reset),
            .enable     (1'b1),
            .in_data    (br_allocated_ports[i]),
            .out_data   (st_allocated_ports[i])
        );
    end

    for (genvar i = 0; i < NUM_PORTS; ++i) begin : br_pipe_2
        pipe_register_1D #(
            .DATAW      (`FLIT_DATA_WIDTH)
        ) br2st_data (
            .clk        (clk),
            .reset      (reset),
            .enable     (1'b1),
            .in_data    (vc_outdata[i][br_vc_index[i]]),
            .out_data   (st_out_buffer_data_per_port[i])
        );
    end
    // To denote if the data from a port is being read (based on allocation)
    logic   [NUM_PORTS-1:0] st_vc_read_valid;
    pipe_register_1D #(
        .DATAW      (NUM_PORTS)
    ) br2st_data (
        .clk        (clk),
        .reset      (reset),
        .enable     (1'b1),
        .in_data    (br_vc_read_valid),
        .out_data   (st_vc_read_valid)
    );

    /************************************
    *       Switch traversal            *
    ************************************/
    crossbar #(
        .NUM_PORTS  (NUM_PORTS)
    ) cxb (
        .in_vc_data (st_out_buffer_data_per_port),
        .vc_mapping (st_allocated_ports),
        .valid      (st_vc_read_valid),
        .out_data   (out_data),
        .out_valid  (out_valid)
    );

endmodule