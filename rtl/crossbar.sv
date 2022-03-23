// Description: Module for the crossbar switch
// File Details
//    Author: Varun Saxena
//    GT id: 903562211

module crossbar #(
    parameter NUM_PORTS = 4,
    parameter NUM_VC    = 4,
    parameter DATA_WIDTH = 32
) (
    input logic [DATA_WIDTH-1:0] in_vc_data [NUM_PORTS-1:0][NUM_VC-1:0],
    // Map the input vcs to the outport
    input logic [NUM_PORTS-1:0]  vc_mapping [NUM_PORTS-1:0][NUM_VC-1:0],
    output logic [DATA_WIDTH-1:0] out_data [NUM_PORTS-1:0]
);

    // Output port
    for (genvar i = 0; i < NUM_PORTS; ++i) begin
        // Place the output mux
        always_comb begin
            // Input port
            for (int j = 0; j < NUM_PORTS; ++j) begin
                // In VCs
                for (int k = 0; k < NUM_VC; ++k) begin
                    if (vc_mapping[j][k][i] == 1) begin
                        out_data[i] = in_vc_data[j][k];
                    end
                end
            end
        end
    end

endmodule