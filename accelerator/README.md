# FLOOD 加速器基线说明

> **文档定位（2026-08-08）**：本文描述现有 FLOOD CNN/MacMachine 基线，供代码理解、复用和回归验证使用。当前研究主线是 AXKU15 上的 Stable Diffusion 1.5 ResNetBlock 加速器，范围、接口、精度和完成判据以[正式设计规格](../docs/superpowers/specs/2026-08-08-sd15-resnetblock-accelerator-design.md)为准。

> **参数提示**：下方 `Config` 示例为历史快照，可能落后于源码。当前 `src/main/scala/core/Config.scala` 的关键值为 `rowSize=32`、`colSize=32`、`dataWidth=8`、`pipeline=2`、`tLatency=4`、`compressionFactor=4`、`tileSize=16`。新的 Diffusion 原型首版按 8 Tile 进行综合评估，不能把旧 16 Tile 配置直接视作 AXKU15 可实现结论。

## 项目概述

FLOOD_Accelerator 是一个高效的计算加速器项目，采用多核架构设计，旨在实现高性能的乘累加计算和数据存储管理。该项目采用分层设计，包含以下核心模块：

- **MacMachine**: 多核架构的完整封装结构，集成FSM、Cluster、OutRouter三个模块
- **MacMachineWrapper**: MacMachine的封装层，提供乒乓缓冲和SRAM管理
- **Cluster**: 多核架构的完整封装结构，管理多个Tile和InterNoC
- **Tile**: 多核架构的基本计算单元，封装CIMCore并提供核间通信
- **OutRouterPlanePost**: 带嵌入平面处理功能的Router模块，支持BN、激活函数、池化等后处理
- **DynamicTruncateData**: 动态截位数据模块，支持运行时动态控制截位位数
- **CIMCore**: 计算内存核心，实现乘累加计算
- **SRAM**: 存储管理模块，包括权重SRAM、特征图SRAM、输出SRAM等

## 全局配置

### Config对象配置参数

Config对象定义了整个系统的全局配置参数，位于`src/main/scala/core/Config.scala`：

```scala
object Config {
  // CIMCore参数
  val rowSize = 32        // CIMCore行数
  val colSize = 32        // CIMCore列数

  // 基础参数
  val dataWidth = 8       // 输入数据位宽
  val outputWidth = 2*dataWidth+log2Ceil(rowSize)  // 输出数据位宽
  val weightBandWidth = colSize * dataWidth // CIMCore的权重总线位宽
  val featureMapBandWidth = weightBandWidth // MacMachine的特征图总线位宽
  
  // MACTree参数
  val pipeline = 5        // 流水线级数
  val tLatency = 1        // 每级流水线延迟
  val compressionFactor = 2 // 除乘法流水级之外，每个流水级输入结果相邻与前一级的输入结果的压缩比
  
  // Tile参数
  val maxKernelSize = colSize // Tile内支持的最大卷积2D尺寸k
  val maxWorkMode = 5     // Tile最大的可重构工作模式数量
  
  // Cluster参数
  val tileSize = 16       // Cluster内Tile的总数
  val finalWidth = outputWidth+log2Ceil(tileSize)+log2Ceil(colSize) // 最终Cluster的输出数据位宽

  // 配置总线参数
  val configDataWidth = 32 // 配置数据位宽
  val configAddrWidth = 32 // 配置地址位宽

  // FSM/OutRouter参数
  val maxKernelBlockK = maxKernelSize // 卷积核Block的最大2D尺寸k值
  val maxKernelBlockCout = 32 // 一轮计算中，结果图Block的通道数
  val maxKernelBlockCin = 1024 // 卷积核Block的最大输入通道数
  val maxGroupSize = tileSize // Cluster中，最大可能实现的组内Tile数
  val maxGroupNum = tileSize // Cluster中，最大可能实现的组内Tile数
  val maxResolutionCol = 768 // 特征图的最大W坐标

  // SRAM参数
  val weightSramDataWidth = 8
  val weightSramAddrWidth = 18
  val featureMapSramDataWidth = 8
  val featureMapSramAddrWidth = 18
  val outputBufferDataWidth = 8
  val outputBufferAddrWidth = 18
}
```

### 配置寄存器说明

系统使用32位配置寄存器，包含以下信息域：

1. **Tile配置寄存器**（地址：0-15，32位）：
   ```
   [31:16] - remain (16位) - 预留扩展位
   [15:8]  - featureMapLine (8位) - 特征图行索引
   [7:4]   - workMode (4位) - 工作模式
   [3:0]   - inputId (4位) - 输入ID
   [2:0]   - kernelSize (3位) - 卷积核大小(k-1)
   ```

2. **InterNoC配置寄存器**（地址：16-30，32位）：
   ```
   [31:24] - remain (8位) - 预留扩展位
   [23:16] - workMode (8位) - 工作模式
   [15:8]  - inputId (8位) - 输入ID
   [7:4]   - 预留位
   [3]     - deliver (1位) - 是否发送数据
   [2]     - systolic (1位) - 是否使用systolic模式
   [1:0]   - 预留位
   ```

3. **FSM/OutRouter配置寄存器**：
   - **Normal配置寄存器**（地址：31）：
     ```
     [31:0] - k (5位) + groupSize (4位) + groupNum (4位) + cout (5位) + 预留位
     ```
   - **Special配置寄存器**（地址：32）：
     ```
     [31:28] - truncateBits (4位) - 截位位数控制
     [27:25] - workMode (3位) - 工作模式
     [24:14] - colIdx (11位) - 列索引
     [13:3]  - cinIdx (11位) - 输入通道索引
     [2:0]   - 预留位
     ```

4. **BN参数寄存器**（地址：33-64，32位）：
   ```
   [31:16] - bnMulParam (16位) - BN乘法参数（有符号）
   [15:0]  - bnAddParam (16位) - BN加法参数（有符号）
   ```

5. **全局配置寄存器**（地址：65，32位）：
   ```
   [31]    - pingpong (1位) - 全局乒乓标志
   [30]    - weightPingpong (1位) - 权重乒乓标志
   [29]    - outputPingpong (1位) - 输出乒乓标志
   [7:0]   - actionMode (8位) - 动作模式控制
     [0]   - dataFlowMode - 数据流模式 (0:FLOOD, 1:NVIDIA)
     [1]   - isFinalCinIdx - 是否为最终输入通道索引
     [2]   - bnEn - BN使能
     [3]   - actEn - 激活函数使能
     [4]   - poolEn - 池化使能
   ```

