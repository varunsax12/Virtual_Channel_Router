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
    reg clk, rstn;
    reg [NUM_VCS*NUM_PORTS-1:0] vc_availability;

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
        .reset(rstn),
        .vc_availability(vc_availability),
        .out_data(out_data),
        .out_valid(out_valid)
    );

    initial begin
        $dumpfile("test.vcd");
        $dumpvars;
        clk = 0;
        @(negedge clk) rstn = 0;
        @(negedge clk) rstn = 1;
        @(negedge clk) rstn = 0;

        for (int i = 0; i < NUM_PORTS; ++i) begin
            for (int j = 0; j < NUM_VCS; ++j) begin
                rt.vc_buffer[i][j][`FLIT_DATA_WIDTH-1-:4] = $urandom%16;
                rt.vc_valid[i][j] = $urandom%2;
                $display("Port = %d, VC = %d, dest = %d", i, j, rt.vc_buffer[i][j][`FLIT_DATA_WIDTH-1-:4]);
            end
        end
        foreach(vc_availability[i]) begin
            vc_availability[i] = 1;
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
