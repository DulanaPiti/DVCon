`timescale 1ns / 1ps

module pointwise_conv #(
    parameter NUM_MACS   = 16, // 16 parallel MACs
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 32
)(
    input  wire clk,
    input  wire rst_n,
    input  wire en,
    input  wire clear_acc,
    
    // Broadcast: 1 activation shared across all 16 MACs
    input  wire signed [DATA_WIDTH-1:0] act_in_broadcast,
    
    // Flat vector holding 16 individual 8-bit weights (128 bits total)
    input  wire [(NUM_MACS*DATA_WIDTH)-1:0] weight_vector,
    
    // Flat vector outputting 16 individual 32-bit accumulators (512 bits total)
    output wire [(NUM_MACS*ACC_WIDTH)-1:0] acc_out_vector
);

    // Generate loop to instantiate the 1D array of 16 MACs
    genvar i;
    generate
        for (i = 0; i < NUM_MACS; i = i + 1) begin : mac_array
            
            mac_unit #(
                .DATA_WIDTH(DATA_WIDTH),
                .ACC_WIDTH(ACC_WIDTH)
            ) u_mac (
                .clk(clk),
                .rst_n(rst_n),
                .en(en),
                // Slice the 128-bit weight vector to give each MAC its specific 8-bit weight
                .weight(weight_vector[(i*DATA_WIDTH) +: DATA_WIDTH]),
                .act_in(act_in_broadcast),
                .clear_acc(clear_acc),
                // Pack the 32-bit result back into the 512-bit output vector
                .acc_out(acc_out_vector[(i*ACC_WIDTH) +: ACC_WIDTH]) 
            );
            
        end
    endgenerate

endmodule