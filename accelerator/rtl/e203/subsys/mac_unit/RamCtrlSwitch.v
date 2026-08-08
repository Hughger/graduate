// Project: E203 HBIRD V2 SoC
// Author: Assistant
// Date: 2025-01-XX
// Description: RAM Control Switch Module
// Switches RAM control between AXI and MAC Machine based on control register
// Control register at 0xF_0000, default value 0 (AXI control)

module RamCtrlSwitch (
    input  wire        clk,
    input  wire        rst_n,

    // Control interface from AXI (for address 0xF_0000)
    input  wire        ctrl_valid,    // Valid signal for control write
    input  wire [31:0] ctrl_data,     // Control data (bit 0 = crtl_axi_macm)
    output wire        ctrl_ready,    // Ready to accept control data

    // BRAM interface from AXI controller (axi2bram_64k) - Pseudo dual-port
    // AXI Write port
    input  wire [10:0]  axi_bram_w_addr,   // 11-bit for 64KB
    input  wire [255:0] axi_bram_w_din,
    input  wire         axi_bram_w_en,
    input  wire [31:0]  axi_bram_w_we,
    // AXI Read port
    input  wire [10:0]  axi_bram_r_addr,   // 11-bit for 64KB
    output wire [255:0] axi_bram_r_dout,
    input  wire         axi_bram_r_en,

    // BRAM interface from MAC controller (MacMachine_RamCtrlSimple) - Pseudo dual-port
    // MAC Write port
    input  wire [10:0]  mac_bram_w_addr,   // 11-bit for 64KB
    input  wire [255:0] mac_bram_w_din,
    input  wire         mac_bram_w_en,
    input  wire [31:0]  mac_bram_w_we,
    // MAC Read port
    input  wire [10:0]  mac_bram_r_addr,   // 11-bit for 64KB
    output wire [255:0] mac_bram_r_dout,
    input  wire         mac_bram_r_en,

    // BRAM interface to actual BRAM (e203_bram_64k) - Pseudo dual-port
    // Write port
    output wire [10:0]  bram_w_addr,       // 11-bit for 64KB
    output wire [255:0] bram_w_din,
    output wire         bram_w_en,
    output wire [31:0]  bram_w_we,
    // Read port
    output wire [10:0]  bram_r_addr,       // 11-bit for 64KB
    input  wire [255:0] bram_r_dout,
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

// Write port multiplexing
assign bram_w_addr = crtl_axi_macm ? mac_bram_w_addr : axi_bram_w_addr;
assign bram_w_din  = crtl_axi_macm ? mac_bram_w_din  : axi_bram_w_din;
assign bram_w_en   = crtl_axi_macm ? mac_bram_w_en   : axi_bram_w_en;
assign bram_w_we   = crtl_axi_macm ? mac_bram_w_we   : axi_bram_w_we;

// Read port multiplexing
assign bram_r_addr = crtl_axi_macm ? mac_bram_r_addr : axi_bram_r_addr;
assign bram_r_en   = crtl_axi_macm ? mac_bram_r_en   : axi_bram_r_en;

// Route BRAM read output back to both controllers
assign axi_bram_r_dout = bram_r_dout;
assign mac_bram_r_dout = bram_r_dout;

// Control outputs
assign ctrl_ready = ctrl_ready_o;
assign mac_enable = crtl_axi_macm;  // Enable MAC when control is 1

endmodule
