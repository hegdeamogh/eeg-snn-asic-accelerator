`timescale 1ns/1ps
module neuromorphic_acc #(
    parameter [47:0] LEVEL_MIN  = 48'd0,
    parameter [15:0] STEP_SHIFT = {4'd8, 4'd8, 4'd8, 4'd8}
)(
    input  wire        clk_50mhz,
    input  wire        rst_n,

    input  wire [11:0] adc_ch0,
    input  wire [11:0] adc_ch1,
    input  wire [11:0] adc_ch2,
    input  wire [11:0] adc_ch3,
    input  wire        adc_valid,        // strobe at 256 Hz (may be asynchronous / multi-cycle)

    output wire        seizure_detect,

    output wire [8:0]  debug_firing_rate,
    output wire        debug_hidden_spikes,
    output wire        debug_output_spike
);
    // ---- adc_valid: synchronize + rising-edge detect -> 1-cycle sample_pulse ----
    // Assumes adc_ch* are held stable for >= 3 clk cycles around the strobe.
    reg [2:0] valid_sync;
    always @(posedge clk_50mhz or negedge rst_n) begin
        if (!rst_n) valid_sync <= 3'b000;
        else        valid_sync <= {valid_sync[1:0], adc_valid};
    end
    wire sample_pulse = valid_sync[1] & ~valid_sync[2];

    wire [23:0] gidx;
    wire        enc_valid, hid_valid, out_valid;
    wire [7:0]  hidden_spikes;
    wire        output_spike;

    spike_encoder #(.LEVEL_MIN(LEVEL_MIN), .STEP_SHIFT(STEP_SHIFT)) u_encoder (
        .clk(clk_50mhz), .rst_n(rst_n),
        .sample_valid(sample_pulse),
        .adc_in({adc_ch3, adc_ch2, adc_ch1, adc_ch0}),
        .enc_valid(enc_valid),
        .gidx(gidx)
    );

    lif_hidden_layer u_hidden (
        .clk(clk_50mhz), .rst_n(rst_n),
        .step(enc_valid), .gidx(gidx),
        .valid(hid_valid), .spikes_out(hidden_spikes)
    );

    lif_output_neuron u_output (
        .clk(clk_50mhz), .rst_n(rst_n),
        .step(hid_valid), .hidden_spikes(hidden_spikes),
        .valid(out_valid), .spike_out(output_spike)
    );

    seizure_decision u_decision (
        .clk(clk_50mhz), .rst_n(rst_n),
        .sample_valid(out_valid), .output_spike(output_spike),
        .seizure_detect(seizure_detect), .firing_rate(debug_firing_rate)
    );

    assign debug_hidden_spikes = |hidden_spikes;
    assign debug_output_spike  = output_spike;
endmodule