6. **运行控制寄存器**：
   - **runProcess寄存器**（地址：48）：启动一轮计算
   - **interruptFresh寄存器**（地址：49）：清空MacMachine内的中断标志

## 系统架构

### MacMachine（多核架构完整封装）

MacMachine是多核架构的完整封装结构，位于`src/main/scala/machine/MacMachine.scala`，主要功能：

- **模块集成**：集成FSM、Cluster、OutRouter三个核心模块
- **乒乓控制**：提供全局乒乓控制信号
- **SRAM接口**：提供权重SRAM、输出SRAM、Joint SRAM的读写接口
- **配置总线**：统一的配置总线接口
- **特征图总线**：用于特征图数据传输
- **启动控制**：支持启动/完成握手协议

### MacMachineWrapper（封装层）

MacMachineWrapper是MacMachine的封装层，位于`src/main/scala/machine/MacMachineWrapper.scala`，主要功能：

- **乒乓缓冲管理**：
  - 权重SRAM乒乓缓冲（ping/pong）
  - 输出SRAM乒乓缓冲（ping/pong）
  - Joint SRAM独立管理
- **地址映射**：根据地址边界自动选择SRAM
- **中断管理**：done和error中断标志
- **运行控制**：通过配置寄存器控制启动和中断清除

### Cluster（多核架构管理）

Cluster是多核架构的完整封装结构，位于`src/main/scala/cluster/Cluster.scala`，主要功能：

- **Tile管理**：管理16个Tile实例
- **InterNoC管理**：管理15个InterNoC实例，实现Tile间通信
- **输出仲裁**：使用Round-Robin仲裁器管理Tile输出
- **配置分发**：将配置总线和权重总线分发给各个Tile和InterNoC

### Tile（基本计算单元）

Tile是多核架构的基本计算单元，位于`src/main/scala/core/Tile.scala`，主要功能：

- **CIMCore封装**：封装计算内存核心
- **移位相加**：根据kernelSize执行移位相加操作
- **核间通信**：通过InterNoC实现Tile间数据传递
- **状态管理**：管理计算状态和输出状态
- **配置支持**：支持动态配置kernelSize、inputId、workMode等参数

### OutRouterPlanePost（后处理Router）

OutRouterPlanePost是带嵌入平面处理功能的Router模块，位于`src/main/scala/machine/OutRouterPlanePost.scala`，主要功能：

- **平面处理**：支持输入通道补齐、列向拼接、高向拼接
- **后处理流水线**：
  - BN（Batch Normalization）：乘法和加法操作
  - 激活函数：ReLU激活
  - 池化：2x2最大池化
- **动态截位控制**：集成DynamicTruncateData模块，支持运行时动态控制截位位数
- **工作模式**：
  - 初始列向拼接（001）
  - 一般列向拼接（010）
  - 仅输入通道补齐（011/100）
  - 默认模式（000）
- **双SRAM管理**：outputSram和jointSram的读写管理

### DynamicTruncateData（动态截位模块）

DynamicTruncateData是动态截位数据模块，位于`src/main/scala/tools/DynamicTruncateData.scala`，主要功能：

- **动态截位控制**：支持运行时通过寄存器动态控制截位位数
- **位宽自适应**：根据输入输出位宽自动选择处理策略
- **四舍五入**：支持精确的四舍五入算法
- **饱和处理**：防止数据溢出，确保数值稳定性
- **向量化处理**：支持多路数据并行处理

#### 接口定义
```scala
val io = IO(new Bundle {
  val inputData = Input(Vec(vecSize, SInt(inputWidth.W)))
  val outputData = Output(Vec(vecSize, SInt(inputWidth.W)))  // 输出位宽与输入一致
  val truncateBits = Input(UInt(truncateBitsWidth.W))
})
```

#### 位宽处理策略
**重要说明**：`DynamicTruncateData` 的输出位宽与输入位宽一致，`outputWidth` 参数表示有效位宽（只有低 `outputWidth` 位有效）。

1. **inputWidth > outputWidth**：饱和截位，需要截断高位并进行饱和处理，输出位宽保持与输入一致
2. **inputWidth == outputWidth**：直接截位，根据truncateBits进行右移，输出位宽与输入一致
3. **inputWidth < outputWidth**：符号位扩展，补足到目标位宽，输出位宽与输入一致

**参数语义**：
- `inputWidth`：输入数据位宽
- `outputWidth`：有效位宽（只有低 `outputWidth` 位有效，其余位为零或符号扩展）
- `outputData`：输出数据位宽与 `inputData` 一致，但只有低 `outputWidth` 位有效

#### 性能特性
- **时钟频率**：在28nm工艺下可达625MHz
- **硬件资源**：优化的组合逻辑，减少MUX开销
- **延迟**：单周期完成截位操作

#### 使用示例
```scala
val truncateModule = Module(new DynamicTruncateData(
  inputWidth = 16,           // 输入数据位宽
  outputWidth = 8,           // 有效位宽（只有低8位有效）
  vecSize = 4,               // 向量大小
  truncateBitsWidth = 4      // 截位位数寄存器位宽
))

truncateModule.io.inputData := inputData
truncateModule.io.truncateBits := truncateBits
val outputData = truncateModule.io.outputData  // 输出位宽为16位，但只有低8位有效
```

### 配置示例

以下是配置系统的伪代码示例：

