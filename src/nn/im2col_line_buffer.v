`timescale 1ns / 1ps

module im2col_line_buffer #(
    parameter IMG_WIDTH = 224, // Width of the incoming image
    parameter DATA_WIDTH = 32
)(
    input  wire clk,
    input  wire rst_n,
    
    // --- Incoming Raster Scan (from Camera/DMA) ---
    input  wire [DATA_WIDTH-1:0] s_axis_tdata,
    input  wire                  s_axis_tvalid,
    output reg                   s_axis_tready,
    
    // --- Outgoing Patch Stream (to accelerator_top.v) ---
    output reg  [DATA_WIDTH-1:0] m_axis_tdata,
    output reg                   m_axis_tvalid,
    input  wire                  m_axis_tready
);

    // 1. Line Buffers (FIFOs implemented as BRAMs or Shift Regs)
    reg [DATA_WIDTH-1:0] line_buf_0 [0:IMG_WIDTH-1];
    reg [DATA_WIDTH-1:0] line_buf_1 [0:IMG_WIDTH-1];
    
    reg [15:0] wr_ptr; // Tracks position in the row
    
    // 2. 3x3 Window Registers
    reg [DATA_WIDTH-1:0] p00, p01, p02; // Top row
    reg [DATA_WIDTH-1:0] p10, p11, p12; // Middle row
    reg [DATA_WIDTH-1:0] p20, p21, p22; // Bottom row (current incoming)

    // 3. State Machine for Serialization
    localparam STATE_FILL   = 2'b00;
    localparam STATE_OUTPUT = 2'b01;
    
    reg [1:0] state;
    reg [3:0] burst_count; // Counts from 0 to 8 (9 cycles for 3x3)

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr        <= 0;
            state         <= STATE_FILL;
            burst_count   <= 0;
            s_axis_tready <= 1'b0;
            m_axis_tvalid <= 1'b0;
            m_axis_tdata  <= 0;
        end else begin
            case (state)
                STATE_FILL: begin
                    m_axis_tvalid <= 1'b0;
                    s_axis_tready <= 1'b1; // Accept new pixels
                    
                    if (s_axis_tvalid && s_axis_tready) begin
                        // Shift data down the rows
                        line_buf_0[wr_ptr] <= line_buf_1[wr_ptr];
                        line_buf_1[wr_ptr] <= s_axis_tdata;
                        
                        // Shift window horizontally
                        p00 <= p01; p01 <= p02; p02 <= line_buf_0[wr_ptr];
                        p10 <= p11; p11 <= p12; p12 <= line_buf_1[wr_ptr];
                        p20 <= p21; p21 <= p22; p22 <= s_axis_tdata;
                        
                        if (wr_ptr < IMG_WIDTH - 1)
                            wr_ptr <= wr_ptr + 1;
                        else
                            wr_ptr <= 0;

                        // Trigger output when a valid 3x3 window is formed
                        // (Simplified logic: assumes padding is handled upstream)
                        state <= STATE_OUTPUT;
                    end
                end
                
                STATE_OUTPUT: begin
                    s_axis_tready <= 1'b0; // Halt incoming stream
                    m_axis_tvalid <= 1'b1;
                    
                    if (m_axis_tready) begin
                        // Serialize the 3x3 window over 9 cycles
                        case (burst_count)
                            4'd0: m_axis_tdata <= p00;
                            4'd1: m_axis_tdata <= p01;
                            4'd2: m_axis_tdata <= p02;
                            4'd3: m_axis_tdata <= p10;
                            4'd4: m_axis_tdata <= p11;
                            4'd5: m_axis_tdata <= p12;
                            4'd6: m_axis_tdata <= p20;
                            4'd7: m_axis_tdata <= p21;
                            4'd8: m_axis_tdata <= p22;
                            default: m_axis_tdata <= 32'h0;
                        endcase
                        
                        if (burst_count == 4'd8) begin
                            burst_count <= 0;
                            state       <= STATE_FILL;
                        end else begin
                            burst_count <= burst_count + 1;
                        end
                    end
                end
            endcase
        end
    end
endmodule