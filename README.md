# FLOOD Accelerator — Graduate Workspace

`graduate` 是从现有 FLOOD 工作目录中提取的加速器维护副本，建立于 2026-08-07。原文件均保留在原位；这里不包含原仓库的 Git 历史、完整 SDK 工具链、IDE/综合缓存或历史压缩包。

> 当前内容来自带有本地提交和未提交改动的工作树，不是正式 release。首次提交或对外分发前，请先阅读 [SOURCE_STATE.md](./SOURCE_STATE.md)。

## 当前研究方向（2026-08-08）

本工作区当前以 **Stable Diffusion 1.5 U-Net ResNetBlock 的 AXKU15 FPGA 原型**为研究主线，复用 FLOOD 的 INT8 计算结构，重点研究片上驻留、算子融合和双缓冲数据流。目标不是一次性硬化完整 SD，而是先完成可验证、可综合、可上板的真实 ResNetBlock 加速器。

- 正式设计规格：[SD1.5 ResNetBlock 加速器设计](./docs/superpowers/specs/2026-08-08-sd15-resnetblock-accelerator-design.md)
- 实施计划：[SD1.5 ResNetBlock AXKU15 加速器实施计划](./docs/superpowers/plans/2026-08-08-sd15-resnetblock-accelerator-implementation.md)
- 板卡用户手册：[AXKU15 V1.2 用户手册](./AXKU15_V1.2_UG.pdf)
- 板级原理图：[AXKU15 扩展板原理图](./01_原理图PCB结构图等硬件资料/AXKU15原理图V1.0.pdf)、[ACKU15 核心板原理图](./01_原理图PCB结构图等硬件资料/ACKU15核心板.pdf)

现有 CNN Demo、MacMachine 和六周执行计划继续保留，作为 FLOOD 基线、接口审计和回归验证资料；其历史参数与任务优先级不覆盖上述正式设计规格。

## 目录

```text
graduate/
├─ accelerator/                  # FLOOD 加速器主体，保留原工程相对结构
│  ├─ src/                       # Chisel/Scala、Python、C 辅助代码与测试
│  ├─ rtl/                       # E203/FLOOD RTL
│  ├─ c/                         # APB/AXI/UART 测试与 CNN 示例
│  ├─ tb/                        # Verilog testbench 与测试向量
│  ├─ tests/                     # 单元/公共测试框架
│  ├─ tools/                     # 量化与数据生成工具
│  ├─ vsim/                      # 仿真入口
│  ├─ fpga/                      # FPGA 源码、约束和构建脚本
│  ├─ doc/                       # Sphinx/参考文档
│  └─ pics/                      # README/文档图片
├─ integrations/
│  ├─ chip-test-vivado/          # 精简后的 Vivado 芯片测试工程
│  ├─ hbird-sdk-overlay/         # 需要应用到指定 hbird-sdk 的本地定制层
│  └─ board-interface/           # 引脚、连接器、转接板和 PCB 约束输入
├─ validation/
│  ├─ plans/                     # HPCA/PyTorchSim 测试方案与结果清单
│  └─ netlists/                  # Fan-out 网络表
├─ docs/superpowers/{specs,plans}/ # 正式设计规格与实施计划
├─ 01_原理图PCB结构图等硬件资料/ # AXKU15/ACKU15 原理图与结构资料
└─ planning/                     # 历史计划与后续任务拆分
```

## 主要入口

- 当前正式设计规格：[docs/superpowers/specs/2026-08-08-sd15-resnetblock-accelerator-design.md](./docs/superpowers/specs/2026-08-08-sd15-resnetblock-accelerator-design.md)
- 当前实施计划：[docs/superpowers/plans/2026-08-08-sd15-resnetblock-accelerator-implementation.md](./docs/superpowers/plans/2026-08-08-sd15-resnetblock-accelerator-implementation.md)
- 加速器说明：[accelerator/README.md](./accelerator/README.md)
- Chisel/Scala 主源码：[accelerator/src/main](./accelerator/src/main/)
- RTL：[accelerator/rtl/e203](./accelerator/rtl/e203/)
- AXI 软件测试：[accelerator/c/axi_test](./accelerator/c/axi_test/)
- 仿真入口：[accelerator/vsim/README.md](./accelerator/vsim/README.md)
- FPGA 工程：[accelerator/fpga/README.md](./accelerator/fpga/README.md)
- AXKU15 集成：[accelerator/fpga/AXKU15](./accelerator/fpga/AXKU15/)
- Vivado 芯片测试工程：[integrations/chip-test-vivado/system_chip_test.xpr](./integrations/chip-test-vivado/system_chip_test.xpr)
- SDK 覆盖层：[integrations/hbird-sdk-overlay](./integrations/hbird-sdk-overlay/)
- PyTorchSim 测试执行方案：[validation/plans/FLOOD_PyTorchSim测试执行方案.md](./validation/plans/FLOOD_PyTorchSim测试执行方案.md)

## 使用方式

### 1. 加速器 RTL/Chisel

进入 `accelerator`，先阅读原工程 README、`build.sbt`、`e203_core.core` 和 `e203_soc.core`。本副本保留了当前工作树中的 Scala、RTL、C、测试和工具文件，但没有复制原来的 `.git` 和 SBT/IDE 缓存。

### 2. 软件与 SDK

完整 hbird-sdk 未复制。请准备远端 `https://gitee.com/riscv-mcu/hbird-sdk.git` 在提交 `321ecb29f64197748a4a4bdb9f42c0961cb8145b` 附近的工作树，再审查并应用 `integrations/hbird-sdk-overlay/hbird-sdk` 中的覆盖文件。覆盖层包含当前本地修改，不能无审查覆盖到其他 SDK 版本。

### 3. FPGA/Vivado

`accelerator/fpga` 保留 FPGA 源码、约束和脚本，但删除了两个约 26.1 MB 的预生成 MCS。`integrations/chip-test-vivado` 保留 `.xpr`、约束、XCI、RTL、C 和初始化数据，未复制 Vivado cache/runs、可执行文件、DCP 和结果文本。工程原目录显示使用过 Vivado 2022.2；在其他版本打开时先备份并检查升级提示。

### 4. 验证

`validation/plans` 是测试目标和执行流程，`validation/netlists` 是板级网络数据。新增实验结果时建议按“日期—配置—提交—结果”命名，并记录对应 RTL、软件、bitstream 和模型版本。

## 维护规则

1. 将 `graduate` 视为独立维护副本；不要假设它会与原目录自动同步。
2. 首次建立 Git 历史前，先确认 `SOURCE_STATE.md` 中列出的本地改动均已纳入或明确放弃。
3. 不提交工具链、虚拟机、Vivado cache/runs、SBT target、波形和临时压缩包。
4. 生成物放入独立 `artifacts/<date-or-revision>/`，并附提交号、工具版本和校验值。
5. SDK 修改优先以 overlay/patch 维护，不再复制整套 3.47 GiB 工具链。
6. 对外发布时另建 release 包；本目录本身不是 PCB/SMT 或 FPGA 生产交付包。

## 本次未复制

- 所有 `.git` 历史及 Git 对象。
- 完整 `hybird_sdk`/`NUCLEI_TOOL_ROOT`。
- Vivado `.Xil`、cache、runs、gen、hw、sim、IP user files 和既有 bitstream。
- `fpga.zip`、`src/main/scala.zip`、根目录工程压缩包及虚拟机/IDE 环境。
- 两个 `prebuilt_mcs/system.mcs`。
- HPCA 论文调研模板、旧版周任务、旧执行计划和与加速器维护无直接关系的历史材料。

