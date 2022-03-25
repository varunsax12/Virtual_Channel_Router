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
    input logic dwnstr_router_increment [NUM_PORTS-1:0],

    // Router output
    output logic upstr_router_increment [NUM_PORTS-1:0],
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

    /************************************
    *       VC Availability             *
    ************************************/
    /*
    router_top will take the following inputs=>
        1. dwnstr_router_increment[NUM_PORTS-2:0] signals for each of its ports except local, external signals
        2. curr_router_decrement[NUM_PORTS-2:0] signals from the switch allocator continously
        3. always @(posedge clk) store the result of 
        (switch allocator outputs && vc allocator outputs) into a temporary register called old_vc_availability.
            ->if(reset) assign old_vc_availability to all 1s.
        4. upstr_router_increment[NUM_PORTS-2:0] signals 
            ->based on requests to VCA and grants to SA send increment signals for each of current routers ports.

    instantiate this combinatorial ckt and use the new_vc_availability=>
    update_vca #(.NUM_PORTS(NUM_PORTS),.NUM_VCS(NUM_VCS)) uvca (.curr_router_decrement(curr_router_decrement),
    .dwn_router_increment(dwn_router_increment), .old_vc_availability(old_vc_availability),
    .new_vc_availability(new_vc_availability));
    */
    localparam NUM_VCS = NUM_VC;
    logic [NUM_VC*NUM_PORTS-1:0] vc_availability;
    logic [NUM_VC*NUM_PORTS-1:0] allocated_ip_vcs [NUM_VC*NUM_PORTS-1:0];
    logic [NUM_PORTS-1:0] allocated_ports [NUM_PORTS-1:0];    
    // Expand [NUM_PORTS-1:0] old_allocated_ports [NUM_PORTS-1:0] to [NUM_VCS*NUM_PORTS-1:0] old_allocated_ip_vcs [NUM_VCS*NUM_PORTS-1:0]
    logic [NUM_VCS*NUM_PORTS-1:0] final_allocated_ip_vcs [NUM_VCS*NUM_PORTS-1:0];
    // Iterate over every ip vc
    for(genvar i=0; i<NUM_PORTS; i=i+1) begin
        for(genvar j=0; j<NUM_VCS; j=j+1) begin
            // Iterate over every bit, assign the result of allocated_ports & allocated_ip_vcs
            for(genvar ii=0; ii<NUM_PORTS; ii=ii+1) begin
                for(genvar jj=0; jj<NUM_VCS; jj=jj+1) begin
                    assign final_allocated_ip_vcs[i*NUM_VCS+j][ii*NUM_VCS+jj] = allocated_ports[ii] & allocated_ip_vcs[ii*NUM_VCS+jj];
                end
            end
        end
    end
    // Convert to old_vc_availability vector
    logic [NUM_VC*NUM_PORTS-1:0] comb_old_vc_availability;
    always_comb begin
        comb_old_vc_availability = 0;
        for(int i=0; i<NUM_PORTS; i=i+1) begin
            for(int j=0; j<NUM_VCS; j=j+1) begin
                comb_old_vc_availability = comb_old_vc_availability | final_allocated_ip_vcs[i*NUM_VCS+j];
            end
        end
    end
    // Store old_vc_availability into temp register
    logic [NUM_VC*NUM_PORTS-1:0] old_vc_availability;
    always @ (posedge clk) begin
        if(reset) begin
            old_vc_availability <= 0;
        end else begin
            old_vc_availability <= comb_old_vc_availability;
        end
    end
    // Instantiate module to update vc_availability
    logic curr_router_decrement [NUM_PORTS-1:0] ; // Updated in the end of VC Availability
    update_vca #(.NUM_PORTS(NUM_PORTS),.NUM_VCS(NUM_VCS)) uvca (.cur_router_decrement(curr_router_decrement),
    .dwn_router_increment(dwnstr_router_increment), .old_vc_availability(old_vc_availability),
    .new_vc_availability(vc_availability));
    // Increment & Decrement based on Current router decisions=>
    // Get the requested op vcs for every ip vc
    logic [NUM_VCS*NUM_PORTS-1:0] requested_op_vcs [NUM_VCS*NUM_PORTS-1:0];
    for(genvar i=0; i<NUM_PORTS; i=i+1) begin
        for(genvar j=0; j<NUM_VCS; j=j+1) begin
            for(genvar ii=0; ii<NUM_PORTS; ii=ii+1) begin
                for(genvar jj=0; jj<NUM_VCS; jj=jj+1) begin
                    assign requested_op_vcs[i*NUM_VCS+j][ii*NUM_VCS+jj] = dst_port[i*NUM_VCS+j][ii];
                end
            end
        end
    end
    // Based on the requests that are cleared (flit released)
    // 1. Assign upstream router increment signals, indicating that the request has been granted.
    // 2. Assign current router decrement signals, indicating latest vc availability.
    //logic upstr_router_increment [NUM_PORTS-1:0];
    always_comb begin
        for(int i=0; i<NUM_PORTS; i=i+1) begin
            upstr_router_increment[i] = 0;
            for(int j=0; j<NUM_VCS; j=j+1) begin
                if( 
                    (|requested_op_vcs[i*NUM_VCS+j]!=0) && 
                    !(|(allocated_ip_vcs[i*NUM_VCS+j] & requested_op_vcs[i*NUM_VCS+j]))
                ) begin
                    upstr_router_increment[i] = 1;
                    curr_router_decrement[i] = 0;
                end else begin
                    upstr_router_increment[i] = 0;
                    curr_router_decrement[i] = 1;                    
                end
            end
        end
    end


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
    // To denote if the data from a port is being read (based on allocation)
    logic   [NUM_PORTS-1:0]        vc_read_valid;

    // VC index to read per port
    logic   [VC_BITS-1:0]          vc_index [NUM_PORTS-1:0];

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

    /************************************
    *       Switch traversal            *
    ************************************/
    crossbar #(
        .NUM_PORTS(NUM_PORTS)
    ) cxb (
        .in_vc_data(out_buffer_data_per_port),
        .vc_mapping(allocated_ports),
        .valid(vc_read_valid),
        .out_data(out_data),
        .out_valid(out_valid)
    );

endmodule