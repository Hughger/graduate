# MAC Unit 组件设计说明文档

## 1. 核心设计思想

MAC Unit 是一个专门为神经网络计算设计的加速器模块，采用分层架构设计，实现了从64位外部接口到256位内部SRAM的高效数据转换和管理。整个设计围绕以下核心思想：

### 1.1 数据宽度转换策略
- **外部接口**: 64位数据总线（符合标准AXI接口）
- **内部存储**: 256位数据总线（提高存储带宽和计算效率）
- **转换机制**: 通过4:1的数据聚合实现64位到256位的转换

### 1.2 多SRAM管理架构
- **6个独立SRAM**: 支持不同的数据存储需求
- **双端口设计**: 支持同时读写操作
- **控制切换**: 支持AXI和MAC Machine之间的控制权切换

### 1.3 模块化设计
- **接口标准化**: 统一的BRAM接口规范
- **功能分离**: 数据转换、存储管理、控制逻辑分离
- **可扩展性**: 支持不同配置的MAC Machine集成

## 2. 各模块功能详解

### 2.1 Mac_ASIC_top.v - 顶层集成模块
**功能**: 整个MAC Unit的顶层集成，协调各个子模块的工作

**主要特性**:
- 提供64位外部接口（dinout[63:0]）
- 集成6个SRAM存储单元
- 实现地址解码和SRAM选择逻辑
- 支持中断信号输出

**接口说明**:
```verilog
input  clk, rst_n
inout  [63:0] dinout        // 64位双向数据总线
input  [15:0] addr          // 16位地址总线
input  en, wr_en            // 使能和写使能信号
output macMachineDone_interrupt, macMachineerror_interrupt
```

### 2.2 design_ram_mux.v - RAM多路复用器
**功能**: 实现6个SRAM的地址解码和数据路由

**地址映射**:
- RAM 0: 0x5000_0000 - 0x5000_FFFF (配置总线)
- RAM 1: 0x5001_0000 - 0x5001_FFFF (输入数据)
- RAM 2: 0x5002_0000 - 0x5002_FFFF (权重SRAM 0)
- RAM 3: 0x5003_0000 - 0x5003_FFFF (权重SRAM 1)
- RAM 4: 0x5004_0000 - 0x5004_FFFF (输出SRAM 0)
- RAM 5: 0x5005_0000 - 0x5005_FFFF (输出SRAM 1)
- CTRL: 0x5006_0000 (控制寄存器)

**关键特性**:
- 支持同步BRAM时序
- 实现延迟使能信号匹配
- 提供控制信号生成

### 2.3 b64_b256.v - 64位到256位数据转换器
**功能**: 实现64位数据到256位SRAM的数据转换

**核心机制**:
- **数据聚合**: 4个64位数据聚合成1个256位数据
- **地址映射**: 13位地址转换为11位BRAM地址（除以4）
- **时序控制**: 使用计数器控制数据写入时机

**工作流程**:
1. 接收64位数据并存储到256位缓冲区
2. 使用2位计数器跟踪数据位置（0-3）
3. 当计数器达到3时，将完整256位数据写入BRAM
4. 读操作直接从BRAM读取并选择对应64位段

### 2.4 b64_b32.v - 配置总线接口
**功能**: 处理配置总线的64位到32位转换

**特性**:
- 提取64位数据的低32位作为配置数据
- 直接传递地址和使能信号
- 读操作返回0（配置总线为只写）

### 2.5 e203_bram_64k.v - 64KB伪双端口SRAM
**功能**: 提供64KB容量的伪双端口SRAM存储

**技术规格**:
- **容量**: 64KB (2048 × 256位)
- **端口**: 伪双端口（独立读写端口）
- **数据宽度**: 256位
- **地址宽度**: 11位
- **字节使能**: 32位字节使能支持

**关键特性**:
- 支持同时读写不同地址
- 完整的字节使能控制
- 同步时钟操作

### 2.6 RamCtrlSwitch.v - RAM控制切换器
**功能**: 在AXI控制器和MAC Machine之间切换RAM控制权

**控制机制**:
- **控制寄存器**: 位0控制切换（0=AXI，1=MAC）
- **地址**: 0xF_0000
- **多路复用**: 根据控制位选择数据源

**接口**:
- AXI接口: 来自外部AXI控制器的访问
- MAC接口: 来自MAC Machine的访问
- BRAM接口: 连接到实际SRAM

### 2.7 MacMachine_RamCtrlSimple.v - 简单RAM控制器
**功能**: 为MAC Machine提供简单的RAM控制接口

