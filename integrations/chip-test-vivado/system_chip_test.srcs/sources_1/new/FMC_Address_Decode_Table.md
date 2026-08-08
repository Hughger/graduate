# FMC 地址 → 芯片寄存器/SRAM 译码表

## 1. 总线架构概览

```
FPGA (AXKU15)                              ASIC 芯片 (FLOOD Accelerator)
┌─────────────────┐    FMC1 (J12)           ┌──────────────────────────┐
│  chip_add[15:0] │ ──────────────────────→ │ 内部总线译码器            │
│  chip_din[63:0] │ ←─────────────────────→ │   ├── CFG 寄存器空间      │
│  chip_wr_en     │ ──────────────────────→ │   ├── FEAT SRAM          │
│  chip_en        │ ──────────────────────→ │   ├── WEIGHT SRAM        │
│  chip_clk_ic    │ ──────────────────────→ │   ├── OUTPUT SRAM        │
│  chip_clk_core  │ ──────────────────────→ │   └── CTRL 寄存器        │
│  chip_rst_n_io  │ ──────────────────────→ │                          │
│  chip_rst_n_core│ ──────────────────────→ │                          │
│  chip_input_full│ ←────────────────────── │                          │
│  chip_output_emp│ ←────────────────────── │                          │
│  chip_mac_done  │ ←────────────────────── │                          │
│  chip_mac_err   │ ←────────────────────── │                          │
└─────────────────┘                         └──────────────────────────┘
```

## 2. 地址编码规则

| 项目 | 说明 |
|------|------|
| 芯片内部字节地址宽度 | 19 bit (`addr[18:0]`)，寻址空间 512KB |
| FMC 地址宽度 | 16 bit (`chip_add[15:0]`) |
| 数据宽度 | 64 bit（8 字节/字） |
| **chip_add 与字节地址关系** | `chip_add = byte_addr[18:3]`（64位字地址） |
| **芯片内部恢复字节地址** | `byte_addr = {chip_add, 3'b0}` |

> **注意**：`system_chip_test.v` 中使用的是字节地址常数（如 `ADDR_GLOBAL_CONF = 16'h0210`），
> 而 `chip_test_0601/0602/0603.v` 中使用的是字地址常数（如 `REG_GLOBAL = 16'h0042`）。
> 两者关系：**字地址 = 字节地址 >> 3**，**字节地址 = 字地址 << 3**。

---

## 3. 芯片内部地址空间译码（通过 chip_add 访问）

### 3.1 总地址空间划分

| chip_add 字地址 | 对应字节地址 | 大小 | 区域 | 说明 |
|:---:|:---:|:---:|:---:|------|
| `0x0000 - 0x1FFF` | `0x00000 - 0x0FFFF` | 64KB (8KW) | **CFG 配置寄存器** | Tile/NoC/FSM/Global/Run/Intr |
| `0x2000 - 0x3FFF` | `0x10000 - 0x1FFFF` | 64KB (8KW) | **FEAT 特征 SRAM** | 输入特征图数据 |
| `0x4000 - 0x7FFF` | `0x20000 - 0x3FFFF` | 128KB (16KW) | **WEIGHT 权重 SRAM** | 权重数据 |
| `0x8000 - 0xBFFF` | `0x40000 - 0x5FFFF` | 128KB (16KW) | **OUTPUT 输出 SRAM** | 计算结果（仅 0601 版本） |
| `0xC000` | `0x60000` | 1 字 | **CTRL 控制寄存器** | SRAM 访问权切换 |

### 3.2 CFG 配置寄存器空间详细译码 (chip_add = 0x0000 ~ 0x1FFF)

