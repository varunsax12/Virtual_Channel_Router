// Description: Pipeline register
// File Details
//    Author: Varun Saxena

module pipe_register_1D #(
    parameter DATAW = 4
) (
    // Standard inputs
    input wire clk, reset, enable,
    input wire [DATAW-1:0] in_data,
    output reg [DATAW-1:0] out_data
);

    always @(posedge clk) begin
        if (reset) begin
            out_data <= 0;
        end
        else if (enable) begin
            out_data <= in_data;
        end
        // else latch the same data
    end

endmodule