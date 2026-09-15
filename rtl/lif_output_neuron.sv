module lif_output_neuron (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        spike_valid,
    input  wire [7:0]  hidden_spikes,
    input  wire [7:0]  weights,
    input  wire [15:0] membrane,
    input  wire [15:0] threshold,
    input  wire [15:0] decay,
    output reg  [15:0] membrane_out,
    output reg         spike_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            membrane_out <= 16'd0;
            spike_out <= 1'b0;
        end else if (spike_valid) begin
            // Count active hidden spikes (simplified)
            reg [3:0] spike_count;
            spike_count <= $countones(hidden_spikes);
            
            // Decay
            membrane_out <= (membrane * decay) >>> 8;
            // Accumulate (placeholder: each spike adds 0.25)
            membrane_out <= membrane_out + ({12'd0, spike_count} << 6);
            
            // Spike generation
            if (membrane_out >= threshold) begin
                spike_out <= 1'b1;
                membrane_out <= membrane_out - threshold;
            end else begin
                spike_out <= 1'b0;
            end
        end else begin
            // No spikes: decay only
            membrane_out <= (membrane * decay) >>> 8;
            spike_out <= 1'b0;
        end
    end

endmodule