// Description: Module to act as priority encoder
// Possible improvement: If size known, then switch case statement can be
// used for a better structure

module priority_encoder #(
    parameter NUM_INPUTS = 4,
    parameter NUM_BITS   = $clog2(NUM_INPUTS)
) (
    input [NUM_INPUTS-1:0]      in_signals,
    output reg [NUM_BITS-1:0]   out_index
);

    always_comb begin
        out_index = 0;
        for (int i = NUM_INPUTS-1; i >= 0; --i) begin
            if (in_signals[i]) out_index = i;
        end
    end

endmodule
