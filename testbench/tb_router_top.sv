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
    logic dwnstr_router_increment [NUM_PORTS-2:0];
    // Signals to upstream routers for each current router port
    logic upstr_router_increment [NUM_PORTS-2:0];

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

    always @(posedge clk) begin
        $display("VC UP&DOWN STREAM SIGNALS:");
        for (int i = 0; i < NUM_PORTS-1; ++i) begin
            $display("Signals, port=%d, dwnstr_router_increment=%b, upstr_router_increment=%b, old_vc_availability:%b, new_vc_availability:%b", i, dwnstr_router_increment[i], upstr_router_increment[i], rt.old_vc_availability, rt.vc_availability);
        end
        $display("\n\n");
    end

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
                $display("Port = %d, VC = %d, dest = %d", i, j, rt.vc_buffer[i][j][`FLIT_DATA_WIDTH-1-:4]);
            end
        end
    
        // Input_data and 
        foreach(input_data[i]) begin
            input_data[i] = 1;
            input_valid[i] = 1;
        end
        foreach(dwnstr_router_increment[i]) begin
            dwnstr_router_increment[i] = 0;
            if(i==0)
                dwnstr_router_increment[i] = 1;
        end

        $display("VC BUFFER STATE PER OPERATION:");
        for (int i = 0; i < NUM_PORTS; ++i) begin
            for (int j = 0; j < NUM_VCS; ++j) begin
                $display("Buffer, port=%d, vc=%d, valid=%b, data=%b", i, j, rt.vc_valid[i][j], rt.vc_buffer[i][j]);
            end
        end
        for (int i = 0; i < 1; ++i) begin
            // NOTE: In current test setup, takes 2 cycles to reach switch traversed state
            @(negedge clk);
            @(negedge clk);
            // @(negedge clk) begin
            //     vc_availability[0] = 0;
            // end
            for (int i = 0; i < NUM_PORTS; ++i) begin
                for (int j = 0; j < NUM_VCS; ++j) begin
                    $display("Port req, Port = %d, VC = %d, %b", i, j, rt.dst_port[i*NUM_VCS+j]);
                end
            end
            for (int i = 0; i < NUM_PORTS; ++i) begin
                for (int j = 0; j < NUM_VCS; ++j) begin
                    $display("VC alloc, %d, %b, %b", i, rt.vca.available_op_vcs[i*NUM_VCS+j], rt.allocated_ip_vcs[i*NUM_VCS+j]);
                end
            end
            for (int i = 0; i < NUM_PORTS; ++i) begin
                for (int j = 0; j < NUM_VCS; ++j) begin
                    $display("VC alloc..2, %d, %b", i, rt.vc_grants[i*NUM_VCS+j]);
                end
            end
            for (int i = 0; i < NUM_PORTS; ++i) begin
                $display("req2port , %d, %b", i, rt.port_req[i]);
            end
            for (int i = 0; i < NUM_PORTS; ++i) begin
                $display("SAlloc, %d, %b", i, rt.allocated_ports[i]);
            end
            for (int i = 0; i < NUM_PORTS; ++i) begin
                $display("vc index = %d, %b, %b", i, rt.vc_index[i], rt.vc_read_valid[i]);
            end
            for (int i = 0; i < NUM_PORTS; ++i) begin
                $display("buffer read, %d, %b", i, rt.out_buffer_data_per_port[i]);
            end
            for (int i = 0; i < NUM_PORTS; ++i) begin
                $display("vc_read_valid, %d, %b", i, rt.vc_read_valid[i]);
            end
            $display("OUTPUT DATA:");
            for (int i = 0; i < NUM_PORTS; ++i) begin
                $display("port index = %d, valid=%b, data=%b", i, out_valid[i], out_data[i]);
            end
            $display("VC BUFFER STATE:");
            for (int i = 0; i < NUM_PORTS; ++i) begin
                for (int j = 0; j < NUM_VCS; ++j) begin
                    $display("Buffer, port=%d, vc=%d, valid=%b, data=%b", i, j, rt.vc_valid[i][j], rt.vc_buffer[i][j]);
                end
            end
        end
        $finish;
        //#20
        //foreach(dst_port[i]) begin
        //    dst_port[i] = 0;
        //end
        //foreach(vc_availability[i]) begin
        //    vc_availability[i] = 0;
        //end
    end

    always begin
        #5 clk = !clk;
    end

endmodule
