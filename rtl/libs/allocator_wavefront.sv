// Description: Acyclic wavefront allocator with input/output transformation
// Reference: Stanford thesis
// File Details:
//    Author: Varun Saxena
//    GT id: 903562211


// TODO: The format of the output is:
// for each request, which resource it gets

`timescale  10ns/1ps

module allocator_wavefront #(
    parameter NUM_REQS = 4,
    parameter NUM_RESS = NUM_REQS
) (
    // Standard inputs
    input logic clk, reset,
    // NUM_RESS requests for each requestor (out of NUM_REQS)
    input logic [NUM_RESS-1:0] requests[NUM_REQS-1:0],
    // NUM_REQS grants for each resource (out of NUM_RESS)
    output reg [NUM_REQS-1:0] grants[NUM_RESS-1:0]
);

    // TODO: Make condition for synthesis
    initial begin
        assert(NUM_REQS == NUM_RESS) else $display("**ERR: NUM_REQS must be equal to NUM_RESS for wavefront. Mask the extra ress.");
    end

    localparam NUM_PORTS = NUM_REQS;

    wire [NUM_PORTS-1:0] local_requests[NUM_PORTS-1:0];
    wire [NUM_PORTS-1:0] local_grants[NUM_PORTS-1:0];

    logic [NUM_PORTS-1:0] g_priority;

    for (genvar i = 0; i < NUM_PORTS; ++i) begin
        one_hot_rotate #(
            .NUM_PORTS(NUM_PORTS),
            .SHIFT_LEFT(0)
        ) ohr_req_wv (
            .one_hot_amt(g_priority),
            .data(requests[i]),
            .out_data(local_requests[i])
        );

        one_hot_rotate #(
            .NUM_PORTS(NUM_PORTS),
            .SHIFT_LEFT(1)
        ) ohr_grt_wv (
            .one_hot_amt(g_priority),
            .data(local_grants[i]),
            .out_data(grants[i])
        );
    end

    array_wavefront #(
        .NUM_PORTS(NUM_PORTS)
    ) arr_wv (
        .g_priority(NUM_PORTS'(1'b1)),
        .requests(local_requests),
        .grants(local_grants)
    );

    // Priority calculation and storage block
    priority_block_wv #(
        .NUM_PORTS(NUM_PORTS)
    ) pb_wv (
        .clk(clk),
        .reset(reset),
        .grants(grants),
        .g_priority(g_priority)
    );

endmodule

// One-hot rotate block
module one_hot_rotate #(
    parameter NUM_PORTS = 4,
    parameter SHIFT_LEFT = 1 // set to 0 for shift right
) (
    input [NUM_PORTS-1:0] one_hot_amt,
    input [NUM_PORTS-1:0] data,
    output logic [NUM_PORTS-1:0] out_data
);
    generate
        logic [2*NUM_PORTS-1:0] data_rot;
        if (SHIFT_LEFT == 1) begin
            always_comb begin
                for (int i = 0; i < NUM_PORTS; ++i) begin
                    if (one_hot_amt[i] == 1) begin
                        // out_data = data << i;
                        data_rot = {data, data};
                        data_rot = data_rot >> (NUM_PORTS - i);
                        out_data = data_rot[NUM_PORTS-1:0];
                    end
                end
            end
        end
        else begin
            always_comb begin
                for (int i = 0; i < NUM_PORTS; ++i) begin
                    if (one_hot_amt[i] == 1) begin
                        // out_data = data >> i;
                        data_rot = {data, data};
                        data_rot = data_rot >> i;
                        out_data = data_rot[NUM_PORTS-1:0];
                    end
                end
            end
        end
    endgenerate
endmodule

// Priority calculation and storage block
module priority_block_wv #(
    parameter NUM_PORTS = 4
) (
    input clk, reset,
    input [NUM_PORTS-1:0]  grants[NUM_PORTS-1:0],
    output [NUM_PORTS-1:0] g_priority
);

    reg [NUM_PORTS-1:0] g_priority_state;

    // Calculate wave of grants across the diagonals
    logic [NUM_PORTS-1:0]   diagonal_grants_ordered [NUM_PORTS-1:0];
    logic [NUM_PORTS-1:0]   diagonal_grants;
    // Idea: For each diagonal, we cannot do a for loop OR operation
    // as it would create a combinatorial loop.
    // So, for each diagonal, first populate the ordered array based
    // on the column for (i+j)%NUM_PORT element. 
    // Then take the OR of each ordered element. This will avoid loops
    for (genvar i = 0; i < NUM_PORTS; ++i) begin
        for (genvar j = 0; j < NUM_PORTS; ++j) begin
            assign diagonal_grants_ordered[(i+j)%NUM_PORTS][j] = grants[i][j];
        end
    end
    // Reduce ordered array into single
    for (genvar i = 0; i < NUM_PORTS; ++i) begin
        assign diagonal_grants[i] = |diagonal_grants_ordered[i];
    end
    
    logic [NUM_PORTS-1:0] arb_priority_grants;
    arbiter_top #(
        .NUM_REQS(NUM_PORTS)
    ) wv_priority (
        .clk(clk),
        .reset(reset),
        .requests(diagonal_grants),
        // Grant/g_priority calculated
        .grants(arb_priority_grants)
    );

    always @(posedge clk) begin
        if (reset)
            g_priority_state <= 1;
        else begin
            g_priority_state <= {arb_priority_grants[NUM_PORTS-2:0], arb_priority_grants[NUM_PORTS-1]};
        end
    end

    assign g_priority = g_priority_state;
endmodule

// x is x(i,j)
// y is y(i,j)
// x_1 is x(i,j+1)
// y_1 is y(i+1,j)
// priority is (i+j) mod n
module bitcell_wavefront (
    input x, y, g_priority, request,
    output x_1, y_1, grant
);
    wire or_x, or_y;
    assign or_x = g_priority | x;
    assign or_y = g_priority | y;
    assign grant = request & or_x & or_y;
    assign x_1 = (~grant) & or_x;
    assign y_1 = (~grant) & or_y;
 
endmodule

// wavefront array for priority 1
module array_wavefront #(
    parameter NUM_PORTS = 4
) (
    input [NUM_PORTS-1:0]   g_priority,
    input [NUM_PORTS-1:0]   requests[NUM_PORTS-1:0],
    output [NUM_PORTS-1:0]  grants[NUM_PORTS-1:0]
);
    // considered as input ports
    logic [NUM_PORTS:0][NUM_PORTS:0] x, y;
    // col
    for (genvar i = 0; i < NUM_PORTS; ++i) begin
        // row
        for (genvar j = 0; j < NUM_PORTS; ++j) begin
            logic x_in, y_in;
            // conditional for diagonal handling
            if ((i+j)%NUM_PORTS != 0) begin
                assign x_in = x[i][j];
                assign y_in = y[i][j];
            end
            else begin
                assign x_in = 0;
                assign y_in = 0;
            end
            bitcell_wavefront bt_wv (
                .x(x_in),
                .y(y_in),
                .g_priority(g_priority[(i+j)%NUM_PORTS]),
                .request(requests[i][j]),
                .x_1(x[i][j+1]),
                .y_1(y[i+1][j]),
                .grant(grants[i][j])
            );

            // connect the edge outs back as inputs
            if (j == NUM_PORTS-1 && i != 0) begin
                assign x[i][0] = x[i][j+1];
            end
            if (i == NUM_PORTS-1 && j != 0) begin
                assign y[0][j] = y[i+1][j];
            end
        end
    end

endmodule