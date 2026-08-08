module e203_bram_test(
    // Common clock and reset
    input  wire         clk,           // Common clock for both read and write
    input  wire         rst_n,         // Active low reset
    
    // Write port (w_port)
    input  wire [12:0]  w_addr,        // Write address (13-bit)
    input  wire [63:0]  w_din,         // Write data (64-bit)
    input  wire         w_en,          // Write port enable
    input  wire [7:0]   w_we,          // Write byte enable (8-bit)
    
    // Read port (r_port)
    input  wire [12:0]  r_addr,        // Read address (13-bit)
    output reg  [63:0]  r_dout,        // Read data (64-bit)
    input  wire         r_en           // Read port enable
);

    // ASIC SRAM memory array: 2048 x 256 bits
// Pseudo dual-port SRAM: simultaneous read/write on different ports
reg [63:0] sram_memory [0:8191];  // 8192 entries = 2^13

// Initialize SRAM memory to zero (ASIC power-on state)
integer i;
initial begin
    for (i = 0; i < 8192; i = i + 1) begin
        sram_memory[i] = 64'h0;
    end
end

// Read port operation (always available when enabled)
// Supports simultaneous read with write operation
always @(posedge clk) begin
    if (~rst_n) begin
        r_dout <= 64'h0;
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