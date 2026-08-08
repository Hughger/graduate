module tb_mac_asic;

  //----------------------1.时钟复位 -------------
  reg clk;
  reg rst_n;
  initial begin
    clk = 1'b0;
    forever #1 clk = ~clk; // 100MHz
  end
  initial begin
    rst_n = 1'b0;
    repeat(10) @(posedge clk);
    rst_n = 1'b1;
  end
  //---------------------------------------------

  //----------------------2.例化DUT -------------
  // 统一总线（连接顶层与适配器）
  wire [15:0] addr;
  wire        en;
  wire        wr_en;     // 1=写; 0=读
  wire [63:0] dinout;    // 与DUT共用的双向总线（驱动交由适配器）

  // 中断
  wire mac_done;
  wire mac_err;

  // DUT 顶层（使用 wrapper，将 inout PAD 与内核 din/dout 适配）
  Mac_ASIC_top_wrapper dut (
    .clk  (clk),
    .rst_n(rst_n),
    .dinout(dinout),
    .addr (addr),
    .en   (en),
    .wr_en(wr_en),
    .macMachineDone_interrupt (mac_done),
    .macMachineerror_interrupt(mac_err)
  );
  //---------------------------------------------

  // 便利宏：选择块（与 design_ram_mux.v 中 decode3BIT 对齐）
  localparam [2:0] SEL_RAM0 = 3'b000; // 0x5000_xxxx（本地16b地址仅取[15:13]）
  localparam [2:0] SEL_RAM1 = 3'b001; // 0x5001
  localparam [2:0] SEL_RAM2 = 3'b010; // 0x5002
  localparam [2:0] SEL_RAM3 = 3'b011; // 0x5003
  localparam [2:0] SEL_RAM4 = 3'b100; // 0x5004
  localparam [2:0] SEL_RAM5 = 3'b101; // 0x5005
  localparam [2:0] SEL_CTRL = 3'b110; // 0x5006 控制

  // ----------------------3.例化适配器--------------
  // 适配器将 testbench 风格的 cfg/feature/weight/output 读写映射到统一总线
  // 适配器内部已处理 bus 三态驱动，tb 不再直接驱动 dinout
  wire        tb_cfg_en;
  wire [31:0] tb_cfg_addr;
  wire [31:0] tb_cfg_data;

  wire        tb_feat_en;
  wire [12:0] tb_feat_addr;
  wire [255:0] tb_feat_data;

  wire        tb_wping_en;
  wire [12:0] tb_wping_addr;
  wire [255:0] tb_wping_data;
  wire        tb_wpong_en;
  wire [12:0] tb_wpong_addr;
  wire [255:0] tb_wpong_data;

  wire        wping_re;
  wire [24:0] wping_raddr;
  wire [255:0] wping_rdata;
  wire        wpong_re;
  wire [24:0] wpong_raddr;
  wire [255:0] wpong_rdata;

  wire        oping_we;
  wire [12:0] oping_waddr;
  wire [255:0] oping_wdata;
  reg         oping_re;
  reg  [12:0] oping_raddr;
  wire [255:0] oping_rdata;

  wire        opong_we;
  wire [12:0] opong_waddr;
  wire [255:0] opong_wdata;
  reg         opong_re;
  reg  [12:0] opong_raddr;
  wire [255:0] opong_rdata;

  wire        ojoint_we;
  wire [12:0] ojoint_waddr;
  wire [255:0] ojoint_wdata;
  wire        ojoint_re;
  wire [12:0] ojoint_raddr;
  wire [255:0] ojoint_rdata;

  wire        joint_we;
  wire [17:0] joint_waddr;
  wire [255:0] joint_wdata;
  wire        joint_re;
  wire [17:0] joint_raddr;
  wire [255:0] joint_rdata;

    // 多周期握手/有效信号
  wire adapter_busy;
  wire oping_rvalid;
  wire opong_rvalid;

  tb_cfg_feat_adapter u_adapter(
    .clock (clk),
    .reset (~rst_n),
    .bus_addr  (addr),
    .bus_en    (en),
    .bus_wr_en (wr_en),
    .bus_dinout(dinout),
    .busy      (adapter_busy),
    // cfg/feature
    .io_configBus_data (tb_cfg_data),
    .io_configBus_addr (tb_cfg_addr),
    .io_configBus_en   (tb_cfg_en),
    .io_featureMapBus_data(tb_feat_data),
    .io_featureMapBus_addr(tb_feat_addr),
    .io_featureMapBus_en  (tb_feat_en),
    // weights
    .io_weightSramWritePing_en  (tb_wping_en),
    .io_weightSramWritePing_addr(tb_wping_addr),
    .io_weightSramWritePing_data(tb_wping_data),
    .io_weightSramWritePong_en  (tb_wpong_en),
    .io_weightSramWritePong_addr(tb_wpong_addr),
    .io_weightSramWritePong_data(tb_wpong_data),
    // weights
    .io_weightSramReadPing_readEnable (wping_re),
    .io_weightSramReadPing_readAddress(wping_raddr),
    .io_weightSramReadPing_readData   (wping_rdata),
    .io_weightSramReadPong_readEnable (wpong_re),
    .io_weightSramReadPong_readAddress(wpong_raddr),
    .io_weightSramReadPong_readData   (wpong_rdata),
    // outputs
    .io_outputSramPing_writeEnable (oping_we),
    .io_outputSramPing_writeAddress(oping_waddr),
    .io_outputSramPing_writeData   (oping_wdata),
    .io_outputSramPing_readEnable  (oping_re),
    .io_outputSramPing_readAddress (oping_raddr),
    .io_outputSramPing_readData    (oping_rdata),
    .io_outputSramPing_readValid   (oping_rvalid),
    .io_outputSramPong_writeEnable (opong_we),
    .io_outputSramPong_writeAddress(opong_waddr),
    .io_outputSramPong_writeData   (opong_wdata),
    .io_outputSramPong_readEnable  (opong_re),
    .io_outputSramPong_readAddress (opong_raddr),
    .io_outputSramPong_readData    (opong_rdata),
    .io_outputSramPong_readValid   (opong_rvalid),
    // outputJoint / joint（占位）
    .io_outputJointSram_writeEnable (ojoint_we),
    .io_outputJointSram_writeAddress(ojoint_waddr),
    .io_outputJointSram_writeData   (ojoint_wdata),
    .io_outputJointSram_readEnable  (ojoint_re),
    .io_outputJointSram_readAddress (ojoint_raddr),
    .io_outputJointSram_readData    (ojoint_rdata),
    .io_jointSram_writeEnable (joint_we),
    .io_jointSram_writeAddress(joint_waddr),
    .io_jointSram_writeData   (joint_wdata),
    .io_jointSram_readEnable  (joint_re),
    .io_jointSram_readAddress (joint_raddr),
    .io_jointSram_readData    (joint_rdata)
  );
  //---------------------------------------------


  //----------------------4.定义参数 -------------
  // ========== 复制 testbench.v 的主流程：信号/任务在本文件就地定义并驱动适配器 ==========
  localparam integer CFG_DATAW = 32;
  localparam integer CFG_ADDRW = 32;
  // 统一与 wrapper/testbench_r32c32t16：feature 256bit 数据，13bit 地址
  localparam integer FEAT_DATAW = 256;
  localparam integer FEAT_ADDRW = 13;
  localparam integer OUTPUT_ADDR_WIDTH = 13; // 与顶层 RAM 索引保持 13 位
  localparam integer OUTBUF_DATAW = 256;
  localparam integer ID_WIDTH = 8;           // 来自 wrapper：addr[12:5]
  localparam integer ROW_ADDR_WIDTH = 5;     // addr[4:0]
  localparam integer CIN_IDX_WIDTH = 6;      // log2ceil(1024/32+1)=6
  localparam integer RES_COL_IDX_WIDTH = 5;  // log2ceil(768/32+1)=5
  localparam integer WORK_MODE_WIDTH = 3;
  localparam integer TRUNC_BITS_WIDTH = 4;
  localparam integer COUT_WIDTH = 5;
  localparam integer GROUP_SIZE_WIDTH = 4;   // tileSize=16
  localparam integer GROUP_NUM_WIDTH = 4;    // tileSize=16
  localparam integer K_WIDTH = 5;            // colSize=32
  localparam integer STRIDE_WIDTH = K_WIDTH;

