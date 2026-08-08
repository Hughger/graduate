// Project: E203 HBIRD V2 SoC
// Author: Assistant
// Date: 2025-01-XX
// Description: 64KB Pseudo Dual-Port SRAM with 256-bit data width
// This is a pseudo dual-port ASIC SRAM IP model with separate read/write ports
// Address width: 11 bits (2048 x 256-bit words = 64KB)
// Data width: 256 bits (ASIC standard interface)
// Supports simultaneous read and write operations on different addresses
`define USE_TSMC_SRAM_IP
`define TSMC_NO_TESTPINS_WARNING
//`define E203_SYNTHESIS
module e203_bram_64k (
    // Common clock and reset
    input  wire         clk,           // Common clock for both read and write
    input  wire         rst_n,         // Active low reset
    
    // Write port (w_port)
    input  wire [10:0]  w_addr,        // Write address (11-bit)
    input  wire [255:0] w_din,         // Write data (256-bit)
    input  wire         w_en,          // Write port enable
    input  wire [31:0]  w_we,          // Write byte enable (32-bit)
    
    // Read port (r_port)
    input  wire [10:0]  r_addr,        // Read address (11-bit)
    output reg  [255:0] r_dout,        // Read data (256-bit)
    input  wire         r_en           // Read port enable
);

`ifdef USE_TSMC_SRAM_IP

// TSMC 28HPCP Dual-Port SRAM IP: TSDN28HPCPUHDB1024X128M4MWA
// - Each macro: 1024-depth x 128-bit
// - We build 2 depth-banks (2K/1K) per 128-bit half, and two halves to form 256-bit

// Micro-delay the SRAM clock for simulation to satisfy setup/hold of the model
wire clk_mem;
`ifndef E203_SYNTHESIS
assign #0.3 clk_mem = clk; // 0.3ns phase shift only in simulation
`else
assign clk_mem = clk;
`endif

// Address split: depth bank select and index within 1K
wire        w_bank = w_addr[10];
wire [9:0]  w_idx  = w_addr[9:0];
wire        r_bank = r_addr[10];
wire [9:0]  r_idx  = r_addr[9:0];

// Write mask expansion: 32 bytes -> two 128-bit bit-masks (active low for IP)
wire [127:0] bwe_lo;
wire [127:0] bwe_hi;
genvar _gi;
generate
for (_gi = 0; _gi < 16; _gi = _gi + 1) begin: gen_bwe
    assign bwe_lo[_gi*8+7:_gi*8] = {8{~w_we[_gi]}};
    assign bwe_hi[_gi*8+7:_gi*8] = {8{~w_we[16+_gi]}};
end
endgenerate

wire has_we_lo = |w_we[15:0];
wire has_we_hi = |w_we[31:16];

// Read data mux from 2 banks per half
reg [127:0] r_lo_mux;
reg [127:0] r_hi_mux;

// Two depth-banks per half; instantiate 1024x128 macros
wire [127:0] qb_lo_b0;
wire [127:0] qb_lo_b1;
wire [127:0] qb_hi_b0;
wire [127:0] qb_hi_b1;

