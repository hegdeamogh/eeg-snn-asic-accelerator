`timescale 1ns/1ps

module spike_encoder (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        adc_valid,
    input  wire [47:0] adc_in,           // {ch3, ch2, ch1, ch0}
    input  wire [47:0] level_min,        // {ch3_min, ch2_min, ch1_min, ch0_min}
    input  wire [47:0] level_step,       // {ch3_step, ch2_step, ch1_step, ch0_step}
    output reg  [63:0] spike_onehot,
    output reg  [5:0]  active_idx [3:0]
);

    wire [11:0] adc_ch  [3:0];
    wire [11:0] min_ch  [3:0];
    wire [11:0] step_ch [3:0];

    assign adc_ch[0] = adc_in[11:0];
    assign adc_ch[1] = adc_in[23:12];
    assign adc_ch[2] = adc_in[35:24];
    assign adc_ch[3] = adc_in[47:36];

    assign min_ch[0] = level_min[11:0];
    assign min_ch[1] = level_min[23:12];
    assign min_ch[2] = level_min[35:24];
    assign min_ch[3] = level_min[47:36];

    assign step_ch[0] = level_step[11:0];
    assign step_ch[1] = level_step[23:12];
    assign step_ch[2] = level_step[35:24];
    assign step_ch[3] = level_step[47:36];

    integer i;
    reg [3:0]  level_idx   [3:0];   // combinational per cycle, no longer a separate register stage
    reg [63:0] onehot_next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spike_onehot  <= 64'd0;
            active_idx[0] <= 6'd0;
            active_idx[1] <= 6'd0;
            active_idx[2] <= 6'd0;
            active_idx[3] <= 6'd0;
        end else if (adc_valid) begin
            onehot_next = 64'd0;
            for (i = 0; i < 4; i = i + 1) begin

                if (adc_ch[i] < min_ch[i])
                    level_idx[i] = 4'd0;
                else if (((adc_ch[i] - min_ch[i]) / step_ch[i]) > 15)
                    level_idx[i] = 4'd15;
                else
                    level_idx[i] = (adc_ch[i] - min_ch[i]) / step_ch[i];

                onehot_next[16*i + level_idx[i]] = 1'b1;
                active_idx[i] <= {2'b00, level_idx[i]};
            end
            spike_onehot <= onehot_next;
        end
    end

endmodule
