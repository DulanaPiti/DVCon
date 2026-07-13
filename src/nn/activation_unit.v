// ============================================================================
//  Activation Unit — 16 parallel channels, 2-stage pipeline
// ============================================================================
//  Applies one of four activation functions to each channel's INT32 accumulator.
//  All channels process independently, sharing the same mode and enable.
//
//  Mode Table:
//    mode[1:0]  Name           Function                          Formula
//    ────────   ────────────   ────────────────────────────────  ───────────────────────
//    00         HardSwish      x · clamp(x+3, 0, 6) / 6          t=clamp(x+3,0,6); y=(x*t*171)>>>10
//    01         ReLU           max(0, x)                         y = x[31] ? 0 : x
//    10         HardSigmoid    clamp(x+3, 0, 6) /  6              t=clamp(x+3,0,6); y=(t*171)>>>10
//    11         Identity       y = x                             y = x
//
//  All functions share the common intermediate t = clamp(x + 3, 0, 6):
//    - HardSwish:    x · t / 6    ≈ (x · t · 171) >> 10   (0.2% error vs 12.5% for >>3)
//    - HardSigmoid:  t / 6        ≈ (t · 171) >> 10       (reuses same t)
//    - ReLU:         ignores t, uses sign bit of x
//    - Identity:     ignores t, passes x through
//
//  Why ×171 >> 10 instead of >> ~2.58?
//    Division by 6 in fixed-point: 1/6 ≈ 0.1666667
//    ×171 >> 10 = 171/1024 = 0.1669922  (0.2% relative error)
//    >>3         = 1/8      = 0.125      (25% relative error)
//
//  2-Stage Pipeline:
//    Stage 1 (en=1):  x_reg <= x_in, t_reg <= clamp(x_in + 3, 0, 6)
//    Stage 2 (en=1):  y_reg <= case(mode) of function (reads x_reg, t_reg)
//
//  Used in two instances in accelerator_top.v:
//    u_dw_activation — DW path, enabled during SE_GAP(0-1) and PW_COMPUTE(0-1)
//    u_pw_activation — PW path, enabled during PW_COMPUTE(20-21) drain phase
// ============================================================================

module activation_unit #(
    parameter NUM_CH = 16,
    parameter ACC_WIDTH = 32
) (
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire                         en,
    input  wire [1:0]                   mode,
    input  wire [NUM_CH*ACC_WIDTH-1:0]  acc_in,
    output wire [NUM_CH*ACC_WIDTH-1:0]  act_out
);

    genvar i;
    generate
        for (i = 0; i < NUM_CH; i = i + 1) begin : act_chan
            reg signed [ACC_WIDTH-1:0] x_reg;
            reg signed [ACC_WIDTH-1:0] t_reg;
            reg signed [ACC_WIDTH-1:0] y_reg;

            wire signed [ACC_WIDTH-1:0] x_in = acc_in[i*ACC_WIDTH +: ACC_WIDTH];

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    x_reg <= {ACC_WIDTH{1'b0}};
                    t_reg <= {ACC_WIDTH{1'b0}};
                end else if (en) begin
                    x_reg <= x_in;
                    if ($signed(x_in) > 32'sd3)
                        t_reg <= 32'sd6;
                    else if ($signed(x_in) < -32'sd3)
                        t_reg <= {ACC_WIDTH{1'b0}};
                    else
                        t_reg <= $signed(x_in) + 32'sd3;
                end
            end

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    y_reg <= {ACC_WIDTH{1'b0}};
                end else if (en) begin
                    case (mode)
                        2'b00: y_reg <= ($signed(x_reg) * $signed(t_reg) * 32'sd171) >>> 10;
                        2'b01: y_reg <= x_reg[ACC_WIDTH-1] ? {ACC_WIDTH{1'b0}} : x_reg;
                        2'b10: y_reg <= ($signed(t_reg) * 32'sd171) >>> 10;
                        2'b11: y_reg <= x_reg;
                    endcase
                end
            end

            assign act_out[i*ACC_WIDTH +: ACC_WIDTH] = y_reg;
        end
    endgenerate

endmodule