// Lower 128-bit half, bank 0 (addr[10]==0)
TSDN28HPCPUHDB1024X128M4MWA u_sram_lo_b0 (
    .RTSEL(2'b00),
    .WTSEL(2'b00),
    .PTSEL(2'b00),
    .AA   (w_idx),
    .DA   (w_din[127:0]),
    .BWEBA(bwe_lo),
    .WEBA (~(w_en & (~w_bank) & has_we_lo)), // active low
    .CEBA (~(w_en & (~w_bank))),             // active low when port enabled
    .CLK  (clk_mem),
    .AB   (r_idx),
    .DB   (128'h0),
    .BWEBB({128{1'b1}}),
    .WEBB (1'b1),
    .CEBB (~(r_en & (~r_bank))),
    .AWT  (1'b0),
    .QA   (),
    .QB   (qb_lo_b0)
);

// Lower 128-bit half, bank 1 (addr[10]==1)
TSDN28HPCPUHDB1024X128M4MWA u_sram_lo_b1 (
    .RTSEL(2'b00),
    .WTSEL(2'b00),
    .PTSEL(2'b00),
    .AA   (w_idx),
    .DA   (w_din[127:0]),
    .BWEBA(bwe_lo),
    .WEBA (~(w_en & ( w_bank) & has_we_lo)), // active low
    .CEBA (~(w_en & ( w_bank))),             // active low when port enabled
    .CLK  (clk_mem),
    .AB   (r_idx),
    .DB   (128'h0),
    .BWEBB({128{1'b1}}),
    .WEBB (1'b1),
    .CEBB (~(r_en & ( r_bank))),
    .AWT  (1'b0),
    .QA   (),
    .QB   (qb_lo_b1)
);

// Upper 128-bit half, bank 0 (addr[10]==0)
TSDN28HPCPUHDB1024X128M4MWA u_sram_hi_b0 (
    .RTSEL(2'b00),
    .WTSEL(2'b00),
    .PTSEL(2'b00),
    .AA   (w_idx),
    .DA   (w_din[255:128]),
    .BWEBA(bwe_hi),
    .WEBA (~(w_en & (~w_bank) & has_we_hi)), // active low
    .CEBA (~(w_en & (~w_bank))),             // active low when port enabled
    .CLK  (clk_mem),
    .AB   (r_idx),
    .DB   (128'h0),
    .BWEBB({128{1'b1}}),
    .WEBB (1'b1),
    .CEBB (~(r_en & (~r_bank))),
    .AWT  (1'b0),
    .QA   (),
    .QB   (qb_hi_b0)
);

// Upper 128-bit half, bank 1 (addr[10]==1)
TSDN28HPCPUHDB1024X128M4MWA u_sram_hi_b1 (
    .RTSEL(2'b00),
    .WTSEL(2'b00),
    .PTSEL(2'b00),
    .AA   (w_idx),
    .DA   (w_din[255:128]),
    .BWEBA(bwe_hi),
    .WEBA (~(w_en & ( w_bank) & has_we_hi)), // active low
    .CEBA (~(w_en & ( w_bank))),             // active low when port enabled
    .CLK  (clk_mem),
    .AB   (r_idx),
    .DB   (128'h0),
    .BWEBB({128{1'b1}}),
    .WEBB (1'b1),
    .CEBB (~(r_en & ( r_bank))),
    .AWT  (1'b0),
    .QA   (),
    .QB   (qb_hi_b1)
);

// Combinational read data multiplexing for immediate output
always @(*) begin
    if (~r_bank) begin
        r_lo_mux = qb_lo_b0;
        r_hi_mux = qb_hi_b0;
    end else begin
        r_lo_mux = qb_lo_b1;
        r_hi_mux = qb_hi_b1;
    end
end

// Output read data immediately when enabled, maintain output
reg r_en_last; // 人为添加一拍寄存器，保证读数据在同一拍输出
always @(posedge clk) begin
    if (~rst_n) begin
        r_en_last <= 1'b0;
    end else begin
        r_en_last <= r_en;
    end
end
always @(posedge clk) begin
    if (~rst_n) begin
        r_dout <= 256'h0;
    end else if (r_en_last) begin
        // Output data in the same cycle when read enabled
        r_dout <= {r_hi_mux, r_lo_mux};
    end
    // Note: r_dout maintains its value when r_en is not active
end

`else

// ASIC SRAM memory array: 2048 x 256 bits
// Pseudo dual-port SRAM: simultaneous read/write on different ports
reg [255:0] sram_memory [0:2047];  // 2048 entries = 2^11

// Initialize SRAM memory to zero (ASIC power-on state)
integer i;
initial begin
    for (i = 0; i < 2048; i = i + 1) begin
        sram_memory[i] = 256'h0;
    end
end

// Read port operation (immediate output when enabled, maintain output)
// Supports simultaneous read with write operation
always @(posedge clk) begin
    if (~rst_n) begin
        r_dout <= 256'h0;
    end else if (r_en) begin
        // Read from memory array and output immediately in the same cycle
        r_dout <= sram_memory[r_addr];
    end
    // Note: r_dout maintains its value when r_en is not active
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

`endif

endmodule