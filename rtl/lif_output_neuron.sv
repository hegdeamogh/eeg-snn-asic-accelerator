`timescale 1ns/1ps
module lif_output_neuron (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       step,            // = hidden layer's valid
    input  wire [7:0] hidden_spikes,
    output reg        valid,           // step delayed 1 cycle, aligned with spike_out
    output reg        spike_out        // 1-cycle pulse
);
`include "snn_weights.vh"

    reg signed [15:0] v;
    reg signed [17:0] acc;
    integer k;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            v         <= 16'sd0;
            spike_out <= 1'b0;
            valid     <= 1'b0;
        end else begin
            valid <= step;
            if (step) begin
                acc = v - (v >>> OUT_LEAK_SHIFT);
                for (k = 0; k < 8; k = k + 1)
                    if (hidden_spikes[k]) acc = acc + w_out(k[2:0]);
                if (acc >  18'sd32767)  acc =  18'sd32767;
                if (acc < -18'sd32768)  acc = -18'sd32768;
                if (acc >= OUT_THRESH) begin
                    v         <= acc[15:0] - OUT_THRESH;
                    spike_out <= 1'b1;
                end else begin
                    v         <= acc[15:0];
                    spike_out <= 1'b0;
                end
            end else begin
                spike_out <= 1'b0;
            end
        end
    end
endmodule