**特性**:
- 固定写入地址0
- 写入固定数据模式（全6模式）
- 仅在使能时工作

### 2.8 MacMachine_top.v - MAC Machine顶层
**功能**: 集成MacMachineWrapper并提供标准BRAM接口

**主要接口**:
- 配置总线接口
- 输入SRAM接口（内部BRAM）
- 权重SRAM接口（外部SRAM 0,1）
- 输出SRAM接口（外部SRAM 0,1）
- 内部Joint SRAM接口

## 3. 64位到256位数据转换详细说明

### 3.1 转换原理
64位inout口到256位SRAM的转换通过`b64_b256`模块实现，核心思想是**数据聚合**：

```
64位数据流 → 256位数据块
[63:0]   → [255:192] (第4个64位)
[63:0]   → [191:128] (第3个64位)  
[63:0]   → [127:64]  (第2个64位)
[63:0]   → [63:0]    (第1个64位)
```

### 3.2 地址映射关系
- **外部地址**: 13位（0-8191）
- **BRAM地址**: 11位（0-2047）
- **映射关系**: `BRAM_addr = External_addr[12:2]`
- **段选择**: `Segment = External_addr[1:0]`

### 3.3 时序控制
```verilog
// 计数器控制写入时机
reg [1:0] cnt;  // 0-3循环计数

// 数据缓冲区
reg [255:0] data_buffer;

// 写入逻辑
case (cnt)
    2'd0: data_buffer[63:0]    <= w_data;
    2'd1: data_buffer[127:64]  <= w_data;
    2'd2: data_buffer[191:128] <= w_data;
    2'd3: data_buffer[255:192] <= w_data;
endcase

// 当cnt=3时，写入BRAM
assign bram_w_en = (cnt == 2'd3);
```

### 3.4 读操作处理
```verilog
// 根据地址低2位选择对应64位段
assign r_data = bram_r_data[r_addr_reg[1:0]*64 +: 64];
```

## 4. 使用方法

### 4.1 基本操作流程

#### 4.1.1 数据写入流程
1. **选择目标SRAM**: 通过地址[15:13]选择SRAM
2. **连续写入4次**: 每次写入64位数据
3. **自动聚合**: 第4次写入后自动写入256位BRAM
4. **地址递增**: 每次写入后地址自动递增

#### 4.1.2 数据读取流程
1. **选择目标SRAM**: 通过地址[15:13]选择SRAM
2. **单次读取**: 一次读取操作获取64位数据
3. **段选择**: 根据地址[1:0]选择256位数据中的对应段

### 4.2 控制寄存器操作

#### 4.2.1 SRAM控制切换
```verilog
// 写入控制寄存器 0x5006_0000
// 数据格式: [3:0] 对应 RAM5-RAM2 的控制位
// 例如: 写入 0x0F 表示启用所有SRAM的MAC控制
```

#### 4.2.2 MAC Machine控制
```verilog
// 写入控制寄存器 0xF_0000
// 位0: 0=AXI控制, 1=MAC Machine控制
```

### 4.3 编程示例

#### 4.3.1 写入256位数据到SRAM
```c
// 假设要写入到RAM2 (0x5002_0000)
uint64_t data[4] = {0x123456789ABCDEF0, 0x23456789ABCDEF01, 
                    0x3456789ABCDEF012, 0x456789ABCDEF0123};

// 连续写入4次64位数据
for(int i = 0; i < 4; i++) {
    write_64bit(0x50020000 + i*8, data[i]);
}
// 第4次写入后，256位数据自动写入BRAM
```

#### 4.3.2 从SRAM读取64位数据
```c
// 读取特定段的64位数据
uint64_t data = read_64bit(0x50020002);  // 读取第3段数据
```

### 4.4 注意事项

1. **时序要求**: 写入操作必须连续4次，不能中断
2. **地址对齐**: 读取地址必须与4字节对齐
3. **控制切换**: 在切换控制权前确保当前操作完成
4. **中断处理**: 及时响应MAC Machine的中断信号

## 5. 系统集成

### 5.1 与E203 SoC集成
- 通过AXI总线接口连接
- 支持标准的内存映射访问
- 集成到E203的存储子系统

### 5.2 与MAC Machine集成
- 提供标准BRAM接口
- 支持配置总线通信
- 实现中断信号传递

### 5.3 性能特性
- **数据带宽**: 64位外部接口，256位内部处理
- **存储容量**: 6×64KB = 384KB总容量
- **访问延迟**: 1-4个时钟周期（取决于操作类型）
- **并发支持**: 支持同时读写不同SRAM

## 6. 地址跳转规律详解