```scala
// 1. 配置Tile
def configureTile(tileId: Int, kernelSize: Int, inputId: Int, workMode: Int, featureMapLine: Int) {
  // 设置乒乓信号为false
  pingpong = false
  
  // 配置Tile
  configBus.addr = tileId
  configBus.data = (remain << 16) | (featureMapLine << 8) | (workMode << 4) | inputId
  configBus.en = true
  
  // 写入权重
  for (addr <- 0 until rowSize*colSize) {
    weightBus.tileId = tileId
    weightBus.addr = addr
    weightBus.data = weights(addr)
    weightBus.en = true
  }
  
  // 设置乒乓信号为true使配置生效
  pingpong = true
  wait(5 cycles)
}

// 2. 配置InterNoC
def configureInterNoC(nocId: Int, deliver: Boolean, systolic: Boolean) {
  // 设置乒乓信号为false
  pingpong = false
  
  // 配置InterNoC
  configBus.addr = nocId
  configBus.data = (remain << 24) | (workMode << 16) | (inputId << 8) |
                   (deliver << 3) | (systolic << 2)
  configBus.en = true
  
  // 设置乒乓信号为true使配置生效
  pingpong = true
}

// 3. 配置OutRouterPlanePost
def configureOutRouter(k: Int, groupSize: Int, groupNum: Int, cout: Int, 
                      cinIdx: Int, colIdx: Int, workMode: Int, truncateBits: Int = 0) {
  // 配置Normal寄存器
  configBus.addr = 31 // FSMRouterConfIdStart
  configBus.data = (k << 0) | (groupSize << 5) | (groupNum << 9) | (cout << 13)
  configBus.en = true
  
  // 配置Special寄存器（包含truncateBits字段）
  configBus.addr = 32 // FSMRouterConfIdEnd
  configBus.data = (truncateBits << 24) | (workMode << 21) | (colIdx << 11) | (cinIdx << 0)
  configBus.en = true
}

// 4. 配置BN参数
def configureBNParams(bnParams: Array[(Int, Int)]) {
  for (i <- 0 until colSize) {
    val (mulParam, addParam) = bnParams(i)
    configBus.addr = 33 + i // bnConfIdStart + i
    configBus.data = (mulParam << 16) | addParam
    configBus.en = true
  }
}

// 5. 配置全局参数
def configureGlobal(dataFlowMode: Boolean, isFinalCinIdx: Boolean, 
                   bnEn: Boolean, actEn: Boolean, poolEn: Boolean) {
  configBus.addr = 65 // globalConfId
  configBus.data = (pingpong << 31) | (weightPingpong << 30) | (outputPingpong << 29) |
                   (poolEn << 4) | (actEn << 3) | (bnEn << 2) | (isFinalCinIdx << 1) | dataFlowMode
  configBus.en = true
}

// 6. 启动计算
def startComputation() {
  configBus.addr = 48 // runProcessId
  configBus.data = 1
  configBus.en = true
  
  // 等待计算完成
  while (!interrupts.doneInterrupt) {
    wait(1 cycle)
  }
  
  // 清除中断
  configBus.addr = 49 // interruptFreshId
  configBus.data = 1
  configBus.en = true
}

// 7. 使用示例
// 配置全systolic模式
for (i <- 0 until tileSize) {
  configureTile(i, kernelSize=2, inputId=i, workMode=0, featureMapLine=i)
}

for (i <- 0 until tileSize-1) {
  configureInterNoC(i, deliver=true, systolic=true)
}

// 配置OutRouter（包含截位控制）
configureOutRouter(k=3, groupSize=4, groupNum=4, cout=32, cinIdx=0, colIdx=0, workMode=0, truncateBits=1)

// 配置BN参数（示例）
val bnParams = Array.fill(colSize)((0x1000, 0x0100)) // (mulParam, addParam)
configureBNParams(bnParams)

// 配置全局参数
configureGlobal(dataFlowMode=false, isFinalCinIdx=true, bnEn=true, actEn=true, poolEn=false)

// 启动计算
startComputation()
```

### 配置注意事项

1. **乒乓机制**：
   - 配置前必须设置乒乓信号为false
   - 配置完成后设置乒乓信号为true使配置生效
   - 支持权重SRAM和输出SRAM的独立乒乓控制

2. **地址映射**：
   - Tile配置寄存器地址：0-15
   - InterNoC配置寄存器地址：16-30
   - FSM/OutRouter配置寄存器地址：31-32
   - BN参数寄存器地址：33-64
   - 全局配置寄存器地址：65
   - 运行控制寄存器地址：48-49

3. **工作模式**：
   - OutRouterPlanePost支持5种工作模式（0-4）
   - 模式0：默认情况（不补齐也不拼接）
   - 模式1：初始列向拼接
   - 模式2：一般列向拼接
   - 模式3/4：仅输入通道补齐

4. **数据流模式**：
   - FLOOD模式（dataFlowMode=0）：使用index 0的BN参数应用到所有列
   - NVIDIA模式（dataFlowMode=1）：为每列使用对应的BN参数

5. **后处理流水线**：
   - BN、激活函数、池化仅在isFinalCinIdx有效时执行
   - 池化操作仅在count=0的数据上执行
   - 支持2x2最大池化，stride=2

6. **中断管理**：
   - done中断：计算完成时触发
   - error中断：发生错误时触发
   - 通过interruptFresh寄存器清除中断标志

## 总结

FLOOD_Accelerator是一个高性能的多核计算加速器，采用分层架构设计，支持：

- **多核并行计算**：16个Tile并行处理，支持灵活的核间通信
- **乒乓缓冲机制**：提高数据吞吐量，支持连续计算
- **后处理流水线**：集成BN、激活函数、池化等深度学习后处理操作
- **可重构架构**：支持多种工作模式和通信方式
- **高效存储管理**：多级SRAM管理，优化数据访问模式

该加速器特别适用于深度学习推理任务，能够高效处理卷积、全连接等计算密集型操作。
    4. 精确的握手机制
    5. 可扩展的路由信息

### 5. Cluster 模块

#### 文件: `src/main/scala/cluster/cluster.scala`

