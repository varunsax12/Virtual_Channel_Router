// Description: Module for the crossbar switch
// File Details
//    Author: Varun Saxena
//    GT id: 903562211

`include "VR_define.vh"

module crossbar #(
    parameter NUM_PORTS = 4
) (
    input logic [`FLIT_DATA_WIDTH-1:0] in_vc_data [NUM_PORTS-1:0],
    // Map the input ports to output port
    input logic [NUM_PORTS-1:0]  vc_mapping [NUM_PORTS-1:0],
    // Valid signal per port
    input logic [NUM_PORTS-1:0]  valid,
    output logic [`FLIT_DATA_WIDTH-1:0] out_data [NUM_PORTS-1:0],
    output logic [NUM_PORTS-1:0] out_valid
);

    // Output port
    for (genvar i = 0; i < NUM_PORTS; ++i) begin
        // Place the output mux
        always_comb begin
            // Input port
            out_valid[i] = 0;
            for (int j = 0; j < NUM_PORTS; ++j) begin
                if (vc_mapping[j][i] == 1 && valid[j] == 1) begin
                    out_data[i] = in_vc_data[j];
                    out_valid[i] = 1;
                end
            end
        end
    end

endmodule