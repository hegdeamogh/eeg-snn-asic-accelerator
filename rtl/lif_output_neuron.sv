`timescale 1ns/1ps

module lif_output_neuron (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        spike_valid,
    input  wire [7:0]  hidden_spikes,
    input  wire [7:0]  weights,          // not yet wired in
    input  wire [15:0] membrane,
    input  wire [15:0] threshold,
    input  wire [15:0] decay,
    output reg  [15:0] membrane_out,
    output reg         spike_out
);

    reg [15:0] decayed;
    reg [3:0]  spike_count;
    reg [15:0] input_current;
    reg [15:0] accumulated;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            membrane_out <= 16'd0;
            spike_out    <= 1'b0;
        end else begin
            decayed = (membrane * decay) >>> 8;

            if (spike_valid) begin
                spike_count   = $countones(hidden_spikes);
                input_current = {12'd0, spike_count} << 6;  // Placeholder: 0.25/spike
            end else begin
                input_current = 16'd0;
            end

            accumulated = decayed + input_current;

            if (accumulated >= threshold) begin
                membrane_out <= accumulated - threshold;
                spike_out    <= 1'b1;
            end else begin
                membrane_out <= accumulated;
                spike_out    <= 1'b0;
            end
        end
    end

endmodule