- **Cluster 类**
  - 功能: 实现Tile集群的集成管理
  - 参数: 继承Config对象的所有配置参数
  - 接口信息:

    ```scala
    val io = IO(new Bundle {
      // 乒乓控制信号
      val pingpong = Input(Bool())

      // 输入NoC接口
      val inputNoc = Flipped(Decoupled(new Bundle {
        val data = Vec(rowSize, SInt(dataWidth.W))
        val writeId = UInt(tileIdWidth.W)
        val count = UInt(8.W)
        val remain = UInt(16.W)
      }))

      // 输出NoC接口
      val outputNoc = Decoupled(new Bundle {
        val data = Vec(colSize*2, SInt((outputWidth+log2Ceil(tileSize)).W))
        val tileId = UInt(tileIdWidth.W)
        val count = UInt(8.W)
        val remain = UInt(16.W)
      })

      // 配置总线接口
      val configBus = new Bundle {
        val data = Input(UInt(configBusWidth.W))
        val tileId = Input(UInt(tileIdWidth.W))
      }

      // 权重总线接口
      val weightBus = new Bundle {
        val data = Input(UInt(weightBandWidth.W))
        val tileId = Input(UInt(tileIdWidth.W))
        val addr = Input(UInt(log2Ceil(colSize * rowSize).W))
      }
    })
    ```
  - 电路工作原理:

    1. 模块实例化

       - 实例化 `tileSize`个Tile模块，ID从0开始顺序分配
       - 实例化 `tileSize-1`个InterNoC模块，ID从 `tileSize`开始顺序分配
    2. 信号连接

       - 输入NoC广播到所有Tile
       - 输出NoC通过仲裁器(Arbiter)集成多个Tile的输出
       - 配置总线和权重总线并行连接到所有Tile
       - 乒乓控制信号全局广播
    3. 互联逻辑

       - 相邻Tile通过InterNoC模块连接
       - 最下方Tile的nocDown接口保持就绪状态
       - 最上方Tile的nocUp接口保持非就绪状态
    4. 特殊处理

       - 输入NoC的ready信号由目标Tile的ready信号决定
       - 输出NoC使用优先级仲裁器处理多Tile并发输出
  - 关键特性:

    1. 支持大规模Tile集群扩展
    2. 智能总线仲裁机制
    3. 灵活的拓扑结构配置
    4. 统一的全局接口管理
    5. 可靠的边界条件处理

### 6. FSM 模块

#### 文件: `src/main/scala/machine/FSM.scala`

- **FSM 类**
  - 功能: 实现多层嵌套循环的卷积核调度与数据流控制，负责根据配置参数自动完成权重与输入数据的分发、状态管理和异常检测。
  - 参数:
    - `tileId`: 当前FSM的唯一ID号
    - 继承全局Config对象的所有配置参数
  - 接口信息:
    ```scala
    val io = IO(new Bundle {
      val pingpong = Input(Bool())
      val configBus = new Bundle {
        val data = Input(UInt(configBusWidth.W))
        val tileId = Input(UInt(tileIdWidth.W))
      }
      val inputNoc = Decoupled(new Bundle {
        val data = Vec(rowSize, SInt(dataWidth.W))
        val writeId = UInt(tileIdWidth.W)
        val count = UInt(8.W)
        val inputMode = UInt(8.W)
        val cout = UInt(kernelBlockCoutWidth.W)
        val kernelRow = UInt(kernelBlockKWidth.W)
        val remain = UInt(8.W)
      })
      val weightSramRead = new Bundle {
        val readEnable = Output(Bool())
        val readAddress = Output(UInt(log2Ceil(Config.weightSramLength).W))
        val readData = Input(UInt((rowSize * dataWidth).W))
      }
      val error = Output(Bool())
      val start = Flipped(Decoupled(Bool()))
      val done = Decoupled(Bool())
    })
    ```
  - **配置寄存器分配方式（最新版）**：
    - 使用1个配置寄存器，通过`configBus.tileId = tileId`写入。
    - 寄存器参数分配如下：
      **kernelConfig**：
        - `[kernelBlockKWidth-1:0]`：k（卷积核尺寸）
        - `[kernelBlockKWidth+groupSizeWidth-1:kernelBlockKWidth]`：groupSize（每组Tile数量）
        - `[kernelBlockKWidth+groupSizeWidth+groupNumWidth-1:kernelBlockKWidth+groupSizeWidth]`：groupNum（组数）
        - `[kernelBlockKWidth+groupSizeWidth+groupNumWidth+kernelBlockCinWidth-1:kernelBlockKWidth+groupSizeWidth+groupNumWidth]`：cinIdx（当前输入通道组的序号）
        - `[kernelBlockKWidth+groupSizeWidth+groupNumWidth+kernelBlockCinWidth+kernelBlockCoutWidth-1:kernelBlockKWidth+groupSizeWidth+groupNumWidth+kernelBlockCinWidth]`：cout（输出通道数）
        - 其他位预留扩展
    - **注意**：各参数位宽由Config对象定义，需保证configBusWidth足够容纳所有参数。
  - **典型用法**：
    1. 写入kernel配置寄存器：
       ```scala
       // kernelConfig: k, groupSize, groupNum, cinIdx, cout
       val kernelConfig = (cout << (kernelBlockKWidth + groupSizeWidth + groupNumWidth + kernelBlockCinWidth)) |
                          (cinIdx << (kernelBlockKWidth + groupSizeWidth + groupNumWidth)) |
                          (groupNum << (kernelBlockKWidth + groupSizeWidth)) |
                          (groupSize << kernelBlockKWidth) |
                          k
       writeConfig(dut, tileId, kernelConfig)
       ```
    2. 拉高start.valid启动FSM，在FSM拉起start.ready信号后才有效
    3. FSM自动完成多层循环调度，期间自动分发权重和输入数据
    4. 运算完成后拉高done.valid（done.bits恒为true），外部必须拉高done.ready信号完成握手，否则无法发起下一次start握手
    5. 若发生异常，error信号拉高
  - **多层嵌套循环结构**：
    1. **第一层（最内层）循环**：Cluster结构的输入写满（groupSize次写入），对应卷积核参数的输入通道
    2. **第二层循环**：卷积核2D结构一行的遍历（k次写满）
    3. **第三层循环**：卷积核所有行的遍历（k次行遍历）
    4. **第四层循环**：卷积核块的遍历（cout次行遍历）
    5. **特殊处理**：k=1时跳过第2、3层循环结构
  - **注意事项**：
    1. 配置参数必须严格按照上述分配方式拼接和分段，否则FSM无法正确解析
    2. pingpong机制：配置前必须先将pingpong信号设置为false，配置完成后拉高为true，等待2个周期生效
    3. 权重SRAM为同步读，地址提前一拍，FSM内部已自动处理
    4. inputNoc.valid为寄存器结构，ready拉低时valid也拉低，确保数据时序安全
    5. 超时检测：若inputNoc.ready长时间未响应，FSM自动进入error状态
    6. 错误检查：k不能大于2倍groupNum，否则触发errorFlag1
  - **关键特性**：
    1. 支持多层嵌套循环的自动调度
    2. 灵活的可重构参数配置
    3. 乒乓配置寄存器机制
    4. 完善的异常检测与恢复
    5. 兼容Cluster与SRAM等模块的标准接口
    6. 支持卷积核尺寸可重构（1-16）
    7. 权重缓存与输出缓存的乒乓更新解耦合

### 7. MultipleDetector 模块

