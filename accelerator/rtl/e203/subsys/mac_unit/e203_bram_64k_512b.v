// Project: E203 HBIRD V2 SoC
// Author: Assistant
// Date: 2025-01-XX
// Description: 64KB Pseudo Dual-Port SRAM with 512-bit data width
// This is a pseudo dual-port ASIC SRAM IP model with separate read/write ports
// Address width: 10 bits (1024 x 512-bit words = 64KB)
// Data width: 512 bits (ASIC standard interface)
// Supports simultaneous read and write operations on different addresses
`define USE_TSMC_SRAM_IP
`define TSMC_NO_TESTPINS_WARNING
//`define E203_SYNTHESIS

module e203_bram_64k_512b (
    // Common clock and reset
    input  wire         clk,           // Common clock for both read and write
    input  wire         rst_n,         // Active low reset

    // Write port (w_port)
    input  wire [10:0]  w_addr,        // Write address (11-bit, bit[10] used for domain select by upstream)
    input  wire [511:0] w_din,         // Write data (512-bit)
    input  wire         w_en,          // Write port enable
    input  wire [63:0]  w_we,          // Write byte enable (64-bit)

    // Read port (r_port)
    input  wire [10:0]  r_addr,        // Read address (11-bit, bit[10] used for domain select by upstream)
    output reg  [511:0] r_dout,        // Read data (512-bit)
    input  wire         r_en           // Read port enable
);

`ifdef USE_TSMC_SRAM_IP

// TSMC 28HPCP Dual-Port SRAM IP (depth x width): TSDN28HPCPUHDB1024X128M4MWA
// - We use 4 quarters (q0..q3), each 1024x128b, to form a 1024x512b macro

// Micro-delay the SRAM clock for simulation to satisfy setup/hold of the model
`ifndef E203_SYNTHESIS
wire clk_mem;
assign #0.3 clk_mem = clk; // 0.3ns phase shift only in simulation
`else
wire clk_mem = clk;
`endif

// Write mask expansion: 64 bytes -> four 128-bit bit-masks (active low for IP)
wire [127:0] bwe_q0;
wire [127:0] bwe_q1;
wire [127:0] bwe_q2;
wire [127:0] bwe_q3;
genvar _gi;
generate
for (_gi = 0; _gi < 16; _gi = _gi + 1) begin: gen_bwe
    assign bwe_q0[_gi*8+7:_gi*8] = {8{~w_we[_gi]}};
    assign bwe_q1[_gi*8+7:_gi*8] = {8{~w_we[16+_gi]}};
    assign bwe_q2[_gi*8+7:_gi*8] = {8{~w_we[32+_gi]}};
    assign bwe_q3[_gi*8+7:_gi*8] = {8{~w_we[48+_gi]}};
end
endgenerate

wire has_we_q0 = |w_we[15:0];
wire has_we_q1 = |w_we[31:16];
wire has_we_q2 = |w_we[47:32];
wire has_we_q3 = |w_we[63:48];

// Quarter read data wires
wire [127:0] qb_q0;
wire [127:0] qb_q1;
wire [127:0] qb_q2;
wire [127:0] qb_q3;

