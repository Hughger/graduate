# Source State at Extraction

本文件记录 `graduate` 于 2026-08-07 从现有工作树提取时的来源状态。它用于保留溯源信息，不表示这些改动已经审核或形成正式 release。

## 1. 加速器主工程

- 来源：`e203_asic_c/e203_asic_c/flood_accelerator`
- Git 分支：`asic_flood`
- HEAD：`482970e`（2026-05-28，`Add c/demo/common directory`）
- 与远端关系：`asic_flood...origin/asic_flood [ahead 1]`
- 原 `.git` 目录：约 1.363 GiB，未复制

提取时已修改、且已复制其工作树内容：

- `c/axi_test/Makefile`
- `c/axi_test/mac_test_tb2.c`
- `src/main/scala/Machine/MacMachineWrapper.scala`
- `src/main/scala/core/CIMcore.scala`

提取时未跟踪、且已复制的主要工程文件：

- `CNN_Accelerator_Deployment_Plan.md`
- `FMC_Address_Decode_Table.md`
- `c/axi_test/cnn_demo.c`
- `c/axi_test/cnn_multilayer.c`
- `c/axi_test/cnn_multilayer.h`
- `c/axi_test/cnn_perf.c`
- `c/axi_test/cnn_perf.h`
- `c/demo/lenet/lenet_config.h`
- `chip_test_0601.v`、`chip_test_0602.v`、`chip_test_0603.v`
- `system_chip_test.v`
- `fpga/AXKU15` 下新增的约束和芯片测试 RTL
- `tests/common/test_framework.h`、`tests/unit/test_conv.c`
- `tools/data_gen/image_preprocess.py`、`tools/quantization/quantize_weights.py`
- `团队协作指南.md`

未复制的未跟踪内容包括完整内嵌 SDK、`fpga.zip`、`src/main/scala.zip`、HPCA 调研模板和部分旧任务草稿。当前候选执行计划与任务拆分已单独复制到 `planning`。

## 2. hbird-sdk 覆盖层

- 来源：`e203_asic_c/e203_asic_c/flood_accelerator/hybird_sdk/hbird-sdk`
- 远端：`https://gitee.com/riscv-mcu/hbird-sdk.git`
- 分支：`master`
- HEAD：`321ecb29f64197748a4a4bdb9f42c0961cb8145b`
- 与远端关系：`master...origin/master [ahead 2]`

覆盖层包含以下本地状态：

- 已修改：`application/custom/axi_test/Makefile`
- 已修改：`application/custom/axi_test/link.ld`
- 已修改：`application/custom/axi_test/main.c`
- 已修改：`setup.bat`
- 未跟踪：`application/custom/axi_test/tte.py`（提取时为空文件）
- 未跟踪：`软件编译工具及流程解读.md`
- 一并保留：`application/custom/axi_test/README.md` 与 `startup.S`

SDK 构建生成物 `axi_test.bin/.elf/.hex/.map/.verilog` 和 `.o` 未复制。

## 3. Vivado 芯片测试工程

- 来源：`chip_test/chip_test`
- 入口：`system_chip_test.xpr`
- 保留：`system_chip_test.srcs` 中的 XDC、XCI、RTL、C、MEM 和初始化数据
- 排除：`.Xil`、cache、runs、gen、hw、sim、ip_user_files、`.exe`、`.dcp` 和 `result_*.txt`

原工程已有多个 bitstream/ILA 输出，但未复制到本维护副本。需要可追溯产物时，应从 `graduate` 的明确提交重新生成并放入独立 artifacts 目录。

## 4. 数据与文档来源

- 板级接口：根目录 `引脚列表.xlsx`，以及 `流片` 下的连接器、转接板和 PCB 约束表。
- 验证计划：`论文/测试方案` 下 4 份 Markdown。
- 测试网络表：`测试` 下 3 份 CSV。
- 规划文档：主工程中的 `Project_Execution_Plan_v3.md`、`Week1_Code_Tasks_v2.md`、`Week1_Detailed_Tasks.md`。
- `转接板引脚.csv` 和 3 份 `Fan_Out_Netlabel` CSV 使用 UTF-16LE（带 BOM）；这是来源文件的 Excel 兼容编码，复制时保持不变。其余抽查的文本文件为有效 UTF-8。

## 5. 重要限制

1. FLOOD 根目录本身不是 Git 仓库。
2. 本副本包含来源工作树的未提交内容，但不包含其 Git 索引和历史。
3. 两份 hbird-sdk 在来源目录中表现为高度一致的工作副本；本次只从主加速器内嵌副本提取 overlay。
4. 本文件记录的是提取时事实，不替代代码审查、功能回归或 release 审核。