#### 文件: `src/main/scala/machine/MultipleDetector.scala`

- **MultipleDetector 类**
  - 功能: 快速检测数A+1是否是数B的整数倍的专用模块，用于优化Tile调度和资源分配
  - 参数: 继承全局Config对象的tileSize参数
  - 接口信息:
    ```scala
    val io = IO(new Bundle {
      val A = Input(UInt(tileIdWidth.W))  // 输入数A
      val B = Input(UInt(tileIdWidth.W))  // 输入数B
      val isValid = Output(Bool())      // A+1是否是B的整数倍
      val multiple = Output(UInt(tileIdWidth.W))  // A=1与B之间的倍数关系（如果isValid为true）
    })
    ```
  - **算法原理**：
    1. **特殊情况处理**：
       - B=0时：非法输入，返回false
       - B=1时：任何数都是1的倍数，返回true，倍数为A+1
       - B=2时：检查A+1是否为偶数，通过检查A的第0位实现
    2. **一般情况处理（B≥3）**：
       - 计算TileSize内B的所有倍数
       - 与A+1进行比较
       - 使用优先级编码器找到匹配的倍数
  - **电路工作原理**：
    1. **输入处理**：
       - 计算A+1作为比较基准
       - 根据B的值选择不同的处理路径
    2. **特殊情况检测**：
       - 使用when-elsewhen-otherwise结构处理B=0、B=1、B=2的情况
       - B=2时通过位操作检查奇偶性
    3. **倍数计算**：
       - 生成tileSize个比较器，每个检查一个倍数
       - 使用VecInit创建比较结果向量
    4. **优先级编码**：
       - 使用PriorityEncoder模块找到最高优先级的匹配
       - 输出匹配的倍数和有效性标志
  - **位宽计算**：
    - tileIdWidth = 2 * log2Ceil(tileSize)
    - 高半表示NoCId，低半表示TileId
    - 与Cluster模块的tileIdWidth定义保持一致
  - **关键特性**：
    1. 高效的硬件实现，支持单周期检测
    2. 完整的边界条件处理
    3. 优化的倍数计算算法
    4. 与系统其他模块的位宽兼容
    5. 支持大规模Tile集群的调度优化

- **PriorityEncoder 类**
  - 功能: 优先级编码器，输入n位向量，输出最高位1的位置
  - 参数: n - 输入向量长度
  - 接口信息:
    ```scala
    val io = IO(new Bundle {
      val in = Input(Vec(n, Bool()))
      val out = Output(UInt(log2Ceil(n).W))
    })
    ```
  - **实现方式**：
    - 使用chisel3.util.PriorityEncoder
    - 自动处理位宽计算
    - 支持任意长度的输入向量

### 8. OutRouterPlane 模块

#### 文件: `src/main/scala/machine/OutRouterPlane.scala`

