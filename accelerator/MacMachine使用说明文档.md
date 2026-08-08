# FLOOD Accelerator

> **文档定位（2026-08-08）**：本文是现有 MacMachine 的历史使用说明，保留用于理解 FLOOD 数据流。当前 SD1.5 ResNetBlock 原型的权威设计见[正式设计规格](../docs/superpowers/specs/2026-08-08-sd15-resnetblock-accelerator-design.md)。本文示例中的 `configBus.tileId` 等接口写法可能与当前源码不一致，实施前必须以 Chisel 接口和测试为准，不能直接据此定义新 AXI 寄存器。

## 概述
FLOOD 加速器是一个高效的通用卷积神经网络(CNN)加速器。其执行MAC计算的核心模块 MacMachine 采用多核架构和乒乓缓冲机制，支持可重构的卷积运算。MacMachine在实现了TOPS级吞吐量的情况下，实现了超低的片上缓存开销，并对k<=32的任意输入通道、输出通道卷积核均支持加速。

## MacMachine 模块使用说明

### 工作原理
MacMachine 是 FLOOD 加速器的核心控制模块，它通过有限状态机(FSM)控制权重数据的读取和分发，将数据送入由多个 Tile 组成的计算集群(Cluster)进行并行乘加运算，随后通过输出路由器(OutRouter)将计算结果写入输出 SRAM。整个系统采用乒乓缓冲机制，支持连续的数据流处理，并允许并发的与外部数据交互以及内部计算。

### 使用流程
1. **参数配置**  
   通过配置总线(configBus)设置卷积参数：
   ```scala
   // 示例：配置 k=3, cout=16, groupSize=4, groupNum=4
   io.configBus.tileId := fsmTileId
   io.configBus.data := Cat(3.U, 4.U, 4.U, 16.U)
   ```

2. **特征图写入**  
   通过特征图总线(featureMapBus)写入特征图数据：
   ```scala
   io.featureMapBus.tileId := targetTileId
   io.featureMapBus.addr := targetAddress
   io.featureMapBus.data := featureMapData
   ```
   - AXI总线的一个写通道直接对接该io
   - tile_0放置特征图Block第0行的数据，对应列向宽度为colSize，通道数为16; tile_1放置第1行的数据……，依次类推

3. **权重写入**  
   通过AXI总线写入到权重矩阵中：
   ```scala
   weightSramWrite(writeAddress)
   ```
   - AXI总线的一个写通道直接对接该io
   - 内部存储结构为：卷积核的列->卷积核的行->卷积核的输入通道->卷积核的输出通道
   - 内部数据连续摆放，不同列/行/输入通道/输出通道的数据之间无间隔


4. **启动计算**  
   通过 start 接口发起启动握手：
   ```scala
   while(!io.start.ready) {} // 等待FSM准备好启动下一个卷积核Block的计算
   io.start.valid := true.B
   ```

4. **识别工作完成**  
   监测 FSMdone 和 OutRouterdone 信号：
   ```scala
   // 等待 FSM 完成 (表示当前卷积核Block的所有数据输入完成)
   while(!io.FSMdone.valid) {}
   io.FSMdone.ready := true.B // 外部回握
   
   // 等待 OutRouter 完成 (表示所有计算结果均存储到输出Sram) (一般会略晚于FSMdone)
   while(!io.OutRouterdone.valid) {}
   io.OutRouterdone.ready := true.B // 外部回握
   ```
   - 等待期间可以完成乒乓特征图更新
   - 等待期间可以完成乒乓权重数据更新
   - 等待期间可以完成乒乓配置信息更新
   - 等待期间可以完成结果图迁移

5. **读取结果**  
   从输出 SRAM 读取计算结果：
   ```scala
   result = outputSramRead(readAddress)
   ```
   - MacMachine仅具有输出Sram的Write接口，该输出Sram的Read接口直接接入AXI总线的读通道
   - 内部存储结构为：数据的列->数据的行->数据的通道
   - 内部数据连续摆放，不同列/行/通道的数据之间无间隔

### 可配置参数

#### I 类参数 (Config 中设置)
| 参数名 | 默认值 | 描述 | 约束 |
|---|------|----------|------|
| `rowSize` | 32 | Tile的输入并行度大小(行尺寸) | 2 的幂 |
| `colSize` | 32 | Tile的输入并行度大小(列尺寸) | 2 的幂；>=最大k值 |
| `pipeline` | 1 | Tile内Mac树的流水线级数 | compressionFactor^pipeline <= rowSize |
| `compressionFactor` | 2 | Mac树除最后一级外每级流水线的数据维度压缩比 | compressionFactor^pipeline <= rowSize |
| `tileSize` | 16 | cluster内Tile的数量 | - |
| `dataWidth` | 8 | 特征图/卷积核的数据位宽 | - |
| `tileSize` | 4 | Cluster 内 Tile 数量 | - |
| `configBusWidth` | 32 | 配置总线位宽 | - |
| `featureMapBandWidth` | `colSize * dataWidth` | 特征图总线位宽 | - |
| `outputWidth` | `dataWidth + log2ceil(rowSize)` | Tile的输出量化精度 | - |
| `finalWidth` | `dataWidth + log2ceil(rowSize) + log2ceil(colSize)` | Cluster的输出量化精度 | - |
| `weightSramLength` | 4096 | 权重Sram的地址空间长度 | - |
| `outputSramLength` | 2048 | 权重Sram的地址空间长度 | - |



