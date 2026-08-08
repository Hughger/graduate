// Project: E203 HBIRD V2 SoC
// Author: Assistant
// Date: 2025-01-XX
// Description: 128KB Pseudo Dual-Port SRAM with 256-bit data width
// This is a pseudo dual-port ASIC SRAM IP model with separate read/write ports
// Address width: 12 bits (4096 x 256-bit words = 128KB)
// Data width: 256 bits (ASIC standard interface)
// Supports simultaneous read and write operations on different addresses

module e203_bram_128k (
    // Common clock and reset
    input  wire         clk,           // Common clock for both read and write
    input  wire         rst_n,         // Active low reset
    
    // Write port (w_port)
    input  wire [11:0]  w_addr,        // Write address (12-bit)
    input  wire [255:0] w_din,         // Write data (256-bit)
    input  wire         w_en,          // Write port enable
    input  wire [31:0]  w_we,          // Write byte enable (32-bit)
    
    // Read port (r_port)
    input  wire [11:0]  r_addr,        // Read address (12-bit)
    output reg  [255:0] r_dout,        // Read data (256-bit)
    input  wire         r_en           // Read port enable
);

// ASIC SRAM memory array: 4096 x 256 bits
// Pseudo dual-port SRAM: simultaneous read/write on different ports
reg [255:0] sram_memory [0:4095];  // 4096 entries = 2^12

// Initialize SRAM memory to zero (ASIC power-on state)
integer i;
initial begin
    for (i = 0; i < 4096; i = i + 1) begin
        sram_memory[i] = 256'h0;
    end
end

// Read port operation (always available when enabled)
// Supports simultaneous read with write operation
always @(posedge clk) begin
    if (~rst_n) begin
        r_dout <= 256'h0;
    end else if (r_en) begin
        // Read from memory array
        r_dout <= sram_memory[r_addr];
    end
end

// Write port operation with byte enable support
// Can operate simultaneously with read port
always @(posedge clk) begin
    if (~rst_n) begin
        // No explicit reset needed for memory array in ASIC
    end else if (w_en && (|w_we)) begin
        // Byte-wise write enable logic for pseudo dual-port operation
        sram_memory[w_addr] <= {
            // Bytes 31-24 (MSB)
            w_we[31] ? w_din[255:248] : sram_memory[w_addr][255:248],
            w_we[30] ? w_din[247:240] : sram_memory[w_addr][247:240],
            w_we[29] ? w_din[239:232] : sram_memory[w_addr][239:232],
            w_we[28] ? w_din[231:224] : sram_memory[w_addr][231:224],
            w_we[27] ? w_din[223:216] : sram_memory[w_addr][223:216],
            w_we[26] ? w_din[215:208] : sram_memory[w_addr][215:208],
            w_we[25] ? w_din[207:200] : sram_memory[w_addr][207:200],
            w_we[24] ? w_din[199:192] : sram_memory[w_addr][199:192],
            // Bytes 23-16
            w_we[23] ? w_din[191:184] : sram_memory[w_addr][191:184],
            w_we[22] ? w_din[183:176] : sram_memory[w_addr][183:176],
            w_we[21] ? w_din[175:168] : sram_memory[w_addr][175:168],
            w_we[20] ? w_din[167:160] : sram_memory[w_addr][167:160],
            w_we[19] ? w_din[159:152] : sram_memory[w_addr][159:152],
            w_we[18] ? w_din[151:144] : sram_memory[w_addr][151:144],
            w_we[17] ? w_din[143:136] : sram_memory[w_addr][143:136],
            w_we[16] ? w_din[135:128] : sram_memory[w_addr][135:128],
            // Bytes 15-8
            w_we[15] ? w_din[127:120] : sram_memory[w_addr][127:120],
            w_we[14] ? w_din[119:112] : sram_memory[w_addr][119:112],
            w_we[13] ? w_din[111:104] : sram_memory[w_addr][111:104],
            w_we[12] ? w_din[103:96]  : sram_memory[w_addr][103:96],
            w_we[11] ? w_din[95:88]   : sram_memory[w_addr][95:88],
            w_we[10] ? w_din[87:80]   : sram_memory[w_addr][87:80],
            w_we[9]  ? w_din[79:72]   : sram_memory[w_addr][79:72],
            w_we[8]  ? w_din[71:64]   : sram_memory[w_addr][71:64],
            // Bytes 7-0 (LSB)
            w_we[7]  ? w_din[63:56]   : sram_memory[w_addr][63:56],
            w_we[6]  ? w_din[55:48]   : sram_memory[w_addr][55:48],
            w_we[5]  ? w_din[47:40]   : sram_memory[w_addr][47:40],
            w_we[4]  ? w_din[39:32]   : sram_memory[w_addr][39:32],
            w_we[3]  ? w_din[31:24]   : sram_memory[w_addr][31:24],
            w_we[2]  ? w_din[23:16]   : sram_memory[w_addr][23:16],
            w_we[1]  ? w_din[15:8]    : sram_memory[w_addr][15:8],
            w_we[0]  ? w_din[7:0]     : sram_memory[w_addr][7:0]
        };
    end
end

endmodule