### 6.1 SRAM写入地址跳转规律

#### 6.1.1 外部地址到内部地址映射
```
外部地址格式: [15:0] = {SRAM_SEL[2:0], ADDR[12:0]}
内部地址格式: [12:0] = ADDR[12:0] (直接传递)
BRAM地址格式: [10:0] = ADDR[12:2] (除以4，因为256bit=4×64bit)
```

#### 6.1.2 64位到256位转换的地址跳转
**写入操作**:
- 外部连续写入4次64位数据
- 地址跳转: `addr, addr+8, addr+16, addr+24` (每次+8字节)
- 内部BRAM地址: `addr[12:2]` (保持不变)
- 段选择: `addr[1:0]` 决定在256位数据中的位置

**地址跳转示例**:
```verilog
// 写入256位数据到地址0x50020000
write_64bit(0x50020000, data0);  // 段0: [63:0]
write_64bit(0x50020008, data1);  // 段1: [127:64]  
write_64bit(0x50020010, data2);  // 段2: [191:128]
write_64bit(0x50020018, data3);  // 段3: [255:192]
// 第4次写入后，完整256位数据写入BRAM地址0x1000
```

#### 6.1.3 读取操作的地址跳转
**单次读取**:
- 外部地址: 任意64位对齐地址
- 内部BRAM地址: `addr[12:2]`
- 段选择: `addr[1:0]` 选择256位数据中的对应64位段

### 6.2 配置数据写入地址规律

#### 6.2.1 配置总线地址映射
```
配置地址格式: [31:0] = {17'h0, addr[12:0]}
外部地址格式: [15:0] = {3'b000, addr[12:0]}  // RAM0选择
```

#### 6.2.2 配置数据写入规律
- **地址范围**: 0x5000_0000 - 0x5000_FFFF
- **数据格式**: 64位数据，低32位有效
- **写入方式**: 单次写入，无地址跳转
- **地址传递**: 直接传递到MacMachineWrapper

## 7. 32位配置数据格式详解

### 7.1 配置寄存器地址映射
```verilog
localparam [CFG_ADDRW-1:0] TILE_CONF_START    = 32'd0;   // Tile配置起始
localparam [CFG_ADDRW-1:0] NOC_CONF_START     = 32'd4;   // NoC配置起始  
localparam [CFG_ADDRW-1:0] FSM_CONF_START_ID  = 32'd7;   // FSM配置起始
localparam [CFG_ADDRW-1:0] FSM_CONF_END_ID    = 32'd8;   // FSM配置结束
localparam [CFG_ADDRW-1:0] GLOBAL_CONF_ID     = 32'd14;  // 全局配置
localparam [CFG_ADDRW-1:0] RUN_PROCESS_ID     = 32'd12;  // 运行控制
localparam [CFG_ADDRW-1:0] INTR_FRESH_ID      = 32'd13;  // 中断清除
```

### 7.2 各配置寄存器数据格式

#### 7.2.1 Tile配置寄存器 (地址0-3)
**数据格式**: `{featureMapLine[7:0], workMode[2:0], writeId[7:0], kminus1[1:0]}`
- **featureMapLine[7:0]**: 特征图行索引 (8位)
- **workMode[2:0]**: 工作模式 (3位)
- **writeId[7:0]**: 写入ID (8位)  
- **kminus1[1:0]**: 卷积核大小-1 (2位)

#### 7.2.2 NoC配置寄存器 (地址4-6)
**数据格式**: `{deliver, systolic, add, reserved}`
- **deliver**: 数据传递使能 (1位)
- **systolic**: 脉动阵列模式 (1位)
- **add**: 加法模式 (1位)
- **reserved**: 保留位 (1位)

#### 7.2.3 FSM配置寄存器

**FSM起始配置 (地址7)**:
**数据格式**: `{stride[2:0], cout_m1[7:0], groupNum_m1[7:0], groupSize_m1[7:0], k_m1[7:0]}`
- **stride[2:0]**: 步长-1 (3位)
- **cout_m1[7:0]**: 输出通道数-1 (8位)
- **groupNum_m1[7:0]**: 组数-1 (8位)
- **groupSize_m1[7:0]**: 组大小-1 (8位)
- **k_m1[7:0]**: 卷积核大小-1 (8位)

**FSM结束配置 (地址8)**:
**数据格式**: `{truncateBits[3:0], planeWorkMode[3:0], resolutionColIdx[7:0], cinIdx[7:0]}`
- **truncateBits[3:0]**: 截断位数 (4位)
- **planeWorkMode[3:0]**: 平面工作模式 (4位)
- **resolutionColIdx[7:0]**: 分辨率列索引 (8位)
- **cinIdx[7:0]**: 输入通道索引 (8位)