#### II 类参数 (通过配置寄存器设置)
| 参数名 | 位宽 | 有效范围 | 描述 | 约束 |
|--------|------|----------|------|------|
| `k` | `[log2Ceil(Config.maxKernelBlockK)-1:0]` | [0, maxKernelBlockK-1] | 卷积核尺寸k | - |
| `cout` | `[log2Ceil(Config.maxKernelBlockCout)-1:0]` | [0, maxKernelBlockCout-1] | 卷积核Block的输出通道数/结果图Block的通道数 | - |
| `groupSize` | `[log2Ceil(Config.maxGroupSize)-1:0]` | [0, maxGroupSize-1] | Cluster中若分组，一组内 Tile 的数量 | groupSize*groupNum<=tileSize |
| `groupNum` | `[log2Ceil(Config.maxGroupNum)-1:0]` | [0, maxGroupNum-1] | Cluster中若分组，总的组数 | groupSize*groupNum<=tileSize |

### IO 接口说明
| 接口名称 | 方向 | 位宽/类型 | 描述 |
|----------|------|------------|------|
| **乒乓控制** ||||
| `pingpong` | I | `[0:0]` | 乒乓缓冲区选择信号 |
| **配置总线** ||||
| `configBus.data` | I | `[Config.configBusWidth-1:0]` | 配置数据 |
| `configBus.tileId` | I | `[2*log2Ceil(Config.tileSize)-1:0]` | 目标 Tile ID |
| **特征图总线** ||||
| `featureMapBus.data` | I | `[Config.featureMapBandWidth-1:0]` | 特征图数据 |
| `featureMapBus.tileId` | I | `[2*log2Ceil(Config.tileSize)-1:0]` | 目标 Tile ID |
| `featureMapBus.addr` | I | `[log2Ceil(Config.colSize * Config.rowSize)-1:0]` | 写入地址 |
| **启动/完成** ||||
| `start` | I | `Decoupled[Bool]` | 启动握手信号 |
| `FSMdone` | O | `Decoupled[Bool]` | FSM 完成信号 |
| `OutRouterdone` | O | `Decoupled[Bool]` | OutRouter 完成信号 |
| **SRAM 接口** ||||
| `weightSramRead.readEnable` | O | `[0:0]` | 权重 SRAM 读使能 |
| `weightSramRead.readAddress` | O | `[log2Ceil(Config.weightSramLength)-1:0]` | 权重 SRAM 读地址 |
| `weightSramRead.readData` | I | `[Config.rowSize * Config.dataWidth-1:0]` | 权重 SRAM 读数据 |
| `outputSramWrite.writeEnable` | O | `[0:0]` | 输出 SRAM 写使能 |
| `outputSramWrite.writeAddress` | O | `[log2Ceil(Config.outputSramLength)-1:0]` | 输出 SRAM 写地址 |
| `outputSramWrite.writeData` | O | `[Config.finalWidth * Config.colSize-1:0]` | 输出 SRAM 写数据 |
| **状态指示** ||||
| `error` | O | `[0:0]` | 错误指示信号 |

> **注意**：所有位宽参数均来自 `Config` 对象，实际实现中会根据配置自动调整。

## 示例代码
参考测试用例 `MacMachineTest.scala`：
```scala
// 初始化配置
for(i=0; i<tileSize; i++){
   writeConfig(tileId = i, k = 3, cout = 16, groupSize = 4, groupNum = 4)
}

// 写入特征图数据
for(i=0;i<tileSize;i++){
   writeSram(startAddr=featureStartAddr+i*rowSize, length=rowSize)
}

// 写入权重数据
writeSram(startAddr=weightStartAddr, length=weightSramLength)

// 乒乓更新,切换为使用刚刚写入的数据
writeAPB(addr=pingPongAddr, value=~pingPong)

// 启动计算
startMacMachine()

// 计算同时执行乒乓更新
for(i=0;i<tileSize;i++){
   writeSram(startAddr=featureStartAddr+i*rowSize, length=rowSize)
}
writeSram(startAddr=weightStartAddr, length=weightSramLength)

// 等待计算完成
while(!done)

// 迁移结果
readSram(length)
```

## 资源利用率
| 资源类型 | 使用量 | 占比 |
|----------|--------|------|
| LUTs |  |  |
| FFs |  |  |
| BRAMs |  |  |

## 性能表现
| 卷积核尺寸 | 吞吐量 | 利用率 |
|----------|--------|------|
| 16×32×3×3 |  |  |
| 16×1024×3×3 |  |  |
| 256×1024×1×1 |  |  |
| 16×32×5×5 |  |  |
| 16×32×32×32 |  |  |