# 基于 FLOOD 与 AXKU15 的 Stable Diffusion 1.5 ResNetBlock 加速器设计

## 文档状态

- 日期：2026-08-08
- 状态：正式规格已于 2026-08-08 确认；实施计划已建立，尚未开始 RTL 修改
- 目标：研究生毕业设计与 AXKU15 FPGA 原型
- 设计主线：以片上驻留、跨算子融合和双缓冲调度降低 Stable Diffusion U-Net ResNetBlock 的 DDR 访问

本文档是当前 Diffusion 加速器研究方向的正式设计规格。原 FLOOD CNN 文档继续作为基线架构和历史验证资料保留；二者发生差异时，FLOOD 现有实现以源码为准，Diffusion 扩展以本文档为准。

## 1. 研究问题与论证链

Stable Diffusion 1.5 在潜空间中迭代执行 U-Net。ResNetBlock 内连续出现 GroupNorm、SiLU、卷积、时间步嵌入和残差相加。若每个算子都把中间特征写回 DDR，再由下一个算子读回，数据搬运会削弱 MAC 阵列带来的收益。

本设计要回答的问题是：

> 在 AXKU15 的片上存储和 DSP 约束下，能否复用 FLOOD 的可重构 INT8 MAC 阵列，通过分块映射、跨算子片上驻留与 DMA/计算重叠，显著减少 SD 1.5 ResNetBlock 的 DDR 流量并提高阵列利用率？

论文证据链为：

```text
真实工作负载分析
  -> 分块与融合数据流
  -> 定点黄金模型和 RTL
  -> AXKU15 原型
  -> 正确性、流量、性能、资源与功耗实验
  -> 消融与局限性分析
```

## 2. 已确认范围

### 2.1 目标工作负载

- 模型：Stable Diffusion 1.5。
- 硬件对象：U-Net 中的 ResNetBlock。
- 第一阶段不硬化 Cross-Attention；进度允许时将其作为扩展。
- 主验证形状：
  - `64 x 64 x 320`
  - `32 x 32 x 640`
  - `16 x 16 x 1280`
  - `8 x 8 x 1280`
- GroupNorm 组数固定为 32，激活函数为 SiLU。
- 第一阶段优先支持 `Cin == Cout` 的 Block；通道变化时的 `1 x 1` 残差投影作为扩展，复用同一卷积引擎。

### 2.2 目标平台与协同方式

- FPGA：ALINX AXKU15，核心板器件为 `XCKU15P-FFVE1517-2-I`（手册写作 `XCKU15PFFVE1517`，速度等级 `-2`、工业级；建工程时以 Vivado 完整器件名为准）。
- 外部存储：5 片 Micron `MT40A512M16LY-062E`，每片 1 GB，合计 5 GB，组成 80-bit DDR4 数据总线；标称数据速率 2666 Mbps。
- 执行方式：主机与 FPGA 协同。
- 主机负责模型加载、真实张量捕获、量化、数据布局转换、任务下发和结果检查。
- FPGA 负责 ResNetBlock 的核心计算与片上调度。
- 扩展板提供 PCIe Gen3 x16 机械连接器，但 FPGA 侧只连接 8 路 GT，因此本项目按 **Gen3 x8 电气链路**设计与报告，禁止把 x16 插槽写成 x16 有效链路。
- PCIe/XDMA 不是计算核心的硬依赖。核心内部统一使用 AXI4-Lite、AXI4-MM 和中断接口；若 XDMA 环境不可用，可先使用仿真、JTAG 或板上控制路径验证。

板级资料核对结果及设计约束：

| 板级事实 | 设计约束 |
|---|---|
| DDR4 位于 FPGA HP Bank 66、67、68、69、70，数据总线为 80 bit | MIG 必须按手册引脚表和本地原理图重新生成；不得直接套用 64-bit DDR 或 ECC 板卡预设 |
| 核心板有两个 200 MHz 晶振，分别供 FPGA 逻辑和 DDR 控制参考时钟 | 时钟向导/MIG 以实际差分时钟引脚为准；150 MHz 是加速器核心目标频率，不等于板级输入时钟 |
| PCIe 参考时钟由连接器输入，存在 `PCIE_PERST_n`，仅连接 8 路 GT | XDMA 集成按 x8 配置，复位同步、参考时钟域跨越和链路降级状态必须进入板级测试 |
| JTAG 与 USB-UART 可用 | 在 PCIe 未就绪时，保留配置、状态读取和最小板上诊断路径 |

