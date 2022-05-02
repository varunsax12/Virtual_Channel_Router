// Description: Module torus topology NxN

`include "VR_define.vh"

module torus_topology #(
    parameter ROW_COUNT = 3,
    parameter COL_COUNT = 3,
    parameter NUM_VC    = 4,
    parameter ROUTER_COUNT = ROW_COUNT * COL_COUNT
) (
    input logic clk, reset,
    input logic [ROUTER_COUNT-1:0]      nic_output_valid,
    input logic [`FLIT_DATA_WIDTH-1:0]  nic_output_data [ROUTER_COUNT-1:0],
    output logic [ROUTER_COUNT-1:0]     nic_input_valid,
    output logic [`FLIT_DATA_WIDTH-1:0] nic_input_data  [ROUTER_COUNT-1:0]
);

    // wire count for 3x3 is 18
    localparam WIRE_COUNT = (ROW_COUNT-1) * COL_COUNT + (COL_COUNT-1)*ROW_COUNT + 2*(ROW_COUNT);
    localparam NUM_PORTS = 5;

    logic [NUM_PORTS-1:0] rt_input_valid[ROW_COUNT-1:0][COL_COUNT-1:0];
    logic       rt_dwnstr_credit_increment [ROW_COUNT-1:0][COL_COUNT-1:0][NUM_PORTS-2:0][NUM_VC-1:0];
    logic [`FLIT_DATA_WIDTH-1:0] rt_input_data [ROW_COUNT-1:0][COL_COUNT-1:0][NUM_PORTS-1:0];

    logic [NUM_PORTS-1:0] rt_output_valid[ROW_COUNT-1:0][COL_COUNT-1:0];
    logic       rt_upstr_credit_increment [ROW_COUNT-1:0][COL_COUNT-1:0][NUM_PORTS-2:0][NUM_VC-1:0];
    logic [`FLIT_DATA_WIDTH-1:0] rt_output_data [ROW_COUNT-1:0][COL_COUNT-1:0][NUM_PORTS-1:0];


    // Connect the NIC ports to the module output
    for (genvar i = 0; i < ROW_COUNT; ++i) begin
        for (genvar j = 0; j < COL_COUNT; ++j) begin
            assign nic_input_valid[i*COL_COUNT+j] = rt_output_valid[i][j][`NIC_PORT];
            assign nic_input_data [i*COL_COUNT+j] = rt_output_data [i][j][`NIC_PORT];
            assign rt_input_valid [i][j][`NIC_PORT] = nic_output_valid[i*COL_COUNT+j];
            assign rt_input_data  [i][j][`NIC_PORT] = nic_output_data [i*COL_COUNT+j];
        end
    end

    // Create connections between routers
    for (genvar i = 0; i < ROW_COUNT; ++i) begin
        for (genvar j = 0; j < COL_COUNT; ++j) begin
            // Connect north port
            assign rt_input_valid[i][j][`NORTH] = rt_output_valid[(i + (ROW_COUNT-1)) % ROW_COUNT][j][`SOUTH];
            assign rt_input_data [i][j][`NORTH] = rt_output_data [(i + (ROW_COUNT-1)) % ROW_COUNT][j][`SOUTH];
            assign rt_dwnstr_credit_increment [i][j][`NORTH-1] = rt_upstr_credit_increment [(i + (ROW_COUNT-1)) % ROW_COUNT][j][`SOUTH-1];
            // Connect south port
            assign rt_input_valid[i][j][`SOUTH] = rt_output_valid[(i + 1) % ROW_COUNT][j][`NORTH];
            assign rt_input_data [i][j][`SOUTH] = rt_output_data [(i + 1) % ROW_COUNT][j][`NORTH];
            assign rt_dwnstr_credit_increment [i][j][`SOUTH-1] = rt_upstr_credit_increment [(i + 1) % ROW_COUNT][j][`NORTH-1];
            // Connect east port
            assign rt_input_valid[i][j][`EAST] = rt_output_valid[i][(j + 1) % COL_COUNT][`WEST];
            assign rt_input_data [i][j][`EAST] = rt_output_data [i][(j + 1) % COL_COUNT][`WEST];
            assign rt_dwnstr_credit_increment [i][j][`EAST-1] = rt_upstr_credit_increment [i][(j + 1) % COL_COUNT][`WEST-1];
            // Connect west port
            assign rt_input_valid[i][j][`WEST] = rt_output_valid[i][(j + (COL_COUNT-1)) % COL_COUNT][`EAST];
            assign rt_input_data [i][j][`WEST] = rt_output_data [i][(j + (COL_COUNT-1)) % COL_COUNT][`EAST];
            assign rt_dwnstr_credit_increment [i][j][`WEST-1] = rt_upstr_credit_increment [i][(j + (COL_COUNT-1)) % COL_COUNT][`EAST-1];
        end
    end

    for (genvar i = 0; i < ROW_COUNT; ++i) begin
        for (genvar j = 0; j < COL_COUNT; ++j) begin
            router_top #(
                .NUM_PORTS      (NUM_PORTS),
                .NUM_VC         (NUM_VC),
                .NUM_ROUTERS    (ROUTER_COUNT),
                .ROUTER_PER_ROW (ROW_COUNT),
                .ROUTER_ID      (i*COL_COUNT + j),
                .BUFFER_DEPTH   (8)
            ) rt (
                .clk        (clk),
                .reset      (reset),

                .input_data(rt_input_data[i][j]),
                .input_valid(rt_input_valid[i][j]),

                .dwnstr_credit_increment(rt_dwnstr_credit_increment[i][j]),

                .upstr_credit_increment(rt_upstr_credit_increment[i][j]),
                .out_data(rt_output_data[i][j]),
                .out_valid(rt_output_valid[i][j])
            );
        end
    end

endmodule

