# OutputBuffer 模块使用说明

## 概述

OutputBuffer 是一个高级的SRAM缓存管理模块，专门设计用于FLOOD_Accelerator项目中的输出数据缓存管理。该模块内部集成了3个outputSram和1个jointSram，支持复杂的乒乓缓存策略和地址映射逻辑，并提供AXI read接口用于外部总线读取。

## 模块架构

### 内部组件

1. **outputSram0** - 乒乓缓存组件A
   - `pingpongInherit = false`
   - 当 `io.pingpong = false` 时活跃

2. **outputSram1** - 乒乓缓存组件B  
   - `pingpongInherit = true`
   - 当 `io.pingpong = true` 时活跃

3. **outputSram2** - 特殊用途缓存组件
   - `pingpongInherit = false`
   - 使用 `io.configBus.data(0)` 作为乒乓控制信号
   - 支持特殊的地址映射逻辑

4. **jointSram** - 边界拼接缓存组件
   - `pingpongInherit = false`
   - 使用 `io.configBus.data(0)` 作为乒乓控制信号

### 技术参数

- **blockLength**: `Config.outputSramLength/2` (前2个outputSram) 和 `Config.jointSramLength` (jointSram)
- **blockWidth**: `Config.colSize` (默认4)  
- **blockChannel**: `Config.rowSize` (默认4)
- **数据位宽**: `Config.outputBufferDataWidth` (默认8位)
- **地址偏移量**: `outputBufferBias = colSize * rowSize * tileSize = 64`

## 接口说明

### 输入接口

```scala
val io = IO(new Bundle {
  // 乒乓控制信号（用于前2个outputSram）
  val pingpong = Input(Bool())
  
  // 配置总线（第0bit用于第3个outputSram和jointSram的乒乓控制）
  val configBus = new Bundle {
    val data = Input(UInt(configBusWidth.W))
    val tileId = Input(UInt((2*log2Ceil(Config.tileSize)).W))
  }
  
  // 统一的SRAM接口
  val outputSramWrite = new Bundle {
    val enable = Input(Bool())
    val address = Input(UInt(outputAddrWidth.W))
    val data = Input(Vec(colSize, UInt(outputBufferDataWidth.W)))
  }
  
  val outputSramRead = new Bundle {
    val enable = Input(Bool())
    val address = Input(UInt(outputAddrWidth.W))
    val data = Output(Vec(colSize, UInt(outputBufferDataWidth.W)))
  }
  
  val jointSramWrite = new Bundle {
    val enable = Input(Bool())
    val address = Input(UInt(jointAddrWidth.W))
    val data = Input(Vec(colSize, UInt(outputBufferDataWidth.W)))
  }
  
  val jointSramRead = new Bundle {
    val enable = Input(Bool())
    val address = Input(UInt(jointAddrWidth.W))
    val data = Output(Vec(colSize, UInt(outputBufferDataWidth.W)))
  }
  
  // AXI read接口
  val outputSramAxiRead = new Bundle {
    val enable = Input(Bool())
    val address = Input(UInt(outputAddrWidth.W))
    val data = Output(Vec(rowSize, UInt(outputBufferDataWidth.W)))
    val valid = Output(Bool())
  }
  
  val jointSramAxiRead = new Bundle {
    val enable = Input(Bool())
    val address = Input(UInt(jointAddrWidth.W))
    val data = Output(Vec(rowSize, UInt(outputBufferDataWidth.W)))
    val valid = Output(Bool())
  }
})
```

### 接口功能说明

1. **pingpong信号**: 控制前2个outputSram的乒乓切换
2. **configBus.data(0)**: 控制第3个outputSram和jointSram的乒乓切换
3. **统一接口**: 所有SRAM操作通过统一的接口进行，模块内部自动路由
4. **AXI read接口**: 用于外部AXI总线读取数据，支持所有SRAM组件的读取

## 工作原理

### 乒乓控制逻辑

#### 前2个outputSram的乒乓控制
```scala
// 根据pingpong信号选择当前活跃的outputSram
val activeOutputSram = Mux(io.pingpong, outputSram1, outputSram0)

// 乒乓控制信号连接
outputSram0.io.pingpong := io.pingpong
outputSram1.io.pingpong := io.pingpong
```

