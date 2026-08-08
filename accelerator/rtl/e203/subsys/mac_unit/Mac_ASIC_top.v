module Mac_ASIC_top(
    input  clk,
    input  rst_n,
    // inout  [63:0] dinout,
    input  [63:0] din,
    output [63:0] dout,
    input  [15:0] addr,
    input  en,
    input  wr_en,
    // Interrupt outputs from MacMachine
    output wire macMachineDone_interrupt,
    output wire macMachineerror_interrupt
);

  // Interconnect signals between mux and local SRAMs
  wire [5:0]  ram_sel;
  wire [63:0] ram_wdata;
  wire        ram_wen;
  wire        ram_we;
  wire        ram_ren;
  wire [12:0] ram_waddr;
  wire [12:0] ram_raddr;
  // Use top-level clk and rst_n directly

  // Read data from 6 SRAMs (mux only returns 2~5)
  wire [63:0] ram0_rdata;
  wire [63:0] ram1_rdata;
  wire [63:0] ram2_rdata;
  wire [63:0] ram3_rdata;
  wire [63:0] ram4_rdata;
  wire [63:0] ram5_rdata;

  // Control signals from RAM MUX for RAM switches
  wire        ram2_ctrl_valid;
  wire [31:0] ram2_ctrl_data;
  wire        ram3_ctrl_valid;
  wire [31:0] ram3_ctrl_data;
  wire        ram4_ctrl_valid;
  wire [31:0] ram4_ctrl_data;
  wire        ram5_ctrl_valid;
  wire [31:0] ram5_ctrl_data;

  // RAM MUX: bridge BRAM-like interface from AXI to 6 local SRAMs
  design_ram_mux u_design_ram_mux(
    .BRAM_PORTA_0_clk    (clk),
    .BRAM_PORTA_0_rstn   (rst_n),
    .BRAM_PORTA_0_addr   (addr),
    .BRAM_PORTA_0_din    (din),
    .BRAM_PORTA_0_dout   (dout),
    // .BRAM_PORTA_0_dinout (dinout),
    .BRAM_PORTA_0_en     (en),
    .BRAM_PORTA_0_we     (wr_en),

    .RAM_sel    (ram_sel),
    .RAM_2_rdata(ram2_rdata),
    .RAM_3_rdata(ram3_rdata),
    .RAM_4_rdata(ram4_rdata),
    .RAM_5_rdata(ram5_rdata),
    .RAM_wdata  (ram_wdata),
    .RAM_wen    (ram_wen),
    .RAM_we     (ram_we),
    .RAM_ren    (ram_ren),
    .RAM_waddr  (ram_waddr),
    .RAM_raddr  (ram_raddr),

    // Control signals for RAM switches
    .ram2_ctrl_valid(ram2_ctrl_valid),
    .ram2_ctrl_data (ram2_ctrl_data),
    .ram3_ctrl_valid(ram3_ctrl_valid),
    .ram3_ctrl_data (ram3_ctrl_data),
    .ram4_ctrl_valid(ram4_ctrl_valid),
    .ram4_ctrl_data (ram4_ctrl_data),
    .ram5_ctrl_valid(ram5_ctrl_valid),
    .ram5_ctrl_data (ram5_ctrl_data)
  );

  // Config Bus signals from MacMachine_top
  wire [31:0] macmachine_configBus_data;
  wire [31:0] macmachine_configBus_addr;
  wire        macmachine_configBus_en;

  // 6 pseudo dual-port SRAMs
  b64_b32 u_b64_b32_0(
    .clk               (clk),
    .rst_n             (rst_n),
    .w_data            (ram_wdata),
    .w_addr            (ram_waddr),
    .en                ((ram_wen || ram_ren) && ram_sel[0]),
    .we                (ram_wen && ram_sel[0]),
    .r_addr            (ram_raddr),
    .r_data            (ram0_rdata),
    .io_configBus_data (macmachine_configBus_data),  // Connect to MacMachine_top
    .io_configBus_addr (macmachine_configBus_addr),  // Connect to MacMachine_top
    .io_configBus_en   (macmachine_configBus_en)     // Connect to MacMachine_top
  );

  // Input SRAM signals for MacMachine_top connection
  wire [10:0]  input_sram0_bram_w_addr;
  wire [255:0] input_sram0_bram_w_din;
  wire         input_sram0_bram_w_en;
  wire [31:0]  input_sram0_bram_w_we;
  wire [10:0]  input_sram0_bram_r_addr;
  wire [255:0] input_sram0_bram_r_dout;
  wire         input_sram0_bram_r_en;

  b64_b256 u_b64_b256_1(
    .clk      (clk),
    .rst_n    (rst_n),
    .w_data   (ram_wdata),
    .w_addr   (ram_waddr),
    .en       ((ram_wen || ram_ren) && ram_sel[1]),
    .we       (ram_wen && ram_sel[1]),
    .r_addr   (ram_raddr),
    .r_data   (ram1_rdata),
    // bram interface - connect to MacMachine_top input_sram0
    .bram_w_addr  (input_sram0_bram_w_addr),
    .bram_w_data  (input_sram0_bram_w_din),
    .bram_w_en    (input_sram0_bram_w_en),
    .bram_w_we    (input_sram0_bram_w_we),
    .bram_r_addr  (input_sram0_bram_r_addr),
    .bram_r_data  (input_sram0_bram_r_dout),
    .bram_r_en    (input_sram0_bram_r_en)
  );

  // RAM2: b64_b256 -> RamCtrlSwitch -> e203_bram_64k + MacMachine_RamCtrlSimple
  wire [10:0]  ram2_bram_w_addr;
  wire [255:0] ram2_bram_w_data;
  wire         ram2_bram_w_en;
  wire [31:0]  ram2_bram_w_we;
  wire [10:0]  ram2_bram_r_addr;
  wire [255:0] ram2_bram_r_data;
  wire         ram2_bram_r_en;

  b64_b256 u_b64_b256_2(
    .clk      (clk),
    .rst_n    (rst_n),
    .w_data   (ram_wdata),
    .w_addr   (ram_waddr),
    .en       ((ram_wen || ram_ren) && ram_sel[2]),
    .we       (ram_wen && ram_sel[2]),
    .r_addr   (ram_raddr),
    .r_data   (ram2_rdata),
    .bram_w_addr (ram2_bram_w_addr),
    .bram_w_data (ram2_bram_w_data),
    .bram_w_en   (ram2_bram_w_en),
    .bram_w_we   (ram2_bram_w_we),
    .bram_r_addr (ram2_bram_r_addr),
    .bram_r_data (ram2_bram_r_data),
    .bram_r_en   (ram2_bram_r_en)
  );

  wire [255:0] ram2_switch_bram_r_dout;
  wire [255:0] ram2_bram_r_dout;
  wire         ram2_mac_enable;

  wire [10:0]  ram2_switch_bram_w_addr;
  wire [255:0] ram2_switch_bram_w_din;
  wire         ram2_switch_bram_w_en;
  wire [31:0]  ram2_switch_bram_w_we;
  wire [10:0]  ram2_switch_bram_r_addr;
  wire         ram2_switch_bram_r_en;

  // Signals for MAC controller connection to switch
  wire [10:0]  ram2_mac_bram_w_addr;
  wire [255:0] ram2_mac_bram_w_din;
  wire         ram2_mac_bram_w_en;
  wire [31:0]  ram2_mac_bram_w_we;
  wire [10:0]  ram2_mac_bram_r_addr;
  wire [255:0] ram2_mac_bram_r_dout;
  wire         ram2_mac_bram_r_en;

  RamCtrlSwitch u_RamCtrlSwitch_2(
    .clk          (clk),
    .rst_n        (rst_n),
    .ctrl_valid   (ram2_ctrl_valid),
    .ctrl_data    (ram2_ctrl_data),
    .ctrl_ready   (),              // Not used
    .axi_bram_w_addr  (ram2_bram_w_addr),
    .axi_bram_w_din   (ram2_bram_w_data),
    .axi_bram_w_en    (ram2_bram_w_en),
    .axi_bram_w_we    (ram2_bram_w_we),
    .axi_bram_r_addr  (ram2_bram_r_addr),
    .axi_bram_r_dout  (ram2_bram_r_data),
    .axi_bram_r_en    (ram2_bram_r_en),
    .mac_bram_w_addr  (ram2_mac_bram_w_addr),
    .mac_bram_w_din   (ram2_mac_bram_w_din),
    .mac_bram_w_en    (ram2_mac_bram_w_en),
    .mac_bram_w_we    (ram2_mac_bram_w_we),
    .mac_bram_r_addr  (ram2_mac_bram_r_addr),
    .mac_bram_r_dout  (ram2_mac_bram_r_dout),
    .mac_bram_r_en    (ram2_mac_bram_r_en),
    .bram_w_addr  (ram2_switch_bram_w_addr),
    .bram_w_din   (ram2_switch_bram_w_din),
    .bram_w_en    (ram2_switch_bram_w_en),
    .bram_w_we    (ram2_switch_bram_w_we),
    .bram_r_addr  (ram2_switch_bram_r_addr),
    .bram_r_dout  (ram2_bram_r_dout),
    .bram_r_en    (ram2_switch_bram_r_en),
    .mac_enable   (ram2_mac_enable)
  );

  e203_bram_64k u_e203_bram_64k_2(
    .clk      (clk),
    .rst_n    (rst_n),
    .w_addr   (ram2_switch_bram_w_addr),
    .w_din    (ram2_switch_bram_w_din),
    .w_en     (ram2_switch_bram_w_en),
    .w_we     (ram2_switch_bram_w_we),
    .r_addr   (ram2_switch_bram_r_addr),
    .r_dout   (ram2_bram_r_dout),
    .r_en     (ram2_switch_bram_r_en)
  );

  // u_MacMachine_RamCtrlSimple_2 replaced by MacMachine_top weight_sram0 interface

  // RAM3: b64_b256 -> RamCtrlSwitch -> e203_bram_64k + MacMachine_RamCtrlSimple
  wire [10:0]  ram3_bram_w_addr;
  wire [255:0] ram3_bram_w_data;
  wire         ram3_bram_w_en;
  wire [31:0]  ram3_bram_w_we;
  wire [10:0]  ram3_bram_r_addr;
  wire [255:0] ram3_bram_r_data;
  wire         ram3_bram_r_en;

  b64_b256 u_b64_b256_3(
    .clk      (clk),
    .rst_n    (rst_n),
    .w_data   (ram_wdata),
    .w_addr   (ram_waddr),
    .en       ((ram_wen || ram_ren) && ram_sel[3]),
    .we       (ram_wen && ram_sel[3]),
    .r_addr   (ram_raddr),
    .r_data   (ram3_rdata),
    .bram_w_addr (ram3_bram_w_addr),
    .bram_w_data (ram3_bram_w_data),
    .bram_w_en   (ram3_bram_w_en),
    .bram_w_we   (ram3_bram_w_we),
    .bram_r_addr (ram3_bram_r_addr),
    .bram_r_data (ram3_bram_r_data),
    .bram_r_en   (ram3_bram_r_en)
  );

  wire [255:0] ram3_switch_bram_r_dout;
  wire [255:0] ram3_bram_r_dout;
  wire         ram3_mac_enable;

  wire [10:0]  ram3_switch_bram_w_addr;
  wire [255:0] ram3_switch_bram_w_din;
  wire         ram3_switch_bram_w_en;
  wire [31:0]  ram3_switch_bram_w_we;
  wire [10:0]  ram3_switch_bram_r_addr;
  wire         ram3_switch_bram_r_en;

  // Signals for MAC controller connection to switch
  wire [10:0]  ram3_mac_bram_w_addr;
  wire [255:0] ram3_mac_bram_w_din;
  wire         ram3_mac_bram_w_en;
  wire [31:0]  ram3_mac_bram_w_we;
  wire [10:0]  ram3_mac_bram_r_addr;
  wire [255:0] ram3_mac_bram_r_dout;
  wire         ram3_mac_bram_r_en;

  RamCtrlSwitch u_RamCtrlSwitch_3(
    .clk          (clk),
    .rst_n        (rst_n),
    .ctrl_valid   (ram3_ctrl_valid),
    .ctrl_data    (ram3_ctrl_data),
    .ctrl_ready   (),              // Not used
    .axi_bram_w_addr  (ram3_bram_w_addr),
    .axi_bram_w_din   (ram3_bram_w_data),
    .axi_bram_w_en    (ram3_bram_w_en),
    .axi_bram_w_we    (ram3_bram_w_we),
    .axi_bram_r_addr  (ram3_bram_r_addr),
    .axi_bram_r_dout  (ram3_bram_r_data),
    .axi_bram_r_en    (ram3_bram_r_en),
    .mac_bram_w_addr  (ram3_mac_bram_w_addr),
    .mac_bram_w_din   (ram3_mac_bram_w_din),
    .mac_bram_w_en    (ram3_mac_bram_w_en),
    .mac_bram_w_we    (ram3_mac_bram_w_we),
    .mac_bram_r_addr  (ram3_mac_bram_r_addr),
    .mac_bram_r_dout  (ram3_mac_bram_r_dout),
    .mac_bram_r_en    (ram3_mac_bram_r_en),
    .bram_w_addr  (ram3_switch_bram_w_addr),
    .bram_w_din   (ram3_switch_bram_w_din),
    .bram_w_en    (ram3_switch_bram_w_en),
    .bram_w_we    (ram3_switch_bram_w_we),
    .bram_r_addr  (ram3_switch_bram_r_addr),
    .bram_r_dout  (ram3_bram_r_dout),
    .bram_r_en    (ram3_switch_bram_r_en),
    .mac_enable   (ram3_mac_enable)
  );

  e203_bram_64k u_e203_bram_64k_3(
    .clk      (clk),
    .rst_n    (rst_n),
    .w_addr   (ram3_switch_bram_w_addr),
    .w_din    (ram3_switch_bram_w_din),
    .w_en     (ram3_switch_bram_w_en),
    .w_we     (ram3_switch_bram_w_we),
    .r_addr   (ram3_switch_bram_r_addr),
    .r_dout   (ram3_bram_r_dout),
    .r_en     (ram3_switch_bram_r_en)
  );

  // u_MacMachine_RamCtrlSimple_3 replaced by MacMachine_top weight_sram1 interface

  // RAM4: b64_b256 -> RamCtrlSwitch -> e203_bram_64k + MacMachine_RamCtrlSimple
  wire [10:0]  ram4_bram_w_addr;
  wire [255:0] ram4_bram_w_data;
  wire         ram4_bram_w_en;
  wire [31:0]  ram4_bram_w_we;
  wire [10:0]  ram4_bram_r_addr;
  wire [255:0] ram4_bram_r_data;
  wire         ram4_bram_r_en;

  b64_b256 u_b64_b256_4(
    .clk      (clk),
    .rst_n    (rst_n),
    .w_data   (ram_wdata),
    .w_addr   (ram_waddr),
    .en       ((ram_wen || ram_ren) && ram_sel[4]),
    .we       (ram_wen && ram_sel[4]),
    .r_addr   (ram_raddr),
    .r_data   (ram4_rdata),
    .bram_w_addr (ram4_bram_w_addr),
    .bram_w_data (ram4_bram_w_data),
    .bram_w_en   (ram4_bram_w_en),
    .bram_w_we   (ram4_bram_w_we),
    .bram_r_addr (ram4_bram_r_addr),
    .bram_r_data (ram4_bram_r_data),
    .bram_r_en   (ram4_bram_r_en)
  );

  wire [511:0] ram4_switch_bram_r_dout;  // 512-bit data
  wire [511:0] ram4_bram_r_dout;         // 512-bit data
  wire         ram4_mac_enable;

  wire [10:0]  ram4_switch_bram_w_addr;  // 11-bit: bit10 selects sub-domain
  wire [511:0] ram4_switch_bram_w_din;   // 512-bit data
  wire         ram4_switch_bram_w_en;
  wire [63:0]  ram4_switch_bram_w_we;    // 64-bit write enable
  wire [10:0]  ram4_switch_bram_r_addr;  // 11-bit: bit10 selects sub-domain
  wire         ram4_switch_bram_r_en;

  // Signals for MAC controller connection to switch (upgraded to 512-bit)
  wire [10:0]  ram4_mac_bram_w_addr;   // 11-bit to match MacMachine_top interface
  wire [511:0] ram4_mac_bram_w_din;    // 512-bit data
  wire         ram4_mac_bram_w_en;
  wire [63:0]  ram4_mac_bram_w_we;     // 64-bit write enable
  wire [10:0]  ram4_mac_bram_r_addr;   // 11-bit to match MacMachine_top interface
  wire [511:0] ram4_mac_bram_r_dout;   // 512-bit data
  wire         ram4_mac_bram_r_en;

  RamCtrlSwitch_512b u_RamCtrlSwitch_4(
    .clk          (clk),
    .rst_n        (rst_n),
    .ctrl_valid   (ram4_ctrl_valid),
    .ctrl_data    (ram4_ctrl_data),
    .ctrl_ready   (),              // Not used
    .axi_bram_w_addr  (ram4_bram_w_addr),
    .axi_bram_w_din   (ram4_bram_w_data),
    .axi_bram_w_en    (ram4_bram_w_en),
    .axi_bram_w_we    (ram4_bram_w_we),
    .axi_bram_r_addr  (ram4_bram_r_addr),
    .axi_bram_r_dout  (ram4_bram_r_data),
    .axi_bram_r_en    (ram4_bram_r_en),
    .mac_bram_w_addr  (ram4_mac_bram_w_addr),
    .mac_bram_w_din   (ram4_mac_bram_w_din),
    .mac_bram_w_en    (ram4_mac_bram_w_en),
    .mac_bram_w_we    (ram4_mac_bram_w_we),
    .mac_bram_r_addr  (ram4_mac_bram_r_addr),
    .mac_bram_r_dout  (ram4_mac_bram_r_dout),
    .mac_bram_r_en    (ram4_mac_bram_r_en),
    .bram_w_addr  (ram4_switch_bram_w_addr),
    .bram_w_din   (ram4_switch_bram_w_din),
    .bram_w_en    (ram4_switch_bram_w_en),
    .bram_w_we    (ram4_switch_bram_w_we),
    .bram_r_addr  (ram4_switch_bram_r_addr),
    .bram_r_dout  (ram4_bram_r_dout),
    .bram_r_en    (ram4_switch_bram_r_en),
    .mac_enable   (ram4_mac_enable)
  );

  e203_bram_64k_512b u_e203_bram_64k_4(
    .clk      (clk),
    .rst_n    (rst_n),
    .w_addr   (ram4_switch_bram_w_addr),
    .w_din    (ram4_switch_bram_w_din),
    .w_en     (ram4_switch_bram_w_en),
    .w_we     (ram4_switch_bram_w_we),
    .r_addr   (ram4_switch_bram_r_addr),
    .r_dout   (ram4_bram_r_dout),
    .r_en     (ram4_switch_bram_r_en)
  );

  // u_MacMachine_RamCtrlSimple_4 replaced by MacMachine_top output_sram0 interface

  // RAM5: b64_b256 -> RamCtrlSwitch -> e203_bram_64k + MacMachine_RamCtrlSimple
  wire [10:0]  ram5_bram_w_addr;
  wire [255:0] ram5_bram_w_data;
  wire         ram5_bram_w_en;
  wire [31:0]  ram5_bram_w_we;
  wire [10:0]  ram5_bram_r_addr;
  wire [255:0] ram5_bram_r_data;
  wire         ram5_bram_r_en;

  b64_b256 u_b64_b256_5(
    .clk      (clk),
    .rst_n    (rst_n),
    .w_data   (ram_wdata),
    .w_addr   (ram_waddr),
    .en       ((ram_wen || ram_ren) && ram_sel[5]),
    .we       (ram_wen && ram_sel[5]),
    .r_addr   (ram_raddr),
    .r_data   (ram5_rdata),
    .bram_w_addr (ram5_bram_w_addr),
    .bram_w_data (ram5_bram_w_data),
    .bram_w_en   (ram5_bram_w_en),
    .bram_w_we   (ram5_bram_w_we),
    .bram_r_addr (ram5_bram_r_addr),
    .bram_r_data (ram5_bram_r_data),
    .bram_r_en   (ram5_bram_r_en)
  );

  wire [511:0] ram5_switch_bram_r_dout;  // 512-bit data
  wire [511:0] ram5_bram_r_dout;         // 512-bit data
  wire         ram5_mac_enable;

  wire [10:0]  ram5_switch_bram_w_addr;  // 11-bit: bit10 selects sub-domain
  wire [511:0] ram5_switch_bram_w_din;   // 512-bit data
  wire         ram5_switch_bram_w_en;
  wire [63:0]  ram5_switch_bram_w_we;    // 64-bit write enable
  wire [10:0]  ram5_switch_bram_r_addr;  // 11-bit: bit10 selects sub-domain
  wire         ram5_switch_bram_r_en;

  // Signals for MAC controller connection to switch (upgraded to 512-bit)
  wire [10:0]  ram5_mac_bram_w_addr;   // 11-bit to match MacMachine_top interface
  wire [511:0] ram5_mac_bram_w_din;    // 512-bit data
  wire         ram5_mac_bram_w_en;
  wire [63:0]  ram5_mac_bram_w_we;     // 64-bit write enable
  wire [10:0]  ram5_mac_bram_r_addr;   // 11-bit to match MacMachine_top interface
  wire [511:0] ram5_mac_bram_r_dout;   // 512-bit data
  wire         ram5_mac_bram_r_en;

  RamCtrlSwitch_512b u_RamCtrlSwitch_5(
    .clk          (clk),
    .rst_n        (rst_n),
    .ctrl_valid   (ram5_ctrl_valid),
    .ctrl_data    (ram5_ctrl_data),
    .ctrl_ready   (),              // Not used
    .axi_bram_w_addr  (ram5_bram_w_addr),
    .axi_bram_w_din   (ram5_bram_w_data),
    .axi_bram_w_en    (ram5_bram_w_en),
    .axi_bram_w_we    (ram5_bram_w_we),
    .axi_bram_r_addr  (ram5_bram_r_addr),
    .axi_bram_r_dout  (ram5_bram_r_data),
    .axi_bram_r_en    (ram5_bram_r_en),
    .mac_bram_w_addr  (ram5_mac_bram_w_addr),
    .mac_bram_w_din   (ram5_mac_bram_w_din),
    .mac_bram_w_en    (ram5_mac_bram_w_en),
    .mac_bram_w_we    (ram5_mac_bram_w_we),
    .mac_bram_r_addr  (ram5_mac_bram_r_addr),
    .mac_bram_r_dout  (ram5_mac_bram_r_dout),
    .mac_bram_r_en    (ram5_mac_bram_r_en),
    .bram_w_addr  (ram5_switch_bram_w_addr),
    .bram_w_din   (ram5_switch_bram_w_din),
    .bram_w_en    (ram5_switch_bram_w_en),
    .bram_w_we    (ram5_switch_bram_w_we),
    .bram_r_addr  (ram5_switch_bram_r_addr),
    .bram_r_dout  (ram5_bram_r_dout),
    .bram_r_en    (ram5_switch_bram_r_en),
    .mac_enable   (ram5_mac_enable)
  );

  e203_bram_64k_512b u_e203_bram_64k_5(
    .clk      (clk),
    .rst_n    (rst_n),
    .w_addr   (ram5_switch_bram_w_addr),
    .w_din    (ram5_switch_bram_w_din),
    .w_en     (ram5_switch_bram_w_en),
    .w_we     (ram5_switch_bram_w_we),
    .r_addr   (ram5_switch_bram_r_addr),
    .r_dout   (ram5_bram_r_dout),
    .r_en     (ram5_switch_bram_r_en)
  );

  // u_MacMachine_RamCtrlSimple_5 replaced by MacMachine_top output_sram1 interface

  // ==================== MacMachine_top Instantiation ====================
  MacMachine_top u_MacMachine_top(
    // Config Bus interface (connect to u_b64_b32_0)
    .io_configBus_data(macmachine_configBus_data),
    .io_configBus_addr(macmachine_configBus_addr),
    .io_configBus_en(macmachine_configBus_en),

    // Input SRAM 0 interface (connect to u_b64_b256_1 BRAM)
    .input_sram0_bram_w_addr(input_sram0_bram_w_addr),
    .input_sram0_bram_w_din(input_sram0_bram_w_din),
    .input_sram0_bram_w_en(input_sram0_bram_w_en),
    .input_sram0_bram_w_we(input_sram0_bram_w_we),
    .input_sram0_bram_r_addr(input_sram0_bram_r_addr),
    .input_sram0_bram_r_dout(input_sram0_bram_r_dout),
    .input_sram0_bram_r_en(input_sram0_bram_r_en),

    // Weight SRAM 0 control interface (replace u_MacMachine_RamCtrlSimple_2)
    .weight_sram0_enable(ram2_mac_enable),
    .weight_sram0_bram_w_addr(ram2_mac_bram_w_addr),
    .weight_sram0_bram_w_din(ram2_mac_bram_w_din),
    .weight_sram0_bram_w_en(ram2_mac_bram_w_en),
    .weight_sram0_bram_w_we(ram2_mac_bram_w_we),
    .weight_sram0_bram_r_addr(ram2_mac_bram_r_addr),
    .weight_sram0_bram_r_dout(ram2_mac_bram_r_dout),
    .weight_sram0_bram_r_en(ram2_mac_bram_r_en),

    // Weight SRAM 1 control interface (replace u_MacMachine_RamCtrlSimple_3)
    .weight_sram1_enable(ram3_mac_enable),
    .weight_sram1_bram_w_addr(ram3_mac_bram_w_addr),
    .weight_sram1_bram_w_din(ram3_mac_bram_w_din),
    .weight_sram1_bram_w_en(ram3_mac_bram_w_en),
    .weight_sram1_bram_w_we(ram3_mac_bram_w_we),
    .weight_sram1_bram_r_addr(ram3_mac_bram_r_addr),
    .weight_sram1_bram_r_dout(ram3_mac_bram_r_dout),
    .weight_sram1_bram_r_en(ram3_mac_bram_r_en),

    // Output SRAM 0 control interface (replace u_MacMachine_RamCtrlSimple_4)
    .output_sram0_enable(ram4_mac_enable),
    .output_sram0_bram_w_addr(ram4_mac_bram_w_addr),
    .output_sram0_bram_w_din(ram4_mac_bram_w_din),
    .output_sram0_bram_w_en(ram4_mac_bram_w_en),
    .output_sram0_bram_w_we(ram4_mac_bram_w_we),
    .output_sram0_bram_r_addr(ram4_mac_bram_r_addr),
    .output_sram0_bram_r_dout(ram4_mac_bram_r_dout),
    .output_sram0_bram_r_en(ram4_mac_bram_r_en),

    // Output SRAM 1 control interface (replace u_MacMachine_RamCtrlSimple_5)
    .output_sram1_enable(ram5_mac_enable),
    .output_sram1_bram_w_addr(ram5_mac_bram_w_addr),
    .output_sram1_bram_w_din(ram5_mac_bram_w_din),
    .output_sram1_bram_w_en(ram5_mac_bram_w_en),
    .output_sram1_bram_w_we(ram5_mac_bram_w_we),
    .output_sram1_bram_r_addr(ram5_mac_bram_r_addr),
    .output_sram1_bram_r_dout(ram5_mac_bram_r_dout),
    .output_sram1_bram_r_en(ram5_mac_bram_r_en),

    // Interrupt signals
    .macMachineDone_interrupt(macMachineDone_interrupt),
    .macMachineerror_interrupt(macMachineerror_interrupt),

    // System signals
    .clk(clk),
    .rst_n(rst_n)
  );

endmodule

 