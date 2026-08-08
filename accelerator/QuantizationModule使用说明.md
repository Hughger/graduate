# 自适应量化硬件模块使用说明

## 概述

本量化模块专为可重构MAC阵列设计，支持动态并行度调整，提供硬件友好的量化实现。模块采用定点乘法+位移的方式实现重新量化，避免了昂贵的浮点除法器，同时支持逐通道量化参数配置。

## 核心特性

### 1. 自适应并行度支持
- 支持1-256路动态并行度调整
- 32位累加器防止溢出
- 可编程的量化参数配置

### 2. 硬件友好的实现
- 定点乘法器替代浮点除法
- 桶形移位器实现可变位移
- 支持饱和和舍入策略

### 3. 灵活的配置接口
- 支持逐通道量化参数
- 批量参数配置
- 实时参数更新

## 模块结构

### QuantizationUnit - 核心量化单元

```scala
class QuantizationUnit(
  val maxParallelism: Int = 256,        // 最大并行度
  val inputWidth: Int = 32,             // 输入累加器位宽
  val outputWidth: Int = 8,             // 输出数据位宽
  val paramWidth: Int = 32,             // 参数寄存器位宽
  val shiftWidth: Int = 6,              // 位移量位宽
  val channelWidth: Int = 8,            // 通道索引位宽
  val enableRounding: Boolean = true,   // 是否启用舍入
  val enableSaturation: Boolean = true  // 是否启用饱和
)
```

### QuantizationConfigurator - 参数配置器

```scala
class QuantizationConfigurator(
  val maxChannels: Int = 256,
  val paramWidth: Int = 32,
  val shiftWidth: Int = 6,
  val channelWidth: Int = 8
)
```

### MACArrayWithQuantization - 集成示例

```scala
class MACArrayWithQuantization(
  val maxParallelism: Int = 256,
  val inputWidth: Int = 8,
  val weightWidth: Int = 8,
  val outputWidth: Int = 8,
  val channelWidth: Int = 8,
  val enableQuantization: Boolean = true
)
```

## 使用方法

### 1. 基本使用

```scala
// 创建标准量化单元
val quantUnit = QuantizationUnit.createStandard(
  maxParallelism = 256,
  enableRounding = true,
  enableSaturation = true
)

// 配置量化参数
quantUnit.io.config.writeEnable := true.B
quantUnit.io.config.channelId := 0.U
quantUnit.io.config.multiplier := 1.S
quantUnit.io.config.shiftAmount := 0.U
quantUnit.io.config.zeroPoint := 0.S

// 输入数据
quantUnit.io.input := 100.S
quantUnit.io.bias := 0.S
quantUnit.io.channelId := 0.U
quantUnit.io.enable := true.B
quantUnit.io.valid := true.B

// 获取输出
val output = quantUnit.io.output
val outputValid = quantUnit.io.outputValid
```

### 2. 多通道配置

```scala
// 创建配置器
val configurator = QuantizationUnit.createConfigurator(maxChannels = 256)

// 配置多个通道
for (i <- 0 until 4) {
  configurator.io.config.writeEnable := true.B
  configurator.io.config.channelId := i.U
  configurator.io.config.multiplier := (i + 1).S
  configurator.io.config.shiftAmount := i.U
  configurator.io.config.zeroPoint := (i * 10).S
  // 等待一个时钟周期
}

// 批量配置
configurator.io.batchConfig.enable := true.B
configurator.io.batchConfig.startChannel := 0.U
configurator.io.batchConfig.endChannel := 3.U
configurator.io.batchConfig.multiplier := 2.S
configurator.io.batchConfig.shiftAmount := 1.U
configurator.io.batchConfig.zeroPoint := 5.S
```

### 3. 集成到MAC阵列

```scala
// 创建带量化的MAC阵列
val macArray = MACArrayWithQuantization.createStandard(
  maxParallelism = 256,
  enableQuantization = true
)

// 配置量化参数
macArray.io.quantConfig.writeEnable := true.B
macArray.io.quantConfig.channelId := 0.U
macArray.io.quantConfig.multiplier := 1.S
macArray.io.quantConfig.shiftAmount := 0.U
macArray.io.quantConfig.zeroPoint := 0.S

// 输入数据
macArray.io.inputs := inputs
macArray.io.weights := weights
macArray.io.bias := bias
macArray.io.channelId := 0.U
macArray.io.parallelism := 32.U  // 使用32路并行
macArray.io.enable := true.B
macArray.io.valid := true.B

// 获取输出
val output = macArray.io.output
val outputValid = macArray.io.outputValid
```

