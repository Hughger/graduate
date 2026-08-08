/*
教学用双口SRAM Testbench（TSMC 28HPCP U-HDDP SRAM 模型）

要点概览：
- 端口极性：`CEBA/CEBB`、`WEBA/WEBB`、`BWEBA/BWEBB` 均为低有效；`BWE=0` 表示写该位，`1` 表示不写。
- 双端口并行：本例中 A 口只写、B 口只读，同时访问不同地址，体现真正并行；如需同址读写，请参考 `AWT` 写透/旁路策略与模型文档。
- 模型时序限制：模型要求控制/地址/数据不要在 `CLK` 正沿瞬时切换，否则可能输出 `X/Z` 或报 `$setup/$hold` 告警。
- 系统式激励冲突与解决：SoC 中寄存器通常在正沿翻转，会与模型限制冲突。本 TB 采用“仅仿真”的微偏移技巧：
  1) 给 SRAM 实例的时钟引入极小延迟：`assign #0.3 CLK_mem = CLK;` 并让实例接 `CLK_mem`。这样系统信号仍在正沿变化，但模型看到的正沿略晚（本例 300ps），满足其建立/保持时间（曾见到 ~121ps 要求）。
  2) 若仍有告警，可略调偏移值，或对个别输入（如 `CEB/WEB/AA/AB/DA`）加极小线延迟。以上做法仅影响仿真，不影响综合/时序。
- 写入节奏（第二阶段）：A 口写脉冲宽度 1 个时钟，写一次后空 2 个时钟再写下一次；B 口每个时钟读先前写入的地址，验证双口并行正确性。
- 打印与波形：通过 `$display` 打印每次 A 写与 B 读的地址/数据；波形输出为 `tb_sram.fsdb`，便于教学展示。
- 可选仿真宏：如 `+define+TSMC_CM_UNIT_DELAY`、`+no_warning`、`+TSMC_INITIALIZE_MEM` 等，请参考厂商 `.v/.ds` 文档。

文件流程：
- 第一阶段：A 口写地址 `0..15`（全写）。
- 第二阶段：B 口按 `0..15` 依次读，A 口并行写 `16..31`，写脉冲 1clk，间隔 2clk。
*/