#### 7.2.4 全局配置寄存器 (地址14)
**数据格式**: `{featurePingpongFlag, weightPingpongFlag, outputPingpongFlag, reserved[23:0], actionMode[4:0]}`
- **featurePingpongFlag**: 特征图乒乓标志 (1位)
- **weightPingpongFlag**: 权重乒乓标志 (1位)
- **outputPingpongFlag**: 输出乒乓标志 (1位)
- **reserved[23:0]**: 保留位 (24位)
- **actionMode[4:0]**: 动作模式 (5位)
  - bit 0: dataFlowMode
  - bit 1: isFinalCinIdx
  - bit 2: bnEn (批归一化使能)
  - bit 3: actEn (激活使能)
  - bit 4: poolEn (池化使能)

#### 7.2.5 控制寄存器

**运行控制寄存器 (地址12)**:
- **数据**: 0x1 启动处理
- **功能**: 触发MAC Machine开始计算

**中断清除寄存器 (地址13)**:
- **数据**: 0x1 清除中断
- **功能**: 清除完成和错误中断标志

### 7.3 SRAM控制寄存器 (地址0x5006_0000)
**数据格式**: `{28'h0, ctrl_bits[3:0]}`
- **ctrl_bits[0]**: RAM2控制位 (权重SRAM 0)
- **ctrl_bits[1]**: RAM3控制位 (权重SRAM 1)  
- **ctrl_bits[2]**: RAM4控制位 (输出SRAM 0)
- **ctrl_bits[3]**: RAM5控制位 (输出SRAM 1)
- **0**: AXI控制, **1**: MAC Machine控制

## 8. 使用示例

### 8.1 完整的配置和运行流程
```c
// 1. 配置Tile参数
for(int tileId = 0; tileId < TILE_SIZE; tileId++) {
    uint32_t configData = {
        (featureMapLine & 0xFF) << 21 |
        (workMode & 0x7) << 18 |
        (writeId & 0xFF) << 10 |
        ((k-1) & 0x3) << 8
    };
    cfg_write(TILE_CONF_START + tileId, configData);
}

// 2. 配置NoC参数
for(int nocId = 0; nocId < TILE_SIZE-1; nocId++) {
    uint32_t configData = {
        (deliver ? 1 : 0) << 3 |
        (systolic ? 1 : 0) << 2 |
        (add ? 1 : 0) << 1
    };
    cfg_write(NOC_CONF_START + nocId, configData);
}

// 3. 配置FSM参数
uint32_t normalConfig = {
    ((stride-1) & 0x7) << 29 |
    ((cout-1) & 0xFF) << 21 |
    ((groupNum-1) & 0xFF) << 13 |
    ((groupSize-1) & 0xFF) << 5 |
    ((k-1) & 0x1F)
};
cfg_write(FSM_CONF_START_ID, normalConfig);

uint32_t specialConfig = {
    (truncateBits & 0xF) << 28 |
    (planeWorkMode & 0xF) << 24 |
    (resolutionColIdx & 0xFF) << 16 |
    (cinIdx & 0xFF) << 8
};
cfg_write(FSM_CONF_END_ID, specialConfig);

// 4. 配置全局参数
uint32_t globalConf = {
    (featurePingpongFlag ? 1 : 0) << 31 |
    (weightPingpongFlag ? 1 : 0) << 30 |
    (outputPingpongFlag ? 1 : 0) << 29 |
    (actionMode & 0x1F)
};
cfg_write(GLOBAL_CONF_ID, globalConf);

// 5. 启动处理
cfg_write(RUN_PROCESS_ID, 0x1);

// 6. 等待完成
wait_for_interrupt();

// 7. 清除中断
cfg_write(INTR_FRESH_ID, 0x1);
```

## 9. 总结

MAC Unit通过精心设计的数据转换机制，成功解决了64位外部接口与256位内部SRAM之间的数据宽度不匹配问题。整个设计采用模块化架构，具有良好的可扩展性和可维护性，为神经网络加速提供了高效的存储解决方案。

关键创新点：
1. **4:1数据聚合**: 高效的64位到256位转换
2. **多SRAM管理**: 灵活的存储资源分配
3. **控制权切换**: 支持不同控制器的动态切换
4. **标准化接口**: 便于系统集成和扩展
5. **精确的地址映射**: 清晰的外部到内部地址转换规律
6. **丰富的配置接口**: 支持复杂的神经网络参数配置