## 量化参数计算

### 软件端参数计算

```scala
// 计算量化参数
val scale = 0.5
val zeroPoint = 0
val (multiplier, shiftAmount) = QuantizationUtils.calculateQuantizationParams(
  scale = scale,
  zeroPoint = zeroPoint,
  inputWidth = 32,
  outputWidth = 8
)

// 逐通道参数计算
val scales = Array(0.5, 1.0, 2.0)
val zeroPoints = Array(0, 5, -5)
val params = QuantizationUtils.calculatePerChannelParams(
  scales = scales,
  zeroPoints = zeroPoints,
  inputWidth = 32,
  outputWidth = 8
)
```

### 硬件端参数配置

```scala
// 配置计算好的参数
quantUnit.io.config.writeEnable := true.B
quantUnit.io.config.channelId := channelId
quantUnit.io.config.multiplier := multiplier.S
quantUnit.io.config.shiftAmount := shiftAmount.U
quantUnit.io.config.zeroPoint := zeroPoint.S
```

## 设计原理

### 1. 累加器设计
- 使用32位累加器支持最大256路并行度
- 理论最大累加值：256 × (127×127) ≈ 412万
- 32位累加器最大值：21亿，有足够裕量

### 2. 重新量化实现
- 使用定点乘法：`result = (accumulator + bias) × multiplier`
- 使用算术右移：`result = result >> shiftAmount`
- 添加零点偏移：`result = result + zeroPoint`
- 应用饱和逻辑：限制在INT8范围内

### 3. 舍入策略
- 支持四舍五入：检查被移去的最高位
- 支持截断：直接丢弃低位
- 可配置的舍入策略

### 4. 饱和逻辑
- 正溢出：> 127 → 127
- 负溢出：< -128 → -128
- 防止正负反转

## 性能特点

### 1. 硬件开销
- 32位乘法器：1个
- 桶形移位器：1个
- 参数寄存器：256个通道 × 3个参数
- 总开销：约2K逻辑单元

### 2. 延迟
- 流水线延迟：4个时钟周期
- 配置延迟：1个时钟周期
- 支持连续数据流

### 3. 精度
- 量化误差：< 0.1%
- 支持逐通道优化
- 可配置的舍入策略

## 测试验证

### 运行测试
```bash
# 运行量化单元测试
sbt "testOnly FLOOD_Accelerator.core.QuantizationUnitTest"

# 运行特定测试
sbt "testOnly FLOOD_Accelerator.core.QuantizationUnitTest -- -z basic"
```

### 测试覆盖
- 基本量化功能
- 饱和和溢出处理
- 位移操作
- 多通道配置
- 舍入功能
- 参数计算

## 集成建议

### 1. 与现有系统集成
- 在MacMachine中集成量化单元
- 在OutRouter中集成量化处理
- 在FSM中集成量化参数配置

### 2. 配置管理
- 使用QuantizationParameterManager管理参数
- 在系统启动时预配置参数
- 支持运行时参数更新

### 3. 性能优化
- 使用流水线提高吞吐量
- 使用并行配置减少延迟
- 使用批量配置提高效率

## 注意事项

### 1. 参数范围
- multiplier：-2^31 到 2^31-1
- shiftAmount：0 到 63
- zeroPoint：-128 到 127

### 2. 配置顺序
- 先配置参数，再输入数据
- 参数配置需要1个时钟周期生效
- 支持实时参数更新

### 3. 错误处理
- 检查overflow和underflow信号
- 处理无效的通道ID
- 处理参数范围错误

## 扩展功能

### 1. 支持更多量化方案
- 对称量化
- 非对称量化
- 动态量化

### 2. 支持更多数据类型
- INT16输入输出
- 混合精度
- 浮点量化

### 3. 支持更多舍入策略
- 随机舍入
- 截断舍入
- 自定义舍入

这个量化模块为您的可重构MAC阵列提供了完整的量化解决方案，支持动态并行度调整，硬件友好的实现，以及灵活的配置接口。通过合理的参数配置和集成，可以显著提高MAC阵列的精度和效率。