`timescale 1ns/1ps

module tb_sram;

    // 时钟和复位
    reg CLK;
    // 给SRAM模型的仿真微偏移时钟（100ps），避免在上升沿同时切换控制/地址/数据
    wire CLK_mem;

    // 端口A信号
    reg [1:0] RTSEL;
    reg [1:0] WTSEL;
    reg [1:0] PTSEL;
    reg [4:0] AA;      // 地址A (5位，对应32个地址)
    reg [127:0] DA;    // 数据输入A (128位)
    reg [127:0] BWEBA; // 位写使能A (128位)
    reg WEBA;          // 写使能A
    reg CEBA;          // 片选A
    wire [127:0] QA;   // 数据输出A (128位)

    // 端口B信号
    reg [4:0] AB;      // 地址B (5位)
    reg [127:0] DB;    // 数据输入B (128位)
    reg [127:0] BWEBB; // 位写使能B (128位)
    reg WEBB;          // 写使能B
    reg CEBB;          // 片选B
    reg AWT;
    wire [127:0] QB;   // 数据输出B (128位)

    // 实例化SRAM模块
    TSDN28HPCPUHDB32X128M4MWA u_sram (
        .RTSEL(RTSEL),
        .WTSEL(WTSEL),
        .PTSEL(PTSEL),
        .AA(AA),
        .DA(DA),
        .BWEBA(BWEBA),
        .WEBA(WEBA),
        .CEBA(CEBA),
        .CLK(CLK_mem),
        .AB(AB),
        .DB(DB),
        .BWEBB(BWEBB),
        .WEBB(WEBB),
        .CEBB(CEBB),
        .AWT(AWT),
        .QA(QA),
        .QB(QB)
    );

    // 时钟生成
    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK; // 10ns周期，100MHz
    end

    // 仅仿真用途：将SRAM实例的CLK相对系统CLK延迟0.3ns（timescale 1ns/1ps）
    // 确保控制/地址/数据在SRAM看到的上升沿之前已满足建立/保持时间
    assign #0.3 CLK_mem = CLK;

    // 测试向量
    initial begin
        // 初始化信号
        RTSEL = 2'b00;
        WTSEL = 2'b00;
        PTSEL = 2'b00;
        AA = 5'b0;
        DA = 128'b0;
        BWEBA = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // 全1=不写任何位（低有效）
        WEBA = 1'b1;  // 低有效写使能，1=读/非写
        CEBA = 1'b1;  // 低有效片选，1=禁用
        AB = 5'b0;
        DB = 128'b0;
        BWEBB = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // 全1=不写任何位（低有效）
        WEBB = 1'b1;  // 低有效写使能，1=读/非写
        CEBB = 1'b1;  // 低有效片选，默认禁用端口B
        AWT = 1'b0;

        // 等待几个时钟周期
        #100;

        $display("开始SRAM测试...");

        // === 第一阶段：使用端口A写前16个地址 ===
        $display("=== 使用端口A写前16个地址 ===");
        CEBA = 1'b0;  // 低有效片选，拉低使能
        WEBA = 1'b0;  // 低有效写使能，拉低=写
        BWEBA = 128'h0; // 低有效位写使能，0=写该位（全写）

        for (integer i = 0; i < 16; i = i + 1) begin
            // 在时钟上升沿更新地址和数据
            @(posedge CLK);
            AA = i;
            DA = {112'h0, 16'hABCD + i};  // 写入测试数据
            $display("写地址 %0d: 数据 = %h", i, DA);
            #1;
        end

        // 关闭写使能
        @(posedge CLK);
        WEBA = 1'b1; // 置为读/非写
        CEBA = 1'b1; // 关闭片选

        // 等待几个周期让数据稳定
        #50;

        // === 第二阶段：使用端口B读前16个地址（A口只写，B口只读） ===
        $display("=== 使用端口B读前16个地址（同时A口继续写其他地址） ===");
        @(posedge CLK);
        CEBA = 1'b1;  // A口初始保持非使能
        WEBA = 1'b1;  // A口初始非写
        BWEBA = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // A口初始不写
        CEBB = 1'b0;  // 低有效片选，启用端口B
        WEBB = 1'b1;  // 低有效写使能，高=读
        BWEBB = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // B口不写

        for (integer i = 0; i < 16; i = i + 1) begin
            // 在时钟上升沿同时更新：B口读地址、A口写脉冲地址/数据/控制
            @(posedge CLK);
            AB   = i;                 // B口读取先前写入的0..15
            AA   = i + 16;            // A口写入16..31
            DA   = {112'h0, 16'hC000 + i};
            CEBA = 1'b0;              // 低有效片选：A口使能
            WEBA = 1'b0;              // 低有效写使能：写
            BWEBA= 128'h0;            // 低有效位写使能：全写

            // 给模型一个极小时间稳定，随后在SRAM的延迟上升沿采样
            #2; // 等待数据输出稳定后检查B口读
            $display("B口读地址 %0d: 数据 = %h, 期望 = %h", i, QB, {112'h0, 16'hABCD + i});
            $display("A口写地址 %0d: 数据 = %h", i+16, {112'h0, 16'hC000 + i});
            if (QB !== {112'h0, 16'hABCD + i}) begin
                $display("ERROR: B口 地址 %0d 数据不匹配!", i);
            end else begin
                $display("SUCCESS: B口 地址 %0d 数据匹配!", i);
            end

            // 在下一个上升沿撤销A口写（写脉冲持续正好1个clk）
            @(posedge CLK);
            WEBA  = 1'b1;             // 非写
            CEBA  = 1'b1;             // 关闭片选
            BWEBA = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // 不写

            // 额外空两个上升沿再进行下一次写
            @(posedge CLK);
            @(posedge CLK);
        end

        // 关闭B口片选，同时A口保持使能但切回非写
        CEBB = 1'b1;
        @(posedge CLK);
        WEBA = 1'b1; // A口非写
        BWEBA = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // 不写任何位

        // 等待几个周期
        #50;

        $display("SRAM测试完成!");
        $finish;
    end

    // 波形输出
    initial begin
        $fsdbDumpfile("tb_sram.fsdb");
        $fsdbDumpvars(0, tb_sram);
    end

endmodule
