`timescale 1ns/1ps
module spike_encoder #(
    parameter [47:0] LEVEL_MIN  = 48'd0,                       // {ch3..ch0}, 12 bit each
    parameter [15:0] STEP_SHIFT = {4'd8, 4'd8, 4'd8, 4'd8}     // log2(step) per channel
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        sample_valid,   // 1-cycle pulse per ADC sample
    input  wire [47:0] adc_in,         // {ch3, ch2, ch1, ch0}
    output reg         enc_valid,      // sample_valid delayed 1 cycle, aligned with gidx
    output reg  [23:0] gidx            // {ch3,ch2,ch1,ch0}, 6-bit global input index each
);
    wire [23:0] gidx_c;
    genvar c;
    generate
        for (c = 0; c < 4; c = c + 1) begin : g_ch
            localparam [1:0] CH = c;
            wire [11:0] x   = adc_in[12*c +: 12];
            wire [11:0] mn  = LEVEL_MIN[12*c +: 12];
            wire [11:0] sh  = (x - mn) >> STEP_SHIFT[4*c +: 4];
            wire [3:0]  lvl = (x < mn)      ? 4'd0  :
                              (sh > 12'd15) ? 4'd15 : sh[3:0];     // clamp, no aliasing
            assign gidx_c[6*c +: 6] = {CH, lvl};                    // 16*ch + level
        end
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enc_valid <= 1'b0;
            gidx      <= 24'd0;
        end else begin
            enc_valid <= sample_valid;
            if (sample_valid) gidx <= gidx_c;
        end
    end
endmodule
