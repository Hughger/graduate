`timescale 1ns/1ps
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
  output wire       chip_en,          // → FMC1_LA03_P (A23) → 芯片 en        (引脚63)
  output wire       chip_wr_en,       // → FMC1_LA03_N (A24) → 芯片 wr_en     (引脚62)

  // ● 状态/中断输入（芯片输出，FPGA读入）
  input  wire       chip_input_full,  // ← FMC1_LA04_P (G22) ← 芯片 input_full  (引脚48)
  input  wire       chip_output_empty,// ← FMC1_LA04_N (F22) ← 芯片 output_empty(引脚49)
  input  wire       chip_mac_done,    // ← FMC1_LA05_P (K20) ← 芯片 macDone_interrupt (引脚56)
  input  wire       chip_mac_err,     // ← FMC1_LA05_N (K21) ← 芯片 macErr_interrput  (引脚57)

  // ● 地址总线（FPGA输出，16位）
  output wire [15:0] chip_add,        // → FMC1_LA06~LA13 → 芯片 add[15:0]（引脚64~87）

  // ● 64位双向数据总线（IOBUF，方向由chip_wr_en控制）
  //   chip_wr_en=1: FPGA → 芯片（写操作）
  //   chip_wr_en=0: 芯片 → FPGA（读操作）
  inout  wire [63:0] chip_din          // ↔ FMC1_LA14~LA33 + FMC1_HA00~HA11 → 芯片 din[63:0]
);

  //====================================================================
  // 内部信号声明
  //====================================================================
  wire sys_clk;
  wire clk_16M;
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
  assign dbg_chip_rst_ok  = rst_n_reg;
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
  // 【第1部分】时钟生成（200MHz→16MHz）
  //====================================================================
  IBUFGDS u_ibufg_sys_clk (
    .I(sys_clk_p), .IB(sys_clk_n), .O(sys_clk)
  );

  // MMCM：200MHz→16MHz（两路时钟，分别给芯片 clk_ic 和 clk_core）
  // 注：实际上用同一个16MHz，两路时钟相同，可根据需要改为不同频率
  mmcm ip_mmcm (
    .resetn  (ck_rst),
    .clk_in1 (sys_clk),
    .clk_out1(clk_16M),
    .locked  (mmcm_locked)
  );

  assign ck_rst = fpga_rst & mcu_rst;

  //====================================================================
  // 【第2部分】时钟输出给芯片（ODDR原语，减少时钟抖动）
  //====================================================================
  ODDR #(.DDR_CLK_EDGE("SAME_EDGE"), .INIT(1'b0), .SRTYPE("SYNC"))
  u_oddr_clk_ic (
    .Q(chip_clk_ic), .C(clk_16M), .CE(1'b1),
    .D1(1'b1), .D2(1'b0), .R(1'b0), .S(1'b0)
  );

  ODDR #(.DDR_CLK_EDGE("SAME_EDGE"), .INIT(1'b0), .SRTYPE("SYNC"))
  u_oddr_clk_core (
    .Q(chip_clk_core), .C(clk_16M), .CE(1'b1),
    .D1(1'b1), .D2(1'b0), .R(1'b0), .S(1'b0)
  );

  //====================================================================
  // 【第3部分】复位控制
  // MMCM锁定后延迟256周期再释放芯片复位
  // 两路复位（rst_n_io, rst_n_core）同步释放
  //====================================================================
  always @(posedge clk_16M or negedge ck_rst) begin
    if (!ck_rst) begin
      rst_cnt   <= 8'h00;
      rst_n_reg <= 1'b0;
    end else if (!mmcm_locked) begin
      rst_cnt   <= 8'h00;
      rst_n_reg <= 1'b0;
    end else if (!rst_n_reg) begin
      rst_cnt <= rst_cnt + 1'b1;
      if (&rst_cnt) rst_n_reg <= 1'b1;
    end
  end

  assign chip_rst_n_io   = rst_n_reg;
  assign chip_rst_n_core = rst_n_reg;

  //====================================================================
  // 【第4部分】64位双向数据总线（IOBUF）
  // wr_en=1 → FPGA写数据到芯片（输出方向）
  // wr_en=0 → 芯片输出数据到FPGA（输入方向）
  //====================================================================
  assign data_out_to_chip = fsm_data_out;

  IOBUF u_iobuf_din[63:0] (
    .IO(chip_din),            // 连接到芯片 din[63:0] 引脚
    .O (data_in_from_chip),   // 读入方向：芯片→FPGA
    .I (data_out_to_chip),    // 写出方向：FPGA→芯片
    .T (~chip_wr_en)          // T=1:输入(高阻), T=0:输出
                              // wr_en=1(写)→T=0(输出); wr_en=0(读)→T=1(高阻)
  );

  //====================================================================
  // 【第5部分】控制信号连接
  //====================================================================
  assign chip_en    = fsm_en;
  assign chip_wr_en = fsm_wr_en;
  assign chip_add   = fsm_addr;

  //====================================================================
  // 【第6部分】测试控制器 FSM
  //
  // 状态机实现一个完整的MAC计算测试序列：
  //   RESET → CONFIG → WRITE_WEIGHTS → WRITE_FEATURES →
  //   START → WAIT_DONE → READ_RESULT → IDLE → (循环)
  //
  // 配置寄存器地址规则（来自 mac_test_tb2.c）：
  //   实际字节地址 = 配置ID × 8
  //   例：RUN_PROCESS_ID=0x43 → 字节地址=0x43×8=0x218 → add=0x0218
  //====================================================================

  // FSM 地址常量（字节地址 = ID × 8）
  // 这些对应 Mac_ASIC_top.v 内部的寄存器映射
  localparam ADDR_GLOBAL_CONF  = 16'h0210; // 0x42 × 8 = GLOBAL_CONF
  localparam ADDR_RUN_PROCESS  = 16'h0218; // 0x43 × 8 = RUN_PROCESS（触发计算）
  localparam ADDR_INTR_FRESH   = 16'h0220; // 0x44 × 8 = 清除中断标志
  localparam ADDR_TILE_CONF0   = 16'h0000; // 0x00 × 8 = Tile0配置
  localparam ADDR_FSM_NORMAL   = 16'h00F8; // 0x1F × 8 = FSM Normal配置
  localparam ADDR_FSM_SPECIAL  = 16'h0100; // 0x20 × 8 = FSM Special配置

  // FSM 状态定义
  localparam S_RESET       = 8'd0;   // 等待复位释放
  localparam S_INIT_WAIT   = 8'd1;   // 复位后等待稳定
  localparam S_CFG_TILES   = 8'd2;   // 配置Tile寄存器
  localparam S_CFG_FSM     = 8'd3;   // 配置FSM参数
  localparam S_CFG_GLOBAL  = 8'd4;   // 配置全局参数
  localparam S_START_MAC   = 8'd5;   // 写RUN_PROCESS触发计算
  localparam S_WAIT_DONE   = 8'd6;   // 等待macDone_interrupt
  localparam S_CLR_INTR    = 8'd7;   // 清除中断
  localparam S_DONE        = 8'd8;   // 完成，循环等待
  localparam S_BUS_IDLE    = 8'd9;   // 总线空闲（写操作完成后的间隔周期）

  reg [7:0]  fsm_state     = S_RESET;
  reg [7:0]  fsm_next_state;          // 写操作完成后跳转到的下一状态
  reg [15:0] fsm_wait_cnt  = 16'h0;   // 等待计数器
  reg [4:0]  fsm_tile_idx  = 5'd0;    // 当前配置的Tile序号(0~15)
  reg        test_done_latch = 1'b0;

  assign dbg_fsm_state = fsm_state;

  // 写总线操作：发起一次单周期写
  // 写操作时序：en=1, wr_en=1，维持1个时钟周期，然后en=0
  task do_write;
    input [15:0] addr;
    input [63:0] data;
    begin
      fsm_en      = 1'b1;
      fsm_wr_en   = 1'b1;
      fsm_addr    = addr;
      fsm_data_out = data;
    end
  endtask

  always @(posedge clk_16M or negedge rst_n_reg) begin
    if (!rst_n_reg) begin
      fsm_state     <= S_RESET;
      fsm_en        <= 1'b0;
      fsm_wr_en     <= 1'b0;
      fsm_addr      <= 16'h0;
      fsm_data_out  <= 64'h0;
      fsm_wait_cnt  <= 16'h0;
      fsm_tile_idx  <= 5'd0;
      test_active   <= 1'b0;
      mac_done_latch <= 1'b0;
      test_done_latch <= 1'b0;
    end else begin
      // 默认：总线空闲（每个状态处理后回到空闲）
      fsm_en    <= 1'b0;
      fsm_wr_en <= 1'b0;

      case (fsm_state)
        //--------------------------------------------------------------
        // S_RESET：等待复位完全释放后稳定
        //--------------------------------------------------------------
        S_RESET: begin
          fsm_wait_cnt <= fsm_wait_cnt + 1;
          if (fsm_wait_cnt == 16'hFFFF)
            fsm_state <= S_INIT_WAIT;
        end

        //--------------------------------------------------------------
        // S_INIT_WAIT：额外等待（芯片内部稳定）
        //--------------------------------------------------------------
        S_INIT_WAIT: begin
          fsm_wait_cnt <= 16'h0;
          fsm_tile_idx <= 5'd0;
          fsm_state    <= S_CFG_TILES;
        end

        //--------------------------------------------------------------
        // S_CFG_TILES：配置16个Tile（地址 0x00~0x0F，每个×8）
        // Tile配置值（简化示例）：
        //   [15:8]=featureMapLine=0, [7:4]=workMode=0, [3:0]=inputId=tile序号
        //--------------------------------------------------------------
        S_CFG_TILES: begin
          // 写 Tile[fsm_tile_idx] 配置寄存器
          fsm_en       <= 1'b1;
          fsm_wr_en    <= 1'b1;
          fsm_addr     <= {11'h0, fsm_tile_idx, 3'b000}; // tile_idx × 8
          fsm_data_out <= {60'h0, fsm_tile_idx[3:0]};    // inputId=tile编号

          if (fsm_tile_idx == 5'd15)
            fsm_state <= S_CFG_FSM;
          else
            fsm_tile_idx <= fsm_tile_idx + 1;
        end

        //--------------------------------------------------------------
        // S_CFG_FSM：配置FSM Normal参数
        // Normal[31:0]: k(5b)=3 | groupSize(4b)=2 | groupNum(4b)=8 | cout(5b)=32
        //--------------------------------------------------------------
        S_CFG_FSM: begin
          fsm_en       <= 1'b1;
          fsm_wr_en    <= 1'b1;
          fsm_addr     <= ADDR_FSM_NORMAL;
          // cout=32(0x20), groupNum=8(0x8), groupSize=2(0x2), k=3(0x3)
          fsm_data_out <= {32'h0, 5'd3, 4'd2, 4'd8, 5'd32, 14'h0};
          fsm_state    <= S_CFG_GLOBAL;
        end

        //--------------------------------------------------------------
        // S_CFG_GLOBAL：配置全局参数（选择FLOOD数据流模式）
        // globalConf[7:0]: dataFlowMode=0(FLOOD)
        //--------------------------------------------------------------
        S_CFG_GLOBAL: begin
          fsm_en       <= 1'b1;
          fsm_wr_en    <= 1'b1;
          fsm_addr     <= ADDR_GLOBAL_CONF;
          fsm_data_out <= {64'h0000_0000_0000_0000};  // FLOOD模式，所有标志=0
          fsm_state    <= S_START_MAC;
        end

        //--------------------------------------------------------------
        // S_START_MAC：写 RUN_PROCESS 寄存器触发MAC计算
        // ★ test_active 在这里拉高，用于功耗测量对齐
        //--------------------------------------------------------------
        S_START_MAC: begin
          fsm_en       <= 1'b1;
          fsm_wr_en    <= 1'b1;
          fsm_addr     <= ADDR_RUN_PROCESS;
          fsm_data_out <= 64'h0000_0000_0000_0001;  // 写1触发
          test_active  <= 1'b1;  // ★ MAC开始计算，拉高测试活跃信号
          fsm_state    <= S_WAIT_DONE;
        end

        //--------------------------------------------------------------
        // S_WAIT_DONE：等待 macDone_interrupt 信号（轮询）
        // macDone 拉高说明这一轮计算完成
        //--------------------------------------------------------------
        S_WAIT_DONE: begin
          if (chip_mac_done) begin
            test_active    <= 1'b0;  // ★ MAC计算结束，拉低测试活跃信号
            mac_done_latch <= 1'b1;  // 记录完成一次（LED用）
            fsm_state      <= S_CLR_INTR;
          end else if (chip_mac_err) begin
            // 发生错误，也停止计时
            test_active <= 1'b0;
            fsm_state   <= S_CLR_INTR;
          end
          // 超时保护
          fsm_wait_cnt <= fsm_wait_cnt + 1;
          if (fsm_wait_cnt == 16'hFFFF) begin
            test_active  <= 1'b0;
            fsm_wait_cnt <= 16'h0;
            fsm_state    <= S_CLR_INTR;
          end
        end

        //--------------------------------------------------------------
        // S_CLR_INTR：写 INTR_FRESH 清除中断标志，准备下一轮
        //--------------------------------------------------------------
        S_CLR_INTR: begin
          fsm_en       <= 1'b1;
          fsm_wr_en    <= 1'b1;
          fsm_addr     <= ADDR_INTR_FRESH;
          fsm_data_out <= 64'h0000_0000_0000_0001;
          fsm_wait_cnt <= 16'h0;
          fsm_state    <= S_DONE;
        end

        //--------------------------------------------------------------
        // S_DONE：一轮完成，等待后重新开始（持续循环测试）
        // 等待一段时间再触发下一轮，方便区分每轮功耗波形
        //--------------------------------------------------------------
        S_DONE: begin
          fsm_wait_cnt <= fsm_wait_cnt + 1;
          if (fsm_wait_cnt == 16'h0FFF) begin  // 等待约1ms再重新开始
            fsm_wait_cnt <= 16'h0;
            fsm_tile_idx <= 5'd0;
            test_done_latch <= 1'b1;
            fsm_state    <= S_CFG_TILES;  // 循环：重新配置并运行
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
  assign led_chip_ok  = rst_n_reg;
  assign led_mac_done = mac_done_latch;  // 完成一次后常亮

  //====================================================================
  // 【第8部分】UART（保留接口，当前未使用，后续可加调试输出）
  //====================================================================
  assign uart_tx = 1'b1;  // 空闲（UART_IDLE=高电平）

endmodule
