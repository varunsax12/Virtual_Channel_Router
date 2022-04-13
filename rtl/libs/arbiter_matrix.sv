// Description: Matrix arbiter design
// Reference: M06-RouterMicroarchitecture in ECE6115, Prof. Tushar Krishna
// File Details
//    Author: Sandilya Balemarthy
//    GT id: 903482005

`timescale 10ns/1ns

module arbiter_matrix #(
    parameter NUM_REQS = 3
) (
    // Standard
    input wire                 clk,
    input wire                 reset,
    // Requests to the arbiter
    input wire  [NUM_REQS-1:0] requests,
    // Grants from the arbiter
    output wire [NUM_REQS-1:0] grants
);

    logic weight_mat[NUM_REQS-1:0][NUM_REQS-1:0];
    logic dable[NUM_REQS-1:0];
    logic tmp_dable[NUM_REQS-1:0][NUM_REQS-1:0];
    logic tmp_or[NUM_REQS-1:0][NUM_REQS-1:0];

    // Disable signals
    always_comb begin
        for(int i=0; i<NUM_REQS; i=i+1) begin
            dable[i] = 0;
            for(int j=0; j<NUM_REQS; j=j+1) begin
                dable[i] = dable[i] || ((i==j) ? 0 : (weight_mat[j][i] && requests[j]));
            end
        end
    end

    // Grant Policy
    for(genvar i = 0; i < NUM_REQS; i=i+1) begin
        assign grants[i] = requests[i] && !dable[i];
    end

    // Update Policy
    always @(posedge clk) begin
        if(reset) begin
            // Reset matrix with preference for 0 over all, 1 over 2+, 2 over 3+
            for(int m=0; m<NUM_REQS; m=m+1) begin
                for(int n=0; n<NUM_REQS; n=n+1) begin
                    weight_mat[m][n] <= (m<=n) ? 1 : 0;
                end
            end
        end
        else begin
            for(int m=0; m<NUM_REQS; m=m+1) begin
                for(int n=0; n<NUM_REQS; n=n+1) begin
                    if(grants[m]) begin
                        // Reset row
                        weight_mat[m][n] <= 0;
                        // Set col
                        weight_mat[n][m] <= 1;
                    end
                end
            end
        end
    end

endmodule