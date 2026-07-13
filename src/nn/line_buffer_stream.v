`timescale 1ns / 1ps

module line_buffer_stream #(
    parameter DATA_W = 128,  // 16 channels x 8 bits
    parameter ADDR_W = 12    // 4096 words = 64KB
)(
    input  wire               clk,
    input  wire               rst_n,

    // Write port (from PW_expand serializer)
    input  wire [DATA_W-1:0]  wdata,
    input  wire               wen,
    input  wire [ADDR_W-1:0]  waddr,

    // Read port (to DW engine)
    input  wire [ADDR_W-1:0]  raddr,
    output reg  [DATA_W-1:0]  rdata
);

    reg [DATA_W-1:0] mem [0:(1<<ADDR_W)-1];

    integer init_i;
    initial begin
        for (init_i = 0; init_i < (1<<ADDR_W); init_i = init_i + 1)
            mem[init_i] = 0;
    end

    always @(posedge clk) begin
        if (wen) begin
            mem[waddr] <= wdata;
// `ifndef __SYNTHESIS__
//             $display("  [LB] cycle=%0d WEN addr=%0d data_ch0=%0d", $time, waddr, $signed(wdata[7:0]));
// `endif
        end
    end

    always @(posedge clk) begin
        rdata <= mem[raddr];
// `ifndef __SYNTHESIS__
//         if (raddr == 0)
//             $display("  [LB] cycle=%0d RD  addr=%0d data_ch0=%0d", $time, raddr, $signed(mem[raddr][7:0]));
// `endif
    end

endmodule
