`timescale 1ns / 1ps
//=============================================================================
// 文件名：system_chip_test.v
// 功  能：FPGA 作为 FLOOD MAC加速器芯片的测试主控制器
//
// 芯片实际引脚（共90个信号引脚）：
//   clk_ic, clk_core          ← 时钟（FPGA提供）
//   rst_n_io, rst_n_core      ← 复位（低有效，FPGA提供）
//   en, wr_en                 ← 使能、写使能（FPGA输出）
//   add[15:0]                 ← 16位地址（FPGA输出）
//   din[63:0]                 ← 64位双向数据总线（IOBUF）
//   input_full, output_empty  ← 状态输出（FPGA读入）
//   macDone_interrupt         ← MAC完成中断（FPGA读入）
//   macErr_interrput          ← MAC错误中断（FPGA读入）
//
// FPGA 的角色：主控制器（Master）
//   1. 提供时钟和复位
//   2. 写配置寄存器（通过地址/数据总线）
//   3. 写权重数据和特征数据到芯片内部SRAM
//   4. 写 RUN_PROCESS 寄存器触发计算
//   5. 等待 macDone_interrupt 中断
//   6. 读结果数据
//   7. 循环运行（用于持续功耗测试）
//
// 功耗测试方法：
//   test_active 信号在MAC计算期间为高电平
//   ILA 捕获此信号，与稳压电源电流读数对齐
//   稳压电源串联电流表，记录 test_active=1 时的功耗
//=============================================================================

module system_chip_test
(
  //-------------------------------------------------------------------
  // FPGA 板载信号
  //-------------------------------------------------------------------
  input  wire       sys_clk_p,        // 200MHz 差分时钟正端 (AR32)
  input  wire       sys_clk_n,        // 200MHz 差分时钟负端 (AT32)
  input  wire       fpga_rst,         // 复位按键K1，低有效 (A8)
  input  wire       mcu_rst,          // 复位按键K2，低有效 (B9)

  // 调试串口（可选，用于PC查看测试进度）
  output wire       uart_tx,          // → PC串口助手 (D2)
  input  wire       uart_rx,          // ← PC串口助手 (D1)

  // 板载LED（状态指示）
  output wire       led_mmcm_ok,      // 亮 = FPGA时钟锁定 (D8)
  output wire       led_chip_ok,      // 亮 = 芯片复位已释放 (D7)
  output wire       led_mac_done,     // 闪 = MAC计算完成过一次 (D11)
  output wire       led_chip_output_empty,

  //-------------------------------------------------------------------
  // 通过 FMC1(J12) 连接到芯片测试板
  // 所有芯片侧信号：1.8V LVCMOS（BANK69/BANK70/BANK71）
  //-------------------------------------------------------------------

  // ● 时钟输出给芯片（使用 CC 差分对的P脚）
  output wire       chip_clk_ic,      // → FMC1_LA00_CC_P (E23) → 芯片 clk_ic  (引脚46)
  output wire       chip_clk_core,    // → FMC1_LA01_CC_P (F23) → 芯片 clk_core (引脚47)

  // ● 复位输出（低有效）
  output wire       chip_rst_n_io,    // → FMC1_LA02_P (E21) → 芯片 rst_n_io  (引脚54)
  output wire       chip_rst_n_core,  // → FMC1_LA02_N (D21) → 芯片 rst_n_core (引脚55)

  // ● 控制信号输出
  output wire       chip_en,          // → PACKAGE_PIN J15 (HA20_P) → 芯片 EN
  output wire       chip_wr_en,       // → PACKAGE_PIN H15 (HA20_N) → 芯片 WR_EN

  // ● 状态/中断输入（芯片输出，FPGA读入）
  input  wire       chip_input_full,  // ← PACKAGE_PIN E15 (HA11_N) ← INPUT_FULL
  input  wire       chip_output_empty,// ← PACKAGE_PIN E16 (HA11_P) ← OUTPUT_EMPTY
  input  wire       chip_mac_done,    // ← PACKAGE_PIN F19 (HA00_CC_P) ← MACMACHINE_DONE
  input  wire       chip_mac_err,     // ← PACKAGE_PIN F20 ← MACMACHINE_ERROR

  // ● 地址总线（FPGA输出，16位）
  output wire [15:0] chip_add,        // → FMC1_LA12~LA18_CC + HA18 → ADDR0~15

  // ● 64位双向数据总线（IOBUF，方向由chip_wr_en控制）
  //   chip_wr_en=1: FPGA → 芯片（写操作）
  //   chip_wr_en=0: 芯片 → FPGA（读操作）
  inout  wire [63:0] chip_din          // ↔ FMC1_LA20~LA33 + HA00~HA17 → DINOUT0~63
);

  //====================================================================
  // 内部信号声明
  //====================================================================
  wire sys_clk;
  wire clk_16M;
  (* mark_debug = "true" *) wire clk_50M;
  wire mmcm_locked;
  wire ck_rst;

  // 数据总线内部读写方向
  wire [63:0] data_out_to_chip;   // FPGA→芯片的写数据
  wire [63:0] data_in_from_chip;  // 芯片→FPGA的读数据

  // 测试控制器 FSM 信号
  reg  [63:0] fsm_data_out;       // FSM要写的数据
  reg  [15:0] fsm_addr;           // FSM要访问的地址
  reg         fsm_en;             // FSM的使能控制
  reg         fsm_wr_en;          // FSM的读写控制
  wire        fsm_data_in_valid;  // 读数据有效

  // 复位控制
  reg  [7:0]  rst_cnt    = 8'h00;
  reg         rst_n_reg  = 1'b0;

  // 测试状态
  reg         test_active = 1'b0;  // 高=MAC正在计算（用于功耗测量对齐）
  reg         mac_done_latch = 1'b0;

  //====================================================================
  // ILA 调试信号
  // 在 Vivado Hardware Manager 中实时查看这些信号的波形
  //====================================================================
  (* mark_debug = "true" *) wire        dbg_mmcm_locked;
  (* mark_debug = "true" *) wire        dbg_chip_rst_ok;
  (* mark_debug = "true" *) wire        dbg_mac_done;       // MAC计算完成中断
  (* mark_debug = "true" *) wire        dbg_mac_err;        // MAC错误中断
  (* mark_debug = "true" *) wire        dbg_input_full;     // 输入缓冲满
  (* mark_debug = "true" *) wire        dbg_output_empty;   // 输出缓冲空
  (* mark_debug = "true" *) wire        dbg_test_active;    // ★核心：MAC计算中（用于功耗对齐）
  (* mark_debug = "true" *) wire        dbg_chip_en;        // 总线使能
  (* mark_debug = "true" *) wire        dbg_chip_wr_en;     // 总线读写方向
  (* mark_debug = "true" *) wire [15:0] dbg_chip_addr;      // 当前访问地址
  (* mark_debug = "true" *) wire [63:0] dbg_chip_data;      // 当前总线数据
  (* mark_debug = "true" *) wire [7:0]  dbg_fsm_state;      // FSM状态（方便调试）

  assign dbg_mmcm_locked  = mmcm_locked;
  assign dbg_chip_rst_ok  = chip_rst_n_reg;
  assign dbg_mac_done     = chip_mac_done;
  assign dbg_mac_err      = chip_mac_err;
  assign dbg_input_full   = chip_input_full;
  assign dbg_output_empty = chip_output_empty;
  assign dbg_test_active  = test_active;
  assign dbg_chip_en      = chip_en;
  assign dbg_chip_wr_en   = chip_wr_en;
  assign dbg_chip_addr    = chip_add;
  assign dbg_chip_data    = chip_wr_en ? data_out_to_chip : data_in_from_chip;

  //====================================================================
  // 【第1部分】时钟生成
  // 与原 system.v 完全相同，保留不变
  // 200MHz差分时钟 → MMCM → 16MHz（芯片主时钟）
  //                        → 分频 → 32.768KHz（芯片慢时钟）
  //====================================================================

  // 差分时钟转单端
  IBUFGDS u_ibufg_sys_clk
  (
    .I  (sys_clk_p),
    .IB (sys_clk_n),
    .O  (sys_clk)
  );

  // MMCM 锁相环：200MHz → 16MHz
  // （这个 IP 在 Vivado IP Catalog 中生成，名字叫 "mmcm"）
  clk_wiz_0 ip_mmcm
  (
    .reset   (~ck_rst),
    .clk_in1 (sys_clk),
    .clk_out1(clk_16M),
    .clk_out2(clk_50M),
    .locked  (mmcm_locked)
  );

  // 32.768KHz 分频（16MHz / 488 ≈ 32.787KHz，误差<0.1%，足够）
  wire CLK32768KHZ;
  divclk U0_divclk
  (
    .clk    (clk_16M),
    .rstn   (ck_rst),
    .clk_out(CLK32768KHZ)
  );

  //====================================================================
  // 【第2部分】复位逻辑
  // 与原 system.v 相同
  // 按键低有效：两个按键都不按时 ck_rst=1（正常运行）
  //====================================================================

  assign ck_rst = fpga_rst & mcu_rst;  // 两个按键都不按=1；任一按下=0（复位）

  // 芯片复位：等 MMCM 锁定后，再延迟 256 个时钟周期才释放
  // （避免时钟不稳定时芯片乱跑）
  reg [7:0] chip_rst_cnt   = 8'h00;
  reg       chip_rst_n_reg = 1'b0;

  always @(posedge clk_16M or negedge ck_rst) begin
    if (!ck_rst) begin
      // 按下任意复位键 → 立即拉低芯片复位
      chip_rst_cnt   <= 8'h00;
      chip_rst_n_reg <= 1'b0;
    end else if (!mmcm_locked) begin
      // MMCM 还没锁定 → 保持芯片复位
      chip_rst_cnt   <= 8'h00;
      chip_rst_n_reg <= 1'b0;
    end else if (!chip_rst_n_reg) begin
      // MMCM 已锁定，计数256个周期后释放复位
      chip_rst_cnt <= chip_rst_cnt + 1'b1;
      if (&chip_rst_cnt)          // 计到 0xFF 时
        chip_rst_n_reg <= 1'b1;   // 释放复位 → 芯片开始工作
    end
  end

  //====================================================================
  // 【第3部分】输出时钟给芯片
  // ★ 与原 system.v 最大的不同：原来的信号连接到内部RTL实例，
  //   现在直接输出到 FMC1 引脚，由测试板传到真实芯片
  //
  // 使用 ODDRE1 原语输出时钟（Kintex UltraScale+ 无 7 系列的 ODDR）：
  //   - ODDRE1 经 IOB 把时钟送到引脚，利于时钟专用路由、减少“逻辑驱动时钟脚”类告警
  //   - 若直接 assign chip_hfclk = clk_16M，工具常对时钟走线报警，故仍推荐原语输出
  //====================================================================

  // 输出 16MHz → 芯片 clk_ic（FMC1_LA00_CC_P, E23）
  ODDRE1 #(
    .SIM_DEVICE ("ULTRASCALE_PLUS"),
    .SRVAL      (1'b0)
  ) u_oddre1_clk_ic (
    .Q  (chip_clk_ic),   // 输出到 E23 → FMC1_LA00_CC_P → 测试板 → 芯片
    .C  (clk_16M),
    .D1 (1'b1),
    .D2 (1'b0),
    .SR (1'b0)          // 高有效同步复位；常开输出时钟时接 0
  );

  // 输出 16MHz → 芯片 clk_core（FMC1_LA01_CC_P, F23）
  ODDRE1 #(
    .SIM_DEVICE ("ULTRASCALE_PLUS"),
    .SRVAL      (1'b0)
  ) u_oddre1_clk_core (
    .Q  (chip_clk_core),   // 输出到 F23 → FMC1_LA01_CC_P → 测试板 → 芯片
    .C  (clk_16M),
    .D1 (1'b1),
    .D2 (1'b0),
    .SR (1'b0)
  );

  //====================================================================
  // 【第4部分】控制信号输出给芯片
  //====================================================================

  // 复位信号输出
  // assign chip_rst_n_io   = rst_n_reg;
  // assign chip_rst_n_core = rst_n_reg;
  assign chip_rst_n_io   = chip_rst_n_reg;
  assign chip_rst_n_core = chip_rst_n_reg;

  //====================================================================
  // 【第5部分】控制信号连接
  //====================================================================
  assign chip_en    = fsm_en;
  assign chip_wr_en = fsm_wr_en;
  assign chip_add   = fsm_addr;

  //====================================================================
  // 【第6部分】测试控制器 FSM（流程对齐 mac_test_tb2.c）
  //   set_sram(0) → config_tiles_and_noc → 写权重 →
  //   每轮: set_sram(1) → FSM Normal/Special/Global → drive_feature →
  //         RUN_PROCESS → 等 mac_done → INTR_FRESH → cin/分辨率推进
  //====================================================================

  // mac_test_tb2.c 参数
  localparam integer K_PARAM            = 3;
  localparam integer COUT_PARAM         = 256;
  localparam integer GROUP_SIZE_PARAM   = 2;
  localparam integer GROUP_NUM_PARAM    = 8;
  localparam integer STRIDE_PARAM       = 2;
  localparam integer CIN_IDX_TOTAL      = 8;
  localparam integer RES_COL_TOTAL      = 1;
  localparam integer RES_ROW_TOTAL      = 4;
  localparam integer TILE_SIZE_PARAM    = 16;
  localparam integer ROW_SIZE_PARAM     = 32;

  // mac_test_tb2.c 位宽常量（FSM Special 拼接）
  localparam integer TRUNC_BITS_WIDTH   = 4;
  localparam integer WORK_MODE_WIDTH    = 3;
  localparam integer RES_COL_IDX_WIDTH  = 5;
  localparam integer CIN_IDX_WIDTH      = 6;
  localparam integer PINGPONG_EN_FLAG   = 0;  // main 中 pingpongEnFlag=0

  // 字节地址 = 配置 ID × 8
  localparam [15:0] ADDR_TILE_BASE      = 16'h0000;
  localparam [15:0] ADDR_NOC_BASE       = 16'h0080; // (0x10 + nocId) * 8
  localparam [15:0] ADDR_FSM_NORMAL     = 16'h00F8;
  localparam [15:0] ADDR_FSM_SPECIAL    = 16'h0100;
  localparam [15:0] ADDR_GLOBAL_CONF    = 16'h0210;
  localparam [15:0] ADDR_RUN_PROCESS    = 16'h0218;
  localparam [15:0] ADDR_INTR_FRESH     = 16'h0220;
  localparam [15:0] ADDR_SRAM_CTRL      = 16'h0300; // 测试板 CTRL 映射，可按板卡修改
  localparam [15:0] ADDR_WEIGHT_BASE    = 16'h4000; // 避开配置寄存器区
  localparam [15:0] ADDR_FEAT_TILE_BASE = 16'h1000; // S3 低 16 位（特征 ping）
  localparam [15:0] ADDR_OUT_S3_PING    = 16'h1000; // print_output_results ping
  localparam [15:0] ADDR_OUT_S4_PONG    = 16'h2000; // print_output_results pong

  localparam [63:0] SRAM_CTRL_EXT_ALL  = 64'h0;           // set_sram(0,0,0,0)
  localparam [63:0] SRAM_CTRL_MAC_ALL   = 64'h0000_0000_0000_000F; // set_sram(1,1,1,1)
  localparam [63:0] SRAM_CTRL_READ_OUT = 64'h0000_0000_0000_0003; // set_sram(1,1,0,0)

  localparam [15:0] READ_SRAM_WAIT_MAX  = 16'h0400; // 对齐 C long_delay 量级

  localparam [23:0] WAIT_MAC_MAX = 24'hFFFFFF;
  localparam [3:0]  BUS_GAP_MAX  = 4'd4;

  localparam S_RESET         = 8'd0;
  localparam S_INIT_WAIT     = 8'd1;
  localparam S_CFG_SRAM_EXT  = 8'd2;
  localparam S_CFG_TILES     = 8'd3;
  localparam S_CFG_NOC       = 8'd4;
  localparam S_WRITE_WEIGHTS = 8'd5;
  localparam S_PREP_RUN      = 8'd6;
  localparam S_CFG_FSM       = 8'd7;  // FSM Normal
  localparam S_CFG_FSM_SPEC  = 8'd8;
  localparam S_CFG_GLOBAL    = 8'd9;
  localparam S_FEAT_PUSH     = 8'd10;
  localparam S_START_MAC     = 8'd11;
  localparam S_WAIT_DONE     = 8'd12;
  localparam S_CLR_INTR      = 8'd13;
  localparam S_ADVANCE_RUN   = 8'd14;
  localparam S_READ_RESULTS  = 8'd15;
  localparam S_DONE          = 8'd16;
  localparam S_BUS_HOLD      = 8'd17;
  localparam S_MAC_TIMEOUT   = 8'd18;  // MAC 超时停住，便于 ILA 判别
  localparam S_SET_SRAM_RD   = 8'd19;  // 读结果前 set_sram(1,1,0,0)
  localparam S_READ_WAIT     = 8'd20;  // 切换 SRAM 后等待

  reg [7:0]  fsm_state     = S_RESET;
  reg [7:0]  fsm_next_after_hold;
  reg [15:0] fsm_wait_cnt  = 16'h0;
  reg [23:0] mac_wait_cnt  = 24'h0;
  reg [3:0]  bus_gap_cnt   = 4'h0;
  reg [4:0]  fsm_tile_idx  = 5'd0;
  reg [4:0]  cfg_noc_idx   = 5'd0;

  reg [15:0] data_addr = 16'h0;
  reg [15:0] read_wait_cnt = 16'h0;
  reg        mac_seen_done = 1'b0;
  (* mark_debug = "true" *) reg [10:0] weight_idx  = 11'd0;
  (* mark_debug = "true" *) reg [14:0] feature_idx = 15'd0;
  reg [7:0]  result_idx = 8'd0;

  reg [2:0]  cin_idx     = 3'd0;
  reg [1:0]  res_row_idx = 2'd0;
  reg        res_col_idx = 1'b0;

  reg [4:0]  feat_tile  = 5'd0;
  reg [5:0]  feat_row   = 6'd0;
  reg [1:0]  feat_word  = 2'd0;

  reg        feat_pp_flag = 1'b0;
  reg        wt_pp_flag   = 1'b0;
  reg        out_pp_flag  = 1'b0;

  localparam WEIGHT_MEM_FILE  = "weight_data.mem";
  localparam FEATURE_MEM_FILE = "feature_data.mem";

  (* ram_style = "block" *) reg [63:0] weight_data  [0:1151];
  (* ram_style = "block" *) reg [63:0] feature_data [0:32767];
  reg [63:0] result_data [0:15];

  reg [10:0] weight_raddr;
  reg [63:0] weight_rdata;
  reg [14:0] feature_raddr;
  reg [63:0] feature_rdata;
  reg        rom_wr_setup;

  // Tile / NoC 配置组合逻辑（config_tiles_and_noc）
  wire [7:0] tile_fml  = fsm_tile_idx / GROUP_SIZE_PARAM;
  wire [7:0] tile_wid  = GROUP_SIZE_PARAM - 1 - (fsm_tile_idx % GROUP_SIZE_PARAM);
  wire [31:0] tile_cfg = (tile_fml << 16) | (3'b0 << 13) | (tile_wid << 5) | ((K_PARAM - 1) & 5'h1F);

  wire [4:0] noc_upper = cfg_noc_idx / GROUP_SIZE_PARAM;
  wire [4:0] noc_lower = (cfg_noc_idx + 1) / GROUP_SIZE_PARAM;
  wire       noc_systolic = (noc_upper != noc_lower);
  wire       noc_add      = (noc_upper == noc_lower);
  wire [31:0] noc_cfg = {28'h0, 1'b1, noc_systolic, noc_add, 1'b0};

  wire [31:0] fsm_normal_cfg = {
    (STRIDE_PARAM - 1)     & 5'h1F,
    (COUT_PARAM - 1)       & 5'h1F,
    (GROUP_NUM_PARAM - 1)  & 4'hF,
    (GROUP_SIZE_PARAM - 1) & 4'hF,
    (K_PARAM - 1)          & 5'h1F
  };

  wire [4:0] plane_work_mode =
      (res_row_idx == 2'd0) ?
          ((res_col_idx == 1'b0) ? 5'd0 : 5'd4) :
          ((res_col_idx == 1'b0) ? 5'd1 : 5'd2);
  wire [4:0] pwm_for_cin = (cin_idx == 3'd0) ? plane_work_mode : 5'd3;

  // 对齐 run_process() 中 specialConfig（truncateEn/truncBits 在 main 中为 0）
  wire [2:0] pwm_w = pwm_for_cin[2:0];
  wire [4:0] rci_w = {{(RES_COL_IDX_WIDTH - 1){1'b0}}, res_col_idx};
  wire [5:0] cix_w = {{(CIN_IDX_WIDTH - 3){1'b0}}, cin_idx};

  wire [31:0] fsm_special_cfg =
      (1'b0 << (TRUNC_BITS_WIDTH + WORK_MODE_WIDTH + RES_COL_IDX_WIDTH + CIN_IDX_WIDTH)) |
      (4'd0  << (WORK_MODE_WIDTH + RES_COL_IDX_WIDTH + CIN_IDX_WIDTH)) |
      (pwm_w << (RES_COL_IDX_WIDTH + CIN_IDX_WIDTH)) |
      (rci_w << CIN_IDX_WIDTH) |
      cix_w;

  wire       is_final_cin = (cin_idx == CIN_IDX_TOTAL - 1);
  // actionMode: dataFlow=0, isFinalCin@bit1, bn/act/pool=0
  wire [4:0] action_mode = {1'b0, 1'b0, 1'b0, is_final_cin, 1'b0};
  wire [31:0] global_cfg = {
    feat_pp_flag, wt_pp_flag, out_pp_flag,
    24'b0, action_mode
  };

  wire [31:0] feat_start_row_cin =
      (cin_idx * (ROW_SIZE_PARAM * GROUP_SIZE_PARAM) +
       ((GROUP_SIZE_PARAM - 1 - (feat_tile % GROUP_SIZE_PARAM)) * ROW_SIZE_PARAM)) *
      (GROUP_NUM_PARAM * RES_ROW_TOTAL);
  wire [31:0] feat_start_row_h =
      (res_row_idx * GROUP_NUM_PARAM) + (feat_tile / GROUP_SIZE_PARAM);
  wire [31:0] feat_start_row = feat_start_row_cin + feat_start_row_h;
  wire [31:0] feat_byte_off =
      ((feat_start_row + feat_row * GROUP_NUM_PARAM * RES_ROW_TOTAL) * 8) +
      (res_col_idx ? 32'd32 : 32'd0) +
      (feat_word * 8);
  wire [14:0] feat_mem_idx_w = feat_byte_off[20:3];
  wire [15:0] feat_chip_addr =
      ADDR_FEAT_TILE_BASE + (feat_tile[3:0] << 10) + (feat_row[4:0] << 5) + (feat_word << 3);

  wire [15:0] result_read_base = out_pp_flag ? ADDR_OUT_S4_PONG : ADDR_OUT_S3_PING;
  wire [15:0] result_read_addr = result_read_base + {5'h0, result_idx[7:0], 3'b000};

  assign dbg_fsm_state = fsm_state;

  always @(posedge clk_16M) begin
    weight_rdata  <= weight_data[weight_raddr];
    feature_rdata <= feature_data[feature_raddr];
  end

  initial begin
    $readmemh(WEIGHT_MEM_FILE,  weight_data);
    $readmemh(FEATURE_MEM_FILE, feature_data);
  end

  always @(posedge clk_16M or negedge ck_rst) begin
    if (!ck_rst) begin
      fsm_state          <= S_RESET;
      fsm_en             <= 1'b0;
      fsm_wr_en          <= 1'b0;
      fsm_addr           <= 16'h0;
      fsm_data_out       <= 64'h0;
      fsm_wait_cnt       <= 16'h0;
      mac_wait_cnt       <= 24'h0;
      bus_gap_cnt        <= 4'h0;
      fsm_tile_idx       <= 5'd0;
      cfg_noc_idx        <= 5'd0;
      test_active        <= 1'b0;
      mac_done_latch     <= 1'b0;
      data_addr          <= 16'h0;
      weight_idx         <= 11'd0;
      feature_idx        <= 15'd0;
      result_idx         <= 8'd0;
      weight_raddr       <= 11'd0;
      feature_raddr      <= 15'd0;
      rom_wr_setup       <= 1'b0;
      cin_idx            <= 3'd0;
      res_row_idx        <= 2'd0;
      res_col_idx        <= 1'b0;
      feat_tile          <= 5'd0;
      feat_row           <= 6'd0;
      feat_word          <= 2'd0;
      feat_pp_flag       <= 1'b0;
      wt_pp_flag         <= 1'b0;
      out_pp_flag        <= 1'b0;
      read_wait_cnt      <= 16'h0;
      mac_seen_done      <= 1'b0;
    end else begin
      fsm_en    <= 1'b0;
      fsm_wr_en <= 1'b0;

      case (fsm_state)
        S_RESET: begin
          fsm_wait_cnt <= fsm_wait_cnt + 1;
          if (fsm_wait_cnt == 16'hFFFF) begin
            fsm_wait_cnt <= 16'h0;
            fsm_state    <= S_INIT_WAIT;
          end
        end

        S_INIT_WAIT: begin
          fsm_wait_cnt <= 16'h0;
          fsm_tile_idx <= 5'd0;
          cfg_noc_idx  <= 5'd0;
          fsm_state    <= S_CFG_SRAM_EXT;
        end

        // set_sram_control(0,0,0,0)
        S_CFG_SRAM_EXT: begin
          if (!chip_input_full) begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= ADDR_SRAM_CTRL;
            fsm_data_out <= SRAM_CTRL_EXT_ALL;
            fsm_next_after_hold <= S_CFG_TILES;
            fsm_state    <= S_BUS_HOLD;
          end
        end

        // config_tiles_and_noc — Tile 部分
        S_CFG_TILES: begin
          if (!chip_input_full) begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= ADDR_TILE_BASE + {10'h0, fsm_tile_idx, 3'b000};
            fsm_data_out <= {32'h0, tile_cfg};
            if (fsm_tile_idx == 5'd15) begin
              fsm_tile_idx <= 5'd0;
              fsm_next_after_hold <= S_CFG_NOC;
            end else begin
              fsm_tile_idx <= fsm_tile_idx + 1'b1;
              fsm_next_after_hold <= S_CFG_TILES;
            end
            fsm_state <= S_BUS_HOLD;
          end
        end

        // config_tiles_and_noc — NoC 部分（15 项）
        S_CFG_NOC: begin
          if (!chip_input_full) begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= ADDR_NOC_BASE + {10'h0, cfg_noc_idx, 3'b000};
            fsm_data_out <= {32'h0, noc_cfg};
            if (cfg_noc_idx == 5'd14) begin
              cfg_noc_idx  <= 5'd0;
              weight_idx   <= 11'd0;
              rom_wr_setup <= 1'b0;
              fsm_next_after_hold <= S_WRITE_WEIGHTS;
            end else begin
              cfg_noc_idx <= cfg_noc_idx + 1'b1;
              fsm_next_after_hold <= S_CFG_NOC;
            end
            fsm_state <= S_BUS_HOLD;
          end
        end

        // drive_weights_from_files（1152×64b）
        S_WRITE_WEIGHTS: begin
          if (chip_input_full) begin
            fsm_en <= 1'b0;
          end else if (!rom_wr_setup) begin
            weight_raddr <= weight_idx;
            rom_wr_setup <= 1'b1;
          end else begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= ADDR_WEIGHT_BASE + {5'h0, weight_idx, 3'b000};
            fsm_data_out <= weight_rdata;
            weight_idx   <= weight_idx + 1'b1;
            rom_wr_setup <= 1'b0;
            if (weight_idx == 11'd1151) begin
              cin_idx      <= 3'd0;
              res_row_idx  <= 2'd0;
              res_col_idx  <= 1'b0;
              feat_tile    <= 5'd0;
              feat_row     <= 6'd0;
              feat_word    <= 2'd0;
              mac_seen_done <= 1'b0;
              fsm_next_after_hold <= S_PREP_RUN;
            end else begin
              fsm_next_after_hold <= S_WRITE_WEIGHTS;
            end
            fsm_state <= S_BUS_HOLD;
          end
        end

        // set_sram_control(1,1,1,1) — 每轮 run_process 前
        S_PREP_RUN: begin
          if (!chip_input_full) begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= ADDR_SRAM_CTRL;
            fsm_data_out <= SRAM_CTRL_MAC_ALL;
            fsm_next_after_hold <= S_CFG_FSM;
            fsm_state    <= S_BUS_HOLD;
          end
        end

        // FSM Normal
        S_CFG_FSM: begin
          if (!chip_input_full) begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= ADDR_FSM_NORMAL;
            fsm_data_out <= {32'h0, fsm_normal_cfg};
            fsm_next_after_hold <= S_CFG_FSM_SPEC;
            fsm_state    <= S_BUS_HOLD;
          end
        end

        // FSM Special
        S_CFG_FSM_SPEC: begin
          if (!chip_input_full) begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= ADDR_FSM_SPECIAL;
            fsm_data_out <= {32'h0, fsm_special_cfg};
            feat_tile    <= 5'd0;
            feat_row     <= 6'd0;
            feat_word    <= 2'd0;
            rom_wr_setup <= 1'b0;
            fsm_next_after_hold <= S_FEAT_PUSH;
            fsm_state    <= S_BUS_HOLD;
          end
        end

        // drive_feature_from_files — 先推特征，再写 Global
        S_FEAT_PUSH: begin
          if (chip_input_full) begin
            fsm_en <= 1'b0;
          end else if (!rom_wr_setup) begin
            feature_raddr <= feat_mem_idx_w;
            feature_idx   <= feat_mem_idx_w;
            rom_wr_setup  <= 1'b1;
          end else begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= feat_chip_addr;
            fsm_data_out <= feature_rdata;
            rom_wr_setup <= 1'b0;
            if (feat_word == 2'd3) begin
              feat_word <= 2'd0;
              if (feat_row == 6'd31) begin
                feat_row <= 6'd0;
                if (feat_tile == 5'd15) begin
                  feat_tile <= 5'd0;
                  // C: featurePingpongFlag = !flag 在写 Global 之前（pingpongEnFlag=0 时不翻 wt/out）
                  feat_pp_flag <= ~feat_pp_flag;
                  if (PINGPONG_EN_FLAG) begin
                    wt_pp_flag  <= ~wt_pp_flag;
                    out_pp_flag <= ~out_pp_flag;
                  end
                  fsm_next_after_hold <= S_CFG_GLOBAL;
                end else begin
                  feat_tile <= feat_tile + 1'b1;
                  fsm_next_after_hold <= S_FEAT_PUSH;
                end
              end else begin
                feat_row <= feat_row + 1'b1;
                fsm_next_after_hold <= S_FEAT_PUSH;
              end
            end else begin
              feat_word <= feat_word + 1'b1;
              fsm_next_after_hold <= S_FEAT_PUSH;
            end
            fsm_state <= S_BUS_HOLD;
          end
        end

        // Global + pingpong
        S_CFG_GLOBAL: begin
          if (!chip_input_full) begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= ADDR_GLOBAL_CONF;
            fsm_data_out <= {32'h0, global_cfg};
            fsm_next_after_hold <= S_START_MAC;
            fsm_state    <= S_BUS_HOLD;
          end
        end

        S_START_MAC: begin
          if (!chip_input_full) begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= ADDR_RUN_PROCESS;
            fsm_data_out <= 64'h0000_0000_0000_0001;
            test_active  <= 1'b1;
            mac_wait_cnt <= 24'h0;
            fsm_next_after_hold <= S_WAIT_DONE;
            fsm_state    <= S_BUS_HOLD;
          end
        end

        S_WAIT_DONE: begin
          if (chip_mac_done) begin
            test_active    <= 1'b0;
            mac_done_latch <= 1'b1;
            mac_seen_done  <= 1'b1;
            mac_wait_cnt   <= 24'h0;
            fsm_next_after_hold <= S_CLR_INTR;
            fsm_state      <= S_CLR_INTR;
          end else if (chip_mac_err) begin
            test_active  <= 1'b0;
            mac_wait_cnt <= 24'h0;
            fsm_next_after_hold <= S_CLR_INTR;
            fsm_state    <= S_CLR_INTR;
          end else begin
            mac_wait_cnt <= mac_wait_cnt + 1'b1;
            if (mac_wait_cnt == WAIT_MAC_MAX) begin
              test_active  <= 1'b0;
              mac_wait_cnt <= 24'h0;
              fsm_state    <= S_MAC_TIMEOUT;
            end
          end
        end

        // MAC 超时：停在此状态（ILA 可见 0x12），避免无 done 时误入读结果
        S_MAC_TIMEOUT: begin
          fsm_en    <= 1'b0;
          fsm_wr_en <= 1'b0;
        end

        S_CLR_INTR: begin
          if (!chip_input_full) begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= ADDR_INTR_FRESH;
            fsm_data_out <= 64'h0000_0000_0000_0001;
            fsm_next_after_hold <= S_ADVANCE_RUN;
            fsm_state    <= S_BUS_HOLD;
          end
        end

        // 推进 cinIdx / 分辨率（对齐 C main 循环）
        S_ADVANCE_RUN: begin
          if (cin_idx != CIN_IDX_TOTAL - 1) begin
            cin_idx   <= cin_idx + 1'b1;
            feat_tile <= 5'd0;
            feat_row  <= 6'd0;
            feat_word <= 2'd0;
            fsm_state <= S_PREP_RUN;
          end else begin
            cin_idx     <= 3'd0;
            result_idx  <= 8'd0;
            read_wait_cnt <= 16'h0;
            if (mac_seen_done)
              fsm_state <= S_SET_SRAM_RD;
            else
              fsm_state <= S_MAC_TIMEOUT;
          end
        end

        // print_output_results: set_sram(1,1,0,0)
        S_SET_SRAM_RD: begin
          if (!chip_input_full) begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= ADDR_SRAM_CTRL;
            fsm_data_out <= SRAM_CTRL_READ_OUT;
            read_wait_cnt <= 16'h0;
            fsm_next_after_hold <= S_READ_WAIT;
            fsm_state    <= S_BUS_HOLD;
          end
        end

        S_READ_WAIT: begin
          read_wait_cnt <= read_wait_cnt + 1'b1;
          if (read_wait_cnt == READ_SRAM_WAIT_MAX)
            fsm_state <= S_READ_RESULTS;
        end

        S_READ_RESULTS: begin
          if (chip_output_empty) begin
            fsm_en <= 1'b0;
          end else begin
            fsm_en    <= 1'b1;
            fsm_wr_en <= 1'b0;
            fsm_addr  <= result_read_addr;
            result_data[result_idx] <= data_in_from_chip;
            if (result_idx == 8'd15) begin
              if (res_col_idx == RES_COL_TOTAL - 1) begin
                if (res_row_idx == RES_ROW_TOTAL - 1) begin
                  fsm_state <= S_DONE;
                end else begin
                  res_row_idx <= res_row_idx + 1'b1;
                  res_col_idx <= 1'b0;
                  feat_tile   <= 5'd0;
                  feat_row    <= 6'd0;
                  feat_word   <= 2'd0;
                  fsm_state   <= S_PREP_RUN;
                end
              end else begin
                res_col_idx <= res_col_idx + 1'b1;
                feat_tile   <= 5'd0;
                feat_row    <= 6'd0;
                feat_word   <= 2'd0;
                fsm_state   <= S_PREP_RUN;
              end
            end else begin
              result_idx  <= result_idx + 1'b1;
              fsm_next_after_hold <= S_READ_RESULTS;
              fsm_state   <= S_BUS_HOLD;
            end
          end
        end

        S_DONE: begin
          fsm_wait_cnt <= fsm_wait_cnt + 1;
          if (fsm_wait_cnt == 16'h0FFF) begin
            fsm_wait_cnt <= 16'h0;
            cin_idx      <= 3'd0;
            res_row_idx  <= 2'd0;
            res_col_idx  <= 1'b0;
            feat_tile    <= 5'd0;
            feat_row     <= 6'd0;
            feat_word    <= 2'd0;
            fsm_state    <= S_PREP_RUN;
          end
        end

        S_BUS_HOLD: begin
          if (bus_gap_cnt == BUS_GAP_MAX) begin
            bus_gap_cnt <= 4'h0;
            fsm_state   <= fsm_next_after_hold;
          end else begin
            bus_gap_cnt <= bus_gap_cnt + 1'b1;
          end
        end

        default: fsm_state <= S_RESET;
      endcase
    end
  end

  //====================================================================
  // 【第7部分】LED 状态指示
  //====================================================================
  assign led_mmcm_ok  = mmcm_locked;
  assign led_chip_ok  = chip_rst_n_reg;
  assign led_mac_done = mac_done_latch;  // 完成一次后常亮
  assign led_chip_output_empty = chip_output_empty;

  //====================================================================
  // 【第8部分】UART（保留接口，当前未使用，后续可加调试输出）
  //====================================================================
  assign uart_tx = 1'b1;  // 空闲（UART_IDLE=高电平）

  //====================================================================
  // 【第9部分】64位双向数据总线（IOBUF）
  // wr_en=1 → FPGA写数据到芯片（输出方向）
  // wr_en=0 → 芯片输出数据到FPGA（输入方向）
  //====================================================================
  assign data_out_to_chip = fsm_data_out;

  genvar i;
  generate
    for (i = 0; i < 64; i = i + 1) begin : gen_iobuf
      IOBUF u_iobuf_din (
        .IO(chip_din[i]),            // 连接到芯片 din[63:0] 引脚
        .O (data_in_from_chip[i]),   // 读入方向：芯片→FPGA
        .I (data_out_to_chip[i]),    // 写出方向：FPGA→芯片
        .T (~chip_wr_en)             // T=1:输入(高阻), T=0:输出
                                     // wr_en=1(写)→T=0(输出); wr_en=0(读)→T=1(高阻)
      );
    end
  endgenerate

endmodule