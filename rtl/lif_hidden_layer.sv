`timescale 1ns/1ps

module lif_hidden_layer (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        spike_valid,
    input  wire [5:0]  active_idx [3:0],
    input  wire [4095:0] weights,         // 64x8 weights (8-bit each) - not yet wired in
    input  wire [15:0] membrane [7:0],
    input  wire [15:0] threshold [7:0],
    input  wire [15:0] decay [7:0],
    output reg  [15:0] membrane_out [7:0],
    output reg  [7:0]  spikes_out
);

    integer n;
    reg [15:0] decayed       [7:0];
    reg [15:0] input_current [7:0];
    reg [15:0] accumulated   [7:0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (n = 0; n < 8; n = n + 1) begin
                membrane_out[n] <= 16'd0;
                spikes_out[n]   <= 1'b0;
            end
        end else begin
            for (n = 0; n < 8; n = n + 1) begin
                decayed[n]       = (membrane[n] * decay[n]) >>> 8;
                input_current[n] = spike_valid ? 16'h066 : 16'd0;  // Placeholder weight
                accumulated[n]   = decayed[n] + input_current[n];

                if (accumulated[n] >= threshold[n]) begin
                    membrane_out[n] <= accumulated[n] - threshold[n];
                    spikes_out[n]   <= 1'b1;
                end else begin
                    membrane_out[n] <= accumulated[n];
                    spikes_out[n]   <= 1'b0;
                end
            end
        end
    end

endmodule