#### 第3个outputSram和jointSram的乒乓控制
```scala
// 使用configBus的第0bit作为乒乓控制
val innerPingPong = configBuffer(0)
outputSram2.io.pingpong := innerPingPong
jointSram.io.pingpong := innerPingPong
```

### 地址映射逻辑

#### 地址范围判断
```scala
val isOutputSram2Address = io.outputSramWrite.address >= outputBufferBias
val outputBufferBias = (Config.colSize * Config.rowSize * Config.tileSize).U
```

#### 地址路由规则
1. **地址 < outputBufferBias**: 路由到乒乓outputSram（outputSram0或outputSram1）
2. **地址 >= outputBufferBias**: 路由到第3个outputSram（outputSram2），地址自动减去偏移量

### AXI读取逻辑

#### outputSram的AXI读取
```scala
// 根据地址范围选择对应的AXI读取源
val isOutputSram2AxiAddress = io.outputSramAxiRead.address >= outputBufferBias

when(!isOutputSram2AxiAddress) {
  // 从乒乓outputSram读取
  val activeOutputSramAxi = Mux(io.pingpong, outputSram1, outputSram0)
  activeOutputSramAxi.io.axiRead.enable := io.outputSramAxiRead.enable
  activeOutputSramAxi.io.axiRead.address := io.outputSramAxiRead.address
  io.outputSramAxiRead.data := activeOutputSramAxi.io.axiRead.data.map(_.asUInt)
  io.outputSramAxiRead.valid := activeOutputSramAxi.io.axiRead.valid
}.otherwise {
  // 从第3个outputSram读取
  outputSram2.io.axiRead.enable := io.outputSramAxiRead.enable
  outputSram2.io.axiRead.address := io.outputSramAxiRead.address - outputBufferBias
  io.outputSramAxiRead.data := outputSram2.io.axiRead.data.map(_.asUInt)
  io.outputSramAxiRead.valid := outputSram2.io.axiRead.valid
}
```

#### jointSram的AXI读取
```scala
// jointSram的AXI读取
jointSram.io.axiRead.enable := io.jointSramAxiRead.enable
jointSram.io.axiRead.address := io.jointSramAxiRead.address
io.jointSramAxiRead.data := jointSram.io.axiRead.data.map(_.asUInt)
io.jointSramAxiRead.valid := jointSram.io.axiRead.valid
```

### 数据流控制

#### 写入逻辑
```scala
// 乒乓outputSram的写入
when(!isOutputSram2Address) {
  activeOutputSram.io.baseIO.write.enable := io.outputSramWrite.enable
  activeOutputSram.io.baseIO.write.address := io.outputSramWrite.address
  activeOutputSram.io.baseIO.write.data := io.outputSramWrite.data.map(_.asSInt)
}

// 第3个outputSram的写入
when(isOutputSram2Address) {
  outputSram2.io.baseIO.write.enable := io.outputSramWrite.enable
  outputSram2.io.baseIO.write.address := io.outputSramWrite.address - outputBufferBias
  outputSram2.io.baseIO.write.data := io.outputSramWrite.data.map(_.asSInt)
}
```

#### 读取逻辑
```scala
// 根据地址范围选择输出数据
io.outputSramRead.data := Mux(isOutputSram2ReadAddress, 
                              outputSram2Data, 
                              Mux(io.pingpong, outputSram1Data, outputSram0Data))
```

## 使用场景

### 1. 标准乒乓缓存模式
- **用途**: 常规的输出数据缓存，支持连续数据流处理
- **控制**: 使用 `io.pingpong` 信号
- **地址范围**: 0 到 `outputBufferBias-1`
- **AXI读取**: 支持从乒乓outputSram读取数据

### 2. 特殊缓存模式
- **用途**: 用于 `outputNoc.count=1` 时的写入空间和 `position<groupNum` 时的列向拼接读空间
- **控制**: 使用 `io.configBus.data(0)` 信号
- **地址范围**: `outputBufferBias` 及以上
- **AXI读取**: 支持从第3个outputSram读取数据