// Quarter 0: bits [127:0]
TSDN28HPCPUHDB1024X128M4MWA u_sram_q0 (
    .RTSEL(2'b00),
    .WTSEL(2'b00),
    .PTSEL(2'b00),
    .AA   (w_addr[9:0]),
    .DA   (w_din[127:0]),
    .BWEBA(bwe_q0),
    .WEBA (~(w_en & has_we_q0)), // active low
    .CEBA (~w_en),               // active low when port enabled
    .CLK  (clk_mem),
    .AB   (r_addr[9:0]),
    .DB   (128'h0),
    .BWEBB({128{1'b1}}),         // no write on port B
    .WEBB (1'b1),                // inactive (active low)
    .CEBB (~r_en),               // enable when reading
    .AWT  (1'b0),
    .QA   (),
    .QB   (qb_q0)
);

// Quarter 1: bits [255:128]
TSDN28HPCPUHDB1024X128M4MWA u_sram_q1 (
    .RTSEL(2'b00),
    .WTSEL(2'b00),
    .PTSEL(2'b00),
    .AA   (w_addr[9:0]),
    .DA   (w_din[255:128]),
    .BWEBA(bwe_q1),
    .WEBA (~(w_en & has_we_q1)), // active low
    .CEBA (~w_en),               // active low when port enabled
    .CLK  (clk_mem),
    .AB   (r_addr[9:0]),
    .DB   (128'h0),
    .BWEBB({128{1'b1}}),         // no write on port B
    .WEBB (1'b1),                // inactive (active low)
    .CEBB (~r_en),               // enable when reading
    .AWT  (1'b0),
    .QA   (),
    .QB   (qb_q1)
);

// Quarter 2: bits [383:256]
TSDN28HPCPUHDB1024X128M4MWA u_sram_q2 (
    .RTSEL(2'b00),
    .WTSEL(2'b00),
    .PTSEL(2'b00),
    .AA   (w_addr[9:0]),
    .DA   (w_din[383:256]),
    .BWEBA(bwe_q2),
    .WEBA (~(w_en & has_we_q2)), // active low
    .CEBA (~w_en),               // active low when port enabled
    .CLK  (clk_mem),
    .AB   (r_addr[9:0]),
    .DB   (128'h0),
    .BWEBB({128{1'b1}}),         // no write on port B
    .WEBB (1'b1),                // inactive (active low)
    .CEBB (~r_en),               // enable when reading
    .AWT  (1'b0),
    .QA   (),
    .QB   (qb_q2)
);

// Quarter 3: bits [511:384]
TSDN28HPCPUHDB1024X128M4MWA u_sram_q3 (
    .RTSEL(2'b00),
    .WTSEL(2'b00),
    .PTSEL(2'b00),
    .AA   (w_addr[9:0]),
    .DA   (w_din[511:384]),
    .BWEBA(bwe_q3),
    .WEBA (~(w_en & has_we_q3)), // active low
    .CEBA (~w_en),               // active low when port enabled
    .CLK  (clk_mem),
    .AB   (r_addr[9:0]),
    .DB   (128'h0),
    .BWEBB({128{1'b1}}),         // no write on port B
    .WEBB (1'b1),                // inactive (active low)
    .CEBB (~r_en),               // enable when reading
    .AWT  (1'b0),
    .QA   (),
    .QB   (qb_q3)
);

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
        r_dout <= 512'h0;
    end else if (r_en_last) begin
        r_dout <= {qb_q3, qb_q2, qb_q1, qb_q0};
    end
end

`else

// ASIC SRAM memory array: 1024 x 512 bits
// Pseudo dual-port SRAM: simultaneous read/write on different ports
reg [511:0] sram_memory [0:1023];  // 1024 entries = 2^10

// Initialize SRAM memory to zero (ASIC power-on state)
integer i;
initial begin
    for (i = 0; i < 1024; i = i + 1) begin
        sram_memory[i] = 512'h0;
    end
end

// Read port operation (immediate output when enabled, maintain output)
// Supports simultaneous read with write operation
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
        r_dout <= 512'h0;
    end else if (r_en_last) begin
        // Read from memory array and output immediately in the same cycle
        r_dout <= sram_memory[r_addr[9:0]];
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
        sram_memory[w_addr[9:0]] <= {
            // Bytes 63-56 (MSB)
            w_we[63] ? w_din[511:504] : sram_memory[w_addr[9:0]][511:504],
            w_we[62] ? w_din[503:496] : sram_memory[w_addr[9:0]][503:496],
            w_we[61] ? w_din[495:488] : sram_memory[w_addr[9:0]][495:488],
            w_we[60] ? w_din[487:480] : sram_memory[w_addr[9:0]][487:480],
            w_we[59] ? w_din[479:472] : sram_memory[w_addr[9:0]][479:472],
            w_we[58] ? w_din[471:464] : sram_memory[w_addr[9:0]][471:464],
            w_we[57] ? w_din[463:456] : sram_memory[w_addr[9:0]][463:456],
            w_we[56] ? w_din[455:448] : sram_memory[w_addr[9:0]][455:448],
            // Bytes 55-48
            w_we[55] ? w_din[447:440] : sram_memory[w_addr[9:0]][447:440],
            w_we[54] ? w_din[439:432] : sram_memory[w_addr[9:0]][439:432],
            w_we[53] ? w_din[431:424] : sram_memory[w_addr[9:0]][431:424],
            w_we[52] ? w_din[423:416] : sram_memory[w_addr[9:0]][423:416],
            w_we[51] ? w_din[415:408] : sram_memory[w_addr[9:0]][415:408],
            w_we[50] ? w_din[407:400] : sram_memory[w_addr[9:0]][407:400],
            w_we[49] ? w_din[399:392] : sram_memory[w_addr[9:0]][399:392],
            w_we[48] ? w_din[391:384] : sram_memory[w_addr[9:0]][391:384],
            // Bytes 47-40
            w_we[47] ? w_din[383:376] : sram_memory[w_addr[9:0]][383:376],
            w_we[46] ? w_din[375:368] : sram_memory[w_addr[9:0]][375:368],
            w_we[45] ? w_din[367:360] : sram_memory[w_addr[9:0]][367:360],
            w_we[44] ? w_din[359:352] : sram_memory[w_addr[9:0]][359:352],
            w_we[43] ? w_din[351:344] : sram_memory[w_addr[9:0]][351:344],
            w_we[42] ? w_din[343:336] : sram_memory[w_addr[9:0]][343:336],
            w_we[41] ? w_din[335:328] : sram_memory[w_addr[9:0]][335:328],
            w_we[40] ? w_din[327:320] : sram_memory[w_addr[9:0]][327:320],
            // Bytes 39-32
            w_we[39] ? w_din[319:312] : sram_memory[w_addr[9:0]][319:312],
            w_we[38] ? w_din[311:304] : sram_memory[w_addr[9:0]][311:304],
            w_we[37] ? w_din[303:296] : sram_memory[w_addr[9:0]][303:296],
            w_we[36] ? w_din[295:288] : sram_memory[w_addr[9:0]][295:288],
            w_we[35] ? w_din[287:280] : sram_memory[w_addr[9:0]][287:280],
            w_we[34] ? w_din[279:272] : sram_memory[w_addr[9:0]][279:272],
            w_we[33] ? w_din[271:264] : sram_memory[w_addr[9:0]][271:264],
            w_we[32] ? w_din[263:256] : sram_memory[w_addr[9:0]][263:256],
            // Bytes 31-24
            w_we[31] ? w_din[255:248] : sram_memory[w_addr[9:0]][255:248],
            w_we[30] ? w_din[247:240] : sram_memory[w_addr[9:0]][247:240],
            w_we[29] ? w_din[239:232] : sram_memory[w_addr[9:0]][239:232],
            w_we[28] ? w_din[231:224] : sram_memory[w_addr[9:0]][231:224],
            w_we[27] ? w_din[223:216] : sram_memory[w_addr[9:0]][223:216],
            w_we[26] ? w_din[215:208] : sram_memory[w_addr[9:0]][215:208],
            w_we[25] ? w_din[207:200] : sram_memory[w_addr[9:0]][207:200],
            w_we[24] ? w_din[199:192] : sram_memory[w_addr[9:0]][199:192],
            // Bytes 23-16
            w_we[23] ? w_din[191:184] : sram_memory[w_addr[9:0]][191:184],
            w_we[22] ? w_din[183:176] : sram_memory[w_addr[9:0]][183:176],
            w_we[21] ? w_din[175:168] : sram_memory[w_addr[9:0]][175:168],
            w_we[20] ? w_din[167:160] : sram_memory[w_addr[9:0]][167:160],
            w_we[19] ? w_din[159:152] : sram_memory[w_addr[9:0]][159:152],
            w_we[18] ? w_din[151:144] : sram_memory[w_addr[9:0]][151:144],
            w_we[17] ? w_din[143:136] : sram_memory[w_addr[9:0]][143:136],
            w_we[16] ? w_din[135:128] : sram_memory[w_addr[9:0]][135:128],
            // Bytes 15-8
            w_we[15] ? w_din[127:120] : sram_memory[w_addr[9:0]][127:120],
            w_we[14] ? w_din[119:112] : sram_memory[w_addr[9:0]][119:112],
            w_we[13] ? w_din[111:104] : sram_memory[w_addr[9:0]][111:104],
            w_we[12] ? w_din[103:96]  : sram_memory[w_addr[9:0]][103:96],
            w_we[11] ? w_din[95:88]   : sram_memory[w_addr[9:0]][95:88],
            w_we[10] ? w_din[87:80]   : sram_memory[w_addr[9:0]][87:80],
            w_we[9]  ? w_din[79:72]   : sram_memory[w_addr[9:0]][79:72],
            w_we[8]  ? w_din[71:64]   : sram_memory[w_addr[9:0]][71:64],
            // Bytes 7-0 (LSB)
            w_we[7]  ? w_din[63:56]   : sram_memory[w_addr[9:0]][63:56],
            w_we[6]  ? w_din[55:48]   : sram_memory[w_addr[9:0]][55:48],
            w_we[5]  ? w_din[47:40]   : sram_memory[w_addr[9:0]][47:40],
            w_we[4]  ? w_din[39:32]   : sram_memory[w_addr[9:0]][39:32],
            w_we[3]  ? w_din[31:24]   : sram_memory[w_addr[9:0]][31:24],
            w_we[2]  ? w_din[23:16]   : sram_memory[w_addr[9:0]][23:16],
            w_we[1]  ? w_din[15:8]    : sram_memory[w_addr[9:0]][15:8],
            w_we[0]  ? w_din[7:0]     : sram_memory[w_addr[9:0]][7:0]
        };
    end
end

`endif

endmodule