| 寄存器 ID | chip_add 字地址 | 字节地址 | 寄存器名称 | 位宽 | 读写 | 说明 |
|:---:|:---:|:---:|------|:---:|:---:|------|
| `0x00-0x0F` | `0x0000-0x000F` | `0x0000-0x0078` | **TILE_CONF[0:15]** | 32b×16 | W | 16 个 Tile 配置寄存器 |
| `0x10-0x1E` | `0x0010-0x001E` | `0x0080-0x00F0` | **NOC_CONF[0:14]** | 32b×15 | W | 15 个 NoC 路由配置寄存器 |
| `0x1F` | `0x001F` | `0x00F8` | **FSM_NORMAL** | 32b | W | FSM Normal 模式参数 |
| `0x20` | `0x0020` | `0x0100` | **FSM_SPECIAL** | 32b | W | FSM Special 模式参数 |
| `0x21-0x41` | `0x0021-0x0041` | `0x0108-0x0208` | *(保留)* | - | - | 保留未使用 |
| `0x42` | `0x0042` | `0x0210` | **GLOBAL_CONF** | 32b | W | 全局配置（pingpong/数据流模式等） |
| `0x43` | `0x0043` | `0x0218` | **RUN_PROCESS** | 64b | W | 写 1 触发 MAC 计算 |
| `0x44` | `0x0044` | `0x0220` | **INTR_FRESH** | 64b | W | 写 1 清除中断标志 |

### 3.3 FEAT 特征 SRAM (chip_add = 0x2000 ~ 0x3FFF)

| 参数 | 值 |
|------|:---:|
| 基地址（字地址） | `0x2000` |
| 基地址（字节地址） | `0x10000` |
| 容量 | 16K × 64bit = 128KB |
| 寻址方式 | 按 Tile/Row/Beat 三维索引 |

**特征地址计算公式：**
```
feat_dst_word = BUS_FEAT_BASE + ((tile × 32 + row) × 4) + beat
```
其中：`tile[4:0]` (0-15), `row[5:0]` (0-31), `beat[1:0]` (0-3)

### 3.4 WEIGHT 权重 SRAM (chip_add = 0x4000 ~ 0x7FFF)

| 参数 | 值 |
|------|:---:|
| 基地址（字地址） | `0x4000` |
| 基地址（字节地址） | `0x20000` |
| 容量 | 16K × 64bit = 128KB |
| 当前测试用量 | 1152 字 (WEIGHT_WORDS) |

**权重地址：**
```
weight_addr = BUS_WEIGHT_BASE + weight_idx
```
其中 `weight_idx[10:0]` (0-1151)

### 3.5 OUTPUT 输出 SRAM (chip_add = 0x8000 ~ 0xBFFF，仅 0601)

| 参数 | 值 |
|------|:---:|
| 基地址（字地址） | `0x8000` |
| 基地址（字节地址） | `0x40000` |
| 容量 | 16K × 64bit = 128KB |

**输出地址：**
```
result_addr = BUS_OUTP_BASE + result_idx
```

### 3.6 CTRL 控制寄存器 (chip_add = 0xC000)

| chip_add 字地址 | 字节地址 | 寄存器名称 | 有效位 | 读写 | 说明 |
|:---:|:---:|------|:---:|:---:|------|
| `0xC000` | `0x60000` | **SRAM_CTRL** | `[3:0]` | W | SRAM 访问权限切换 |

**CTRL 寄存器位定义：**

| CTRL[3:0] 值 | 宏名 | 含义 |
|:---:|------|------|
| `4'b0000` | `CTRL_EXT_ALL` | 所有 SRAM 归外部（CPU/FPGA）访问 |
| `4'b1111` | `CTRL_MAC_ALL` | 所有 SRAM 切换给 MAC 加速器 |
| `4'b0011` | `CTRL_RD_OUTPUT` | WEIGHT→MAC，OUTPUT→外部（读结果模式） |
| `CTRL[3]` | - | Weight SRAM 控制 (1=MAC) |
| `CTRL[2]` | - | Feature SRAM 控制 (1=MAC) |
| `CTRL[1]` | - | Output SRAM 控制 (1=MAC) |
| `CTRL[0]` | - | 保留/全局控制 |

---

## 4. FPGA 侧地址常数对照表

### 4.1 chip_test_0601/0602/0603.v 使用的常数（字地址）

