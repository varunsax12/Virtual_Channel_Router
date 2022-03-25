// Description: This module updates VC availability based on =>
//                  1. prev opvc availability,
//                  2. current router opvc assignments,
//                  3. down stream router's release of ipvcs.
// Reference: M06-RouterMicroarchitecture in ECE6115, Prof. Tushar Krishna
// File Details
//    Author: Sandilya Balemarthy
//    GT id: 903482005

`timescale 10ns/1ns

module update_vca #(
    parameter NUM_PORTS = 5,
    parameter NUM_VCS = 4
) (
    // Decrement available op vcs based on current router assignments
    input logic curr_router_decrement[NUM_PORTS-1:0],
    // Increment available op vcs based on down stream router completing few ip vcs
    input logic dwnstr_router_increment[NUM_PORTS-1:0],
    // Updated at posedge clk, after SA Allocation
    input logic [NUM_VCS*NUM_PORTS-1:0] old_vc_availability,
    // Computed at posedge clk, increment decrement w.r.t old vc availability
    output logic [NUM_VCS*NUM_PORTS-1:0] new_vc_availability
);

    logic [NUM_VCS*NUM_PORTS-1:0] tmp_vc_availability;

    logic cont_search[NUM_VCS*NUM_PORTS-1:0];
    always_comb begin
        for(int i=0; i<NUM_PORTS; i=i+1) begin
            for(int j=0; j<NUM_VCS; j=j+1) begin
                //Default assign old values
                for(int ii=(i+1)*NUM_VCS-1; ii>i*NUM_VCS-1; ii=ii-1)
                    tmp_vc_availability[ii] = old_vc_availability[ii];
                //Decrement by replacing the first 1 (from left) to 0
                if(curr_router_decrement[i]) begin
                    cont_search[i*NUM_VCS+j] = 1;
                    for(int ii=(i+1)*NUM_VCS-1; ii>i*NUM_VCS-1; ii=ii-1) begin
                        //tmp_vc_availability[ii] = old_vc_availability[ii];
                        //each(tmp_vc_availability[(i+1)*NUM_VCS-1-:NUM_VCS][ii]) begin
                        if(cont_search[i*NUM_VCS+j] && (tmp_vc_availability[ii]==1)) begin
                            cont_search[i*NUM_VCS+j] = 0;
                            tmp_vc_availability[ii] = 0;
                        end
                    end
                end
                //Increment by replacing the first 0 (from left) to 1
                if(dwnstr_router_increment[i]) begin
                    cont_search[i*NUM_VCS+j] = 1;
                    for(int ii=(i+1)*NUM_VCS-1; ii>i*NUM_VCS-1; ii=ii-1) begin
                        //tmp_vc_availability[ii] = old_vc_availability[ii];
                        //each(tmp_vc_availability[(i+1)*NUM_VCS-1-:NUM_VCS][ii]) begin
                        if(cont_search[i*NUM_VCS+j] && (tmp_vc_availability[ii]==0)) begin
                            cont_search[i*NUM_VCS+j] = 0;
                            tmp_vc_availability[ii] = 1;
                        end else begin
                            tmp_vc_availability[ii] = old_vc_availability[ii];
                        end
                    end
                end
            end
        end
    end

    for(genvar i=0; i<NUM_PORTS*NUM_VCS; i++)
        assign new_vc_availability[i] = tmp_vc_availability[i];

endmodule