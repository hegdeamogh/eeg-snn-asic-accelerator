`timescale 1ns/1ps

module seizure_decision (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        sample_valid,   // pulses once per evaluated output sample
    input  wire        output_spike,
    output reg         seizure_detect,
    output wire [7:0]  firing_rate
);

    localparam WINDOW      = 256;
    localparam RATE_THRESH = 26;        // 10% of 256

    reg [WINDOW-1:0] spike_history;
    reg [8:0]        rate_count;        // 0..256 needs 9 bits
    reg [8:0]        next_count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spike_history  <= {WINDOW{1'b0}};
            rate_count     <= 9'd0;
            seizure_detect <= 1'b0;
        end else if (sample_valid) begin
            next_count     = rate_count + output_spike - spike_history[WINDOW-1];
            rate_count     <= next_count;
            spike_history  <= {spike_history[WINDOW-2:0], output_spike};
            seizure_detect <= (next_count > RATE_THRESH);
        end
    end

    assign firing_rate = rate_count[7:0];

endmodule