- **OutRouterPlane 类**
  - 功能: 引入嵌入平面处理功能的高级路由模块，使用3级流水线架构进行数据（输入通道）补齐与（列、行向拼接），支持复杂的特征图Block拼接操作。
  - 参数:
    - `tileId`: 当前OutRouterPlane的唯一ID号，与FSM的ID号相同
    - 继承全局Config对象的所有配置参数
  - 接口信息:

    ```scala
    val io = IO(new Bundle {
      val pingpong = Input(Bool())
      val configBus = new Bundle {
        val data = Input(UInt(configBusWidth.W))
        val tileId = Input(UInt(tileIdWidth.W))
      }
      val outputNoc = Flipped(Decoupled(new Bundle {
        val data = Vec(colSize, SInt((outputWidth+log2Ceil(tileSize)+log2Ceil(colSize)).W))
        val featureMapLine = UInt(tileIdWidth.W)
        val count = UInt(8.W)
        val cout = UInt(kernelBlockCoutWidth.W)
        val kernelRow = UInt(kernelBlockKWidth.W)
        val remain = UInt(16.W)
      }))
      val done = Decoupled(Bool())
      
      // 双SRAM接口
      val outputSramWrite = new Bundle {
        val enable = Output(Bool())
        val address = Output(UInt(outputAddrWidth.W))
        val data = Output(Vec(colSize, UInt(outputBufferDataWidth.W))) // 使用Vec格式，数据位宽为outputBufferDataWidth
      }
      val outputSramRead = new Bundle {
        val enable = Output(Bool())
        val address = Output(UInt(outputAddrWidth.W))
        val data = Input(Vec(colSize, UInt(outputBufferDataWidth.W))) // 使用Vec格式，数据位宽为outputBufferDataWidth
      }
      val jointSramWrite = new Bundle {
        val enable = Output(Bool())
        val address = Output(UInt(log2Ceil(Config.jointSramLength).W))
        val writeData = Output(Vec(colSize, UInt(outputBufferDataWidth.W))) // 使用Vec格式，数据位宽为outputBufferDataWidth
      }
      val jointSramRead = new Bundle {
        val enable = Output(Bool())
        val address = Output(UInt(log2Ceil(Config.jointSramLength).W))
        val readData = Input(Vec(colSize, UInt(outputBufferDataWidth.W))) // 使用Vec格式，数据位宽为outputBufferDataWidth
      }
    })
    ```

  - **配置寄存器信息域划分（最新版）**
    
    配置寄存器（32位）按照从低位到高位的顺序包含以下信息域：

    | 位段范围                                                               | 字段名            | 位宽                  | 功能说明                                        |
    |-------------------------------------------------------------------------|------------------|-----------------------|------------------------------------------------|
    | [kernelBlockKWidth-1:0]                                                | k                | kernelBlockKWidth     | 卷积核窗口尺寸，决定高向拼接范围                |
    | [kernelBlockKWidth+groupSizeWidth-1:kernelBlockKWidth]                 | groupSize        | groupSizeWidth        | 一组内的Tile数量，影响输入通道分组                |
    | [kernelBlockKWidth+groupSizeWidth+groupNumWidth-1:kernelBlockKWidth+groupSizeWidth] | groupNum | groupNumWidth | Cluster内组数，决定outputSram存储范围           |
    | [+cinIdxWidth-1:+groupNumWidth]                                        | cinIdx           | cinIdxWidth           | 当前特征图Block的起始通道索引，用于通道补齐      |
    | [+kernelBlockCoutWidth-1:+cinIdxWidth]                                 | cout             | kernelBlockCoutWidth  | 输出结果图Block的通道数，影响地址计算            |
    | [+resolutionColIdxWidth-1:+kernelBlockCoutWidth]                       | resolutionColIdx | resolutionColIdxWidth | 特征图Block在整个图像分辨率中的列索引，用于列向拼接 |
    | [+workModeWidth-1:+resolutionColIdxWidth]                              | workMode         | workModeWidth(=2)     | 工作模式，控制拼接和补齐行为                     |

    **配置寄存器打包示例**：
    ```scala
    val kernelConfig = (workMode << (kernelBlockKWidth + groupSizeWidth + groupNumWidth + cinIdxWidth + kernelBlockCoutWidth + resolutionColIdxWidth)) |
                      (resolutionColIdx << (kernelBlockKWidth + groupSizeWidth + groupNumWidth + cinIdxWidth + kernelBlockCoutWidth)) |
                      (cout << (kernelBlockKWidth + groupSizeWidth + groupNumWidth + cinIdxWidth)) |
                      (cinIdx << (kernelBlockKWidth + groupSizeWidth + groupNumWidth)) |
                      (groupNum << (kernelBlockKWidth + groupSizeWidth)) |
                      (groupSize << kernelBlockKWidth) |
                      k
    ```

  - **工作模式详细说明**
    - **workMode=0**: 默认模式，不进行任何补齐或拼接操作
      - 适用场景：特征图Block为顶端最左侧，且cin=0的Block
      - 数据处理：直接将outputNoc数据写入对应的SRAM
    - **workMode=1**: 初始列向拼接模式
      - 适用场景：特征图Block为非顶端但是最左侧的Block
      - 数据处理：需要进行高向拼接，不进行列向拼接
    - **workMode=2**: 一般列向拼接模式
      - 适用场景：特征图Block为非顶端且非左侧的Block
      - 数据处理：同时进行高向拼接和列向拼接
    - **workMode=3**: 仅输入通道补齐模式
      - 适用场景：特征图Block为cin!=0的Block，需要与之前通道的结果累加
      - 数据处理：从对应位置读取已有数据进行累加

  - **双SRAM缓存结构详细设计**
    
    **outputSram（主要结果缓存）**：
    - **存储内容**: 结果图Block的主体部分（第0~groupNum行）
    - **地址计算**: `outputBaseAddr = (cout * (groupNum + 1)) << 1`
    - **写地址**: `outputWriteAddr = outputBaseAddr + ((k - kernelRow) << 1) + (featureMapLine << 1) + count`
    - **写使能条件**: `position <= groupNum`，其中`position = featureMapLine + (k - kernelRow)`
    - **存储器结构**: `colSize`个SRAM阵列，每个单元32bit位宽，共享地址映射
    - **数据接口**: 使用Vec格式，`Vec(colSize, UInt(outputBufferDataWidth.W))`，数据位宽为outputBufferDataWidth（32位）

    **jointSram（边界拼接缓存）**：
    - **存储内容**: 结果图Block的高向冗余部分（第groupNum+1~groupNum+k行）和列向拼接缓存区
    - **基地址**: `jointBaseAddr = resolutionColIdx * (cout+1) * k + cout * k`
    - **拼接缓存偏移**: `jointBufferBias = (maxResolutionCol/colSize + 1) * (cout + 1) * k`
    - **写地址**: `jointWriteAddr = jointBaseAddr + (position-groupNum-1) + Mux(count === 0, 0, jointBufferBias)`
    - **写使能条件**: `position > groupNum`
    - **双区域设计**: 结果区域和拼接缓存区，支持复杂的列向拼接操作
    - **数据接口**: 使用Vec格式，`Vec(colSize, UInt(outputBufferDataWidth.W))`，数据位宽为outputBufferDataWidth（32位）

  - **3级流水线架构详细功能**
    
    **Stage 0（地址计算与信号缓存级）**：
    - **主要功能**: 
      - 缓存outputNoc输入数据和控制信号
      - 计算所有读写地址（outputWriteAddr, jointWriteAddr, outputReadAddr等）
      - 生成读写使能信号（outputWriteEn, jointWriteEn, outputReadEn等）
      - 数据量化截断（truncateData函数，截断为finalWidth位宽）
    - **关键操作**: 规避行读与列读地址冲突，为后续级准备地址信息
    - **信号传递**: 使用RegNext实现所有信号的时序传递

    **Stage 1（高向拼接读取与累加级）**：
    - **主要功能**:
      - 执行通道补齐和高向拼接的SRAM读取操作
      - 完成高向拼接数据的累加运算
      - 为Stage 2的列向拼接读取做准备
    - **累加逻辑**: `s1_mergedData(i) = s1_currentData(i) + s1_jointReadElements(i) + s1_outputReadElements(i)`
    - **读取条件**:
      - outputSram读取：workMode=3（通道补齐）或workMode=2且position≤groupNum且count=0（列向拼接）
      - jointSram高向读取：workMode=3且position>groupNum（通道补齐）或workMode=1/2且position<k（高向拼接）
    - **数据处理**: 将读取的32bit×colSize数据拆分为独立元素进行累加

    **Stage 2（列向拼接累加与写回级）**：
    - **主要功能**:
      - 执行列向拼接的SRAM读取和累加运算  
      - 完成最终数据的SRAM写回操作
      - 处理数据格式转换（SInt到UInt，向量到总线）
    - **列向拼接逻辑**: `s2_mergedData(i) = s2_currentData(i) + s2_jointReadElements(i)`
    - **列向拼接条件**: workMode=2且position>groupNum且count=0
    - **写回操作**:
      - outputSram写回：s2_valid && s2_outputWriteEn
      - jointSram写回：s2_valid && s2_jointWriteEn
    - **数据转换**: 通过Cat函数将Vec格式转换为总线格式

  - **关键地址计算算法**
    
    **position计算**：`position = featureMapLine + (k - kernelRow)`
    - 作用：确定当前数据在结果图中的绝对行位置
    - 用途：判断数据应写入outputSram还是jointSram

    **读地址计算**：
    - **outputReadAddr**: 用于列向拼接，读取相邻Block的数据
    - **jointHeightReadAddr**: 用于高向拼接和通道补齐
    - **jointWidthReadAddr**: 用于列向拼接的缓存区读取

  - **数据流控制与时序**
    - **流水线特性**: 始终运行，不依赖valid信号驱动
    - **使能控制**: 通过En信号掩码控制有效数据处理
    - **握手机制**: outputNoc.ready始终为true，支持连续数据流
    - **完成检测**: 基于count、kernelRow、cout、featureMapLine的综合判断

  - **优化特性**
    1. **并行处理**: colSize个数据元素同时处理
    2. **流水线化**: 3级流水线支持高吞吐量数据处理
    3. **灵活拼接**: 支持高向和列向的复杂拼接模式
    4. **地址优化**: 预计算地址减少运行时延迟
    5. **错误避免**: Stage 0空级避免读写冲突

