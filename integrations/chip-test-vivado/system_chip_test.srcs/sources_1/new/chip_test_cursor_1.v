`timescale 1ns / 1ps
//=============================================================================
// chip_test_cursor_1.v
// 由 mac_test_tb2.c 主流程直译为 FPGA 并行总线控制器（无 SoC DMA / PLIC）
//
// C 函数映射：
//   main()                  -> 顶层 FSM 顺序
//   set_sram_control()      -> 写 ADDR_SRAM_CTRL（译码表字地址 0xC000）
//   config_tiles_and_noc()  -> S_CFG_TILES / S_CFG_NOC
//   drive_weights_from_files() -> S_WR_WEIGHT（1152×64b）+ 无 DMA 直写权重区
//   drive_features_to_sram()   -> S_WR_FEAT_SRAM（2048×64b 预灌）
//   run_process()           -> S_RUN_SET_SRAM … S_WAIT_DONE / S_CLR_INTR
//   drive_feature_from_files() -> S_FEAT_PUSH
//   wait_mac_complete()     -> S_WAIT_DONE 轮询 chip_mac_done + S_CLR_INTR
//   print_output_results()  -> S_SET_SRAM_RD / S_READ_OUT（256 通道×32 拍读）
//
// 地址：配置寄存器 byte = reg_id<<3；与 C 的 S2_BASE+id*8 低 16 位一致
// DMA 替换：权重 0x4000；特征 S3 0x1000 区；输出 ping 0x1000 / pong 0x2000
//=============================================================================

module chip_test_cursor_1
(
  input  wire        sys_clk_p,
  input  wire        sys_clk_n,
  input  wire        fpga_rst,
  input  wire        mcu_rst,

  output wire        uart_tx,
  input  wire        uart_rx,

  output wire        led_mmcm_ok,
  output wire        led_chip_ok,
  output wire        led_mac_done,
  output wire        led_chip_output_empty,

  output wire        chip_clk_ic,
  output wire        chip_clk_core,
  output wire        chip_rst_n_io,
  output wire        chip_rst_n_core,
  (* mark_debug = "true" *) output wire        chip_en,
  (* mark_debug = "true" *) output wire        chip_wr_en,

  input  wire        chip_input_full,
  input  wire        chip_output_empty,
  input  wire        chip_mac_done,
  input  wire        chip_mac_err,

  output wire [15:0] chip_add,
  inout  wire [63:0] chip_din
);

  //==========================================================================
  // mac_test_tb2.c 常量
  //==========================================================================
  localparam integer TILE_SIZE           = 16;
  localparam integer ROW_SIZE            = 32;
  localparam integer K_PARAM             = 3;
  localparam integer COUT_PARAM          = 256;
  localparam integer GROUP_SIZE_PARAM   = 2;
  localparam integer GROUP_NUM_PARAM    = 8;
  localparam integer STRIDE_PARAM        = 2;
  localparam integer CIN_IDX_TOTAL       = 8;
  localparam integer RES_COL_TOTAL       = 1;
  localparam integer RES_ROW_TOTAL       = 4;

  localparam integer TRUNC_BITS_WIDTH    = 4;
  localparam integer WORK_MODE_WIDTH     = 3;
  localparam integer RES_COL_IDX_WIDTH   = 5;
  localparam integer CIN_IDX_WIDTH       = 6;
  localparam integer PINGPONG_EN_FLAG    = 0;

  localparam integer WEIGHT_WORDS        = 1152;   // 144×8，与 .mem 一致
  localparam integer FEAT_SRAM_WORDS     = 2048;  // drive_features_to_sram
  localparam integer OUT_BEATS_PER_CH    = 32;    // groupNum*32/8

  //--------------------------------------------------------------------------
  // FMC chip_add 约定（见 FMC_Address_Decode_Table.md）
  //   · CFG / Tile / NoC / FSM / Global / Run / Intr：字节地址（= C 的 S2+reg_id*8）
  //     ILA 已见 0x0210(Global)、0x0218(RUN)，勿改为字地址 0x0042/0x0043
  //   · SRAM_CTRL：字地址 0xC000（§3.6），勿用 0x0300（落在 CFG 保留区）
  //   · WEIGHT：字地址区 0x4000，索引 weight_idx<<3（64b 总线步进 8）
  //   · FEAT：FMC 实测末笔 0x4FF8，采用 0x1000+tile/row/word（对齐 C S3 低 16 位）
  //   · 读结果 ping/pong：S3/S4 低 16 位 0x1000/0x2000（对齐 C print_output）
  //--------------------------------------------------------------------------
  localparam [15:0] ADDR_TILE_BASE       = 16'h0000; // TILE_CONF: byte (id<<3)
  localparam [15:0] ADDR_NOC_BASE        = 16'h0080; // NOC: (0x10+noc)<<3
  localparam [15:0] ADDR_FSM_NORMAL     = 16'h00F8; // FSM_NORMAL  byte
  localparam [15:0] ADDR_FSM_SPECIAL    = 16'h0100; // FSM_SPECIAL byte
  localparam [15:0] ADDR_GLOBAL_CONF    = 16'h0210; // GLOBAL byte（非 0x0042）
  localparam [15:0] ADDR_RUN_PROCESS    = 16'h0218; // RUN byte（非 0x0043）
  localparam [15:0] ADDR_INTR_FRESH     = 16'h0220; // INTR_FRESH byte
  localparam [15:0] ADDR_SRAM_CTRL      = 16'hC000; // SRAM_CTRL 字地址 §3.6

  localparam [15:0] ADDR_WEIGHT_BASE     = 16'h4000; // WEIGHT 字地址区 §3.4
  localparam [15:0] ADDR_FEAT_TILE_BASE = 16'h1000; // FEAT FMC 映射（ILA 末笔 0x4FF8）
  localparam [15:0] ADDR_OUT_S3_PING     = 16'h1000;
  localparam [15:0] ADDR_OUT_S4_PONG     = 16'h2000;

  // 与 chip_test_0601 一致：仅低 4 位 CTRL[3:0] 有效
  localparam [63:0] SRAM_CTRL_EXT_ALL   = {60'h0, 4'h0};
  localparam [63:0] SRAM_CTRL_MAC_ALL   = {60'h0, 4'hF};
  localparam [63:0] SRAM_CTRL_READ_OUT  = {60'h0, 4'h3};

  // 10 min @16MHz ≈ 0x23_86_F680；勿用 48'hFFFF…（≈永不超时，ILA 会一直停在 0x0D）
  localparam [47:0] WAIT_MAC_MAX         = 48'h0000_2386_F680;
  localparam [15:0] SRAM_CTRL_SETTLE_MAX = 16'hFFFF; // C long_delay 量级，写 0xC000 后等待
  localparam [15:0] READ_SRAM_WAIT_MAX   = 16'h0400;
  localparam [3:0]  BUS_GAP_MAX          = 4'd4;
  localparam [15:0] BOOT_WAIT_MAX        = 16'hFFFF;

  localparam WEIGHT_MEM_FILE  = "weight_data.mem";
  localparam FEATURE_MEM_FILE = "feature_data.mem";

  // FSM 状态（ILA 建议十六进制显示）
  localparam S_RESET           = 8'd0;
  localparam S_INIT_WAIT       = 8'd1;
  localparam S_CFG_SRAM_0      = 8'd2;
  localparam S_CFG_TILES       = 8'd3;
  localparam S_CFG_NOC         = 8'd4;
  localparam S_WR_WEIGHT       = 8'd5;
  localparam S_WR_FEAT_SRAM    = 8'd6;
  localparam S_RUN_SET_SRAM    = 8'd7;
  localparam S_CFG_FSM_N       = 8'd8;
  localparam S_CFG_FSM_S       = 8'd9;
  localparam S_FEAT_PUSH       = 8'd10;
  localparam S_CFG_GLOBAL      = 8'd11;
  localparam S_START_MAC       = 8'd12;
  localparam S_WAIT_DONE       = 8'd13;
  localparam S_CLR_INTR        = 8'd14;
  localparam S_CIN_ADVANCE     = 8'd15;
  localparam S_SET_SRAM_RD     = 8'd16;
  localparam S_READ_WAIT       = 8'd17;
  localparam S_READ_OUT        = 8'd18;
  localparam S_RES_ADVANCE     = 8'd19;
  localparam S_DONE            = 8'd20;
  localparam S_BUS_HOLD        = 8'd21;
  localparam S_MAC_TIMEOUT     = 8'd22;
  localparam S_MAC_ERR         = 8'd23;
  localparam S_SRAM_SETTLE     = 8'd24; // 0xC000 写后稳定（对齐 C long_delay）
  localparam S_INTR_BOOT       = 8'd25; // 上电清 INTR_FRESH
  localparam S_MAC_PREP        = 8'd26; // RUN 前再次写 MAC 模式 0xF

  //==========================================================================
  // 时钟 / 复位 / 同步
  //==========================================================================
  wire sys_clk;
  wire clk_16M;
  (* mark_debug = "true" *) wire clk_50M;
  wire mmcm_locked;
  wire ck_rst;

  reg  chip_input_full_r1, chip_input_full_r2;
  reg  chip_output_empty_r1, chip_output_empty_r2;
  reg  chip_mac_done_r1, chip_mac_done_r2;
  reg  chip_mac_done_r3;
  reg  chip_mac_err_r1, chip_mac_err_r2;

  wire chip_input_full_s2 = chip_input_full_r2;
  wire chip_output_empty_s2 = chip_output_empty_r2;
  wire chip_mac_done_s2    = chip_mac_done_r2;
  wire chip_mac_done_s3    = chip_mac_done_r3;
  wire chip_mac_done_rise  = chip_mac_done_s2 & ~chip_mac_done_s3;
  wire chip_mac_done_evt   = chip_mac_done_s2 | chip_mac_done_rise;
  wire chip_mac_err_s2     = chip_mac_err_r2;

  always @(posedge clk_16M or negedge ck_rst) begin
    if (!ck_rst) begin
      chip_input_full_r1  <= 1'b0;
      chip_input_full_r2  <= 1'b0;
      chip_output_empty_r1 <= 1'b1;
      chip_output_empty_r2 <= 1'b1;
      chip_mac_done_r1    <= 1'b0;
      chip_mac_done_r2    <= 1'b0;
      chip_mac_done_r3    <= 1'b0;
      chip_mac_err_r1     <= 1'b0;
      chip_mac_err_r2     <= 1'b0;
    end else begin
      chip_input_full_r1  <= chip_input_full;
      chip_input_full_r2  <= chip_input_full_r1;
      chip_output_empty_r1 <= chip_output_empty;
      chip_output_empty_r2 <= chip_output_empty_r1;
      chip_mac_done_r1    <= chip_mac_done;
      chip_mac_done_r2    <= chip_mac_done_r1;
      chip_mac_done_r3    <= chip_mac_done_r2;
      chip_mac_err_r1     <= chip_mac_err;
      chip_mac_err_r2     <= chip_mac_err_r1;
    end
  end

  IBUFGDS u_ibufg_sys_clk (.I(sys_clk_p), .IB(sys_clk_n), .O(sys_clk));

  clk_wiz_0 ip_mmcm (
    .reset   (~ck_rst),
    .clk_in1 (sys_clk),
    .clk_out1(clk_16M),
    .clk_out2(clk_50M),
    .locked  (mmcm_locked)
  );

  assign ck_rst = fpga_rst & mcu_rst;

  reg [7:0] chip_rst_cnt   = 8'h0;
  reg       chip_rst_n_reg = 1'b0;

  always @(posedge clk_16M or negedge ck_rst) begin
    if (!ck_rst) begin
      chip_rst_cnt   <= 8'h0;
      chip_rst_n_reg <= 1'b0;
    end else if (!mmcm_locked) begin
      chip_rst_cnt   <= 8'h0;
      chip_rst_n_reg <= 1'b0;
    end else if (!chip_rst_n_reg) begin
      chip_rst_cnt <= chip_rst_cnt + 1'b1;
      if (&chip_rst_cnt)
        chip_rst_n_reg <= 1'b1;
    end
  end

  ODDRE1 #(.SIM_DEVICE("ULTRASCALE_PLUS"), .SRVAL(1'b0)) u_oddre_clk_ic (
    .Q(chip_clk_ic), .C(clk_16M), .D1(1'b1), .D2(1'b0), .SR(1'b0));
  ODDRE1 #(.SIM_DEVICE("ULTRASCALE_PLUS"), .SRVAL(1'b0)) u_oddre_clk_core (
    .Q(chip_clk_core), .C(clk_16M), .D1(1'b1), .D2(1'b0), .SR(1'b0));

  assign chip_rst_n_io   = chip_rst_n_reg;
  assign chip_rst_n_core = chip_rst_n_reg;

  //==========================================================================
  // 总线 / BRAM
  //==========================================================================
  wire [63:0] data_out_to_chip;
  wire [63:0] data_in_from_chip;

  reg [63:0] fsm_data_out;
  reg [15:0] fsm_addr;
  reg        fsm_en;
  reg        fsm_wr_en;

  reg [7:0]  fsm_state;
  reg [7:0]  fsm_next_after_hold;
  reg [15:0] fsm_wait_cnt;
  reg [47:0] mac_wait_cnt;
  reg [3:0]  bus_gap_cnt;
  reg [15:0] read_wait_cnt;

  reg [4:0]  tile_idx;
  reg [4:0]  noc_idx;
  reg [10:0] weight_idx;
  reg [11:0] feat_sram_idx;
  reg [2:0]  cin_idx;
  reg [1:0]  res_row_idx;
  reg        res_col_idx;
  reg [4:0]  feat_tile;
  reg [5:0]  feat_row;
  reg [1:0]  feat_word;
  reg [7:0]  out_ch_idx;
  reg [4:0]  out_beat_idx;

  reg        feat_pp_flag, wt_pp_flag, out_pp_flag;
  reg        mac_done_latch;
  reg        mac_seen_done;
  reg        test_active;
  reg        rom_wr_setup;
  reg        use_pwm_three;

  reg [10:0] weight_raddr;
  reg [14:0] feature_raddr;
  reg [63:0] weight_rdata;
  reg [63:0] feature_rdata;

  (* ram_style = "block" *) reg [63:0] weight_data  [0:WEIGHT_WORDS-1];
  (* ram_style = "block" *) reg [63:0] feature_data [0:32767];

  (* mark_debug = "true" *) wire [7:0]  dbg_fsm_state = fsm_state;
  (* mark_debug = "true" *) wire        dbg_test_active = test_active;
  (* mark_debug = "true" *) wire        dbg_mac_done = chip_mac_done_s2;
  (* mark_debug = "true" *) wire [15:0] dbg_chip_addr = chip_add;
  (* mark_debug = "true" *) wire [63:0] dbg_chip_data =
      chip_wr_en ? data_out_to_chip : data_in_from_chip;
  // ILA：仅在 wr_en=1 时看写数据；BUS_HOLD(0x15) 时 addr 可能仍为 0xC000 但 data 为读回
  (* mark_debug = "true" *) wire [63:0] dbg_chip_wdata = fsm_data_out;
  (* mark_debug = "true" *) wire        dbg_chip_wr    = chip_wr_en;

  assign chip_en    = fsm_en;
  assign chip_wr_en = fsm_wr_en;
  assign chip_add   = fsm_addr;

  // config_tiles_and_noc
  wire [7:0] tile_fml  = tile_idx / GROUP_SIZE_PARAM;
  wire [7:0] tile_wid  = GROUP_SIZE_PARAM - 1 - (tile_idx % GROUP_SIZE_PARAM);
  wire [31:0] tile_cfg = (tile_fml << 16) | (3'b0 << 13) | (tile_wid << 5) | ((K_PARAM - 1) & 5'h1F);

  wire [4:0] noc_upper = noc_idx / GROUP_SIZE_PARAM;
  wire [4:0] noc_lower = (noc_idx + 1) / GROUP_SIZE_PARAM;
  wire [31:0] noc_cfg  = {28'h0, 1'b1, (noc_upper != noc_lower), (noc_upper == noc_lower), 1'b0};

  // run_process: normal / special / global
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

  wire [4:0] pwm_val = use_pwm_three ? 5'd3 :
      ((cin_idx == 3'd0) ? plane_work_mode : 5'd3);

  wire [2:0] pwm_w = pwm_val[2:0];
  wire [4:0] rci_w = {{(RES_COL_IDX_WIDTH - 1){1'b0}}, res_col_idx};
  wire [5:0] cix_w = {{(CIN_IDX_WIDTH - 3){1'b0}}, cin_idx};

  wire [31:0] fsm_special_cfg =
      (1'b0 << (TRUNC_BITS_WIDTH + WORK_MODE_WIDTH + RES_COL_IDX_WIDTH + CIN_IDX_WIDTH)) |
      (4'd0  << (WORK_MODE_WIDTH + RES_COL_IDX_WIDTH + CIN_IDX_WIDTH)) |
      (pwm_w << (RES_COL_IDX_WIDTH + CIN_IDX_WIDTH)) |
      (rci_w << CIN_IDX_WIDTH) |
      cix_w;

  wire       is_final_cin = (cin_idx == CIN_IDX_TOTAL - 1);
  wire [4:0] action_mode  = {1'b0, 1'b0, 1'b0, is_final_cin, 1'b0};

  wire [31:0] global_cfg_pp_next = {
    ~feat_pp_flag, wt_pp_flag, out_pp_flag,
    24'b0, action_mode
  };

  // drive_feature_from_files 源 / 目的地址
  wire [31:0] feat_start_row_cin =
      (cin_idx * (ROW_SIZE * GROUP_SIZE_PARAM) +
       ((GROUP_SIZE_PARAM - 1 - (feat_tile % GROUP_SIZE_PARAM)) * ROW_SIZE)) *
      (GROUP_NUM_PARAM * RES_ROW_TOTAL);
  wire [31:0] feat_start_row_h =
      (res_row_idx * GROUP_NUM_PARAM) + (feat_tile / GROUP_SIZE_PARAM);
  wire [31:0] feat_start_row = feat_start_row_cin + feat_start_row_h;
  wire [31:0] feat_byte_off =
      ((feat_start_row + feat_row * GROUP_NUM_PARAM * RES_ROW_TOTAL) * 8) +
      (res_col_idx ? 32'd32 : 32'd0) +
      (feat_word * 8);
  wire [14:0] feat_mem_idx_w = feat_byte_off[20:3];

  // C: S3_BASE | (((tileId&0xFF)<<5 | (r&0x1F))<<5) 低 16 位
  wire [15:0] feat_chip_addr =
      ADDR_FEAT_TILE_BASE + (feat_tile[3:0] << 10) + (feat_row[4:0] << 5) + (feat_word << 3);

  // print_output_results 读地址
  wire [15:0] out_src_base = out_pp_flag ? ADDR_OUT_S4_PONG : ADDR_OUT_S3_PING;
  // C: ch * groupNum * 32 = ch * 256
  wire [15:0] out_read_addr = out_src_base + {out_ch_idx, 8'b0} + {11'h0, out_beat_idx, 3'b0};

  initial begin
    $readmemh(WEIGHT_MEM_FILE,  weight_data);
    $readmemh(FEATURE_MEM_FILE, feature_data);
  end

  always @(posedge clk_16M) begin
    weight_rdata  <= weight_data[weight_raddr];
    feature_rdata <= feature_data[feature_raddr];
  end

  //==========================================================================
  // 主 FSM（mac_test_tb2.c main + run_process + print_output_results）
  //==========================================================================
  always @(posedge clk_16M or negedge ck_rst) begin
    if (!ck_rst) begin
      fsm_state          <= S_RESET;
      fsm_en             <= 1'b0;
      fsm_wr_en          <= 1'b0;
      fsm_addr           <= 16'h0;
      fsm_data_out       <= 64'h0;
      fsm_wait_cnt       <= 16'h0;
      mac_wait_cnt       <= 48'h0;
      bus_gap_cnt        <= 4'h0;
      read_wait_cnt      <= 16'h0;
      tile_idx           <= 5'd0;
      noc_idx            <= 5'd0;
      weight_idx         <= 11'd0;
      feat_sram_idx      <= 12'd0;
      cin_idx            <= 3'd0;
      res_row_idx        <= 2'd0;
      res_col_idx        <= 1'b0;
      feat_tile          <= 5'd0;
      feat_row           <= 6'd0;
      feat_word          <= 2'd0;
      out_ch_idx          <= 8'd0;
      out_beat_idx        <= 5'd0;
      feat_pp_flag       <= 1'b0;
      wt_pp_flag         <= 1'b0;
      out_pp_flag        <= 1'b0;
      mac_done_latch     <= 1'b0;
      mac_seen_done      <= 1'b0;
      test_active        <= 1'b0;
      rom_wr_setup       <= 1'b0;
      use_pwm_three      <= 1'b0;
      weight_raddr       <= 11'd0;
      feature_raddr      <= 15'd0;
    end else begin
      fsm_en    <= 1'b0;
      fsm_wr_en <= 1'b0;

      case (fsm_state)

        // ----- main: 上电等待 -----
        S_RESET: begin
          fsm_wait_cnt <= fsm_wait_cnt + 1'b1;
          if (fsm_wait_cnt == BOOT_WAIT_MAX) begin
            fsm_wait_cnt <= 16'h0;
            fsm_state    <= S_INIT_WAIT;
          end
        end

        S_INIT_WAIT: begin
          tile_idx      <= 5'd0;
          noc_idx       <= 5'd0;
          res_row_idx   <= 2'd0;
          res_col_idx   <= 1'b0;
          cin_idx       <= 3'd0;
          feat_pp_flag  <= 1'b0;
          wt_pp_flag    <= 1'b0;
          out_pp_flag   <= 1'b0;
          use_pwm_three <= 1'b0;
          fsm_state     <= S_INTR_BOOT;
        end

        // main: 清历史中断后再配置
        S_INTR_BOOT: begin
          if (!chip_input_full_s2) begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= ADDR_INTR_FRESH;
            fsm_data_out <= 64'h0000_0000_0000_0001;
            fsm_next_after_hold <= S_CFG_SRAM_0;
            fsm_state    <= S_BUS_HOLD;
          end
        end

        // set_sram_control(0,0,0,0) — 状态 0x02，写数据应为 0 而非 0xF
        S_CFG_SRAM_0: begin
          if (!chip_input_full_s2) begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= ADDR_SRAM_CTRL;
            fsm_data_out <= SRAM_CTRL_EXT_ALL;
            fsm_next_after_hold <= S_CFG_TILES;
            fsm_state    <= S_BUS_HOLD;
          end
        end

        // config_tiles_and_noc — tiles
        S_CFG_TILES: begin
          if (!chip_input_full_s2) begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= ADDR_TILE_BASE + {10'h0, tile_idx, 3'b000};
            fsm_data_out <= {32'h0, tile_cfg};
            if (tile_idx == TILE_SIZE - 1) begin
              tile_idx <= 5'd0;
              fsm_next_after_hold <= S_CFG_NOC;
            end else begin
              tile_idx <= tile_idx + 1'b1;
              fsm_next_after_hold <= S_CFG_TILES;
            end
            fsm_state <= S_BUS_HOLD;
          end
        end

        // config_tiles_and_noc — noc (15)
        S_CFG_NOC: begin
          if (!chip_input_full_s2) begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= ADDR_NOC_BASE + {10'h0, noc_idx, 3'b000};
            fsm_data_out <= {32'h0, noc_cfg};
            if (noc_idx == TILE_SIZE - 2) begin
              noc_idx      <= 5'd0;
              weight_idx   <= 11'd0;
              rom_wr_setup <= 1'b0;
              fsm_next_after_hold <= S_WR_WEIGHT;
            end else begin
              noc_idx <= noc_idx + 1'b1;
              fsm_next_after_hold <= S_CFG_NOC;
            end
            fsm_state <= S_BUS_HOLD;
          end
        end

        // drive_weights_from_files（直写芯片，替代 S1+DMA→S4）
        S_WR_WEIGHT: begin
          if (chip_input_full_s2) begin
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
            if (weight_idx == WEIGHT_WORDS - 1) begin
              feat_sram_idx <= 12'd0;
              rom_wr_setup  <= 1'b0;
              fsm_next_after_hold <= S_WR_FEAT_SRAM;
            end else
              fsm_next_after_hold <= S_WR_WEIGHT;
            fsm_state <= S_BUS_HOLD;
          end
        end

        // drive_features_to_sram（2048×64b 预灌）
        S_WR_FEAT_SRAM: begin
          if (chip_input_full_s2) begin
            fsm_en <= 1'b0;
          end else if (!rom_wr_setup) begin
            feature_raddr <= feat_sram_idx;
            rom_wr_setup  <= 1'b1;
          end else begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= ADDR_FEAT_TILE_BASE + {4'h0, feat_sram_idx, 3'b000};
            fsm_data_out <= feature_rdata;
            feat_sram_idx <= feat_sram_idx + 1'b1;
            rom_wr_setup  <= 1'b0;
            if (feat_sram_idx == FEAT_SRAM_WORDS - 1) begin
              res_row_idx   <= 2'd0;
              res_col_idx   <= 1'b0;
              cin_idx       <= 3'd0;
              use_pwm_three <= 1'b0;
              mac_seen_done <= 1'b0;
              feat_tile     <= 5'd0;
              feat_row      <= 6'd0;
              feat_word     <= 2'd0;
              fsm_next_after_hold <= S_RUN_SET_SRAM;
            end else
              fsm_next_after_hold <= S_WR_FEAT_SRAM;
            fsm_state <= S_BUS_HOLD;
          end
        end

        // run_process: set_sram_control(1,1,1,1)
        S_RUN_SET_SRAM: begin
          if (!chip_input_full_s2) begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= ADDR_SRAM_CTRL;
            fsm_data_out <= SRAM_CTRL_MAC_ALL;
            fsm_next_after_hold <= S_CFG_FSM_N;
            fsm_state    <= S_BUS_HOLD;
          end
        end

        S_CFG_FSM_N: begin
          if (!chip_input_full_s2) begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= ADDR_FSM_NORMAL;
            fsm_data_out <= {32'h0, fsm_normal_cfg};
            fsm_next_after_hold <= S_CFG_FSM_S;
            fsm_state    <= S_BUS_HOLD;
          end
        end

        S_CFG_FSM_S: begin
          if (!chip_input_full_s2) begin
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

        // drive_feature_from_files
        S_FEAT_PUSH: begin
          if (chip_input_full_s2) begin
            fsm_en <= 1'b0;
          end else if (!rom_wr_setup) begin
            feature_raddr <= feat_mem_idx_w;
            rom_wr_setup  <= 1'b1;
          end else begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= feat_chip_addr;
            fsm_data_out <= feature_rdata;
            rom_wr_setup <= 1'b0;
            if (feat_word == 2'd3) begin
              feat_word <= 2'd0;
              if (feat_row == ROW_SIZE - 1) begin
                feat_row <= 6'd0;
                if (feat_tile == TILE_SIZE - 1) begin
                  feat_tile <= 5'd0;
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

        // run_process: toggle pingpong then global
        S_CFG_GLOBAL: begin
          if (!chip_input_full_s2) begin
            feat_pp_flag <= ~feat_pp_flag;
            if (PINGPONG_EN_FLAG) begin
              wt_pp_flag  <= ~wt_pp_flag;
              out_pp_flag <= ~out_pp_flag;
            end
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= ADDR_GLOBAL_CONF;
            fsm_data_out <= {32'h0, global_cfg_pp_next};
            fsm_next_after_hold <= S_MAC_PREP;
            fsm_state    <= S_BUS_HOLD;
          end
        end

        // run_process：启动 MAC 前再次 set_sram(1,1,1,1)，避免中间总线写冲掉 CTRL
        S_MAC_PREP: begin
          if (!chip_input_full_s2) begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= ADDR_SRAM_CTRL;
            fsm_data_out <= SRAM_CTRL_MAC_ALL;
            fsm_next_after_hold <= S_START_MAC;
            fsm_state    <= S_BUS_HOLD;
          end
        end

        S_START_MAC: begin
          if (!chip_input_full_s2) begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= ADDR_RUN_PROCESS;
            fsm_data_out <= 64'h0000_0000_0000_0001;
            test_active  <= 1'b1;
            mac_wait_cnt <= 48'h0;
            fsm_next_after_hold <= S_WAIT_DONE;
            fsm_state    <= S_BUS_HOLD;
          end
        end

        // wait_mac_complete
        S_WAIT_DONE: begin
          if (chip_mac_done_evt) begin
            test_active    <= 1'b0;
            mac_done_latch <= 1'b1;
            mac_seen_done  <= 1'b1;
            mac_wait_cnt   <= 48'h0;
            fsm_state      <= S_CLR_INTR;
          end else if (chip_mac_err_s2) begin
            test_active  <= 1'b0;
            mac_wait_cnt <= 48'h0;
            fsm_state    <= S_MAC_ERR;
          end else begin
            mac_wait_cnt <= mac_wait_cnt + 1'b1;
            if (mac_wait_cnt == WAIT_MAC_MAX)
              fsm_state <= S_MAC_TIMEOUT;
          end
        end

        S_CLR_INTR: begin
          if (!chip_input_full_s2) begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= ADDR_INTR_FRESH;
            fsm_data_out <= 64'h0000_0000_0000_0001;
            fsm_next_after_hold <= S_CIN_ADVANCE;
            fsm_state    <= S_BUS_HOLD;
          end
        end

        // main: 剩余 cin 或 print_output_results
        S_CIN_ADVANCE: begin
          if (cin_idx != CIN_IDX_TOTAL - 1) begin
            cin_idx       <= cin_idx + 1'b1;
            use_pwm_three <= 1'b1;
            feat_tile     <= 5'd0;
            feat_row      <= 6'd0;
            feat_word     <= 2'd0;
            fsm_state     <= S_RUN_SET_SRAM;
          end else if (mac_seen_done) begin
            cin_idx       <= 3'd0;
            out_ch_idx    <= 8'd0;
            out_beat_idx  <= 5'd0;
            read_wait_cnt <= 16'h0;
            fsm_state     <= S_SET_SRAM_RD;
          end else
            fsm_state <= S_MAC_TIMEOUT;
        end

        // print_output_results: set_sram(1,1,0,0)
        S_SET_SRAM_RD: begin
          if (!chip_input_full_s2) begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= ADDR_SRAM_CTRL;
            fsm_data_out <= SRAM_CTRL_READ_OUT;
            read_wait_cnt <= 16'h0;
            fsm_next_after_hold <= S_READ_WAIT;
            fsm_state    <= S_BUS_HOLD;
          end
        end

        S_SRAM_SETTLE: begin
          fsm_wait_cnt <= fsm_wait_cnt + 1'b1;
          if (fsm_wait_cnt == SRAM_CTRL_SETTLE_MAX) begin
            fsm_wait_cnt <= 16'h0;
            fsm_state    <= fsm_next_after_hold;
          end
        end

        S_READ_WAIT: begin
          read_wait_cnt <= read_wait_cnt + 1'b1;
          if (read_wait_cnt == READ_SRAM_WAIT_MAX)
            fsm_state <= S_READ_OUT;
        end

        // print_output_results: 读 256 通道 × 32 拍
        S_READ_OUT: begin
          if (chip_output_empty_s2) begin
            fsm_en <= 1'b0;
          end else begin
            fsm_en    <= 1'b1;
            fsm_wr_en <= 1'b0;
            fsm_addr  <= out_read_addr;
            if (out_beat_idx == OUT_BEATS_PER_CH - 1) begin
              out_beat_idx <= 5'd0;
              if (out_ch_idx == COUT_PARAM - 1)
                fsm_state <= S_RES_ADVANCE;
              else begin
                out_ch_idx <= out_ch_idx + 1'b1;
                fsm_next_after_hold <= S_READ_OUT;
                fsm_state <= S_BUS_HOLD;
              end
            end else begin
              out_beat_idx <= out_beat_idx + 1'b1;
              fsm_next_after_hold <= S_READ_OUT;
              fsm_state <= S_BUS_HOLD;
            end
          end
        end

        // main: 下一分辨率 / 结束
        S_RES_ADVANCE: begin
          use_pwm_three <= 1'b0;
          if (res_col_idx == RES_COL_TOTAL - 1) begin
            if (res_row_idx == RES_ROW_TOTAL - 1)
              fsm_state <= S_DONE;
            else begin
              res_row_idx <= res_row_idx + 1'b1;
              res_col_idx <= 1'b0;
              cin_idx     <= 3'd0;
              feat_tile   <= 5'd0;
              feat_row    <= 6'd0;
              feat_word   <= 2'd0;
              fsm_state   <= S_RUN_SET_SRAM;
            end
          end else begin
            res_col_idx <= res_col_idx + 1'b1;
            cin_idx     <= 3'd0;
            feat_tile   <= 5'd0;
            feat_row    <= 6'd0;
            feat_word   <= 2'd0;
            fsm_state   <= S_RUN_SET_SRAM;
          end
        end

        S_DONE: begin
          fsm_wait_cnt <= fsm_wait_cnt + 1'b1;
          if (fsm_wait_cnt == 16'h0FFF) begin
            fsm_wait_cnt <= 16'h0;
            fsm_state    <= S_RUN_SET_SRAM;
          end
        end

        S_BUS_HOLD: begin
          if (bus_gap_cnt == BUS_GAP_MAX) begin
            bus_gap_cnt <= 4'h0;
            if (fsm_addr == ADDR_SRAM_CTRL) begin
              fsm_wait_cnt <= 16'h0;
              fsm_state    <= S_SRAM_SETTLE;
            end else
              fsm_state <= fsm_next_after_hold;
          end else
            bus_gap_cnt <= bus_gap_cnt + 1'b1;
        end

        S_MAC_TIMEOUT: begin
          test_active <= 1'b0;
        end

        S_MAC_ERR: begin
          test_active <= 1'b0;
          fsm_state   <= S_MAC_TIMEOUT;
        end

        default: fsm_state <= S_RESET;
      endcase
    end
  end

  assign led_mmcm_ok  = mmcm_locked;
  assign led_chip_ok  = chip_rst_n_reg;
  assign led_mac_done = mac_done_latch;
  assign led_chip_output_empty = chip_output_empty;
  assign uart_tx = 1'b1;

  assign data_out_to_chip = fsm_data_out;

  genvar gi;
  generate
    for (gi = 0; gi < 64; gi = gi + 1) begin : gen_iobuf
      IOBUF u_iobuf (
        .IO(chip_din[gi]),
        .O (data_in_from_chip[gi]),
        .I (data_out_to_chip[gi]),
        .T (~chip_wr_en)
      );
    end
  endgenerate

endmodule
