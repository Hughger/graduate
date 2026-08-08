# MACTreeFlood 单级流水修复设计

## 背景与证据

`CIMCoreSpec` 以 `pipeline = 1` 构造 `CIMCore`，其内部实例化 `MACTreeFlood`。`MACTreeFlood` 的构造参数契约允许 `pipeline >= 1`，但其第一级完成分支无条件读取和写入 `stageStates(1)`、`stageCounters(1)`。当 `pipeline = 1` 时，这些 `Vec` 仅有索引 0，Chisel elaboration 在 `CIMcore.scala:410` 抛出 `IndexOutOfBoundsException: 1`。

同文件的既有参考实现对单级流水有独立分支，说明单级参数并非无效测试输入。

## 目标

保持 `MACTreeFlood(pipeline = 1)` 的已声明能力：对一组 `paral` 输入执行时分复用乘加，在 `tLatency` 个周期完成累计，经现有量化/输出路径输出一个结果。

## 非目标

- 不改变默认 `Config.pipeline = 2`、`Config.tLatency = 4` 或 AXKU15 架构。
- 不重构多级流水路径，不改动 `MACTreeRefine`。
- 不在本修复中处理 `MacMachineWrapperTest` 的 Treadle 堆内存需求或 SBT JAR 替换竞态；它们作为独立环境问题保留。

## 方案比较

1. **推荐：实现单级专用分支。** 当 `pipeline == 1` 时，使用现有输入握手、累加寄存器、量化与 FIFO 输出接口，且绝不索引第 1 级；`pipeline >= 2` 时保留当前多级实现。这与模块公开契约和既有参考模式一致。
2. **收紧参数约束为 `pipeline >= 2`。** 代码改动小，但会使现有 `CIMCoreSpec` 的合法场景失效，并与构造函数当前声明及参考实现不一致。
3. **只改测试为 `pipeline = 2`。** 掩盖模块参数契约缺陷，且丢失单级路径回归覆盖。

采用方案 1。

## 接口与时序约束

- 模块端口、寄存器宽度与 `Decoupled` 握手语义保持不变。
- `pipeline == 1` 分支的状态存取只能使用索引 0；不能构造或访问不存在的第二级状态。
- 单级路径按 `paral / tLatency` 划分每周期操作数；不足整除时，必须在 elaboration 时拒绝非法参数或明确处理余数。本次回归参数 `paral = 2, tLatency = 2` 可整除。
- 完成时复用既有输出 FIFO 和量化截断定义，避免新增数值语义。

## 测试与验收

1. 先运行现有 `CIMCoreSpec` 中 `pipeline = 1` 的矩阵向量测试，确认它因数组越界失败（RED）。
2. 最小实现单级分支后，重复运行该测试，验证无 elaboration 越界且数值输出与测试中的矩阵向量 golden 一致（GREEN）。
3. 再运行 `CIMCoreSpec` 全部测试，确认 `pipeline = 2` 的流式和 ping-pong 测试不回归。
4. 所有验证使用可观察的 SBT 前台模式；若 Windows JAR 原子替换竞态再次阻塞，将记录为环境阻塞，不将其归因于 RTL。

## 风险控制

单级与多级路径由 Scala elaboration-time 的 `if (pipeline == 1)` 分开，避免为不存在的级创建硬件索引。改动只限 `MACTreeFlood` 与与之对应的定向测试。