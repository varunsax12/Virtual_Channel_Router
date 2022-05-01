// Description: Pipeline register
// File Details
//    Author: Varun Saxena
//    GT id: 903562211

module pipe_register_2D #(
    parameter DATAW = 4,
    parameter ARRAY_DEPTH = 4
) (
    // Standard inputs
    input wire clk, reset, enable,
    input wire [DATAW-1:0] in_data  [ARRAY_DEPTH-1:0],
    output reg [DATAW-1:0] out_data [ARRAY_DEPTH-1:0]
);

    for (genvar i = 0; i < ARRAY_DEPTH; ++i) begin
        always @(posedge clk) begin
            if (reset) begin
                out_data[i] <= 0;
            end
            else if (enable) begin
                out_data[i] <= in_data[i];
            end
            // else latch the same data
        end
    end

endmodule