`timescale 1ns/1ps
module seizure_decision #(
    parameter WINDOW          = 256,   // samples (1 s at 256 Hz); rate_count is 9 bits
    parameter RATE_THRESH     = 26,    // >= 26 of 256 (~10.2 %)
    parameter PERSIST_SAMPLES = 1      // consecutive samples above threshold (1 = old behaviour)
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       sample_valid,    // = output neuron's valid
    input  wire       output_spike,
    output reg        seizure_detect,
    output wire [8:0] firing_rate      // 0..256
);
    reg [WINDOW-1:0] spike_history;
    reg [8:0]        rate_count;
    reg [8:0]        next_count;
    reg [8:0]        persist_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spike_history  <= {WINDOW{1'b0}};
            rate_count     <= 9'd0;
            persist_cnt    <= 9'd0;
            seizure_detect <= 1'b0;
        end else if (sample_valid) begin
            next_count    = rate_count + output_spike - spike_history[WINDOW-1];
            rate_count   <= next_count;
            spike_history <= {spike_history[WINDOW-2:0], output_spike};

            if (next_count >= RATE_THRESH) begin
                if (persist_cnt != 9'h1FF) persist_cnt <= persist_cnt + 9'd1;
                seizure_detect <= (persist_cnt + 9'd1 >= PERSIST_SAMPLES);
            end else begin
                persist_cnt    <= 9'd0;
                seizure_detect <= 1'b0;
            end
        end
    end

    assign firing_rate = rate_count;
endmodule
