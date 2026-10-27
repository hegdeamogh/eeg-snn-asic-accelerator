`timescale 1ns/1ps
module lif_hidden_layer (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        step,          // one pulse per ADC sample
    input  wire [23:0] gidx,          // 4 active global input indices
    output reg         valid,         // step delayed 1 cycle, aligned with spikes_out
    output reg  [7:0]  spikes_out     // 1-cycle pulses
);
`include "snn_weights.vh"

    reg signed [15:0] v [0:7];
    reg signed [17:0] acc;
    integer n;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (n = 0; n < 8; n = n + 1) v[n] <= 16'sd0;
            spikes_out <= 8'd0;
            valid      <= 1'b0;
        end else begin
            valid <= step;
            if (step) begin
                for (n = 0; n < 8; n = n + 1) begin
                    acc = (v[n] - (v[n] >>> HID_LEAK_SHIFT))        // shift-add leak
                        + w_hid(gidx[5:0],   n[2:0])
                        + w_hid(gidx[11:6],  n[2:0])
                        + w_hid(gidx[17:12], n[2:0])
                        + w_hid(gidx[23:18], n[2:0]);
                    if (acc >  18'sd32767)  acc =  18'sd32767;      // saturate to 16 bit
                    if (acc < -18'sd32768)  acc = -18'sd32768;
                    if (acc >= HID_THRESH) begin
                        v[n]          <= acc[15:0] - HID_THRESH;    // soft reset
                        spikes_out[n] <= 1'b1;
                    end else begin
                        v[n]          <= acc[15:0];
                        spikes_out[n] <= 1'b0;
                    end
                end
            end else begin
                spikes_out <= 8'd0;
            end
        end
    end
endmodule
