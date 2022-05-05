// Description: Convert the VC request array to port request array

module vc_req_2_port_req #(
    parameter NUM_PORTS = 1,
    parameter NUM_VC    = 2
) (
    input logic [NUM_PORTS*NUM_VC-1:0][NUM_PORTS*NUM_VC-1:0] vc_grants,
    output logic [NUM_PORTS-1:0]       port_req  [NUM_PORTS-1:0]
);

    // Truncate the vc_grants into outport req per vc
    logic [NUM_PORTS-1:0]     vc_port_req [NUM_PORTS*NUM_VC-1:0];
    for (genvar i = 0; i < NUM_PORTS*NUM_VC; ++i) begin
        logic [NUM_PORTS-1:0]  outport_req;
        for (genvar j = 0; j < NUM_PORTS; ++j) begin
            assign outport_req[j] = |(vc_grants[i][(j+1)*(NUM_VC)-1-:NUM_VC]); 
        end
        assign vc_port_req[i] = outport_req;
    end
    // Truncate the vc_port_req to port_req
    for (genvar i = 0; i < NUM_PORTS;  ++i) begin
        always_comb begin
            port_req[i] = 0;
            for (int j = 0; j < NUM_VC; ++j) begin
                port_req[i] = port_req[i] | vc_port_req[i*NUM_VC+j];
            end
        end
    end

endmodule