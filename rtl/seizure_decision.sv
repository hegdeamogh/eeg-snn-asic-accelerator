module seizure_decision (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        output_spike,
    output reg         seizure_detect,
    output wire [7:0]  firing_rate
);

    reg [4095:0] spike_history;
    reg [7:0]    rate_count;
    
    // Shift register
    always @(posedge clk) begin
        spike_history <= {spike_history[4094:0], output_spike};
    end
    
    // Count spikes in last 256 samples
    always @(posedge clk) begin
        rate_count <= $countones(spike_history[4095:4096-256]);
    end
    
    assign firing_rate = rate_count;
    
    // Threshold: 10% = 26 spikes out of 256
    always @(posedge clk) begin
        seizure_detect <= (rate_count > 8'd26);
    end

endmodule