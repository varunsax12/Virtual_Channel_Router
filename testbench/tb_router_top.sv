// Description: Router top testbench
// File Details
//    Author: Varun Saxena
//    GT id: 903562211

`timescale 10ns/1ns

`include "VR_define.vh"

module tb_vc_allocator;
    parameter NUM_PORTS = 5;
    parameter NUM_VCS = 4;
    parameter PORT_BITS = $clog2(NUM_PORTS);
    parameter VC_BITS = $clog2(NUM_VCS);
    reg clk, reset;
    
    logic [`FLIT_DATA_WIDTH-1:0] input_data [NUM_PORTS-1:0];
    logic [NUM_PORTS-1:0] input_valid;

    // Signals from downstream routers for each non-local port
    logic [NUM_PORTS-2:0] dwnstr_router_increment;
    // Signals to upstream routers for each current router port
    logic  [NUM_PORTS-2:0] upstr_router_increment;

    // Waveform compatible
    wire [NUM_VCS*NUM_PORTS-1:0] [NUM_PORTS-1:0] wv_dst_ports;
    wire [NUM_VCS*NUM_PORTS-1:0] [NUM_VCS*NUM_PORTS-1:0] wv_allocated_ip_vcs;
    
    logic [`FLIT_DATA_WIDTH-1:0] out_data [NUM_PORTS-1:0];
    logic [NUM_PORTS-1:0]        out_valid;

    router_top #(
        .NUM_PORTS(NUM_PORTS),
        .NUM_VC(NUM_VCS)
    ) rt (
        .clk(clk),
        .reset(reset),
        .input_data(input_data),
        .input_valid(input_valid),
        .dwnstr_router_increment(dwnstr_router_increment),
        .upstr_router_increment(upstr_router_increment),
        .out_data(out_data),
        .out_valid(out_valid)
    );

    task display();
        $display("Time = %0d", $time);

        $display("**********INPUT SIGNALS******************");
        $display("Reset = %b", reset);
        $display("Input:");
        for (int i = 0; i < NUM_PORTS; ++i) begin
            $display("\tinput_data[%0d]=%b", i, input_data[i]);
        end
        $display("\tinput_valid=%b", input_valid);
        $display("\tdownstream_router_increment=%b", dwnstr_router_increment);
        $display("Outputs:");
        $display("\tupstream_router_increment=%b", upstr_router_increment);
        for (int i = 0; i < NUM_PORTS; ++i) begin
            $display("\tout_data[%0d]=%b", i , out_data[i]);
        end
        $display("\tout_valid=%b", out_valid);

        $display("\n**********VC BUFFER STATUS******************");
        for (int i = 0; i < NUM_PORTS; ++i) begin
            for (int j = 0; j < NUM_VCS; ++j) begin
                $display("Port=%0d, VC=%0d, vc_valid=%b, vc_empty=%b, vc_buffer=%b", i, j, rt.vc_valid[i][j], rt.vc_empty[i][j], rt.vc_buffer[i][j]);
            end
        end

        $display("\n**********BUFFER WRITE******************");
        for (int i = 0; i < NUM_PORTS; ++i) begin
            $display("Port=%0d, empty_vc_index=%0d", i, rt.empty_vc_index[i]);
        end

        $display("\n**********ROUTE COMPUTE******************");
        for (int i = 0; i < NUM_PORTS; ++i) begin
            for (int j = 0; j < NUM_VCS; ++j) begin
                $display("Port=%0d, VC=%0d, dst_port=%b", i, j, rt.dst_port[i*NUM_VCS+j]);
            end
        end

        $display("\n**********VC AVALABILITY******************");
        for(int i = 0; i < NUM_PORTS; ++i) begin
            $display("VCAvailability, Port=%0d, curr_router_decrement:%b, old_vc_availability:%b, new_vc_availability:%b", i, rt.vcavail.curr_router_decrement[i], rt.vcavail.old_vc_availability, rt.vc_availability);
            for(int j = 0; j < NUM_VCS; ++j) begin
                $display("ipvc:%0d, requested_op_vcs:%b, allocated_op_vcs:%b", (i*NUM_VCS+j), rt.vcavail.requested_op_vcs[i*NUM_VCS+j], rt.vcavail.allocated_ip_vcs[i*NUM_VCS+j]);
            end
        end

        $display("\n**********VC ALLOCATION******************");
        for (int i = 0; i < NUM_PORTS; ++i) begin
            for (int j = 0; j < NUM_VCS; ++j) begin
                $display("Port=%0d, VC=%0d, allocated_ip_vcs=%b", i, j, rt.allocated_ip_vcs[i*NUM_VCS+j]);
            end
        end

        $display("\n**********SA ALLOCATION******************");
        for (int i = 0; i < NUM_PORTS; ++i) begin
            $display("Port=%0d, sa_allocated_ports=%b", i, rt.sa_allocated_ports[i]);
        end

        $display("\n**********BUFFER READ******************");
        for (int i = 0; i < NUM_PORTS; ++i) begin
            $display("Port=%0d, vc_index=%0d", i, rt.vc_index[i]);
        end
        for (int i = 0; i < NUM_PORTS; ++i) begin
            $display("Port=%0d, out_buffer_data_per_port=%b", i, rt.out_buffer_data_per_port[i]);
        end

    endtask

    initial begin
        $dumpfile("test.vcd");
        $dumpvars;
        clk = 0;
        @(negedge clk) reset = 0;
        @(negedge clk) reset = 1;
        @(negedge clk) reset = 0;

        for (int i = 0; i < NUM_PORTS; ++i) begin
            for (int j = 0; j < NUM_VCS; ++j) begin
                rt.vc_buffer[i][j][`FLIT_DATA_WIDTH-1-:4] = $urandom%16;
                rt.vc_valid[i][j] = $urandom%2;
            end
        end
    
        // Input_data and 
        foreach(input_data[i]) begin
            input_data[i][`FLIT_DATA_WIDTH-1-:4] = $urandom%16;
            input_valid[i] = 1;
        end
        foreach(dwnstr_router_increment[i]) begin
            dwnstr_router_increment[i] = 0;
            if(i==0)
                dwnstr_router_increment[i] = 1;
        end
        #9;
        display();
        @(negedge clk) $finish;
    end

    always begin
        #10 clk = !clk;
    end

endmodule
