# Week 1 详细任务分配

## 🎯 本周目标

**所有人能独立跑通单层卷积仿真，理解加速器基本工作原理**

---

## 📋 任务总览

| 角色 | 人数 | 组长 | 核心产出 |
|------|------|------|----------|
| 核心开发组 | 2人 | 学生1 | `mac_driver.c/h` |
| 验证测试组 | 2人 | 学生3 | 操作手册 + 验证报告 |
| 文档工具组 | 2人 | 学生5 | 寄存器手册 + Git仓库 |

---

## 🔧 核心开发组（2人）

### 学生1 - 驱动库提取

**任务**: 从mac_test_tb2.c中提取通用驱动函数

**具体工作**:
1. 阅读mac_test_tb2.c，理解以下函数:
   - `config_tiles_and_noc()` - Tile和NoC配置
   - `drive_weights_from_files()` - 权重加载
   - `drive_features_to_sram()` - 特征图加载
   - `run_process()` - 启动计算
   - 中断处理相关代码

2. 创建 `c/demo/common/mac_driver.h`:
```c
#ifndef MAC_DRIVER_H
#define MAC_DRIVER_H

#include <stdint.h>

// 配置函数
void mac_config_tiles(int group_size, int kernel_size);
void mac_config_noc(int work_mode);
void mac_config_fsm(int k, int cout, int group_size, int group_num, int stride);

// 数据加载函数
void mac_load_weights(uint32_t addr, const int8_t* weights, int size);
void mac_load_features(uint32_t addr, const int8_t* features, int size);

// 运行控制
void mac_run(int cin_idx, int col_idx, int row_idx);
void mac_wait_done(void);

// 结果读取
void mac_read_output(uint32_t addr, int8_t* output, int size);

#endif
```

3. 创建 `c/demo/common/mac_driver.c`，实现上述函数

**验收标准**:
- [ ] 头文件定义完整
- [ ] 所有函数有简单实现（可以先复制原代码）
- [ ] 代码能通过编译

---

### 学生2 - 配置函数封装

**任务**: 封装更上层的配置接口

**具体工作**:
1. 分析mac_test_tb2.c中的配置参数:
   - Tile配置寄存器 (0x00-0x0F)
   - NoC配置寄存器 (0x10-0x1E)
   - FSM配置寄存器 (0x1F-0x20)
   - 全局配置寄存器 (0x42)

2. 创建 `c/demo/common/mac_config.h`:
```c
#ifndef MAC_CONFIG_H
#define MAC_CONFIG_H

// 地址定义
#define MAC_BASE_ADDR       0x00420000
#define S1_BASE_ADDR        0x40000000
#define S2_BASE_ADDR        0x50000000

// 寄存器偏移
#define TILE_CONF_START     0x00
#define NOC_CONF_START      0x10
#define FSM_CONF_START      0x1F
#define GLOBAL_CONF         0x42
#define RUN_PROCESS         0x43

// 配置结构体
typedef struct {
    int k;              // kernel size
    int cout;           // output channels
    int cin;            // input channels
    int stride;         // stride
    int group_size;     // tile group size
    int group_num;      // tile group num
} ConvConfig;

// 配置函数
void mac_init(void);
void mac_config_conv(const ConvConfig* config);
void mac_start(void);
int mac_poll_done(void);

#endif
```

3. 实现配置函数，提供比底层驱动更易用的接口

**验收标准**:
- [ ] 配置结构体定义清晰
- [ ] 提供从配置结构体到寄存器写入的转换
- [ ] 有使用示例代码

---

## ✅ 验证测试组（2人）

### 学生3 - 环境搭建与操作手册

**任务**: 跑通仿真，记录详细步骤

**具体工作**:
1. 搭建个人开发环境:
   ```bash
   # 安装RISC-V GCC (如果还没装)
   # 配置环境变量
   export PATH=$PATH:/path/to/riscv64-unknown-elf-gcc/bin
   
   # 验证安装
   riscv64-unknown-elf-gcc --version
   ```

2. 编译现有代码:
   ```bash
   cd c/axi_test
   make clean
   make all
   # 应该生成 axi_test.elf axi_test.hex axi_test.bin
   ```

3. 运行仿真（询问你具体命令）

4. 创建 `doc/Week1_Simulation_Guide.md`:
   ```markdown
   # 单层卷积仿真操作手册
   
   ## 环境要求
   - RISC-V GCC: riscv64-unknown-elf-gcc
   - Verilog仿真器: VCS/Verilator/ModelSim
   - Python 3.8+
   
   ## 编译步骤
   1. 进入目录: `cd c/axi_test`
   2. 编译: `make all`
   3. 检查输出文件...
   
   ## 仿真步骤
   1. 准备仿真环境...
   2. 运行仿真命令...
   3. 查看结果...
   
   ## 常见问题
   - 问题1: ... 解决方案: ...
   - 问题2: ... 解决方案: ...
   ```

**验收标准**:
- [ ] 能独立编译代码
- [ ] 能运行仿真并看到结果
- [ ] 手册详细到新人能按步骤操作

---

### 学生4 - 结果验证

**任务**: 验证单层卷积结果正确性

**具体工作**:
1. 理解mac_test_tb2.c中的测试用例:
   - 输入特征图尺寸
   - 权重数据
   - 预期输出

2. 用Python实现软件卷积（作为golden reference）:
   ```python
   # tools/verify/conv_reference.py
   import numpy as np
   
   def conv2d_software(input_data, weights, stride=1):
       """软件卷积实现"""
       # 实现卷积计算
       pass
   
   def compare_results(hw_output, sw_output):
       """对比硬件和软件结果"""
       # 计算误差
       pass
   ```

3. 对比硬件输出和软件输出，分析误差

