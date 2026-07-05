`timescale 1ns / 1ps

module bram_controller #(
    parameter NUM_BANKS  = 16,  // 16 banks to feed 16 MACs concurrently
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 9    // 512 entries per bank per buffer
)(
    input  wire clk,
    
    // --- AXI Write Port (Fills the BRAM from DDR) ---
    input  wire ping_pong_sel,  // 0 = Write A/Read B, 1 = Write B/Read A
    input  wire axi_we,         // Write Enable from AXI Master
    input  wire [3:0] axi_bank_sel, // Selects which of the 16 banks to write to
    input  wire [ADDR_WIDTH-1:0] axi_addr,
    input  wire [DATA_WIDTH-1:0] axi_data_in,
    
    // --- MAC Array Read Port (Feeds the Pointwise Conv) ---
    input  wire mac_re,         // Read Enable from Accelerator FSM
    input  wire [ADDR_WIDTH-1:0] mac_addr,
    output reg  [(NUM_BANKS*DATA_WIDTH)-1:0] mac_data_out // 128-bit wide output
);

    // 2D Array representing the BRAM. 
    // [Buffer A/B] [16 Banks] [Address Space]
    reg [DATA_WIDTH-1:0] ram [0:1][0:NUM_BANKS-1][0:(1<<ADDR_WIDTH)-1];

    integer i;

    // Synchronous Read and Write Logic
    always @(posedge clk) begin
        // WRITE LOGIC (From AXI)
        if (axi_we) begin
            // Write to the active 'ping' buffer
            ram[ping_pong_sel][axi_bank_sel][axi_addr] <= axi_data_in;
        end
        
        // READ LOGIC (To MAC Array)
        if (mac_re) begin
            // Read from the active 'pong' buffer across ALL 16 banks simultaneously
            for (i = 0; i < NUM_BANKS; i = i + 1) begin
                // Pack the 16 parallel reads into the flat 128-bit output vector
                mac_data_out[(i*DATA_WIDTH) +: DATA_WIDTH] <= ram[~ping_pong_sel][i][mac_addr];
            end
        end
    end

endmodule