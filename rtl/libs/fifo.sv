// Description: Module for fifo
// File Details
//    Author: Varun Saxena
//    GT id: 903562211

module fifo #(
    parameter FIFO_DEPTH = 8,
    parameter DATA_WIDTH = `FLIT_DATA_WIDTH,
    parameter POINTER_WIDTH = $clog2(FIFO_DEPTH) + 1
) (
    input logic clk, reset, push, pop,
    input logic [DATA_WIDTH-1:0]    indata,
    output logic empty, full,
    output logic [DATA_WIDTH-1:0]   outdata
    // output logic [POINTER_WIDTH-1:0] size
);

    logic [POINTER_WIDTH-1:0] size;
    // Registers for the fifo
    reg [DATA_WIDTH-1:0]    buffer [FIFO_DEPTH-1:0];
    // Pointers
    logic [POINTER_WIDTH-1:0] wr_ptr, rd_ptr;
    // Tracker for last action
    logic last_write;

    always @(posedge clk) begin
        if (reset) begin
            wr_ptr     <= 0;
            rd_ptr     <= 0;
            last_write <= 0;
        end
        else begin
            if (push && !full) begin
                buffer[wr_ptr] <= indata;
                last_write     <= 1;
                if (wr_ptr == (FIFO_DEPTH-1)) begin
                    wr_ptr     <= 0;
                end
                else begin
                    wr_ptr     <= wr_ptr + 1;
                end
                size <= size + 1;
            end
            if (pop && !empty) begin
                // The FIFO has an active out to save cycles
                //outdata    <= buffer[rd_ptr];
                last_write <= 0;
                if (rd_ptr == (FIFO_DEPTH-1)) begin
                    rd_ptr <= 0;
                end
                else begin
                    rd_ptr <= rd_ptr + 1;
                end
                size <= size - 1;
            end
            // if both push and pop, then no change
            if ((push && !full) && (pop && !empty)) begin
                size <= size;
            end
        end
    end

    assign outdata = buffer[rd_ptr];
    assign empty  = (wr_ptr == rd_ptr) && !last_write;
    assign full   = (wr_ptr == rd_ptr) && last_write;

endmodule