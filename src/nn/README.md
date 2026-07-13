# src/nn — Module summaries

- Filename: activation_unit.v  
  Purpose: Per-channel activation supporting HardSwish, ReLU, HardSigmoid, and Identity.  
  Parameters: NUM_CH=16, ACC_WIDTH=32  
  Interface: shared mode/enable, per-channel data in/out (32-bit), clk, rst  
  Key behavior / algorithm:
    - Mode 00 — HardSwish: x * clamp(x+3,0,6) * 171 >>> 10
    - Mode 01 — ReLU: max(0, x)
    - Mode 10 — HardSigmoid: clamp(x+3,0,6) * 171 >>> 10
    - Mode 11 — Identity: passthrough
  Pipeline / latency: 2-stage pipeline per channel (shared control signals)  
  Data widths / ranges: ACC_WIDTH=32 internal; inputs/outputs 8-bit signed  
  Notes: x*171 >>> 10 approximates divide-by-6 (~0.2% error).

- Filename: requantize.v  
  Purpose: Per-channel fixed-point requantizer (accumulator → signed INT8).  
  Parameters: NUM_CH=16 (supports 128 for expand/project paths)  
  Interface: per-channel acc in, per-channel INT8 out, per-channel M_scale (u32), zero_point (s8), R_shift, clk, rst  
  Key behavior / algorithm:
    - Stage 1: multiply acc * M_scale
    - Stage 2: shift + round + add zero_point + clamp to [-128,127]
    - Math: result = (acc * M_scale + round) >>> (31 + R_shift) + zero_point
  Pipeline / latency: 2-stage pipeline (mult then shift/round)  
  Data widths / ranges: M_scale unsigned 32-bit; zero_point signed 8-bit; output signed 8-bit

- Filename: line_buffer_stream.v  
  Purpose: Dual-port line buffer RAM for streaming pixel/channel data.  
  Parameters: data width = 128 bits (16 ch × 8 bits), depth = 4096 entries  
  Interface: write port (wen, waddr, wdata), read port (raddr -> 1-cycle registered rdata), clk, rst  
  Key behavior / algorithm: synchronous write; read address registered and data appears next cycle  
  Pipeline / latency: read has 1-cycle registered output  
  Data widths / ranges: 128-bit data bus; 4096-depth  
  Notes: memory zero-initialized on reset in simulation only.

- Filename: im2col_line_buffer.v  
  Purpose: AXI-Stream im2col 3×3 sliding-window generator producing serialized 3×3 patches.  
  Parameters: IMG_WIDTH=224 (default)  
  Interface: s_axis (input pixels), m_axis (output serialized 3×3 patches), clk, rst, ready/valid/tlast signals as applicable  
  Key behavior / algorithm: two line buffers (line_buf_0, line_buf_1) sized to IMG_WIDTH rows; maintain 3×3 window registers p00..p22; FSM: STATE_FILL (shift pixels into window) → STATE_OUTPUT (serialize the 9-pixel patch over 9 cycles)  
  Pipeline / latency: after initial fill, each patch serialized over 9 cycles  
  Data widths / ranges: pixel width per s_axis element (as in module)