本地板级资料是器件、接口拓扑和引脚约束的权威来源：

- [AXKU15 V1.2 用户手册](../../../AXKU15_V1.2_UG.pdf)
- [AXKU15 扩展板原理图 V1.0](../../../01_原理图PCB结构图等硬件资料/AXKU15原理图V1.0.pdf)
- [ACKU15 核心板原理图 V1.0](../../../01_原理图PCB结构图等硬件资料/ACKU15核心板.pdf)

### 2.3 非目标

- 不在第一阶段实现 CLIP、VAE、采样器或完整 Stable Diffusion 端到端硬件。
- 不把 Cross-Attention、Softmax 和 QKV 作为最低交付要求。
- 不以提出新的量化算法为主要贡献。
- 不以 AXKU15 对高端 GPU 的绝对延迟比较作为主要结论。
- 不直接把现有 16 Tile FLOOD 配置视为已经满足 XCKU15P 资源约束。

## 3. 现有 FLOOD 基线与复用边界

### 3.1 可复用模块

- Chisel/Scala 生成 RTL 的工程框架。
- `CIMCore`、`Tile`、`Cluster` 和 `MacMachine` 的层次结构。
- INT8 乘累加数据通路。
- SRAM Ping/Pong 选择与 Wrapper 级运行/中断框架。
- E203、APB/AXI、DMA、Vivado 和软件测试资产。
- 输出截位、饱和与部分后处理经验。

关键入口：

- [Config.scala](../../../accelerator/src/main/scala/core/Config.scala)
- [CIMcore.scala](../../../accelerator/src/main/scala/core/CIMcore.scala)
- [Cluster.scala](../../../accelerator/src/main/scala/cluster/Cluster.scala)
- [MacMachine.scala](../../../accelerator/src/main/scala/Machine/MacMachine.scala)
- [MacMachineWrapper.scala](../../../accelerator/src/main/scala/Machine/MacMachineWrapper.scala)

### 3.2 必须修改或新增的部分

- 将 FLOOD 计算阵列封装为规则的卷积 Tile 接口。
- 参数化 Tile 数量和每拍乘法并行度，使设计能够在 XCKU15P 上收敛。
- 新增面向 `Tci = 32`、`Tco = 32` 的二维空间分块控制器。
- 新增 GroupNorm、SiLU、时间步嵌入和残差融合单元。
- 新增面向完整 ResNetBlock 的片上 Residual/Mid/Accumulator Buffer。
- 新增 AXI 任务接口、Tensor DMA、性能计数器和错误状态。
- 替换依赖旧 CNN 数据布局或旧配置寄存器语义的控制逻辑。

### 3.3 当前基线风险

- README 中部分参数落后于当前源码；现有源码为 `rowSize = 32`、`colSize = 32`、`pipeline = 2`、`tLatency = 4`、`compressionFactor = 4`、`tileSize = 16`。
- 现有 `MacMachine_top.v` 将内部较宽权重地址连接到 11 位 BRAM 地址，需要在 Diffusion 原型中重新定义容量与地址映射。
- 原 16 Tile 配置的乘法器规模可能超过 XCKU15P 可用 DSP，不能跳过首次综合与缩减步骤。
- 原文档存在逻辑配置 ID 与物理 APB 地址混用；新接口必须把两者分开。

## 4. 系统架构

```text
Host / PyTorch
  |-- SD 1.5 张量捕获与定点黄金模型
  |-- 量化、Blocked Layout、任务描述符
  |-- 结果回读与指标统计
  |
  +--> 可替换 Host Bridge（XDMA / JTAG / E203）
          |-- AXI4-Lite 控制
          |-- AXI4-MM DDR 访问
          |-- Done / Error 中断
                  |
                  v
        ResNetBlock Accelerator
          |-- Command & Block Scheduler
          |-- Tensor DMA + Ping/Pong Buffer
          |-- GroupNorm Statistics / Normalize
          |-- SiLU Approximation
          |-- FLOOD Compute Adapter
          |-- Time Embedding Add
          |-- Residual Add
          |-- Residual / Mid / Accumulator Buffer
          |-- Performance & Error Monitor
```

