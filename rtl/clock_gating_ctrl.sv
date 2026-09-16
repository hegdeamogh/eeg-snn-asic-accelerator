module clock_gating_ctrl (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [63:0] spike_onehot,
    input  wire [7:0]  hidden_spikes,
    output reg         en_snn_hidden,
    output reg         en_snn_output,
    output reg         en_mem_weights
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_snn_hidden <= 1'b0;
            en_snn_output <= 1'b0;
            en_mem_weights <= 1'b0;
        end else begin
            //Enable hidden layer when input spikes present
            en_snn_hidden <= |spike_onehot;
            
            //Enable output layer when hidden spikes present
            en_snn_output <= |hidden_spikes;
            
            //Enable memory when either layer active
            en_mem_weights <= en_snn_hidden | en_snn_output;
        end
    end

endmodule