| 常数名 | 字地址 (chip_add) | 对应字节地址 | 说明 |
|------|:---:|:---:|------|
| `BUS_CFG_BASE` | `0x0000` | `0x00000` | 配置寄存器基地址 |
| `BUS_FEAT_BASE` | `0x2000` | `0x10000` | 特征 SRAM 基地址 |
| `BUS_WEIGHT_BASE` | `0x4000` | `0x20000` | 权重 SRAM 基地址 |
| `BUS_OUTP_BASE` | `0x8000` | `0x40000` | 输出 SRAM 基地址 (仅 0601) |
| `BUS_CTRL` | `0xC000` | `0x60000` | 控制寄存器 |
| `REG_FSM_NORMAL` | `0x001F` | `0x000F8` | FSM Normal 配置 |
| `REG_FSM_SPECIAL` | `0x0020` | `0x00100` | FSM Special 配置 |
| `REG_GLOBAL` | `0x0042` | `0x00210` | 全局配置 |
| `REG_RUN` | `0x0043` | `0x00218` | 触发运行 |
| `REG_INTR` | `0x0044` | `0x00220` | 中断清除 |

### 4.2 system_chip_test.v 使用的常数（字节地址）

| 常数名 | 字节地址 | 对应字地址 (chip_add) | 说明 |
|------|:---:|:---:|------|
| `ADDR_TILE_CONF0` | `0x0000` | `0x0000` | Tile0 配置 |
| `ADDR_FSM_NORMAL` | `0x00F8` | `0x001F` | FSM Normal 配置 |
| `ADDR_FSM_SPECIAL` | `0x0100` | `0x0020` | FSM Special 配置 |
| `ADDR_GLOBAL_CONF` | `0x0210` | `0x0042` | 全局配置 |
| `ADDR_RUN_PROCESS` | `0x0218` | `0x0043` | 触发计算 |
| `ADDR_INTR_FRESH` | `0x0220` | `0x0044` | 清除中断 |

---

## 5. FSM Normal 配置寄存器位域 (REG_FSM_NORMAL = 0x001F)

面向 `mac_test_tb2.c` 中的 `run_process(k, cout, groupSize, groupNum, stride, ...)`：

| 位域 | 宽度 | 参数 | 0601/0603 值 | 说明 |
|:---:|:---:|------|:---:|------|
| `[31:27]` | 5 | stride-1 | `1` (stride=2) | 步长 |
| `[26:22]` | 5 | cout-1 | `1` (cout=2) | 输出通道数 |
| `[21:18]` | 4 | groupNum-1 | `7` (groupNum=8) | 分组数 |
| `[17:14]` | 4 | groupSize-1 | `1` (groupSize=2) | 每组大小 |
| `[13:9]` | 5 | k-1 | `2` (k=3) | 卷积核尺寸 |
| `[8:0]` | 9 | *(保留)* | `0` | - |

**0601 版本配置值：** `FSM_NORMAL_CFG = 32'h0007_EE22`
```
stride-1=1, cout-1=31, groupSize-1=1, groupNum-1=7, k-1=2
→ stride=2, cout=32, groupSize=2, groupNum=8, k=3
```

**0603 版本配置值：** `FSM_NORMAL_CFG = 32'h0004_2E22`
```
stride-1=1, cout-1=1, groupSize-1=1, groupNum-1=7, k-1=2
→ stride=2, cout=2, groupSize=2, groupNum=8, k=3
```

---

## 6. FSM Special 配置寄存器位域 (REG_FSM_SPECIAL = 0x0020)

| 位域 | 宽度 | 参数 | 值 | 说明 |
|:---:|:---:|------|:---:|------|
| `[31:29]` | 3 | planeWorkMode | `0` | 平面工作模式 |
| `[28:24]` | 5 | resolutionColIdx | `0` | 列分辨率索引 |
| `[23:18]` | 6 | cinIdx | `0` | 输入通道索引 |
| `[17:13]` | 5 | resolutionRowIdx | `0` | 行分辨率索引 |
| `[12:0]` | 13 | *(保留)* | `0` | - |

**典型值：** `FSM_SPECIAL_CFG = 32'h0000_0000`（全 0）

---

## 7. GLOBAL 配置寄存器位域 (REG_GLOBAL = 0x0042)