### 4.1 主机端

主机程序提供以下功能：

1. 从 SD 1.5 U-Net 捕获 Block 输入、权重、时间步投影向量和 FP16 参考输出。
2. 生成与硬件一致的 W8A8/INT16 定点参考结果。
3. 将 NCHW 张量转换为 32 通道成组的 Blocked Layout。
4. 分配 DDR 地址并生成任务描述符。
5. 下发、等待中断、回读结果并生成误差报告。

### 4.2 FPGA 控制与搬运层

`BlockScheduler` 根据任务描述符展开两个卷积、两次 GroupNorm、两次 SiLU、时间步加法和残差加法。`TensorDMA` 负责 DDR 突发访问并维护 Ping/Pong 状态。DDR 控制器必须从 AXKU15 的 80-bit 拓扑、200 MHz 参考时钟和手册引脚表生成；加速器只依赖 MIG 暴露的 AXI 用户接口，不绑定某个 PCIe IP。控制层不得依赖 PCIe 专用信号。

### 4.3 计算层

`FLOOD Compute Adapter` 将通道块和空间块转换为现有 Tile/CIMCore 可接受的数据形式。第一版采用 8 Tile 保守配置；只有当综合后 DSP、布线、时序和片上存储均满足目标时，才扩大到 16 Tile 或启用 INT8 DSP 打包。

## 5. 分块与数据布局

### 5.1 基本粒度

- 输入通道块：`Tci = 32`。
- 输出通道块：`Tco = 32`。
- 空间块：`Th x Tw`，由设计空间探索选择。
- 3x3 卷积输入块包含一圈 Halo。
- 权重按 `CoutBlock -> CinBlock -> Ky -> Kx -> lane` 排列。
- 激活按 32 通道成组排列，主机端负责重排。

### 5.2 空间块选择规则

候选 `Th x Tw` 通过综合前模型和板上实验共同选择。选取规则依次为：

1. Residual、Mid、Accumulator、权重和双缓冲总量不超过可分配片上存储。
2. DDR 突发长度足够大，Halo 重复流量可接受。
3. FLOOD 阵列有效周期占比最高。
4. 路由与时序能够收敛。

设计文档不预先固定唯一空间块，避免在首次综合前把未经验证的尺寸写成硬约束。

## 6. 融合执行流程

### 阶段 A：GN1 统计与输入驻留

从 DDR 读取 Block 输入，计算 32 组 `sum` 和 `sum-square`，同时保存到片上 Residual Buffer。该 Buffer 后续同时作为 GN1 输入和残差旁路。

### 阶段 B：GN1—SiLU—Conv1—Time Embedding

Residual Buffer 中的数据经过 GN1 和 SiLU 后直接送入卷积阵列。归一化和激活结果不写 DDR。Conv1 使用 INT32 累加，重定标为 INT16 后与主机预投影的时间步向量按通道相加，结果写入 Mid Buffer。

### 阶段 C：GN2 统计

直接扫描片上 Mid Buffer 计算 GN2 统计量，不访问 DDR。

### 阶段 D：GN2—SiLU—Conv2—Residual Add

Mid Buffer 经 GN2 和 SiLU 后进入 Conv2。Conv2 输出与 Residual Buffer 相加，完成饱和和重定标后写回 DDR。

目标是 Block 级中间特征不离开 FPGA 片上存储。外部流量主要由输入、两个卷积的权重、时间步向量和最终输出组成。

## 7. 数值方案

| 对象 | 格式 |
|---|---|
| 卷积权重 | INT8，对称、按输出通道缩放 |
| 卷积输入 | INT8 |
| 乘法 | INT8 x INT8 |
| 卷积累加 | INT32 |
| Mid Buffer | INT16 |
| GroupNorm 输入/输出 | INT16 |
| GroupNorm 求和 | 不低于 32 bit |
| GroupNorm 平方和 | 不低于 48 bit |
| 时间步投影向量 | INT16 |
| 最终输出 | INT16，或按任务配置重定标为 INT8 |

### 7.1 GroupNorm

GroupNorm 固定支持 32 组：