4. 创建 `doc/Week1_Verification_Report.md`:
   ```markdown
   # Week 1 验证报告
   
   ## 测试用例
   - 输入: ...
   - 权重: ...
   - 配置: ...
   
   ## 结果对比
   | 位置 | 硬件结果 | 软件结果 | 误差 |
   |------|----------|----------|------|
   | ...  | ...      | ...      | ...  |
   
   ## 结论
   - 结果是否正确: ...
   - 误差分析: ...
   ```

**验收标准**:
- [ ] Python软件卷积实现正确
- [ ] 能对比软硬件结果
- [ ] 有详细的验证报告

---

## 📝 文档工具组（2人）

### 学生5 - 寄存器手册整理

**任务**: 整理加速器寄存器手册

**具体工作**:
1. 阅读以下文件，提取寄存器信息:
   - `src/main/scala/core/Config.scala` - 硬件配置
   - `mac_test_tb2.c` - 寄存器地址使用
   - `AXI_Integration_Guide.md` - AXI接口

2. 创建 `doc/Register_Map.md`:
   ```markdown
   # FLOOD加速器寄存器手册
   
   ## 地址空间
   | 区域 | 起始地址 | 大小 | 说明 |
   |------|----------|------|------|
   | MacMachine | 0x00420000 | 64KB | 加速器配置 |
   | FeatureMap SRAM | 0x50000000 | 64KB | 特征图存储 |
   | S1 (BRAM) | 0x40000000 | 256MB | 数据存储 |
   
   ## 配置寄存器
   
   ### Tile配置 (0x00-0x0F)
   | 地址 | 名称 | 位域 | 说明 |
   |------|------|------|------|
   | 0x00 | TILE0 | [31:0] | Tile 0配置 |
   | ...  | ...  | ...  | ... |
   
   ### NoC配置 (0x10-0x1E)
   ...
   
   ### FSM配置 (0x1F-0x20)
   ...
   
   ### 全局配置 (0x42)
   ...
   
   ## 配置示例
   ```c
   // 配置3x3卷积
   write_reg(0x0042001F, 0x00030202);  // k=3, group_size=2, group_num=2
   ```
   ```

3. 绘制简单的架构图（可以用ASCII或手绘拍照）

**验收标准**:
- [ ] 所有寄存器地址准确
- [ ] 每个寄存器的位域说明清晰
- [ ] 有配置示例

---

### 学生6 - 仓库搭建与目录整理

**任务**: 搭建Git仓库，整理目录结构

**具体工作**:
1. 初始化Git仓库（如果没有）:
   ```bash
   cd /path/to/flood_accelerator
   git init
   git add .
   git commit -m "Initial commit"
   ```

2. 创建分支:
   ```bash
   git checkout -b week1/verify-single-layer
   ```

3. 整理目录结构:
   ```
   flood_accelerator/
   ├── rtl/                    # 已有RTL代码
   ├── c/
   │   ├── axi_test/          # 已有测试代码
   │   └── demo/              # 新建Demo目录
   │       ├── common/        # 通用代码
   │       ├── lenet/         # LeNet Demo
   │       └── cifar10/       # CIFAR-10 Demo
   ├── tools/                 # 工具脚本
   │   ├── quantization/      # 量化工具
   │   ├── preprocess/        # 预处理工具
   │   └── verify/            # 验证工具
   ├── tests/                 # 测试代码
   ├── doc/                   # 文档
   │   ├── meetings/          # 会议纪要
   │   └── guides/            # 操作手册
   └── fpga/                  # FPGA工程
   ```

4. 创建 `.gitignore`:
   ```
   # Build files
   *.o
   *.elf
   *.hex
   *.bin
   *.map
   *.dump
   
   # Python
   __pycache__/
   *.pyc
   
   # IDE
   .vscode/
   .idea/
   ```

5. 创建 `README.md`（项目说明）

**验收标准**:
- [ ] Git仓库初始化完成
- [ ] 目录结构清晰
- [ ] 有基本的README

---

## 📅 每日同步（建议）

虽然每周一次例会，但建议每天简单同步（10分钟）：

**时间**: 每天下午17:00（或其他固定时间）
**形式**: 微信群/线下
**内容**: 
1. 今天完成了什么
2. 遇到了什么问题
3. 明天计划做什么

---

## ✅ 周五检查点

### 整体检查
- [ ] 所有人能独立编译代码
- [ ] 所有人能运行仿真
- [ ] Git仓库已提交本周代码

### 各组产出
- [ ] 核心开发组: `mac_driver.c/h` + `mac_config.c/h`
- [ ] 验证测试组: 操作手册 + 验证报告
- [ ] 文档工具组: 寄存器手册 + 整理好的仓库

### 知识掌握
- [ ] 理解Tile配置原理
- [ ] 理解NoC配置原理
- [ ] 理解FSM配置原理
- [ ] 知道如何启动一次卷积计算

---

## 🆘 求助指南

### 技术问题
1. 先查文档: README.md, AXI_Integration_Guide.md
2. 组内讨论: 同组2人先讨论
3. 组间求助: 问其他组
4. 找你: 以上都解决不了

### 环境问题
- 编译问题 → 问学生3（验证组）
- Git问题 → 问学生6（文档组）
- 仿真问题 → 找你

---

## 📚 学习资料

### 必读（Week 1内完成）
1. `mac_test_tb2.c` - 理解单层卷积流程
2. `cnn_multilayer.c` - 了解多层框架
3. `Config.scala` - 了解硬件参数

### 参考
- RISC-V汇编基础
- AXI4协议简介
- CNN卷积计算原理

---

**文档版本**: v1.0  
**创建日期**: 2026-05-22  
**适用范围**: Week 1
