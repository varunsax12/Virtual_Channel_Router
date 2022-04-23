// Description: Module to convert index bits into one-hot
// File Details
//    Author: Varun Saxena
//    GT id: 903562211

module index_2_one_hot #(
    parameter NUM_BITS     = 2,
    parameter ONE_HOT_SIZE = 2**NUM_BITS
) (
    input logic [NUM_BITS-1:0]  index,
    output logic [ONE_HOT_SIZE-1:0] out_one_hot
);

    assign out_one_hot = 1 << index;

endmodule