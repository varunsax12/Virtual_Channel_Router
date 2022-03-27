// Description: Module to compute the new vc_availability and upstream signals
// Reference: M06-RouterMicroarchitecture in ECE6115, Prof. Tushar Krishna
// File Details
//    Author: Sandilya Balemarthy
//    GT id: 903482005

`timescale 10ns/1ns

module vc_availability #(
    parameter NUM_PORTS = 5,
    parameter NUM_VCS = 4
) (
    // Standard clock and reset signals
    input logic clk, 
    input logic reset,
    // Flit final destination ports as computed by route compute
    input logic  [NUM_PORTS-1:0] vca_dst_port [NUM_VCS*NUM_PORTS-1:0],
    // Credits from down stream routers
    input logic  [NUM_PORTS-2:0] dwnstr_router_increment,
    // Opports allocated for each ip port
    input logic  [NUM_PORTS-1:0] sa_allocated_ports [NUM_PORTS-1:0],
    // Opvcs allocated for each ip vcs
    input logic  [NUM_VCS*NUM_PORTS-1:0] allocated_ip_vcs [NUM_VCS*NUM_PORTS-1:0],
    // Latest vc availability based on down stream credit increments, allocated ports in the current router
    output logic [NUM_VCS*NUM_PORTS-1:0] vc_availability,
    // Upstream credit increments based on flits released in current router
    output logic [NUM_PORTS-2:0] upstr_router_increment
);
    /*
    NOTE: Need to consider only NUM_PORTS-1 ports for downstream and upstream, as local port as port[NUM_PORTS-2]
    router_top will take the following inputs=>
        1. dwnstr_router_increment[NUM_PORTS-2:0] signals for each of its ports except local, external signals
        2. curr_router_decrement[NUM_PORTS-2:0] signals from the switch allocator continously
        3. always @(posedge clk) store the result of 
        (switch allocator outputs && vc allocator outputs) into a temporary register called old_vc_availability.
            ->if(reset) assign old_vc_availability to all 1s.
        4. upstr_router_increment[NUM_PORTS-2:0] signals 
            ->based on requests to VCA and grants to SA send increment signals for each of current routers ports.

    instantiate this combinatorial ckt and use the new_vc_availability=>
    update_vca #(.NUM_PORTS(NUM_PORTS),.NUM_VCS(NUM_VCS)) uvca (.curr_router_decrement(curr_router_decrement),
    .dwnstr_router_increment(dwnstr_router_increment), .old_vc_availability(old_vc_availability),
    .new_vc_availability(new_vc_availability));
    */
    
    localparam local_port_index = 0;
    // Connect expanded dwnstr_router_increment 
    logic exdwnstr_router_increment [NUM_PORTS-1:0];
    assign exdwnstr_router_increment[local_port_index] = 0;
    for(genvar i=0; i<NUM_PORTS-1; i=i+1) begin
        //Mask local port with 0
        assign exdwnstr_router_increment[i+1] = dwnstr_router_increment[i];
    end
    
    // Connect shrunk upstr_router_increment
    logic exupstr_router_increment [NUM_PORTS-1:0];
    for(genvar i=0; i<NUM_PORTS-1; i=i+1) begin
        //Connects only non-local ports
        assign upstr_router_increment[i] = exupstr_router_increment[i+1];
    end
    
    // Expand [NUM_PORTS-1:0] old_allocated_ports [NUM_PORTS-1:0] to [NUM_VCS*NUM_PORTS-1:0] old_allocated_ip_vcs [NUM_VCS*NUM_PORTS-1:0]
    logic [NUM_VCS*NUM_PORTS-1:0] final_allocated_ip_vcs [NUM_VCS*NUM_PORTS-1:0];
    // Iterate over every ip vc
    for(genvar i=0; i<NUM_PORTS; i=i+1) begin
        for(genvar j=0; j<NUM_VCS; j=j+1) begin
            // Iterate over every bit, assign the result of allocated_ports & allocated_ip_vcs
            for(genvar ii=0; ii<NUM_PORTS; ii=ii+1) begin
                for(genvar jj=0; jj<NUM_VCS; jj=jj+1) begin
                    assign final_allocated_ip_vcs[i*NUM_VCS+j][ii*NUM_VCS+jj] = sa_allocated_ports[i][ii] & allocated_ip_vcs[i*NUM_VCS+j][ii*NUM_VCS+jj];
                end
            end
        end
    end
    
    // Convert to old_vc_availability vector
    logic [NUM_VCS*NUM_PORTS-1:0] comb_old_vc_unavailability;
    logic [NUM_VCS*NUM_PORTS-1:0] comb_old_vc_availability;
    always_comb begin
        comb_old_vc_unavailability = 0;
        //NOTE: The below nested for will store all the vcs that are unavailable.
        //We invert the output after the for to get available vcs
        for(int i=0; i<NUM_PORTS; i=i+1) begin
            for(int j=0; j<NUM_VCS; j=j+1) begin
                comb_old_vc_unavailability = comb_old_vc_unavailability | final_allocated_ip_vcs[i*NUM_VCS+j];
            end
        end
        //Invert and store each bit
        for(int i=0; i<NUM_PORTS*NUM_VCS; i=i+1) begin
            comb_old_vc_availability[i] = !comb_old_vc_unavailability[i];
        end
    end
    
    // Store old_vc_availability into temp register
    logic [NUM_VCS*NUM_PORTS-1:0] old_vc_availability;
    always @ (posedge clk) begin
        if(reset) begin
            old_vc_availability <= {(NUM_VCS*NUM_PORTS){1'b1}};
        end else begin
            old_vc_availability <= comb_old_vc_availability;
        end
    end
    
    // Instantiate module to update vc_availability
    logic curr_router_decrement [NUM_PORTS-1:0] ; // Updated in the end of VC Availability
    update_vca #(.NUM_PORTS(NUM_PORTS),.NUM_VCS(NUM_VCS)) uvca (.curr_router_decrement(curr_router_decrement),
    .dwnstr_router_increment(exdwnstr_router_increment), .old_vc_availability(old_vc_availability),
    .new_vc_availability(vc_availability));
    // Increment & Decrement based on Current router decisions=>
    // Get the requested op vcs for every ip vc
    logic [NUM_VCS*NUM_PORTS-1:0] requested_op_vcs [NUM_VCS*NUM_PORTS-1:0];
    for(genvar i=0; i<NUM_PORTS; i=i+1) begin
        for(genvar j=0; j<NUM_VCS; j=j+1) begin
            for(genvar ii=0; ii<NUM_PORTS; ii=ii+1) begin
                for(genvar jj=0; jj<NUM_VCS; jj=jj+1) begin
                    assign requested_op_vcs[i*NUM_VCS+j][ii*NUM_VCS+jj] = vca_dst_port[i*NUM_VCS+j][ii];
                end
            end
        end
    end
    
    // Based on the requests that are cleared (flit released)
    // 1. Assign upstream router increment signals, indicating that the request has been granted.
    // 2. Assign current router decrement signals, indicating latest vc availability.
    //logic upstr_router_increment [NUM_PORTS-1:0];
    always_comb begin
        // Re-initialize counter
        for(int i=0; i<NUM_PORTS; i=i+1)
            curr_router_decrement[i] = 0;

        for(int i=0; i<NUM_PORTS; i=i+1) begin
            if(|sa_allocated_ports[i]) begin
                // Request granted
                exupstr_router_increment[i] = 1; //0;
                for(int ii=0; ii<NUM_PORTS; ii=ii+1) begin
                    if(sa_allocated_ports[i][ii])
                        curr_router_decrement[ii] = 1;
                end
            end else begin
                // Request not granted
                exupstr_router_increment[i] = 0; //1;               
            end
        end
    end

            /*
            for(int j=0; j<NUM_VCS; j=j+1) begin
                if( 
                    (|requested_op_vcs[i*NUM_VCS+j]!=0) && 
                    !(|(allocated_ip_vcs[i*NUM_VCS+j] & requested_op_vcs[i*NUM_VCS+j]))
                ) begin
                    exupstr_router_increment[i] = 1;
                    curr_router_decrement[i] = 0;
                end else begin
                    exupstr_router_increment[i] = 0;
                    curr_router_decrement[i] = 1;                    
                end
            end
            */

endmodule