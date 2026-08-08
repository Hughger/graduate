// Project: E203 HBIRD V2 SoC
// Author: Assistant
// Date: 2025-01-XX
// Description: RAM Control Switch Module
// Switches RAM control between AXI and MAC Machine based on control register
// Control register at 0xF_0000, default value 0 (AXI control)

module RamCtrlSwitch_512b (
    input  wire        clk,
    input  wire        rst_n,

    // Control interface from AXI (for address 0xF_0000)
    input  wire        ctrl_valid,    // Valid signal for control write
    input  wire [31:0] ctrl_data,     // Control data (bit 0 = crtl_axi_macm)
    output wire        ctrl_ready,    // Ready to accept control data

    // BRAM interface from AXI controller (axi2bram_64k) - Pseudo dual-port
    // AXI Write port
    input  wire [10:0]  axi_bram_w_addr,   // 11-bit to maintain external compatibility
    input  wire [255:0] axi_bram_w_din,    // Still 256-bit (half of 512-bit)
    input  wire         axi_bram_w_en,
    input  wire [31:0]  axi_bram_w_we,
    // AXI Read port
    input  wire [10:0]  axi_bram_r_addr,   // 11-bit to maintain external compatibility
    output wire [255:0] axi_bram_r_dout,   // Still 256-bit (extracted from 512-bit)
    input  wire         axi_bram_r_en,

    // BRAM interface from MAC controller (MacMachine_RamCtrlSimple) - Pseudo dual-port
    // MAC Write port
    input  wire [10:0]  mac_bram_w_addr,   // 11-bit to match MacMachine_top interface
    input  wire [511:0] mac_bram_w_din,    // Upgraded to 512-bit
    input  wire         mac_bram_w_en,
    input  wire [63:0]  mac_bram_w_we,     // Upgraded to 64-bit (64 bytes)
    // MAC Read port
    input  wire [10:0]  mac_bram_r_addr,   // 11-bit to match MacMachine_top interface
    output wire [511:0] mac_bram_r_dout,   // Upgraded to 512-bit
    input  wire         mac_bram_r_en,

    // BRAM interface to actual BRAM (e203_bram_64k_512b) - Pseudo dual-port
    // Write port
    output wire [10:0]  bram_w_addr,       // 11-bit for domain select + 1K entries
    output wire [511:0] bram_w_din,        // Upgraded to 512-bit
    output wire         bram_w_en,
    output wire [63:0]  bram_w_we,         // Upgraded to 64-bit (64 bytes)
    // Read port
    output wire [10:0]  bram_r_addr,       // 11-bit for domain select + 1K entries
    input  wire [511:0] bram_r_dout,       // Upgraded to 512-bit
    output wire         bram_r_en,

    // Control output to MAC controller
    output wire         mac_enable
);

// Control register: bit 0 controls AXI/MAC switch
// 0 = AXI control, 1 = MAC control
reg crtl_axi_macm;
reg ctrl_ready_o;

// Default to AXI control (0)
initial begin
    crtl_axi_macm = 1'b0;
    ctrl_ready_o = 1'b1;
end

// Control register write logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        crtl_axi_macm <= 1'b0;  // Default to AXI control
        ctrl_ready_o <= 1'b1;
    end else begin
        if (ctrl_valid && ctrl_ready_o) begin
            crtl_axi_macm <= ctrl_data[0];  // Use bit 0 as control
            ctrl_ready_o <= 1'b1;
        end else begin
            ctrl_ready_o <= 1'b1;  // Always ready
        end
    end
end

// Clock和Reset统一由顶层提供，不在此模块内复用

// AXI 256-bit to 512-bit data expansion for write
// AXI sends 256-bit data, but BRAM needs 512-bit
// We replicate the 256-bit data to both halves of 512-bit
wire [511:0] axi_bram_w_din_expanded;
assign axi_bram_w_din_expanded = {axi_bram_w_din, axi_bram_w_din};

// AXI write enable expansion: 32-bit to 64-bit
// Each AXI byte enable controls 2 BRAM bytes (low and high halves)
wire [63:0] axi_bram_w_we_expanded;
assign axi_bram_w_we_expanded = {axi_bram_w_we, axi_bram_w_we};

// 支持 11 位地址：bit[10] 作为域选择，高/低 256b 域
wire        axi_w_domain = axi_bram_w_addr[10];
wire        axi_r_domain = axi_bram_r_addr[10];
wire        mac_w_domain = mac_bram_w_addr[10];
wire        mac_r_domain = mac_bram_r_addr[10];

wire [10:0] axi_bram_w_addr_full = axi_bram_w_addr[10:0];
wire [10:0] axi_bram_r_addr_full = axi_bram_r_addr[10:0];
wire [10:0] mac_bram_w_addr_full = mac_bram_w_addr[10:0];
wire [10:0] mac_bram_r_addr_full = mac_bram_r_addr[10:0];

// Write port multiplexing
assign bram_w_addr = crtl_axi_macm ? mac_bram_w_addr_full : axi_bram_w_addr_full;

// 写使能：仅 AXI 分支按 addr[10] 选择 256b 半区；MAC 分支保持 512b 全宽
wire [63:0] axi_we_hi = axi_bram_w_we_expanded & {64{axi_w_domain}}; // 高域
wire [63:0] axi_we_lo = axi_bram_w_we_expanded & {64{~axi_w_domain}}; // 低域
wire [63:0] axi_sel_we = axi_we_hi | axi_we_lo; // 两域互斥
assign bram_w_we = crtl_axi_macm ? mac_bram_w_we : axi_sel_we;

// 写数据：
// - AXI：把 256b 复制到 512b 后，再由 addr[10] 决定仅一半有效（另一半 WE=0）
// - MAC：直接透传 512b
assign bram_w_din = crtl_axi_macm ? mac_bram_w_din : axi_bram_w_din_expanded;
assign bram_w_en  = crtl_axi_macm ? mac_bram_w_en  : axi_bram_w_en;

// Read port multiplexing
assign bram_r_addr = crtl_axi_macm ? mac_bram_r_addr_full : axi_bram_r_addr_full;
assign bram_r_en   = crtl_axi_macm ? mac_bram_r_en  : axi_bram_r_en;

// AXI 512->256 读数据域选择：
// - 当 addr[10]==1 取每 16bit 的高 8bit（对应高域）
// - 当 addr[10]==0 取每 16bit 的低 8bit（对应低域）
wire [255:0] axi_bram_r_dout_extracted_hi;
wire [255:0] axi_bram_r_dout_extracted_lo;
genvar i;
generate
    for (i = 0; i < 32; i = i + 1) begin: gen_extract
        // 低域：取每 16bit 的低 8bit -> [7:0]
        assign axi_bram_r_dout_extracted_lo[i*8+7:i*8] = bram_r_dout[i*16+7:i*16];
        // 高域：取每 16bit 的高 8bit -> [15:8]
        assign axi_bram_r_dout_extracted_hi[i*8+7:i*8] = bram_r_dout[i*16+15:i*16+8];
    end
endgenerate
wire [255:0] axi_bram_r_dout_selected = axi_r_domain ? axi_bram_r_dout_extracted_hi
                                                      : axi_bram_r_dout_extracted_lo;

// Route BRAM read output back to controllers
assign axi_bram_r_dout = axi_bram_r_dout_selected;
assign mac_bram_r_dout = bram_r_dout;

// Control outputs
assign ctrl_ready = ctrl_ready_o;
assign mac_enable = crtl_axi_macm;  // Enable MAC when control is 1

endmodule