| 位域 | 说明 | 0603 值 |
|:---:|------|:---:|
| `[31]` | featurePingpong 使能 | `1` |
| `[30:0]` | *(保留/其他配置)* | `0` |

**典型值：** `GLOBAL_CFG_VAL = 32'h8000_0000`（使能 feature pingpong）

---

## 8. 完整测试流程中的地址访问序列

以 `chip_test_0603.v` 为例，一次完整测试中各状态写 chip_add 的顺序：

| 顺序 | FSM 状态 | chip_add | 操作 | 说明 |
|:---:|------|:---:|:---:|------|
| 1 | S_CFG_CTRL_LOAD | `0xC000` | 写 `CTRL_EXT_ALL (0)` | SRAM 全部归外部 |
| 2-17 | S_CFG_TILES | `0x0000-0x000F` | 写 16 个 Tile 配置 | Tile[0:15] 参数 |
| 18-32 | S_CFG_NOC | `0x0010-0x001E` | 写 15 个 NoC 配置 | NoC 路由参数 |
| 33-1184 | S_WRITE_WEIGHTS | `0x4000-0x447F` | 写 1152 个权重字 | 权重数据 |
| 1185 | S_CFG_CTRL_MAC | `0xC000` | 写 `CTRL_MAC_ALL (15)` | SRAM 全部归 MAC |
| 1186 | S_CFG_FSM_N | `0x001F` | 写 FSM Normal 配置 | 计算参数 |
| 1187 | S_CFG_FSM_S | `0x0020` | 写 FSM Special 配置 | 计算参数 |
| 1188-3235 | S_WRITE_FEATURES | `0x2000-0x27FF` | 写 2048 个特征字 | 输入特征 |
| 3236 | S_CFG_GLOBAL | `0x0042` | 写 Global 配置 | pingpong 等 |
| 3237 | S_START_MAC | `0x0043` | 写 1 触发计算 | 启动 MAC |
| 3238 | S_CLR_INTR | `0x0044` | 写 1 清中断 | 中断清除 |

---

## 9. E203 SoC 侧 AXI 地址映射（补充参考，非 FMC）

当芯片通过 E203 RISC-V 核以 AXI 总线访问时：

| SoC AXI 地址 | 大小 | 从设备 | 说明 |
|:---:|:---:|------|------|
| `0x4000_0000 - 0x4001_FFFF` | 128KB | S1 (Main BRAM) | 通用 BRAM |
| `0x5000_0000 - 0x500F_FFFF` | 1MB | S2 (ASIC I/F) | → 芯片内部总线 |
| `0x5001_0000 - 0x5001_FFFF` | 64KB | S3 (Weight SRAM) | 权重存储 |
| `0x5002_0000 - 0x5002_FFFF` | 64KB | S4 (Output SRAM) | 输出存储 |
| `0x0042_0000 - 0x0042_1FFF` | 8KB | DMA APB | DMA 控制器 |
| `0x8000_0000 - 0x8000_FFFF` | 64KB | ITCM | 指令紧耦合内存 |
| `0x9000_0000 - 0x9000_FFFF` | 64KB | DTCM | 数据紧耦合内存 |

---

## 10. 两种地址约定对比速查

| 版本 | 地址常数类型 | 示例 (GLOBAL) | chip_add 实际值 | 转换公式 |
|------|:---:|:---:|:---:|------|
| `system_chip_test.v` | 字节地址 | `16'h0210` | `0x0210` (**注意!**) | - |
| `chip_test_0601/0602/0603.v` | 字地址 (reg_id) | `16'h0042` | `0x0042` | `chip_add = byte_addr >> 3` |

> ⚠️ **重要差异**：`system_chip_test.v` 中 `ADDR_GLOBAL_CONF = 16'h0210` 是字节地址，
> 但直接赋值给 `chip_add`。如果芯片内部期望 `chip_add = byte_addr[18:3]`，
> 则 `system_chip_test.v` 的地址可能不兼容 `chip_test_060x` 系列。
> **建议以 `chip_test_0603.v` 的字地址方案为准。**
