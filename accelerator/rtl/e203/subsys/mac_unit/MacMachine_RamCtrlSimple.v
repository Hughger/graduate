// Project: E203 HBIRD V2 SoC
// Author: Assistant
// Date: 2025-01-XX
// Description: Simple RAM Controller for MAC Machine
// Always writes 256-bit value of all 6's (0x6666...) to BRAM when enabled
// Updated for pseudo dual-port RAM interface

module MacMachine_RamCtrlSimple (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,        // Enable signal from switch

    // BRAM Interface - Pseudo dual-port
    // Write port
    output wire [10:0]  bram_w_addr,   // Write address (11-bit for 64KB)
    output wire [255:0] bram_w_din,    // Write data (all 6's)
    output wire         bram_w_en,     // Write enable
    output wire [31:0]  bram_w_we,     // Write byte enable (all enabled)
    // Read port
    output wire [10:0]  bram_r_addr,   // Read address (11-bit for 64KB)
    input  wire [255:0] bram_r_dout,   // Read data (not used in this simple controller)
    output wire         bram_r_en      // Read enable
);

// Write port assignments
// Always write to address 0
assign bram_w_addr = 11'h0;

// Always write 256-bit value of all 6's (0x666666...666)
assign bram_w_din = {32{8'h66}};  // 32 bytes of 0x66 = 256 bits

// Enable BRAM write when this controller is active
assign bram_w_en = enable;

// Enable all byte writes
assign bram_w_we = 32'hFFFFFFFF;

// Read port assignments (not used in this simple controller, but must be driven)
assign bram_r_addr = 11'h0;       // Default read address
assign bram_r_en = 1'b0;          // Read not enabled in this simple controller

endmodule
