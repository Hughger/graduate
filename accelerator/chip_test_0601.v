`timescale 1ns / 1ps
//=============================================================================
// 文件名：chip_test_0601.v
// 功  能：FPGA 直连 FLOOD 芯片，单次对齐 mac_test_tb2.c 的
//         run_process(0, 0, 0, ...) + 首次 main() 前置步骤
//
// 地址规则（与 tb_cfg_feat_adapter.v / axi2bram_asic.v 一致）：
//   chip_add = 19bit_byte_addr[18:3]  （64 位字地址，每字 +1）
//   配置寄存器字地址 = 寄存器 ID（非 ID×8）
//
// 对齐参数（mac_test_tb2.c）：
//   k=3, cout=256, groupSize=2, groupNum=8, stride=2
//   cinIdx=0, resolutionColIdx=0, resolutionRowIdx=0, planeWorkMode=0
//=============================================================================

module chip_test_0601
(
  input  wire       sys_clk_p,
  input  wire       sys_clk_n,
  input  wire       fpga_rst,
  input  wire       mcu_rst,

  output wire       uart_tx,
  input  wire       uart_rx,

  output wire       led_mmcm_ok,
  output wire       led_chip_ok,
  output wire       led_mac_done,
  output wire       led_chip_output_empty,

  output wire       chip_clk_ic,
  output wire       chip_clk_core,
  output wire       chip_rst_n_io,
  output wire       chip_rst_n_core,
  output wire       chip_en,
  output wire       chip_wr_en,

  input  wire       chip_input_full,
  input  wire       chip_output_empty,
  input  wire       chip_mac_done,
  input  wire       chip_mac_err,

  output wire [15:0] chip_add,
  inout  wire [63:0] chip_din
);

  //==========================================================================
  // 时钟 / 复位
  //==========================================================================
  wire sys_clk;
  wire clk_16M;
  (* mark_debug = "true" *) wire clk_50M;
  wire mmcm_locked;
  wire ck_rst;

  wire [63:0] data_out_to_chip;
  wire [63:0] data_in_from_chip;

  reg  [63:0] fsm_data_out;
  reg  [15:0] fsm_addr;
  reg         fsm_en;
  reg         fsm_wr_en;

  reg  [7:0]  chip_rst_cnt   = 8'h00;
  reg         chip_rst_n_reg = 1'b0;

  reg         test_active    = 1'b0;
  reg         mac_done_latch = 1'b0;

  //==========================================================================
  // ILA 调试信号（与 system_chip_test.v 保持一致，勿改）
  //==========================================================================
  (* mark_debug = "true" *) wire        dbg_mmcm_locked;
  (* mark_debug = "true" *) wire        dbg_chip_rst_ok;
  (* mark_debug = "true" *) wire        dbg_mac_done;
  (* mark_debug = "true" *) wire        dbg_mac_err;
  (* mark_debug = "true" *) wire        dbg_input_full;
  (* mark_debug = "true" *) wire        dbg_output_empty;
  (* mark_debug = "true" *) wire        dbg_test_active;
  (* mark_debug = "true" *) wire        dbg_chip_en;
  (* mark_debug = "true" *) wire        dbg_chip_wr_en;
  (* mark_debug = "true" *) wire [15:0] dbg_chip_addr;
  (* mark_debug = "true" *) wire [63:0] dbg_chip_data;
  (* mark_debug = "true" *) wire [7:0]  dbg_fsm_state;

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

  IBUFGDS u_ibufg_sys_clk (
    .I  (sys_clk_p),
    .IB (sys_clk_n),
    .O  (sys_clk)
  );

  clk_wiz_0 ip_mmcm (
    .reset   (~ck_rst),
    .clk_in1 (sys_clk),
    .clk_out1(clk_16M),
    .clk_out2(clk_50M),
    .locked  (mmcm_locked)
  );

  wire CLK32768KHZ;
  divclk U0_divclk (
    .clk    (clk_16M),
    .rstn   (ck_rst),
    .clk_out(CLK32768KHZ)
  );

  assign ck_rst = fpga_rst & mcu_rst;

  always @(posedge clk_16M or negedge ck_rst) begin
    if (!ck_rst) begin
      chip_rst_cnt   <= 8'h00;
      chip_rst_n_reg <= 1'b0;
    end else if (!mmcm_locked) begin
      chip_rst_cnt   <= 8'h00;
      chip_rst_n_reg <= 1'b0;
    end else if (!chip_rst_n_reg) begin
      chip_rst_cnt <= chip_rst_cnt + 1'b1;
      if (&chip_rst_cnt)
        chip_rst_n_reg <= 1'b1;
    end
  end

  ODDRE1 #(
    .SIM_DEVICE ("ULTRASCALE_PLUS"),
    .SRVAL      (1'b0)
  ) u_oddre1_clk_ic (
    .Q  (chip_clk_ic),
    .C  (clk_16M),
    .D1 (1'b1),
    .D2 (1'b0),
    .SR (1'b0)
  );

  ODDRE1 #(
    .SIM_DEVICE ("ULTRASCALE_PLUS"),
    .SRVAL      (1'b0)
  ) u_oddre1_clk_core (
    .Q  (chip_clk_core),
    .C  (clk_16M),
    .D1 (1'b1),
    .D2 (1'b0),
    .SR (1'b0)
  );

  assign chip_rst_n_io   = chip_rst_n_reg;
  assign chip_rst_n_core = chip_rst_n_reg;
  assign chip_en         = fsm_en;
  assign chip_wr_en      = fsm_wr_en;
  assign chip_add        = fsm_addr;

  //==========================================================================
  // 总线字地址常量（19bit 字节空间 >> 3）
  //==========================================================================
  localparam [15:0] BUS_CFG_BASE    = 16'h0000;
  localparam [15:0] BUS_FEAT_BASE   = 16'h2000;  // S3 输入特征
  localparam [15:0] BUS_WEIGHT_BASE = 16'h4000;  // S4 权重
  localparam [15:0] BUS_OUTP_BASE   = 16'h8000;  // 输出 ping
  localparam [15:0] BUS_CTRL        = 16'hC000;  // SRAM 切换

  localparam [15:0] REG_FSM_NORMAL  = 16'h001F;
  localparam [15:0] REG_FSM_SPECIAL = 16'h0020;
  localparam [15:0] REG_GLOBAL      = 16'h0042;
  localparam [15:0] REG_RUN         = 16'h0043;
  localparam [15:0] REG_INTR        = 16'h0044;

  // mac_test_tb2.c 固定参数
  localparam [31:0] FSM_NORMAL_CFG  = 32'h0007_EE22; // k-1=2,gs-1=1,gn-1=7,cout-1=31,stride-1=1
  localparam [31:0] FSM_SPECIAL_CFG = 32'h0000_0000; // cinIdx=0,col=0,pwm=0
  localparam [31:0] GLOBAL_CFG_VAL  = 32'h8000_0000; // featurePingpong 翻转后为 1

  localparam [3:0]  CTRL_EXT_ALL    = 4'b0000;
  localparam [3:0]  CTRL_MAC_ALL    = 4'b1111;
  localparam [3:0]  CTRL_RD_OUTPUT  = 4'b0011;     // weight→MAC, output→外部

  localparam [10:0] WEIGHT_WORDS     = 11'd1152;
  localparam [13:0] FEAT_XFERS       = 14'd2048;    // 16 tile × 32 row × 4 beat
  localparam [5:0]  RESULT_WORDS     = 6'd32;       // 1 通道 × groupNum 行 × 4 字/行

  //==========================================================================
  // 测试 FSM
  //==========================================================================
  localparam S_RESET           = 8'd0;
  localparam S_INIT_WAIT       = 8'd1;
  localparam S_CFG_CTRL_LOAD   = 8'd2;
  localparam S_CFG_TILES       = 8'd3;
  localparam S_CFG_NOC         = 8'd4;
  localparam S_WRITE_WEIGHTS   = 8'd5;
  localparam S_CFG_CTRL_MAC    = 8'd6;
  localparam S_CFG_FSM_N       = 8'd7;
  localparam S_CFG_FSM_S       = 8'd8;
  localparam S_WRITE_FEATURES  = 8'd9;
  localparam S_CFG_GLOBAL      = 8'd10;
  localparam S_START_MAC       = 8'd11;
  localparam S_WAIT_DONE       = 8'd12;
  localparam S_CLR_INTR        = 8'd13;
  localparam S_DONE            = 8'd14;
  // 读结果阶段暂时省略（C 侧 print_output_results 与 output_empty 引脚
  // 在直连测试里易卡住；功耗验证只需 mac_done + test_active 窗口）

  reg [7:0]  fsm_state     = S_RESET;
  reg [15:0] fsm_wait_cnt  = 16'h0;
  reg [4:0]  fsm_tile_idx  = 5'd0;
  reg [3:0]  fsm_noc_idx   = 4'd0;
  reg        test_done_latch = 1'b0;

  (* mark_debug = "true" *) reg [10:0] weight_idx  = 11'd0;
  (* mark_debug = "true" *) reg [13:0] feat_xfer_idx = 14'd0;
  reg [5:0]  result_idx   = 6'd0;

  reg [10:0] weight_raddr;
  reg [63:0] weight_rdata;
  reg [14:0] feature_raddr;
  reg [63:0] feature_rdata;
  reg        rom_wr_setup;

  reg [4:0]  feat_tile;
  reg [4:0]  feat_row;
  reg [1:0]  feat_beat;
  reg [63:0] result_data [0:31];

  localparam WEIGHT_MEM_FILE  = "weight_data.mem";
  localparam FEATURE_MEM_FILE = "feature_data.mem";

  (* ram_style = "block" *) reg [63:0] weight_data  [0:1151];
  (* ram_style = "block" *) reg [63:0] feature_data [0:16383];

  assign dbg_fsm_state = fsm_state;

  always @(posedge clk_16M) begin
    weight_rdata  <= weight_data[weight_raddr];
    feature_rdata <= feature_data[feature_raddr];
  end

  initial begin
    $readmemh(WEIGHT_MEM_FILE,  weight_data);
    $readmemh(FEATURE_MEM_FILE, feature_data);
  end

  //---------------------------------------------------------------------------
  // 配置计算（对齐 config_tiles_and_noc / drive_feature_from_files）
  //---------------------------------------------------------------------------
  function automatic [31:0] calc_tile_cfg;
    input [4:0] tile_id;
    reg [7:0] feature_map_line;
    reg [7:0] write_id;
    begin
      feature_map_line = tile_id >> 1;
      write_id         = 8'd1 - {7'd0, tile_id[0]};
      calc_tile_cfg    = {8'h0, feature_map_line, 3'b0, write_id, 5'd2};
    end
  endfunction

  function automatic [31:0] calc_noc_cfg;
    input [3:0] noc_id;
    reg [3:0] upper_group;
    reg [3:0] lower_group;
    begin
      upper_group = noc_id >> 1;
      lower_group = (noc_id + 4'd1) >> 1;
      calc_noc_cfg = {28'h0, 1'b1, (upper_group != lower_group),
                      (upper_group == lower_group), 1'b0};
    end
  endfunction

  wire [15:0] feat_start_row =
      (((16'd2 - 16'd1 - {15'd0, feat_tile[0]}) * 16'd32) * 16'd32) +
      {11'd0, feat_tile[4:1]};

  wire [14:0] feat_src_word  = feat_start_row[14:0] + ({9'd0, feat_row} * 15'd32) + {13'd0, feat_beat};
  wire [15:0] feat_dst_word  =
      BUS_FEAT_BASE + (({11'd0, feat_tile} * 16'd32 + {11'd0, feat_row}) * 16'd4) + {14'd0, feat_beat};

  wire [15:0] result_bus_addr = BUS_OUTP_BASE + {10'd0, result_idx};

  //---------------------------------------------------------------------------
  // 主状态机
  //---------------------------------------------------------------------------
  always @(posedge clk_16M or negedge ck_rst) begin
    if (!ck_rst) begin
      fsm_state       <= S_RESET;
      fsm_en          <= 1'b0;
      fsm_wr_en       <= 1'b0;
      fsm_addr        <= 16'h0;
      fsm_data_out    <= 64'h0;
      fsm_wait_cnt    <= 16'h0;
      fsm_tile_idx    <= 5'd0;
      fsm_noc_idx     <= 4'd0;
      test_active     <= 1'b0;
      mac_done_latch  <= 1'b0;
      test_done_latch <= 1'b0;
      weight_idx      <= 11'd0;
      feat_xfer_idx   <= 14'd0;
      result_idx      <= 6'd0;
      weight_raddr    <= 11'd0;
      feature_raddr   <= 15'd0;
      rom_wr_setup    <= 1'b0;
      feat_tile       <= 5'd0;
      feat_row        <= 5'd0;
      feat_beat       <= 2'd0;
    end else begin
      fsm_en    <= 1'b0;
      fsm_wr_en <= 1'b0;

      case (fsm_state)
        S_RESET: begin
          fsm_wait_cnt <= fsm_wait_cnt + 1'b1;
          if (fsm_wait_cnt == 16'hFFFF) begin
            fsm_wait_cnt <= 16'h0;
            fsm_state    <= S_INIT_WAIT;
          end
        end

        S_INIT_WAIT: begin
          fsm_tile_idx <= 5'd0;
          fsm_noc_idx  <= 4'd0;
          fsm_state    <= S_CFG_CTRL_LOAD;
        end

        // set_sram_control(0,0,0,0)
        S_CFG_CTRL_LOAD: begin
          if (!chip_input_full) begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= BUS_CTRL;
            fsm_data_out <= {60'h0, CTRL_EXT_ALL};
            fsm_state    <= S_CFG_TILES;
          end
        end

        // config_tiles_and_noc — Tile 部分
        S_CFG_TILES: begin
          if (!chip_input_full) begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= BUS_CFG_BASE + {11'd0, fsm_tile_idx};
            fsm_data_out <= {32'h0, calc_tile_cfg(fsm_tile_idx)};
            if (fsm_tile_idx == 5'd15) begin
              fsm_tile_idx <= 5'd0;
              fsm_noc_idx  <= 4'd0;
              fsm_state    <= S_CFG_NOC;
            end else begin
              fsm_tile_idx <= fsm_tile_idx + 1'b1;
            end
          end
        end

        // config_tiles_and_noc — NoC 部分（15 项）
        S_CFG_NOC: begin
          if (!chip_input_full) begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= BUS_CFG_BASE + 16'h0010 + {12'd0, fsm_noc_idx};
            fsm_data_out <= {32'h0, calc_noc_cfg(fsm_noc_idx)};
            if (fsm_noc_idx == 4'd14) begin
              weight_idx    <= 11'd0;
              weight_raddr  <= 11'd0;
              rom_wr_setup  <= 1'b0;
              fsm_state     <= S_WRITE_WEIGHTS;
            end else begin
              fsm_noc_idx <= fsm_noc_idx + 1'b1;
            end
          end
        end

        // drive_weights_from_files → S4
        S_WRITE_WEIGHTS: begin
          if (chip_input_full) begin
            // 等待
          end else if (!rom_wr_setup) begin
            weight_raddr <= weight_idx;
            rom_wr_setup <= 1'b1;
          end else begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= BUS_WEIGHT_BASE + {5'd0, weight_idx};
            fsm_data_out <= weight_rdata;
            rom_wr_setup <= 1'b0;
            if (weight_idx == (WEIGHT_WORDS - 11'd1)) begin
              fsm_state <= S_CFG_CTRL_MAC;
            end else begin
              weight_idx <= weight_idx + 1'b1;
            end
          end
        end

        // run_process 开头：set_sram_control(1,1,1,1)
        S_CFG_CTRL_MAC: begin
          if (!chip_input_full) begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= BUS_CTRL;
            fsm_data_out <= {60'h0, CTRL_MAC_ALL};
            fsm_state    <= S_CFG_FSM_N;
          end
        end

        S_CFG_FSM_N: begin
          if (!chip_input_full) begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= REG_FSM_NORMAL;
            fsm_data_out <= {32'h0, FSM_NORMAL_CFG};
            fsm_state    <= S_CFG_FSM_S;
          end
        end

        S_CFG_FSM_S: begin
          if (!chip_input_full) begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= REG_FSM_SPECIAL;
            fsm_data_out <= {32'h0, FSM_SPECIAL_CFG};
            feat_tile     <= 5'd0;
            feat_row      <= 5'd0;
            feat_beat     <= 2'd0;
            feat_xfer_idx <= 14'd0;
            rom_wr_setup  <= 1'b0;
            fsm_state     <= S_WRITE_FEATURES;
          end
        end

        // drive_feature_from_files(0,0,0,...)
        S_WRITE_FEATURES: begin
          if (chip_input_full) begin
            // 等待
          end else if (!rom_wr_setup) begin
            feature_raddr <= feat_src_word;
            rom_wr_setup  <= 1'b1;
          end else begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= feat_dst_word;
            fsm_data_out <= feature_rdata;
            rom_wr_setup <= 1'b0;
            if (feat_xfer_idx == (FEAT_XFERS - 14'd1)) begin
              fsm_state <= S_CFG_GLOBAL;
            end else begin
              feat_xfer_idx <= feat_xfer_idx + 1'b1;
              if (feat_beat == 2'd3) begin
                feat_beat <= 2'd0;
                if (feat_row == 5'd31) begin
                  feat_row  <= 5'd0;
                  feat_tile <= feat_tile + 1'b1;
                end else begin
                  feat_row <= feat_row + 1'b1;
                end
              end else begin
                feat_beat <= feat_beat + 1'b1;
              end
            end
          end
        end

        S_CFG_GLOBAL: begin
          if (!chip_input_full) begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= REG_GLOBAL;
            fsm_data_out <= {32'h0, GLOBAL_CFG_VAL};
            fsm_wait_cnt <= 16'h0;
            fsm_state    <= S_START_MAC;
          end
        end

        S_START_MAC: begin
          if (!chip_input_full) begin
            fsm_en       <= 1'b1;
            fsm_wr_en    <= 1'b1;
            fsm_addr     <= REG_RUN;
            fsm_data_out <= 64'h0000_0000_0000_0001;
            test_active  <= 1'b1;
            fsm_wait_cnt <= 16'h0;
            fsm_state    <= S_WAIT_DONE;
          end
        end

        S_WAIT_DONE: begin
          if (chip_mac_done) begin
            test_active    <= 1'b0;
            mac_done_latch <= 1'b1;
            fsm_wait_cnt   <= 16'h0;
            fsm_state      <= S_CLR_INTR;
          end else if (chip_mac_err) begin
            test_active  <= 1'b0;
            fsm_wait_cnt   <= 16'h0;
            fsm_state      <= S_CLR_INTR;
          end else begin
            fsm_wait_cnt <= fsm_wait_cnt + 1'b1;
            if (fsm_wait_cnt == 16'hFFFF) begin
              test_active  <= 1'b0;
              fsm_wait_cnt <= 16'h0;
              fsm_state    <= S_CLR_INTR;
            end
          end
        end

        // wait_mac_complete 内清中断（不等待 input_full，MAC 算完后该信号可能一直为高）
        S_CLR_INTR: begin
          fsm_en       <= 1'b1;
          fsm_wr_en    <= 1'b1;
          fsm_addr     <= REG_INTR;
          fsm_data_out <= 64'h0000_0000_0000_0001;
          fsm_wait_cnt <= 16'h0;
          fsm_state    <= S_DONE;
        end

        // 功耗循环：约 1ms 后重跑
        S_DONE: begin
          fsm_wait_cnt <= fsm_wait_cnt + 1'b1;
          if (fsm_wait_cnt == 16'h0FFF) begin
            fsm_wait_cnt    <= 16'h0;
            fsm_tile_idx    <= 5'd0;
            fsm_noc_idx     <= 4'd0;
            test_done_latch <= 1'b1;
            fsm_state       <= S_CFG_CTRL_LOAD;
          end
        end

        default: fsm_state <= S_RESET;
      endcase
    end
  end

  assign led_mmcm_ok           = mmcm_locked;
  assign led_chip_ok           = chip_rst_n_reg;
  assign led_mac_done          = mac_done_latch;
  assign led_chip_output_empty = chip_output_empty;
  assign uart_tx               = 1'b1;

  assign data_out_to_chip = fsm_data_out;

  genvar gi;
  generate
    for (gi = 0; gi < 64; gi = gi + 1) begin : gen_iobuf
      IOBUF u_iobuf_din (
        .IO (chip_din[gi]),
        .O  (data_in_from_chip[gi]),
        .I  (data_out_to_chip[gi]),
        .T  (~chip_wr_en)
      );
    end
  endgenerate

endmodule
