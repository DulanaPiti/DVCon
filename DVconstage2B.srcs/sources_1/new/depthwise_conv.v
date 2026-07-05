`timescale 1ns / 1ps

module depthwise_conv #(
    parameter NUM_CH     = 16, // Number of parallel channels
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 32
)(
    input  wire clk,
    input  wire rst_n,
    input  wire en,
    input  wire is_k5,         // 0 for K=3 (9 cycles), 1 for K=5 (25 cycles)
    input  wire start_pixel,   // Pulses high to begin a new spatial pixel
    
    // Flat vectors containing 1 weight and 1 input per channel, per clock cycle
    input  wire [(NUM_CH*DATA_WIDTH)-1:0] weight_in,
    input  wire [(NUM_CH*DATA_WIDTH)-1:0] act_in,
    
    output reg  pixel_done,    // Flags high when the 9 or 25 cycle accumulation is complete
    output wire [(NUM_CH*ACC_WIDTH)-1:0] acc_out_vector
);

    reg [4:0] cycle_count;
    wire [4:0] max_cycles = is_k5 ? 5'd24 : 5'd8; // 25 cycles for K=5, 9 for K=3

    // Control Logic: Count the KxK cycles
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_count <= 0;
            pixel_done  <= 0;
        end else if (en) begin
            if (start_pixel) begin
                cycle_count <= 0;
                pixel_done  <= 0;
            end else if (cycle_count < max_cycles) begin
                cycle_count <= cycle_count + 1;
                pixel_done  <= (cycle_count == max_cycles - 1);
            end else begin
                pixel_done  <= 0;
            end
        end
    end

    // Instantiate 1 MAC per channel (No cross-channel mixing)
    genvar i;
    generate
        for (i = 0; i < NUM_CH; i = i + 1) begin : dw_mac_array
            mac_unit #(
                .DATA_WIDTH(DATA_WIDTH),
                .ACC_WIDTH(ACC_WIDTH)
            ) u_dw_mac (
                .clk(clk),
                .rst_n(rst_n),
                .en(en),
                .weight(weight_in[(i*DATA_WIDTH) +: DATA_WIDTH]),
                .act_in(act_in[(i*DATA_WIDTH) +: DATA_WIDTH]),
                .clear_acc(start_pixel),
                .acc_out(acc_out_vector[(i*ACC_WIDTH) +: ACC_WIDTH])
            );
        end
    endgenerate

endmodule