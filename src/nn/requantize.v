(* use_dsp = "yes" *) module requantize #(
    parameter NUM_CH = 16
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    input  wire [31:0] M_scale,
    input  wire [4:0]  R_shift,
    input  wire [7:0]  zero_point,
    input  wire [NUM_CH*32-1:0] acc_in,
    output wire [NUM_CH*8-1:0] quant_out
);

    genvar i;
    generate
        for (i = 0; i < NUM_CH; i = i + 1) begin : req_chan
            reg signed [63:0] p1;
            reg signed [7:0] p2_byte;
            wire signed [31:0] a = acc_in[i*32 +: 32];
            wire signed [63:0] a_w = a;
            wire signed [63:0] m_w;
            assign m_w = {32'b0, M_scale};
            wire signed [63:0] round_val = $signed(64'd1 << (30 + R_shift));
            wire signed [63:0] shifted = ($signed(p1) + round_val) >>> (31 + R_shift);
            wire signed [63:0] with_zp = shifted + $signed({{56{zero_point[7]}}, zero_point});

            always @(posedge clk or negedge rst_n) begin : req_seq
                if (!rst_n) begin
                    p1 <= 64'd0;
                    p2_byte <= 8'd0;
                end else if (en) begin
                    p1 <= a_w * m_w;
                    if (with_zp > 64'sd127)
                        p2_byte <= 8'sd127;
                    else if (with_zp < -64'sd128)
                        p2_byte <= -8'sd128;
                    else
                        p2_byte <= with_zp[7:0];
                end
            end
        end
    endgenerate

    genvar qi;
    generate
        for (qi = 0; qi < NUM_CH; qi = qi + 1) begin : qassign
            assign quant_out[qi*8 +: 8] = req_chan[qi].p2_byte;
        end
    endgenerate

endmodule
