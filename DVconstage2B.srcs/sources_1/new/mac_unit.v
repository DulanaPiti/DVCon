`timescale 1ns / 1ps

module mac_unit #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH = 32 // 32-bit prevents the 960-term overflow
)(
    input  wire                      clk,
    input  wire                      rst_n,
    input  wire                      en,
    input  wire signed [DATA_WIDTH-1:0] weight,
    input  wire signed [DATA_WIDTH-1:0] act_in,
    input  wire                      clear_acc,
    output reg  signed [ACC_WIDTH-1:0]  acc_out
);

    // --- PIPELINE REGISTERS (Maps to DSP48E1 A, B, and M registers) ---
    reg signed [DATA_WIDTH-1:0] weight_reg;
    reg signed [DATA_WIDTH-1:0] act_in_reg;
    reg signed [ACC_WIDTH-1:0]  prod_reg;
    reg clear_acc_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            weight_reg    <= 0;
            act_in_reg    <= 0;
            prod_reg      <= 0;
            acc_out       <= 0;
            clear_acc_reg <= 0;
        end else if (en) begin
            // Stage 1: Register Inputs (DSP48E1 A and B registers)
            weight_reg    <= weight;
            act_in_reg    <= act_in;
            clear_acc_reg <= clear_acc; // Delay the clear signal to match the pipeline

            // Stage 2: Register the Product (DSP48E1 M register)
            prod_reg      <= weight_reg * act_in_reg;

            // Stage 3: Accumulate (DSP48E1 P register)
            if (clear_acc_reg) begin
                acc_out <= prod_reg;
            end else begin
                acc_out <= acc_out + prod_reg;
            end
        end
    end
endmodule