// Project: E203 HBIRD V2 SoC
// Author: Assistant
// Date: 2025-01-XX
// Description: 128KB ASIC SRAM with 64-bit data width
// This is a standard ASIC SRAM IP model - each address corresponds to 64-bit data
// Address width: 14 bits (16384 x 64-bit words = 128KB)
// Data width: 64 bits (ASIC standard interface)

module e203_bram_1m (
    input  wire [13:0]  bram_addr,     // 14-bit word address for 16384 entries
    input  wire         bram_clk,      // BRAM clock
    input  wire [63:0]  bram_din,      // 64-bit write data
    output reg  [63:0]  bram_dout,     // 64-bit read data
    input  wire         bram_en,       // BRAM enable
    input  wire         bram_rst,      // BRAM reset
    input  wire [7:0]   bram_we,       // 8-bit byte write enable (optional for ASIC)
    input  wire         rst_n          // System reset (active low)
);

// ASIC SRAM memory array: 16384 x 64 bits
// Standard ASIC SRAM: each address = one complete data word
reg [63:0] sram_memory [0:16383];  // 16384 entries = 2^14

// Initialize SRAM memory to zero (ASIC power-on state)
integer i;
initial begin
    for (i = 0; i < 16384; i = i + 1) begin
        sram_memory[i] = 64'h0;
    end
end

// ASIC SRAM read operation
// Standard timing: address -> data valid (typically 1 cycle)
always @(posedge bram_clk) begin
    if (!rst_n || bram_rst) begin
        bram_dout <= 64'h0;
    end else if (bram_en) begin
        // Standard ASIC SRAM: direct address to data mapping
        bram_dout <= sram_memory[bram_addr];
    end
end

// ASIC SRAM write operation with byte enable support
// Standard interface: selective byte write based on bram_we
always @(posedge bram_clk) begin
    if (rst_n && !bram_rst && bram_en && (|bram_we)) begin
        // Read current data and apply byte-level write enable logic
        // For each byte (8 bits), if corresponding bram_we bit is 1, write new data; otherwise keep old data
        sram_memory[bram_addr] <= {
            // Byte 7 (MSB)
            bram_we[7] ? bram_din[63:56] : sram_memory[bram_addr][63:56],
            // Byte 6
            bram_we[6] ? bram_din[55:48] : sram_memory[bram_addr][55:48],
            // Byte 5
            bram_we[5] ? bram_din[47:40] : sram_memory[bram_addr][47:40],
            // Byte 4
            bram_we[4] ? bram_din[39:32] : sram_memory[bram_addr][39:32],
            // Byte 3
            bram_we[3] ? bram_din[31:24] : sram_memory[bram_addr][31:24],
            // Byte 2
            bram_we[2] ? bram_din[23:16] : sram_memory[bram_addr][23:16],
            // Byte 1
            bram_we[1] ? bram_din[15:8]  : sram_memory[bram_addr][15:8],
            // Byte 0 (LSB)
            bram_we[0] ? bram_din[7:0]   : sram_memory[bram_addr][7:0]
        };
    end
end

endmodule 