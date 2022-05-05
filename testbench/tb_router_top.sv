// Description: Router top testbench
// File Details
//    Author: Varun Saxena
//    GT id: 903562211

`timescale 10ns/1ns
`include "VR_define.vh"

module tb_router_top();
    localparam NUM_PORTS = 5;
    localparam NUM_VCS = 4;
    localparam PORT_BITS = $clog2(NUM_PORTS);
    localparam VC_BITS = $clog2(NUM_VCS);
    localparam NUM_ROUTERS = 16;
    localparam ROUTER_ID_BITS = $clog2(NUM_ROUTERS);
    reg clk, reset;
    
    logic [`FLIT_DATA_WIDTH-1:0] input_data [NUM_PORTS-1:0];
    logic [NUM_PORTS-1:0] input_valid;

    // Signals from downstream routers for each non-local port
    logic dwnstr_credit_increment [NUM_PORTS-2:0][NUM_VCS-1:0];
    // Signals to upstream routers for each current router port
    logic upstr_credit_increment [NUM_PORTS-2:0][NUM_VCS-1:0];

    // Waveform compatible
    wire [NUM_VCS*NUM_PORTS-1:0] [NUM_PORTS-1:0] wv_dst_ports;
    wire [NUM_VCS*NUM_PORTS-1:0] [NUM_VCS*NUM_PORTS-1:0] wv_allocated_op_vcs;
    
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
        .dwnstr_credit_increment(dwnstr_credit_increment),
        .upstr_credit_increment(upstr_credit_increment),
        .out_data(out_data),
        .out_valid(out_valid)
    );

    task display();
        $display("\n\n********************Time = %0d***********", $time);

        $display("**********INPUT SIGNALS******************");
        $display("Reset = %b", reset);
        $display("Input:");
        for (int i = 0; i < NUM_PORTS; ++i) begin
            $display("\tinput_data[%0d]=%b", i, input_data[i]);
        end
        $display("\tinput_valid=%b", input_valid);
        for(int i = 0; i < NUM_PORTS-1; i++) begin
            for(int j = 0; j < NUM_VCS; j++)
                $display("\top port:%d, op vc:%d, downstream_router_increment=%b", i+1, j, dwnstr_credit_increment[i][j]);
        end
        $display("Outputs:");
        for(int i = 0; i < NUM_PORTS-1; i++) begin
            for(int j = 0; j < NUM_VCS; j++)
                $display("\tip port:%d, ip vc:%d, upstream_router_increment=%b", i+1, j, upstr_credit_increment[i][j]);
        end
        for (int i = 0; i < NUM_PORTS; ++i) begin
            $display("\tout_data[%0d]=%b", i , out_data[i]);
        end
        $display("\tout_valid=%b", out_valid);

        $display("\n**********VC BUFFER STATUS******************");
        for (int i = 0; i < NUM_PORTS; ++i) begin
            for (int j = 0; j < NUM_VCS; ++j) begin
                $display("Port=%0d, VC=%0d, vc_valid=%b, vc_empty=%b, vc_buffer=%b", i, j, rt.vc_valid[i][j], rt.vc_empty[i][j], rt.vc_outdata[i][j]);
            end
        end

        $display("\n**********BUFFER WRITE******************");
        for (int i = 0; i < NUM_PORTS; ++i) begin
            $display("Port=%0d, VC==%0d", i, rt.input_data[i][`FLIT_DATA_WIDTH-1-:VC_BITS]);
        end

        $display("\n**********ROUTE COMPUTE******************");
        for (int i = 0; i < NUM_PORTS; ++i) begin
            for (int j = 0; j < NUM_VCS; ++j) begin
                $display("Port=%0d, VC=%0d, dst_port=%b", i, j, rt.rc_dst_port[i*NUM_VCS+j]);
            end
        end

        $display("\n**********VC AVALABILITY******************");
        for(int i = 0; i < NUM_PORTS; ++i) begin
            for(int j = 0; j < NUM_VCS; ++j) begin
                $display("VCAvailability, out port=%0d, out vc=%0d, credits:%b, new_vc_availability:%b", i, j, rt.vcavail.credits[i][j], rt.vca_vc_availability);
            end
        end
        $display("\nMask Generation:");
        for (int i = 0; i < NUM_PORTS; ++i) begin
            for (int j = 0; j < NUM_VCS; ++j) begin
                $display("Port=%0d, VC=%0d, VC dst port=%b, SA dst port=%b, BR dst port=%b, valid=%b", i, j, rt.vca_dst_port[i*NUM_VCS + j], rt.sa_allocated_ports[i], rt.br_allocated_ports[i], rt.vca_dst_valid[i*NUM_VCS+j]);
            end
        end

        $display("\n**********VC ALLOCATION******************");
        for (int i = 0; i < NUM_PORTS; ++i) begin
            for (int j = 0; j < NUM_VCS; ++j) begin
                //$display("Port=%0d, VC=%0d, allocated_op_vcs=%b", i, j, rt.allocated_op_vcs[i*NUM_VCS+j]);
                // $display("Port:%0d, Vc=%0d, allocated_op_vcs:%b, sa_allocated_ports=%b", i, j, rt.vcavail.allocated_op_vcs[i*NUM_VCS+j], rt.vcavail.sa_allocated_ports[i]);
                $display("Port:%0d, Vc=%0d, allocated_op_vcs:%b", i, j, rt.vca_allocated_op_vcs[i*NUM_VCS+j]);
            end
        end

        $display("\n**********SA ALLOCATION******************");
        for (int i = 0; i < NUM_PORTS; ++i) begin
            $display("Port=%0d, sa_allocated_ports=%b", i, rt.sa_allocated_ports[i]);
        end

        $display("\n**********BUFFER READ******************");
        for (int i = 0; i < NUM_PORTS; ++i) begin
            $display("Port=%0d, vc_index=%0d vc_valid=%b", i, rt.br_vc_index[i], rt.br_vc_read_valid[i]);
        end
        for (int i = 0; i < NUM_PORTS; ++i) begin
            $display("Port=%0d, br_allocated_ports=%b", i, rt.br_allocated_ports[i]);
        end


        $display("\n**********SWITCH TRAVERSAL******************");
        for (int i = 0; i < NUM_PORTS; ++i) begin
            $display("Port=%0d, out_data=%b, out_valid=%b, valid=%b", i, rt.out_data[i], rt.out_valid[i], rt.st_vc_read_valid);
        end
    endtask

    always @(negedge clk) begin
        display();
    end

    task set_new_inputs();
        $display("\nSetting new inputs at Time = %0d", $time);
        foreach(dwnstr_credit_increment[i]) begin
            for(int j = 0; j < NUM_VCS; j++) begin
                dwnstr_credit_increment[i][j] = 0;
                if(i==0)
                    dwnstr_credit_increment[i][j] = 0;
            end
        end
        foreach(input_data[i]) begin
            input_data [i] = 0;
            //Embed destination
            input_data [i][`FLIT_DATA_WIDTH-VC_BITS-1-:ROUTER_ID_BITS] |= $urandom()%NUM_ROUTERS;
            input_data [i][`FLIT_DATA_WIDTH-1-:VC_BITS] = $urandom()%NUM_VCS;
            input_data [i] |= $urandom()%2048; // create unique identifier to track the flit
            input_valid[i] = 1;
        end
    endtask

    initial begin
        $dumpfile("test.vcd");
        $dumpvars;
        clk = 0;
        @(negedge clk) reset = 0;
        @(negedge clk) reset = 1;
        @(negedge clk) reset = 0;

        //===============Input_data feed==================
        set_new_inputs();
        @(negedge clk)
        set_new_inputs();
        @(negedge clk)
        //================================================

        $display("\nFlusing input data by invalidating all input ports");
        //==============Input_data reset==================
        foreach(input_data[i]) begin
            input_valid[i] = 0;
            input_data[i]  = 0;
        end
        //================================================

        //==============Downstream signal=================
        for (int i = 0; i < 10; ++i) begin
            @(negedge clk);
            //display();
            if(i==5) begin
                $display("\nDownstream router op port 2, op vc 2, sends a credit, i=%0d",i);
                dwnstr_credit_increment[1][2] = 1;
                #1
                dwnstr_credit_increment[1][2] = 0;
            end else begin
                dwnstr_credit_increment[1][2] = 0;
            end
        end
        //================================================
        
        $finish;
    end

    always begin
        #10 clk = !clk;
    end

endmodule