module lif_hidden_layer (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        spike_valid,
    input  wire [5:0]  active_idx [3:0],
    input  wire [511:0] weights,         // 64×8 weights (8-bit each)
    input  wire [15:0] membrane [7:0],
    input  wire [15:0] threshold [7:0],
    input  wire [15:0] decay [7:0],
    output reg  [15:0] membrane_out [7:0],
    output reg  [7:0]  spikes_out
);

    // Placeholder weights (all = 0.1 in Q4.12 = 16'h066)
    wire [7:0] weights_placeholder [511:0];
    integer i;
    genvar j;
    generate
        for (j = 0; j < 512; j = j + 1) begin
            assign weights_placeholder[j] = 8'h40;  // Placeholder: 0.25
        end
    endgenerate
    
    // LIF dynamics for each neuron
    integer n;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (n = 0; n < 8; n = n + 1) begin
                membrane_out[n] <= 16'd0;
                spikes_out[n] <= 1'b0;
            end
        end else if (spike_valid) begin
            // Accumulate input from active spikes
            reg [15:0] input_current [7:0];
            for (n = 0; n < 8; n = n + 1) begin
                input_current[n] <= 16'd0;
                // Add weights for each active input (simplified: use placeholder)
                input_current[n] <= input_current[n] + 16'h066;  // Placeholder weight
            end
            
            // Update membrane and generate spikes
            for (n = 0; n < 8; n = n + 1) begin
                // Decay
                membrane_out[n] <= (membrane[n] * decay[n]) >>> 8;
                // Accumulate
                membrane_out[n] <= membrane_out[n] + input_current[n];
                // Spike generation
                if (membrane_out[n] >= threshold[n]) begin
                    spikes_out[n] <= 1'b1;
                    membrane_out[n] <= membrane_out[n] - threshold[n];  // Subtract reset
                end else begin
                    spikes_out[n] <= 1'b0;
                end
            end
        end else begin
            // No spikes: decay only
            for (n = 0; n < 8; n = n + 1) begin
                membrane_out[n] <= (membrane[n] * decay[n]) >>> 8;
                spikes_out[n] <= 1'b0;
            end
        end
    end

endmodule