```text
mean = sum(x) / M
variance = sum(x^2) / M - mean^2
y = gamma * (x - mean) / sqrt(variance + epsilon) + beta
```

倒数平方根使用 LUT 初值，可选择一次 Newton 迭代。具体实现必须与定点黄金模型使用相同的舍入、截断和饱和规则。

### 7.2 SiLU

SiLU 采用 16 段或 32 段分段线性近似。段数通过误差和资源消融实验选择；选择标准是满足 Block 级数值要求时使用资源更少的实现。

### 7.3 时间步嵌入

正弦编码和时间步 MLP 保留在主机端。FPGA 接收已投影到当前通道数的 INT16 向量，在 Conv1 后广播相加。

## 8. 控制接口

### 8.1 AXI4-Lite 寄存器组

至少包含：

- 控制：`start`、`abort`、`interrupt_clear`。
- 状态：`busy`、`done`、`error`、错误码。
- 形状：`H`、`W`、`Cin`、`Cout`、Group 数。
- 分块：`Th`、`Tw`、`Tci`、`Tco`。
- 地址：输入、两组权重、GN 参数、时间步向量、输出。
- 量化：输入、权重、中间和输出缩放参数。
- 性能：总周期、计算周期、DMA 等待周期、读写字节数、饱和计数。

### 8.2 任务约束

- `Cin` 和 `Cout` 必须按 32 通道对齐；不对齐时由主机填零。
- 首版卷积核固定为 3x3、步长 1、保持空间尺寸。
- 输入和权重地址必须满足 AXI 突发对齐要求。
- Group 数首版固定为 32。
- 不支持的形状不得静默执行，必须返回明确错误码。

## 9. 错误处理与可观测性

硬件至少检测：

- 非法形状或未对齐地址。
- DMA 超时或响应错误。
- 命令在 Busy 状态下重复启动。
- 定点饱和次数和最大/最小值越界。
- 内部 FIFO 或任务状态异常。

所有错误均锁存到状态寄存器并触发 Error 中断。性能计数器用于区分计算受限和带宽受限状态，不能只报告总延迟。

## 10. 验证计划

### 10.1 黄金模型

建立与 RTL 完全一致的定点模型，覆盖量化、舍入、饱和、GroupNorm、SiLU、时间步和残差。RTL 与该模型必须逐元素一致。

### 10.2 单元验证

- DMA 与 Ping/Pong 控制。
- FLOOD 卷积适配器。
- GroupNorm 统计与归一化。
- SiLU 近似。
- 时间步与残差加法。
- 状态、中断、错误与性能计数器。

### 10.3 Block 验证

使用真实 SD 1.5 张量覆盖四个通道层级、多个扩散时间步和不同输入分布。对 FP16、定点软件、RTL 和板上输出进行逐级比较。

### 10.4 FPGA 验证

- 板上输出与 RTL 一致。
- 连续任务和 Ping/Pong 运行不死锁。
- DDR 压力下结果稳定。
- 中断、超时、错误清除和重复运行正确。
- 板上计数器与外部计时相互校验。

## 11. 实验设计

### 11.1 基线

1. FP16 PyTorch：精度参考。
2. W8A8/INT16 软件模型：量化参考。
3. 非融合 FPGA：每个算子结果均回写 DDR。
4. 融合 FPGA：本文方案。

### 11.2 指标

- 数值：MAE、MSE、最大绝对误差、余弦相似度、饱和比例。
- 流量：输入、权重、中间特征和输出的 DDR 字节数。
- 性能：Block 延迟、吞吐率、MAC 利用率、DMA 等待比例。
- 实现：LUT、FF、BRAM、UltraRAM、DSP、Fmax。
- 能效：板级功耗、GOP/s/W。

### 11.3 消融

- 单缓冲与双缓冲。
- 中间结果回 DDR 与片上驻留。
- 不同 `Th x Tw`。
- 8 Tile 与资源允许时的 16 Tile。
- SiLU 16 段与 32 段。
- 敏感算子的不同定点位宽。
- 四个 U-Net 空间/通道层级和多个时间步。

## 12. 工程目标与完成判据

以下是工程目标，不是预先宣称的实验结果：