`ifndef ROW_SIZE
  localparam integer ROW_SIZE = 32;
`else
  localparam integer ROW_SIZE = `ROW_SIZE;
`endif
`ifndef COL_SIZE
  localparam integer COL_SIZE = 32;
`else
  localparam integer COL_SIZE = `COL_SIZE;
`endif
`ifndef TILE_SIZE
  localparam integer TILE_SIZE = 16;
`else
  localparam integer TILE_SIZE = `TILE_SIZE;
`endif

`ifndef K_PARAM
  localparam integer K_PARAM = 3;
`else
  localparam integer K_PARAM = `K_PARAM;
`endif
`ifndef COUT_PARAM
  localparam integer COUT_PARAM = 2;
`else
  localparam integer COUT_PARAM = `COUT_PARAM;
`endif
`ifndef GROUP_SIZE_PARAM
  localparam integer GROUP_SIZE_PARAM = 2;
`else
  localparam integer GROUP_SIZE_PARAM = `GROUP_SIZE_PARAM;
`endif
`ifndef GROUP_NUM_PARAM
  localparam integer GROUP_NUM_PARAM = 8;
`else
  localparam integer GROUP_NUM_PARAM = `GROUP_NUM_PARAM;
`endif
`ifndef STRIDE_PARAM
  localparam integer STRIDE_PARAM = 2;
`else
  localparam integer STRIDE_PARAM = `STRIDE_PARAM;
`endif
`ifndef CIN_IDX_TOTAL
  localparam integer CIN_IDX_TOTAL = 2;
`else
  localparam integer CIN_IDX_TOTAL = `CIN_IDX_TOTAL;
`endif  
`ifndef RES_COL_TOTAL
  localparam integer RES_COL_TOTAL = 2;
`else
  localparam integer RES_COL_TOTAL = `RES_COL_TOTAL;
`endif
`ifndef RES_ROW_TOTAL
  localparam integer RES_ROW_TOTAL = 2;
`else
  localparam integer RES_ROW_TOTAL = `RES_ROW_TOTAL;
`endif
  //---------------------------------------------

  // DUT 兼容的 testbench 主体变量
  reg  [CFG_DATAW-1:0] cfg_data;
  reg  [CFG_ADDRW-1:0] cfg_addr;
  reg                   cfg_en;
  reg  [FEAT_DATAW-1:0] feature_data;
  reg  [FEAT_ADDRW-1:0] feature_addr;
  reg                   feature_en;

  reg  [255:0] wping_data;
  reg  [12:0]  wping_addr;
  reg           wping_en;
  reg  [255:0] wpong_data;
  reg  [12:0]  wpong_addr;
  reg           wpong_en;
  
  // 权重加载完成标志
  reg weights_loaded;

  // 绑定 testbench 风格信号到适配器
  assign tb_cfg_en   = cfg_en;
  assign tb_cfg_addr = cfg_addr;
  assign tb_cfg_data = cfg_data;
  assign tb_feat_en   = feature_en;
  assign tb_feat_addr = feature_addr;
  assign tb_feat_data = feature_data;
  assign tb_wping_en   = wping_en;
  assign tb_wping_addr = wping_addr;
  assign tb_wping_data = wping_data;
  assign tb_wpong_en   = wpong_en;
  assign tb_wpong_addr = wpong_addr;
  assign tb_wpong_data = wpong_data;

  // 以下信号直接与适配器线连
  assign wping_re   = 1'b0; // 由 DUT 驱动时适配器读取，这里为占位
  assign wping_raddr= {25{1'b0}};
  assign wpong_re   = 1'b0;
  assign wpong_raddr= {25{1'b0}};

  // 输出端口由适配器回传
  // 在打印时通过 force/release 方式驱动 re/addr 获取数据

  wire intr_done = mac_done;
  wire intr_error = mac_err;

  integer resolutionRowIdx, resolutionColIdx, cinIdx;

  initial begin
    $dumpfile("tb_mac_asic.vcd");
    $dumpvars(0, tb_mac_asic);
  end

  initial begin
    cfg_data = 0; cfg_addr = 0; cfg_en = 0;
    feature_data = 0; feature_addr = 0; feature_en = 0;
    weights_loaded = 0; // 初始化权重加载标志
    oping_re = 1'b0; oping_raddr = 13'd0;
    opong_re = 1'b0; opong_raddr = 13'd0;
    $display("[TB] Testbench initialized at time %0t", $time);
  end

  // 对齐 MacMachineWrapper 中的配置地址映射
  localparam [CFG_ADDRW-1:0] TILE_CONF_START    = 32'd0;    // 0x00..0x0F
  localparam [CFG_ADDRW-1:0] NOC_CONF_START     = 32'd16;   // 0x10..
  localparam [CFG_ADDRW-1:0] FSM_CONF_START_ID  = 32'd31;   // 0x1F normal
  localparam [CFG_ADDRW-1:0] FSM_CONF_END_ID    = 32'd32;   // 0x20 special
  // BN 配置ID区间（依据 Config.scala：2*tileSize+1 .. 2*tileSize+colSize）
  localparam [CFG_ADDRW-1:0] BN_CONF_START      = 32'd33;   // 2*16+1 = 33
  localparam [CFG_ADDRW-1:0] BN_CONF_END        = 32'd64;   // 2*16+32 = 64
  // 对齐 Config.scala：global=2*tileSize+colSize+2=66, run=+3=67, intr_fresh=+4=68（tileSize=16, colSize=32）
  localparam [CFG_ADDRW-1:0] GLOBAL_CONF_ID     = 32'd66;   // global
  localparam [CFG_ADDRW-1:0] RUN_PROCESS_ID     = 32'd67;   // run
  localparam [CFG_ADDRW-1:0] INTR_FRESH_ID      = 32'd68;   // intr fresh
  // SRAM控制寄存器地址（根据maxunit说明文档）
  localparam [CFG_ADDRW-1:0] SRAM_CTRL_ADDR     = 32'h50060000; // SRAM控制寄存器的Id

  task cfg_write(input [CFG_ADDRW-1:0] a, input [CFG_DATAW-1:0] d);
  begin
    // 等待适配器空闲后再发起
    while (adapter_busy) @(posedge clk);
    @(posedge clk);
    cfg_addr <= a;
    cfg_data <= d;
    cfg_en   <= 1'b1;
    $display("[CFG] Writing config: addr=0x%08x data=0x%08x", a, d);
    @(posedge clk);
    cfg_en   <= 1'b0;
    // 等待本次总线多拍访问完成
    while (adapter_busy) @(posedge clk);
  end
  endtask

  // SRAM控制切换task
  // 根据maxunit说明文档，SRAM控制寄存器地址0x5006_0000
  // 数据格式: {28'h0, ctrl_bits[3:0]}
  // ctrl_bits[0]: RAM2控制位 (权重SRAM 0)
  // ctrl_bits[1]: RAM3控制位 (权重SRAM 1)  
  // ctrl_bits[2]: RAM4控制位 (输出SRAM 0)
  // ctrl_bits[3]: RAM5控制位 (输出SRAM 1)
  // 0=AXI控制, 1=MAC Machine控制
  task set_sram_control(input weight_sram0_ctrl, input weight_sram1_ctrl, 
                        input output_sram0_ctrl, input output_sram1_ctrl);
  reg [CFG_DATAW-1:0] sram_ctrl_data;
  begin
    // 打包控制位：{28'h0, ctrl_bits[3:0]}
    sram_ctrl_data = {28'h0, output_sram1_ctrl, output_sram0_ctrl, 
                      weight_sram1_ctrl, weight_sram0_ctrl};
    
    $display("[TB] Setting SRAM control: weight_sram0=%0d, weight_sram1=%0d, output_sram0=%0d, output_sram1=%0d", 
             weight_sram0_ctrl, weight_sram1_ctrl, output_sram0_ctrl, output_sram1_ctrl);
    $display("[TB] SRAM control data: 0x%08x", sram_ctrl_data);
    
    cfg_write(SRAM_CTRL_ADDR, sram_ctrl_data);
  end
  endtask

  // features.hex 读取与推进（保持与原 testbench 一致）
  reg [RES_COL_TOTAL*FEAT_DATAW-1:0] feat_mem_global [0:(1<<FEAT_ADDRW)-1];
  integer f_feat, lines_feat, c;
  reg [1023:0] buf_feat;
  integer height_calc, width_calc, cin_calc, feature_lines_expect;
  initial begin
    @(posedge rst_n);
    // 先统计文件行数
    f_feat = $fopen("tb/features.hex", "r");
    if (f_feat) begin
      lines_feat = 0;
      while (!$feof(f_feat)) begin
        c = $fgets(buf_feat, f_feat);
        if (c != 0) lines_feat = lines_feat + 1;
      end
      // 如果文件为空则报错并停止
      if (lines_feat == 0) begin
        $display("[ERROR] features.hex is empty");
        $finish;
      end

      // 简要统计（同原 bench）
      height_calc = (TILE_SIZE / GROUP_SIZE_PARAM) * RES_ROW_TOTAL;
      width_calc  = COL_SIZE * RES_COL_TOTAL;
      cin_calc    = CIN_IDX_TOTAL * ROW_SIZE * GROUP_SIZE_PARAM;
      feature_lines_expect = height_calc * cin_calc;
      $display("[CHK] features.hex lines=%0d expect=%0d", lines_feat, feature_lines_expect);
    end
    
    // 读入特征数据
    $display("[TB] $readmemh -> feat_mem_global from features.hex");
    $readmemh("tb/features.hex", feat_mem_global);
    // 文件不存在则报错并停止
    if (!f_feat) begin
      $display("[ERROR] features.hex not found");
      $finish;
    end
    $fclose(f_feat);
  end

  // 权重数据存储（ping和pong）
  reg [255:0] weight_ping_mem [0:8191]; // 13位地址，支持8K个256bit权重
  // reg [255:0] weight_pong_mem [0:8191]; //暂时不使用pong
  integer f_wping, f_wpong, lines_wping, lines_wpong;
  reg [1023:0] buf_wping, buf_wpong;
  
  initial begin
    @(posedge rst_n);
    // 统计权重文件行数
    f_wping = $fopen("tb/weights_ping.hex", "r");
    if (f_wping) begin
      lines_wping = 0;
      while (!$feof(f_wping)) begin
        c = $fgets(buf_wping, f_wping);
        if (c != 0) lines_wping = lines_wping + 1;
      end
      $display("[CHK] weights_ping.hex lines=%0d", lines_wping);
      // 如果文件为空则报错并停止
      if (lines_wping == 0) begin
        $display("[ERROR] weights_ping.hex is empty");
        $finish;
      end
    end

    $display("[TB] $readmemh -> weight_ping_mem from weights_ping.hex");
    $readmemh("tb/weights_ping.hex", weight_ping_mem);
    // 文件不存在则报错并停止
    if (!f_wping) begin
      $display("[ERROR] weights_ping.hex not found");
      $finish;
    end
    // $display("[TB] $readmemh -> weight_pong_mem from weights_pong.hex"); //暂时不使用pong
    // $readmemh("tb/weights_pong.hex", weight_pong_mem);
    
    // 标记权重数据加载完成
    weights_loaded = 1'b1;
    $display("[TB] Weight data loading completed");
    $fclose(f_wping); //关闭文件
  end

  integer k, cout, groupSize, groupNum, stride;
  integer cinIdxTotal, resolutionColIdxTotal, resolutionRowIdxTotal;
  integer planeWorkMode;
  integer dataFlowMode, truncateBits, truncateEn;
  reg featurePingpongFlag, weightPingpongFlag, outputPingpongFlag, pingpongEnFlag;
  initial begin
    k = K_PARAM; cout = COUT_PARAM; groupSize = GROUP_SIZE_PARAM; groupNum = GROUP_NUM_PARAM; stride = STRIDE_PARAM;
    cinIdxTotal = CIN_IDX_TOTAL; resolutionColIdxTotal = RES_COL_TOTAL; resolutionRowIdxTotal = RES_ROW_TOTAL;
    featurePingpongFlag = 1'b0; weightPingpongFlag = 1'b0; outputPingpongFlag = 1'b0; pingpongEnFlag = 1'b0;
    planeWorkMode = 0; dataFlowMode = 0; truncateBits = 0; truncateEn = 0;
    $display("[TB] Parameters initialized: k=%0d cout=%0d groupSize=%0d groupNum=%0d stride=%0d", 
             k, cout, groupSize, groupNum, stride);
    $display("[TB] Resolution: cinIdxTotal=%0d resolutionColIdxTotal=%0d resolutionRowIdxTotal=%0d", 
             cinIdxTotal, resolutionColIdxTotal, resolutionRowIdxTotal);
    $display("[TB] Pingpong flags: feature=%0d weight=%0d output=%0d pingpongEn=%0d", 
             featurePingpongFlag, weightPingpongFlag, outputPingpongFlag, pingpongEnFlag);
  end

  task config_tiles_and_noc;
  integer tileId; integer featureMapLine, writeId; integer nocId, upperGroup, lowerGroup, systolic, add, deliver;
  reg [CFG_DATAW-1:0] configData;
  reg [7:0] featureMapLine2; reg [2:0] workMode2; reg [7:0] writeId2; reg [4:0] kminus1_2;
  begin
    for (tileId = 0; tileId < TILE_SIZE; tileId = tileId + 1) begin
      featureMapLine = tileId / groupSize;
      writeId = (groupSize-1) - (tileId % groupSize);
      workMode2 = 0;
      begin
        featureMapLine2 = featureMapLine; writeId2 = writeId; kminus1_2 = (k-1);
        configData = { {(CFG_DATAW-21){1'b0}}, featureMapLine2, workMode2, writeId2, kminus1_2 };
      end
      cfg_write(TILE_CONF_START + tileId, configData);
    end
    for (nocId = 0; nocId < TILE_SIZE-1; nocId = nocId + 1) begin
      upperGroup = nocId / groupSize; lowerGroup = (nocId + 1) / groupSize;
      systolic = (upperGroup != lowerGroup); add = (upperGroup == lowerGroup); deliver = 1;
      configData = { {(CFG_DATAW-4){1'b0}}, (deliver?1'b1:1'b0), (systolic?1'b1:1'b0), (add?1'b1:1'b0), 1'b0 };
      cfg_write(NOC_CONF_START + nocId, configData);
    end
  end
  endtask

  task drive_feature_from_files(input integer cinIdx, input integer resolutionColIdx, input integer resolutionRowIdx);
  integer tileId, r; integer startRowCin, startRowHeight, startRow; integer addr_in_hex;
  begin
    $display("[FEAT] Starting feature drive: cinIdx=%0d, resolutionColIdx=%0d, resolutionRowIdx=%0d", 
             cinIdx, resolutionColIdx, resolutionRowIdx);
    for (tileId = 0; tileId < TILE_SIZE; tileId = tileId + 1) begin
      startRowCin = (cinIdx * (ROW_SIZE*groupSize) + ((groupSize-1 - (tileId % groupSize)) * ROW_SIZE)) * (groupNum * resolutionRowIdxTotal);
      startRowHeight = (resolutionRowIdx * groupNum) + (tileId / groupSize);
      startRow = startRowCin + startRowHeight;
      for (r = 0; r < ROW_SIZE; r = r + 1) begin
        addr_in_hex = startRow + r*groupNum*resolutionRowIdxTotal;
        // 等待适配器空闲后再发起下一行写
        while (adapter_busy) @(posedge clk);
        @(posedge clk);
        feature_addr <= {tileId[ID_WIDTH-1:0], r[ROW_ADDR_WIDTH-1:0]};
        feature_data <= feat_mem_global[addr_in_hex][resolutionColIdx*FEAT_DATAW +: FEAT_DATAW];
        feature_en   <= 1'b1;
        $display("[FEAT] Writing tile%0d row%0d: startRow=%0d, addr_in_hex=%0d, feature_addr=0x%04x, data[255:0]=0x%064x", 
                 tileId, r, startRow, addr_in_hex, {tileId[ID_WIDTH-1:0], r[ROW_ADDR_WIDTH-1:0]}, 
                 feat_mem_global[addr_in_hex][resolutionColIdx*FEAT_DATAW +: FEAT_DATAW]);
        @(posedge clk);
        feature_en   <= 1'b0;
        @(posedge clk);
        // 等待该256-bit写的四拍完成
        while (adapter_busy) @(posedge clk);
      end
    end
  end
  endtask

  // 权重写入task：从hex文件读取权重数据并写入到MAC_ASIC_TOP内部
  task drive_weights_from_files;
  integer addr, weight_count;
  begin
    $display("[WEIGHT] Starting weight drive from hex files");
    
    // 等待权重数据完全加载
    $display("[WEIGHT] Waiting for weight data to be loaded...");
    while (!weights_loaded) @(posedge clk); // 等待权重数据加载完成
    
    // 写入ping权重
    $display("[WEIGHT] Writing ping weights...");
    weight_count = 0;
    for (addr = 0; addr < cout*cinIdxTotal*groupSize*k*k; addr = addr + 1) begin
      // 等待适配器空闲后再发起写入
      while (adapter_busy) @(posedge clk);
      @(posedge clk);
      wping_addr <= addr[12:0];
      wping_data <= weight_ping_mem[addr];
      wping_en   <= 1'b1;
      $display("[WEIGHT] Writing ping addr=%0d data=0x%064x", addr, weight_ping_mem[addr]);
      @(posedge clk);
      wping_en   <= 1'b0;
      // 等待该256-bit写的四拍完成
      @(posedge clk);
      while (adapter_busy) @(posedge clk);
      weight_count = weight_count + 1;
    end
    $display("[WEIGHT] Ping weights written: %0d entries", weight_count);
    
    // // 写入pong权重(暂时只使用ping)
    // $display("[WEIGHT] Writing pong weights...");
    // weight_count = 0;
    // for (addr = 0; addr < 8192; addr = addr + 1) begin
    //   // 检查是否有有效数据（非全零）
    //   if (weight_pong_mem[addr] !== 256'b0) begin
    //     // 等待适配器空闲后再发起写入
    //     while (adapter_busy) @(posedge clk);
    //     @(posedge clk);
    //     wpong_addr <= addr[12:0];
    //     wpong_data <= weight_pong_mem[addr];
    //     wpong_en   <= 1'b1;
    //     $display("[WEIGHT] Writing pong addr=%0d data=0x%064x", addr, weight_pong_mem[addr]);
    //     @(posedge clk);
    //     wpong_en   <= 1'b0;
    //     // 等待该256-bit写的四拍完成
    //     while (adapter_busy) @(posedge clk);
    //     weight_count = weight_count + 1;
    //   end
    // end
    // $display("[WEIGHT] Pong weights written: %0d entries", weight_count);
    $display("[WEIGHT] Weight drive completed");
  end
  endtask

  task run_process(input integer cinIdx, input integer resolutionColIdx, input integer resolutionRowIdx);
  integer isFinalCinIdx, bnEn, actEn, poolEn, actionMode; reg [CFG_DATAW-1:0] normalConfig, specialConfig, globalConf;
  reg [STRIDE_WIDTH-1:0] stride_w; reg [COUT_WIDTH-1:0] cout_m1_w; reg [GROUP_NUM_WIDTH-1:0] groupNum_m1_w;
  reg [GROUP_SIZE_WIDTH-1:0] groupSize_m1_w; reg [K_WIDTH-1:0] k_m1_w;
  reg [TRUNC_BITS_WIDTH-1:0] trunc_w; reg [WORK_MODE_WIDTH-1:0] pwm_w;
  reg [RES_COL_IDX_WIDTH-1:0] rci_w; reg [CIN_IDX_WIDTH-1:0] cix_w;
  reg [4:0] action5;
  begin
    $display("[DEBUG] Starting run_process: cinIdx=%0d, resolutionColIdx=%0d, resolutionRowIdx=%0d", cinIdx, resolutionColIdx, resolutionRowIdx);
    
    // 切换到MAC控制：权重和输出SRAM由MAC Machine控制
    $display("[TB] Switching SRAM control to MAC Machine for processing");
    set_sram_control(1'b1, 1'b1, 1'b1, 1'b1); // weight_sram0, weight_sram1, output_sram0, output_sram1 = 1 (MAC)
    isFinalCinIdx = (cinIdx == (cinIdxTotal - 1)); bnEn = 0; actEn = 0; poolEn = 0;
    actionMode = (dataFlowMode << 0) | (isFinalCinIdx << 1) | (bnEn << 2) | (actEn << 3) | (poolEn << 4);
    begin
      stride_w = (stride-1) % (1 << STRIDE_WIDTH);
      cout_m1_w = (cout-1) % (1 << COUT_WIDTH);
      groupNum_m1_w = (groupNum-1) % (1 << GROUP_NUM_WIDTH);
      groupSize_m1_w = (groupSize-1) % (1 << GROUP_SIZE_WIDTH);
      k_m1_w = (k-1) % (1 << K_WIDTH);
      normalConfig = { {(CFG_DATAW-(STRIDE_WIDTH+COUT_WIDTH+GROUP_NUM_WIDTH+GROUP_SIZE_WIDTH+K_WIDTH)){1'b0}},
                       stride_w, cout_m1_w, groupNum_m1_w, groupSize_m1_w, k_m1_w };
    end
    cfg_write(FSM_CONF_START_ID, normalConfig);

    begin
      trunc_w = truncateBits % (1 << TRUNC_BITS_WIDTH);
      pwm_w   = planeWorkMode % (1 << WORK_MODE_WIDTH);
      rci_w   = resolutionColIdx % (1 << RES_COL_IDX_WIDTH);
      cix_w   = cinIdx % (1 << CIN_IDX_WIDTH);
      // Special: {truncateEn[1], truncateBits[TRUNC_BITS_WIDTH], workMode, colIdx, cinIdx}
      specialConfig = { (truncateEn ? 1'b1 : 1'b0), trunc_w, pwm_w, rci_w, cix_w };
    end
    cfg_write(FSM_CONF_END_ID, specialConfig);

    drive_feature_from_files(cinIdx, resolutionColIdx, resolutionRowIdx);

    featurePingpongFlag = ~featurePingpongFlag;
    if (pingpongEnFlag) weightPingpongFlag = ~weightPingpongFlag;
    if (pingpongEnFlag) outputPingpongFlag = ~outputPingpongFlag;
    begin
      action5 = actionMode % 32;
      globalConf = { featurePingpongFlag, weightPingpongFlag, outputPingpongFlag, {(CFG_DATAW-3-5){1'b0}}, action5 };
    end
    cfg_write(GLOBAL_CONF_ID, globalConf); // 配置全局参数

    cfg_write(RUN_PROCESS_ID, 32'h1); // 触发 run
    $display("[DEBUG] Started MAC process, waiting for interrupt...");
    wait (intr_done === 1'b1 || intr_error === 1'b1);
    
    if (intr_done === 1'b1 || intr_error === 1'b1) begin
      $display("[DEBUG] Interrupt received! intr_done=%b, intr_error=%b", intr_done, intr_error);
    end
    
    cfg_write(INTR_FRESH_ID, 32'h1); // 清中断
  end
  endtask

  task print_output_results;
    input integer resolutionColIdx; input integer resolutionRowIdx;
    integer file_handle; integer ch, row, addr, col; integer start_addr; integer rows_per_channel; integer addresses_per_channel;
    reg [OUTBUF_DATAW-1:0] line_data; reg signed [15:0] signed_data;
  begin
    // 切换回SRAM外部控制：输出SRAM由外部控制以便读取结果
    $display("[TB] Switching output SRAM control back to external for result reading");
    set_sram_control(1'b1, 1'b1, 1'b0, 1'b0); // weight_sram0, weight_sram1 = 1 (MAC), output_sram0, output_sram1 = 0 (AXI)

    $display("[OUT] Starting output results print: resolutionColIdx=%0d, resolutionRowIdx=%0d", 
             resolutionColIdx, resolutionRowIdx);
    $display("[OUT] Using %s SRAM, outputPingpongFlag=%0d", 
             outputPingpongFlag ? "pong" : "ping", outputPingpongFlag);
    file_handle = $fopen($sformatf("tb/actual_output_results_r%d_c%d.csv", resolutionRowIdx, resolutionColIdx), "w");
    // 如果文件打开失败，则报错
    if (file_handle == 0) begin
      $display("[ERROR] Cannot open file");
      $finish;
    end
    rows_per_channel = groupNum; addresses_per_channel = rows_per_channel;
    $display("[OUT] Parameters: cout=%0d, groupNum=%0d, rows_per_channel=%0d", 
             cout, groupNum, rows_per_channel);
    for (ch = 0; ch < cout; ch = ch + 1) begin
      start_addr = ch * addresses_per_channel;
      $display("[OUT] Processing channel %0d, start_addr=%0d", ch, start_addr);
      for (row = 0; row < rows_per_channel; row = row + 1) begin
        addr = start_addr + row;
        if (!outputPingpongFlag) begin
          // 等待适配器空闲，确保进入 IDLE 再发起下一次读；再多打一拍保证采样窗口
          while (adapter_busy) @(posedge clk);
          @(posedge clk);
          // 发起两拍读使能，地址稳定两拍
          oping_raddr <= addr[12:0];
          oping_re <= 1'b1;
          @(posedge clk);
          oping_re <= 1'b1;
          @(posedge clk);
          oping_re <= 1'b0;
          // 等待数据有效再读取整行
          while (!oping_rvalid) @(posedge clk);
          line_data = oping_rdata;
          // 将256bit数据展开为32维度向量并打印
          $write("[OUT] Read ping addr=%0d data=0x%064x [", addr, line_data);
          begin : print_ping_data
            integer vi;
            for (vi = 0; vi < COL_SIZE; vi = vi + 1) begin
              if (vi > 0) $write(",");
              $write("%0d", $signed(line_data[vi*8 +: 8]));
            end
          end
          $write("]\n");
          for (col = 0; col < COL_SIZE; col = col + 1) begin
            if (col > 0) $fwrite(file_handle, ",");
            signed_data = line_data[col*8 +: 8];
            $fwrite(file_handle, "%0d", signed_data);
          end
          ///////////////////////////////
        end else begin
          while (adapter_busy) @(posedge clk);
          @(posedge clk);
          opong_raddr <= addr[12:0];
          opong_re <= 1'b1;
          @(posedge clk);
          opong_re <= 1'b1;
          @(posedge clk);
          opong_re <= 1'b0;
          while (!opong_rvalid) @(posedge clk);
          line_data = opong_rdata;
          // 将256bit数据展开为32维度向量并打印
          $write("[OUT] Read pong addr=%0d data=0x%064x [", addr, line_data);
          begin : print_pong_data
            integer vi;
            for (vi = 0; vi < COL_SIZE; vi = vi + 1) begin
              if (vi > 0) $write(",");
              $write("%0d", $signed(line_data[vi*8 +: 8]));
            end
          end
          $write("]\n");
          for (col = 0; col < COL_SIZE; col = col + 1) begin
            if (col > 0) $fwrite(file_handle, ",");
            signed_data = line_data[col*8 +: 8];
            $fwrite(file_handle, "%0d", signed_data);
          end
          
        end
        $fwrite(file_handle, "\n");
        // 读完一行后插入一拍空闲，避免下一次读与适配器内部节拍冲突
        @(posedge clk);
      end
      if (ch < cout) $fwrite(file_handle, "\n");
    end
    $fclose(file_handle);
    $display("[OUT] Output results written to file for resolutionColIdx=%0d, resolutionRowIdx=%0d", 
             resolutionColIdx, resolutionRowIdx);
  end
  endtask

  // 全局动态超时看门狗（对齐 testbench_r32c32t16）
  integer watchdog_counter;
  integer watchdog_limit_weight;
  integer watchdog_limit_feature;
  integer watchdog_limit;
  reg prev_cfg_en;
  reg prev_intr_done;

  always @* begin
    watchdog_limit_weight = 4 * cout * k * k * groupSize; // 权重数据写入超时
    watchdog_limit_feature = TILE_SIZE * ROW_SIZE * COL_SIZE; // 特征数据写入超时
    watchdog_limit = (watchdog_limit_weight > watchdog_limit_feature) ? watchdog_limit_weight : watchdog_limit_feature;
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      watchdog_counter <= 0;
      prev_cfg_en      <= 1'b0;
      prev_intr_done   <= 1'b0;
    end else begin
      if ((cfg_en & ~prev_cfg_en) || (intr_done & ~prev_intr_done)) begin
        watchdog_counter <= 0;
      end else begin
        watchdog_counter <= watchdog_counter + 1;
      end
      if (watchdog_counter >= watchdog_limit) begin
        $display("[ERROR][WDOG] Global timeout reached: counter=%0d limit=%0d (4*cout*k*k*groupSize*10)", watchdog_counter, watchdog_limit);
        $finish;
      end
      prev_cfg_en    <= cfg_en;
      prev_intr_done <= intr_done;
    end
  end

  initial begin : main_loop
    @(posedge rst_n);
    
    // 初始化SRAM控制：所有SRAM切换到外部控制（AXI控制）
    $display("[TB] Initializing SRAM control: all SRAMs under external (AXI) control");
    set_sram_control(1'b0, 1'b0, 1'b0, 1'b0); // weight_sram0, weight_sram1, output_sram0, output_sram1 = 0 (AXI)
    
    config_tiles_and_noc();
    
    // 权重写入：在开始处理前先写入权重数据
    $display("[TB] Loading weights into MAC_ASIC_TOP...");
    drive_weights_from_files();
    
    for (resolutionRowIdx = 0; resolutionRowIdx < RES_ROW_TOTAL; resolutionRowIdx = resolutionRowIdx + 1) begin
      for (resolutionColIdx = 0; resolutionColIdx < RES_COL_TOTAL; resolutionColIdx = resolutionColIdx + 1) begin
        if (resolutionRowIdx == 0) begin
          if (resolutionColIdx == 0) planeWorkMode = 0; else planeWorkMode = 4;
        end else begin
          if (resolutionColIdx == 0) planeWorkMode = 1; else planeWorkMode = 2;
        end
        run_process(0, resolutionColIdx, resolutionRowIdx);
        planeWorkMode = 3;
        for (cinIdx = 1; cinIdx < CIN_IDX_TOTAL; cinIdx = cinIdx + 1) begin
          run_process(cinIdx, resolutionColIdx, resolutionRowIdx);
        end
        print_output_results(resolutionColIdx, resolutionRowIdx);
        if (intr_error) disable main_loop;
      end
    end
    $display("[TB] Testbench completed at time %0t", $time);
    repeat(50) @(posedge clk);
    $display("[INFO] Simulation completed successfully.");
    $finish;
  end

  // ========== 运行期信号打印（便于调试） ==========
  // 记录中断沿
  reg mac_done_q, mac_err_q;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mac_done_q <= 1'b0;
      mac_err_q  <= 1'b0;
    end else begin
      if (mac_done & ~mac_done_q) $display("[INTR] done=1 at time %0t", $time);
      if (mac_err  & ~mac_err_q ) $display("[INTR] error=1 at time %0t", $time);
      mac_done_q <= mac_done;
      mac_err_q  <= mac_err;
    end
  end

  // 权重读请求打印（地址/端口）
  always @(posedge clk) begin
    if (wping_re) $display("[WREAD] ping  addr=%0d data=0x%064x", wping_raddr, wping_rdata);
    if (wpong_re) $display("[WREAD] pong  addr=%0d data=0x%064x", wpong_raddr, wpong_rdata);
  end

  // 输出SRAM写入打印
  always @(posedge clk) begin
    if (oping_we)  $display("[OWR]   ping  addr=%0d data=0x%064x", oping_waddr, oping_wdata);
    if (opong_we)  $display("[OWR]   pong  addr=%0d data=0x%064x", opong_waddr, opong_wdata);
    if (ojoint_we) $display("[OWR]   jointO addr=%0d data=0x%064x", ojoint_waddr, ojoint_wdata);
    if (joint_we)  $display("[OWR]   joint  addr=%0d data=0x%064x", joint_waddr, joint_wdata);
  end

  // 适配器状态打印
  always @(posedge clk) begin
    if (adapter_busy) $display("[ADPT] Adapter busy at time %0t", $time);
  end

  // 配置写入状态打印
  always @(posedge clk) begin
    if (cfg_en) $display("[CFG] Config enable: addr=0x%08x data=0x%08x at time %0t", cfg_addr, cfg_data, $time);
  end

  // 特征写入状态打印
  always @(posedge clk) begin
    if (feature_en) $display("[FEAT] Feature enable: addr=0x%04x data[255:0]=0x%064x at time %0t", 
                             feature_addr, feature_data, $time);
  end

endmodule


