`timescale 1ns/1ps

module neuromorphic_acc (
    input  wire        clk_50mhz,
    input  wire        rst_n,
    
    // ADC Interface (4 channels, 12-bit each)
    input  wire [11:0] adc_ch0,
    input  wire [11:0] adc_ch1,
    input  wire [11:0] adc_ch2,
    input  wire [11:0] adc_ch3,
    input  wire        adc_valid,        // Strobe at 256 Hz
    
    // Seizure Output
    output reg         seizure_detect,
    
    // Debug outputs
    output wire [7:0]  debug_firing_rate,
    output wire        debug_hidden_spikes,
    output wire        debug_output_spike
);

    // Internal wires
    wire [63:0] spike_onehot;
    wire [5:0]  active_idx [3:0];
    wire [7:0]  hidden_spikes;
    wire [15:0] hidden_membrane [7:0];
    wire        output_spike;
    wire [15:0] output_membrane;
    wire        en_hidden;
    wire        en_output;
    wire        en_weights;
    
    // ========== 1. SPIKE ENCODER ==========
    spike_encoder u_encoder (
        .clk         (clk_50mhz),
        .rst_n       (rst_n),
        .adc_valid   (adc_valid),
        .adc_in      ({adc_ch3, adc_ch2, adc_ch1, adc_ch0}),
        .level_min   ({12'h000, 12'h000, 12'h000, 12'h000}),  // Placeholder
        .level_step  ({12'h100, 12'h100, 12'h100, 12'h100}),  // Placeholder: 256
        .spike_onehot(spike_onehot),
        .active_idx  (active_idx)
    );
    
    // ========== 2. CLOCK GATING CONTROLLER ==========
    clock_gating_ctrl u_clk_gate (
        .clk          (clk_50mhz),
        .rst_n        (rst_n),
        .spike_onehot (spike_onehot),
        .hidden_spikes(hidden_spikes),
        .en_snn_hidden(en_hidden),
        .en_snn_output(en_output),
        .en_mem_weights(en_weights)
    );
    
    // ========== 3. HIDDEN LAYER (8 LIF neurons) ==========
    lif_hidden_layer u_hidden (
        .clk         (clk_50mhz),
        .rst_n       (rst_n),
        .spike_valid (en_hidden),
        .active_idx  (active_idx),
        .weights     (),  // Placeholder: tie to constants
        .membrane    (hidden_membrane),
        .threshold   ({16'h100, 16'h100, 16'h100, 16'h100, 16'h100, 16'h100, 16'h100, 16'h100}),  // 1.0
        .decay       ({16'h0CC, 16'h0CC, 16'h0CC, 16'h0CC, 16'h0CC, 16'h0CC, 16'h0CC, 16'h0CC}),  // 0.8
        .membrane_out(hidden_membrane),
        .spikes_out  (hidden_spikes)
    );
    
    // ========== 4. OUTPUT LAYER (1 LIF neuron) ==========
    lif_output_neuron u_output (
        .clk         (clk_50mhz),
        .rst_n       (rst_n),
        .spike_valid (en_output),
        .hidden_spikes(hidden_spikes),
        .weights     (8'h00),  // Placeholder
        .membrane    (output_membrane),
        .threshold   (16'h100),  // 1.0
        .decay       (16'h0CC),  // 0.8
        .membrane_out(output_membrane),
        .spike_out   (output_spike)
    );
    
    // ========== 5. SEIZURE DECISION ==========
    seizure_decision u_decision (
        .clk           (clk_50mhz),
        .rst_n         (rst_n),
        .output_spike  (output_spike),
        .seizure_detect(seizure_detect),
        .firing_rate   (debug_firing_rate)
    );
    
    // Debug assignments
    assign debug_hidden_spikes = |hidden_spikes;
    assign debug_output_spike = output_spike;

endmodule