- RTL 与定点黄金模型逐元素一致。
- 相对非融合基线，中间激活 DDR 流量降低不少于 50%。
- LUT、FF、BRAM、UltraRAM 和 DSP 的单项占用原则上不超过 80%。
- 第一版目标频率不低于 150 MHz；若未达到，论文必须给出关键路径与修正结果。
- 融合版本相对非融合版本取得可测量的延迟或能效改善。
- 至少一个真实 SD 1.5 ResNetBlock 在 AXKU15 上完成稳定重复运行。

最低可交付成果为：定点黄金模型、融合 Block RTL、真实张量仿真、AXKU15 综合结果、板上核心路径验证、流量/性能/资源消融。完整 XDMA 主机链路和 Cross-Attention 属于增强成果。

## 13. 里程碑

1. 第 1 月：环境审计、真实张量捕获、定点黄金模型。
2. 第 2 月：FLOOD 参数化、单层 3x3 卷积、首次 XCKU15P 综合。
3. 第 3 月：GroupNorm、SiLU、Residual/Mid Buffer 和 DMA。
4. 第 4 月：融合 ResNetBlock RTL、非融合流量基线、Block 级仿真。
5. 第 5 月：AXKU15 DDR 与板级运行；若环境成熟则接入 XDMA。
6. 第 6 月：时序/资源优化、消融实验、论文主体。
7. 余量阶段：Cross-Attention 或更完整的软件调度。

## 14. 风险与降级路径

| 风险 | 影响 | 降级或应对 |
|---|---|---|
| 现有 16 Tile 资源过大 | 无法布局布线 | 首版 8 Tile；提高时分复用；综合后再扩展 |
| Mid/Residual Buffer 占用过高 | 无法完整片上驻留 | 改为条带驻留；保持算子融合并量化额外流量 |
| GroupNorm 定点误差过大 | Block 输出偏差 | 增加统计位宽、Newton 迭代或局部更高精度 |
| SiLU 近似误差过大 | 生成质量下降 | 增加分段或使用 LUT 插值 |
| PCIe/XDMA 不可用 | 无法直接由主机高速下发 | 保持 AXI 核心；使用 JTAG/E203/预装 DDR 做板级验证 |
| DDR 或时序不收敛 | 性能不达目标 | 缩小 Tile 数和突发并行度，保留完整实验解释 |
| 完整 SD 集成工作量过大 | 论文延期 | 固守真实 ResNetBlock 原型，不扩展 CLIP/VAE/Attention |

## 15. 参考与相关文档

- Rombach et al., *High-Resolution Image Synthesis with Latent Diffusion Models*, CVPR 2022: <https://openaccess.thecvf.com/content/CVPR2022/html/Rombach_High-Resolution_Image_Synthesis_With_Latent_Diffusion_Models_CVPR_2022_paper.html>
- Stable Diffusion 1.5 U-Net 配置：<https://huggingface.co/stable-diffusion-v1-5/stable-diffusion-v1-5/blob/refs%2Fpr%2F22/unet/config.json>
- SDA, *Low-Bit Stable Diffusion Acceleration on Edge FPGAs*, FPL 2024: <https://zhenman.github.io/files/C41-FPL2024-SDA.pdf>
- [本地 AXKU15 V1.2 用户手册](../../../AXKU15_V1.2_UG.pdf)
- [本地 AXKU15 扩展板原理图 V1.0](../../../01_原理图PCB结构图等硬件资料/AXKU15原理图V1.0.pdf)
- [本地 ACKU15 核心板原理图 V1.0](../../../01_原理图PCB结构图等硬件资料/ACKU15核心板.pdf)
- [工作区 README](../../../README.md)
- [实施计划](../plans/2026-08-08-sd15-resnetblock-accelerator-implementation.md)
- [FLOOD 加速器 README](../../../accelerator/README.md)
- [FLOOD MacMachine 使用说明](../../../accelerator/MacMachine使用说明文档.md)
- [旧 CNN Demo 部署计划](../../../accelerator/CNN_Accelerator_Deployment_Plan.md)

## 16. 审阅检查点

书面规格已确认，实施计划已经生成。本检查点不授权直接修改 RTL；开始执行前应先选择执行模式并处理当前目录缺少 Git 元数据的问题。实施顺序固定为环境与资源基线、黄金模型、卷积适配器、融合算子、系统集成和板级实验。