---

### MacMachine 模块

#### 文件: `src/main/scala/machine/MacMachine.scala`

- **MacMachine 类**
  - 功能: 实现多核加速器的顶层集成，封装 FSM、Cluster、OutRouterPlane 三大模块，统一管理配置、特征图、权重、输入输出等全流程数据流。
  - 接口信息:

    ```scala
    val io = IO(new Bundle {
      val pingpong = Input(Bool())
      val configBus = new Bundle {
        val data = Input(UInt(Config.configDataWidth.W))
        val addr = Input(UInt(Config.configAddrWidth.W))
        val en = Input(Bool())
      }
      val featureMapBus = new Bundle {
        val data = Input(UInt(Config.featureMapBandWidth.W))
        val tileId = Input(UInt((2*log2Ceil(Config.tileSize)).W))
        val addr = Input(UInt(log2Ceil(Config.colSize * Config.rowSize).W))
        val en = Input(Bool())
      }
      val start = Flipped(Decoupled(Bool())) // 启动信号
      val FSMdone = Decoupled(Bool())        // FSM完成信号
      val OutRouterdone = Decoupled(Bool())  // OutRouter完成信号
      val weightSramRead = new Bundle {
        val readEnable = Output(Bool())
        val readAddress = Output(UInt(weightAddrWidth.W))
        val readData = Input(UInt((rowSize * dataWidth).W))
      }
      val outputSramWrite = new Bundle {
        val writeEnable = Output(Bool())
        val writeAddress = Output(UInt(outputAddrWidth.W))
        val writeData = Output(UInt((colSize * outputBufferDataWidth).W))
      }
      val outputSramRead = new Bundle {
        val readEnable = Output(Bool())
        val readAddress = Output(UInt(outputAddrWidth.W))
        val readData = Input(UInt((colSize * outputBufferDataWidth).W))
      }
      val jointSramWrite = new Bundle {
        val writeEnable = Output(Bool())
        val writeAddress = Output(UInt(log2Ceil(Config.jointSramLength).W))
        val writeData = Output(UInt((colSize * outputBufferDataWidth).W))
      }
      val jointSramRead = new Bundle {
        val readEnable = Output(Bool())
        val readAddress = Output(UInt(log2Ceil(Config.jointSramLength).W))
        val readData = Input(UInt((colSize * outputBufferDataWidth).W))
      }
      val error = Output(Bool())
    })
    ```

  - **全局配置寄存器（非乒乓）**
    
    MacMachine 模块包含一个全局配置寄存器，用于控制整个系统的行为模式。**注意：此寄存器为非乒乓寄存器，与FSM、Cluster、OutRouter等模块的乒乓配置寄存器不同。**

    **寄存器地址**: `Config.maxMachineApbEnd` (0x00411FFF)
    
    **寄存器位域分配（32位）**:
    
    | 位段范围 | 字段名     | 位宽 | 功能说明                           |
    |----------|------------|------|-----------------------------------|
    | [7:0]    | actionMode | 8位  | 全局行为模式控制，用于控制整个系统的计算模式 |
    | [31:8]   | remain     | 24位 | 预留扩展位                         |

    **配置示例**:
    ```scala
    // 写入全局配置寄存器
    configBus.addr := 0x00411FFF.U
    configBus.data := actionModeValue
    configBus.en := true.B
    ```

    **与乒乓配置寄存器的区别**:
    - **乒乓配置寄存器**: 用于FSM、Cluster、OutRouter等子模块的配置，需要先设置pingpong=false，配置完成后设置pingpong=true生效
    - **全局配置寄存器**: 直接写入生效，无需乒乓机制，用于全局行为控制

  - **时序与模块协同**
    - start信号同时驱动FSM和OutRouterPlane，二者均需握手后进入工作状态
    - FSMdone和OutRouterdone分别由FSM和OutRouterPlane拉起
    - 错误信号为FSM和OutRouterPlane的或
    - 配置、特征图、权重、SRAM接口均为直连
    - 全局配置寄存器通过configBus直接写入，无需乒乓机制

---

（其它模块如Cluster、FSM等如无接口/寄存器/时序重大变化可保持原文档描述）

## 测试

测试文件位于 `src/test/scala/core/` 目录下，包括 `CIMCoreTest.scala` 和 `MACTreeTest.scala`，用于验证核心模块的功能和性能。

## 使用说明

1. 克隆项目到本地。
2. 使用 `sbt` 构建工具编译和运行项目。
3. 运行测试以验证模块功能
4. 各个模块的测试代码的命名规则为<模块名>Test.scala
5. 从tmp中拉取对应的测试代码运行run test进行仿真
6. 在顶层目录下执行 sbt相关指令
7. 仿真波形位于test_run_dir目录下
8. 统一：valiid-ready信号，均常闭，一般情况下，ready在识别到valid后才能被拉起，valid识别到ready信号后才能拉低

## 联系信息

- 作者: 陈挺然
- 邮箱: 18073369150@buaa.edu.cn


## 模块更新说明

### SRAM接口格式更新（最新版本）

在最新版本中，所有SRAM接口的数据字段已从UInt格式更新为Vec格式，以提供更好的类型安全性和代码可读性：

#### 主要变化
1. **数据格式统一**: 所有SRAM接口的data字段现在使用`Vec(colSize, UInt(outputBufferDataWidth.W))`格式
2. **位宽标准化**: 数据位宽统一为`outputBufferDataWidth`（32位）
3. **类型安全**: 使用Vec类型提供编译时类型检查，避免运行时错误

#### 受影响的模块
- **OutRouterPlane**: outputSram和jointSram接口
- **MacMachine**: 顶层SRAM接口封装
- **测试代码**: MacMachineTest等测试文件已相应更新

