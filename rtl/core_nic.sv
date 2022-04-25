// Description: Module for NIC to inject packets into the network
// File Details
//    Author: Varun Saxena
//    GT id: 903562211

// Logic:
//  1. THe core buffer is 0 buffer to hold the flits injected into the network
//  2. We need buffers to hold the buffers which will eject

module core_nic #(
    //
) (
    input logic clk, reset,
    input logic [`FLIT_DATA_WIDTH-1:0]  in_flit,
    output logic [`FLIT_DATA_WIDTH-1:0] out_flit
);

    // reg [`FLIT_DATA_WIDTH-1:0]

endmodule