### 3. 边界拼接缓存
- **用途**: 存储和处理边界数据，支持复杂的拼接操作
- **控制**: 使用 `io.configBus.data(0)` 信号
- **特点**: 独立的地址空间，不参与乒乓切换
- **AXI读取**: 支持从jointSram读取数据

### 4. AXI总线读取
- **用途**: 外部AXI总线访问所有SRAM组件
- **特点**: 自动地址路由，支持乒乓切换
- **数据格式**: 输出 `Vec(rowSize, UInt(outputBufferDataWidth.W))`

## 配置示例

### 基本配置
```scala
// 实例化OutputBuffer
val outputBuffer = Module(new OutputBuffer(tileId = 0))

// 连接乒乓控制信号
outputBuffer.io.pingpong := pingpongSignal

// 连接配置总线
outputBuffer.io.configBus.data := configData
outputBuffer.io.configBus.tileId := tileId
```

### 乒乓切换配置
```scala
// 切换到outputSram1
outputBuffer.io.pingpong := true.B

// 切换到outputSram0  
outputBuffer.io.pingpong := false.B

// 控制第3个outputSram和jointSram的乒乓
outputBuffer.io.configBus.data := Cat(1.U(31.W), pingpongBit)
```

### AXI读取配置
```scala
// 从outputSram读取数据
outputBuffer.io.outputSramAxiRead.enable := true.B
outputBuffer.io.outputSramAxiRead.address := readAddress

// 从jointSram读取数据
outputBuffer.io.jointSramAxiRead.enable := true.B
outputBuffer.io.jointSramAxiRead.address := readAddress

// 等待数据有效
when(outputBuffer.io.outputSramAxiRead.valid) {
  val data = outputBuffer.io.outputSramAxiRead.data
  // 处理读取的数据
}
```

## 注意事项

### 1. 地址映射
- 第3个outputSram的地址会自动减去 `outputBufferBias`
- 确保地址范围不重叠，避免数据冲突
- AXI读取地址遵循相同的路由规则

### 2. 乒乓控制
- 前2个outputSram使用统一的 `pingpong` 信号
- 第3个outputSram和jointSram使用 `configBus.data(0)` 信号
- 两个乒乓控制信号可以独立设置
- AXI读取自动跟随乒乓切换

### 3. 数据格式
- 输入数据为 `Vec(colSize, UInt(outputBufferDataWidth.W))`
- 内部自动转换为 `SInt` 格式传递给TransSram3D
- 输出数据自动转换回 `UInt` 格式
- AXI读取输出为 `Vec(rowSize, UInt(outputBufferDataWidth.W))`

### 4. 时序要求
- 所有SRAM操作都是同步的
- 读取操作有1个时钟周期的延迟
- 写入操作在时钟上升沿生效
- AXI读取的valid信号有1个时钟周期的延迟

### 5. AXI读取特性
- 当pingpong信号与pingpongInherit不匹配时，AXI读取激活
- 支持从所有SRAM组件读取数据
- 自动地址路由，无需手动选择SRAM组件
- 读取延迟为1个时钟周期

## 测试验证

模块包含完整的测试套件，覆盖以下功能：
1. 乒乓切换逻辑测试
2. 地址映射逻辑测试  
3. jointSram操作测试
4. 混合地址范围处理测试
5. **AXI读取操作测试**
6. **AXI读取乒乓切换测试**

运行测试命令：
```bash
sbt "testOnly FLOOD_Accelerator.sram.OutputBufferSpec"
```

## 性能特性

1. **高吞吐量**: 支持colSize个数据元素并行处理
2. **低延迟**: 优化的地址计算和数据路由逻辑
3. **灵活配置**: 支持多种乒乓策略和地址映射模式
4. **资源效率**: 智能的总线复用，减少硬件资源开销
5. **AXI兼容**: 完整的AXI总线接口支持

## 扩展性

模块设计具有良好的扩展性：
1. 支持更大的 `colSize` 和 `rowSize` 配置
2. 可以轻松添加更多的SRAM组件
3. 乒乓控制策略可以根据需求调整
4. 地址映射逻辑支持自定义偏移量
5. AXI接口可以扩展支持更多协议特性 