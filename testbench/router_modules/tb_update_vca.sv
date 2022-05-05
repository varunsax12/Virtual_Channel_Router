// Description: VC Separable allocator testbench
// Reference: M06-RouterMicroarchitecture in ECE6115, Prof. Tushar Krishna
// File Details
//    Author: Sandilya Balemarthy

`timescale 10ns/1ns

module tb_update_vca;
    parameter NUM_PORTS = 5;
    parameter NUM_VCS = 4;
    reg clk, reset;
    reg curr_router_decrement[NUM_PORTS-1:0];
    reg dwnstr_router_increment[NUM_PORTS-1:0];
    reg [NUM_VCS*NUM_PORTS-1:0] old_vc_availability;
    wire [NUM_VCS*NUM_PORTS-1:0] new_vc_availability;

    update_vca #(.NUM_PORTS(NUM_PORTS),.NUM_VCS(NUM_VCS)) uvca (.curr_router_decrement(curr_router_decrement),
    .dwnstr_router_increment(dwnstr_router_increment), .old_vc_availability(old_vc_availability),
    .new_vc_availability(new_vc_availability));

    always @(posedge clk) begin
        for (int i = 0; i < NUM_PORTS; ++i) begin
            $display ("Time = %d, Port=%d, curr_router_decrement[port]=%b, dwnstr_router_increment[port]=%b, old_vc_availability=%b, new_vc_availability=%b", $time,i,curr_router_decrement[i],dwnstr_router_increment[i],old_vc_availability,new_vc_availability);
        end
        $display("\n\n");
    end

    initial begin
        $dumpfile("tb_update_vca.vcd");
        $dumpvars;
        clk = 0;
        @(negedge clk) reset = 0;
        @(negedge clk) reset = 1;
        @(negedge clk) reset = 0;
        foreach(old_vc_availability[i]) begin
            old_vc_availability[i] = 1;
            if(i==NUM_PORTS*NUM_VCS-1)
                old_vc_availability[i] = 0;
        end
        foreach(dwnstr_router_increment[i]) begin
            if(i==0)
                dwnstr_router_increment[i] = 1;
            dwnstr_router_increment[i] = 0;
        end
        foreach(curr_router_decrement[i]) begin
            curr_router_decrement[i] = 0;
        end
        #20
        curr_router_decrement[0] = 1;
        #20
        curr_router_decrement[0] = 0;
        #20
        dwnstr_router_increment[NUM_PORTS-1] = 1;
        #20
        $finish;   
    end

    always begin
        #5 clk = !clk;
    end

endmodule
