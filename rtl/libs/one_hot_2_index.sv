// Description: Module to convert one-hot encoding to index
// File Details
//    Author: Varun Saxena
//    GT id: 903562211

module one_hot_2_index #(
    parameter NUM_BITS = 4,
    parameter INDEX_SIZE = $clog2(NUM_BITS)
) (
    input logic [NUM_BITS-1:0] one_hot_input,
    output logic [INDEX_SIZE-1:0] output_index
);

    for (genvar i = 0; i < NUM_BITS; ++i) begin
        always_comb begin
            if (one_hot_input[i] == 1) begin
                output_index = i;
            end
        end
    end

endmodule