#### 接口示例
```scala
// 旧格式（已废弃）
val data = Output(UInt((outputBufferDataWidth * colSize).W))

// 新格式（当前使用）
val data = Output(Vec(colSize, UInt(outputBufferDataWidth.W)))
```

#### 优势
- **类型安全**: 编译时检查数据类型匹配
- **代码清晰**: 直接反映数据的向量特性
- **性能提升**: 避免不必要的数据打包/解包操作
- **维护性**: 更容易理解和维护的代码结构

### DynamicTruncateData 模块集成

在最新版本中，`OutRouterPlanePost` 模块集成了优化后的 `DynamicTruncateData` 模块，用于动态截位控制：

#### 主要特性
1. **动态截位控制**：通过 `truncateBits` 寄存器字段实现运行时截位位数控制
2. **位宽自适应**：根据输入输出位宽自动选择最优处理策略
3. **性能优化**：在28nm工艺下时钟频率从526MHz提升到625MHz
4. **硬件资源优化**：简化四舍五入逻辑，减少MUX开销

#### 配置寄存器更新
- **Special配置寄存器**新增 `truncateBits` 字段（4位）
- 位域分配：`[31:28] - truncateBits (4位) + [27:25] - workMode (3位) + [24:14] - colIdx (11位) + [13:3] - cinIdx (11位) + [2:0] - 预留位`
- **参数语义更新**：`DynamicTruncateData` 的输出位宽与输入位宽一致，`outputWidth` 表示有效位宽

#### 使用方式
```scala
// 设置截位位数为1
val specialConfig = (BigInt(1) << 24) | (workMode << 21) | (colIdx << 11) | cinIdx
writeConfig(dut, specialConfig, Config.FSMRouterConfIdEnd)
```

### OutRouterPlane 替换 OutRouter

在最新版本中，原始的 `OutRouter` 模块已被功能更强大的 `OutRouterPlane` 模块所替代。主要改进包括：

1. **增强的平面处理功能**：支持输入通道补齐与列、行向拼接操作
   - 高向拼接：处理卷积边界重叠区域的数据累加
   - 列向拼接：实现相邻特征图Block的水平拼接
   - 通道补齐：支持多输入通道的数据累加操作

2. **双SRAM缓存架构**：引入专门设计的双缓存结构
   - **outputSram**：存储主要结果数据（0~groupNum行）
   - **jointSram**：处理边界数据和拼接缓存（groupNum+1~groupNum+k行）
   - 每个SRAM支持colSize个并行存储单元，32bit位宽

3. **3级流水线处理**：采用精心设计的流水线架构
   - **Stage 0**：地址计算与信号缓存，避免读写冲突
   - **Stage 1**：高向拼接读取与累加，处理垂直方向数据融合
   - **Stage 2**：列向拼接累加与写回，完成水平方向数据融合和最终写回

4. **灵活的工作模式**：支持4种精确定义的工作模式
   - **Mode 0**：默认模式，直接数据传递
   - **Mode 1**：初始列向拼接，处理左边界Block
   - **Mode 2**：一般列向拼接，处理中间Block的复杂拼接
   - **Mode 3**：通道补齐模式，处理多通道累加

5. **扩展的配置接口**：增强的配置寄存器设计
   - 新增 `resolutionColIdx` 字段：支持全局坐标定位
   - 新增 `workMode` 字段：精确控制处理模式
   - 完整的 `cout` 和 `kernelRow` 信号：支持复杂卷积操作
   - 32位配置寄存器的精确位域划分

6. **高性能特性**：
   - 并行数据处理：colSize个元素同时处理
   - 预计算地址：减少运行时延迟
   - 连续数据流：支持无暂停的数据处理
   - 智能使能控制：基于工作模式的精确控制逻辑

### FSM 模块接口更新

FSM模块的接口也进行了相应更新：
1. 增加了 `cout` 和 `kernelRow` 信号域
2. 配置寄存器参数扩展，支持 `groupNum` 和 `cinIdx` 参数
3. 权重SRAM接口信号名称统一化

### MacMachine 模块全局配置寄存器

在最新版本中，MacMachine 模块新增了全局配置寄存器功能：

#### 主要变化
1. **新增全局配置寄存器**: 地址为 `Config.maxMachineApbEnd` (0x00411FFF)
2. **非乒乓机制**: 与子模块的乒乓配置寄存器不同，全局配置寄存器直接写入生效
3. **行为模式控制**: 通过 `actionMode` 字段控制整个系统的计算模式
4. **配置总线接口更新**: 增加了 `addr` 和 `en` 信号，支持地址寻址和使能控制

#### 接口变化
```scala
// 旧接口
val configBus = new Bundle {
  val data = Input(UInt(Config.configBusWidth.W))
  val tileId = Input(UInt((2*log2Ceil(Config.tileSize)).W))
}

// 新接口
val configBus = new Bundle {
  val data = Input(UInt(Config.configDataWidth.W))
  val addr = Input(UInt(Config.configAddrWidth.W))
  val en = Input(Bool())
}
```

#### 使用方式
- **全局配置寄存器**: 直接通过 `configBus` 写入，无需乒乓机制
- **子模块配置**: 仍使用乒乓机制，先设置 `pingpong=false`，配置完成后设置 `pingpong=true`

#### 优势
- **简化配置流程**: 全局配置无需乒乓机制，配置更简单
- **灵活控制**: 支持运行时动态调整系统行为模式
- **统一管理**: 在顶层统一管理全局配置，便于系统级控制

## 可能存在的问题

### 1. Cluster的inputNoc.ready逻辑问题

当前Cluster模块中inputNoc.ready信号的生成逻辑为：
```scala
io.inputNoc.ready := tiles.map(tile => tile.io.inputNoc.ready && (tile.io.inputId === io.inputNoc.bits.writeId)).reduce(_ || _)
```

这种实现存在以下潜在问题：
1. 使用或逻辑（`reduce(_ || _)`）可能导致数据丢失
   - 当多个Tile的inputId与writeId匹配时，只要有一个Tile ready就会拉高inputNoc.ready
   - 这可能导致数据被发送到未完全准备好的Tile
2. 可能引发数据竞争
   - 不同Tile的ready信号状态可能不一致
   - 使用或逻辑可能导致数据在错误的时机被发送
3. 建议修改为与逻辑
   - 只有当所有匹配的Tile都ready时，才拉高inputNoc.ready
   - 确保数据能够被所有目标Tile正确接收


