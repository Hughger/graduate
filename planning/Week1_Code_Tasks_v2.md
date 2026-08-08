# Week 1 任务分配 — 代码重构

## 一、本周目标

将mac_test_tb2.c（约2900行单文件）拆分为6个模块化驱动库，为后续Demo部署提供基础。

6人各负责一个独立模块，最终集成为可编译运行的程序，仿真结果与原版一致。

---

## 二、模块划分

mac_test_tb2.c拆分方案：

| 模块 | 文件 | 负责人 | 内容 |
|------|------|--------|------|
| 底层平台 | mac_platform.h/c | 学生1 | 地址宏、寄存器读写、中断、延时 |
| DMA驱动 | mac_dma.h/c | 学生2 | SRAM控制、DMA传输 |
| 配置模块 | mac_config.h/c | 学生3 | Tile/NoC/FSM/全局配置 |
| 数据加载 | mac_data.h/c | 学生4 | 权重/特征图写入 |
| 计算执行 | mac_compute.h/c | 学生5 | 推理执行、输出读取 |
| 测试主程序 | mac_test_single.c + Makefile | 学生6 | 单层测试主程序、编译脚本 |

---

## 三、详细任务

### 3.1 学生1：底层平台模块 mac_platform

**文件**：c/demo/common/mac_platform.h + mac_platform.c

**提取内容**（mac_test_tb2.c）：

1. 地址宏定义（第8-76行）
   - S1_BASE_ADDR ~ S7_BASE_ADDR
   - CTRL_BASE_ADDR, DMA_APB_BASE, PLIC_BASE_ADDR
   - 寄存器偏移宏（TILE_CONF_START, NOC_CONF_START, FSM_CONF_START_ID等）
   - DMA寄存器偏移（DMA_CTRL, DMA_STATUS, DESC0_*）
   - PLIC寄存器偏移
   - 中断ID定义
   - 硬件参数宏（ROW_SIZE, COL_SIZE, TILE_SIZE等）

2. 寄存器读写函数（第2315-2322行）
   ```c
   void write_reg(unsigned int addr, unsigned int data);
   unsigned int read_reg(unsigned int addr);
   ```

3. 中断上下文管理（第78-107行）
   ```c
   typedef struct { volatile int dma_done; volatile int dma_err; } dma_irq_ctx_t;
   typedef struct { volatile int mac_done; volatile int mac_err; } mac_irq_ctx_t;
   void dma_set_context(dma_irq_ctx_t *ctx);
   mac_irq_ctx_t *mac_get_context(void);
   ```

4. PLIC中断函数（第2324-2447行）
   - plic_set_priority(), plic_enable_sources(), plic_claim_irq(), plic_complete_irq()
   - plic_init_mac_interrupts(), plic_init_dma_interrupts()
   - plic_handle_mac_interrupt(), plic_handle_dma_interrupt()
   - trap_entry(), set_mtvec(), enable_plic_interrupts()

5. 延时函数（第2450-2457行）
   ```c
   void delay_cycles(int cycles);
   void short_delay(void);
   void long_delay(void);
   ```

**验收标准**：
- [ ] 头文件中所有宏和函数声明完整
- [ ] .c文件编译无warning
- [ ] 地址定义与原始代码一致

---

### 3.2 学生2：DMA驱动模块 mac_dma

**文件**：c/demo/common/mac_dma.h + mac_dma.c

**提取内容**（mac_test_tb2.c）：

1. SRAM控制函数（第2496-2505行）
   ```c
   void set_sram_control(unsigned int weight_sram0_ctrl,
                         unsigned int weight_sram1_ctrl,
                         unsigned int output_sram0_ctrl,
                         unsigned int output_sram1_ctrl);
   ```

2. DMA等待函数（第2508-2540行）
   ```c
   int wait_dma_complete(void);  // 返回 0=成功, -1=错误, -2=超时
   ```

3. DMA传输函数（第2543-2599行）
   ```c
   void dma_transfer(unsigned int src_addr, unsigned int dst_addr, unsigned int length);
   ```

**依赖**：mac_platform.h（write_reg, read_reg, dma_get_context, DMA相关宏）

**验收标准**：
- [ ] dma_transfer()能独立编译
- [ ] 函数签名与原始代码完全一致
- [ ] 有清晰的参数说明注释

---

### 3.3 学生3：配置模块 mac_config

**文件**：c/demo/common/mac_config.h + mac_config.c

**提取内容**（mac_test_tb2.c）：

1. Tile和NoC配置函数（第2459-2493行）
   ```c
   void config_tiles_and_noc(int groupSize, int k);
   ```

2. FSM配置函数（从run_process第2709-2746行提取）
   - 提取为两个独立函数：
   ```c
   void config_fsm_normal(int stride, int cout, int groupSize, int groupNum, int k);
   void config_fsm_special(int truncateBits, int truncateEn, int planeWorkMode,
                           int resolutionColIdx, int cinIdx);
   ```

3. 全局配置函数（从run_process第2754-2766行提取）
   ```c
   void config_global(unsigned int featurePingpongFlag,
                      unsigned int weightPingpongFlag,
                      unsigned int outputPingpongFlag,
                      int actionMode);
   ```

**依赖**：mac_platform.h（write_reg, short_delay, FSM相关宏）

**验收标准**：
- [ ] config_tiles_and_noc()提取正确
- [ ] FSM配置拆分为两个独立函数
- [ ] 位域拼接逻辑与原始代码一致

---

### 3.4 学生4：数据加载模块 mac_data

**文件**：c/demo/common/mac_data.h + mac_data.c

**提取内容**（mac_test_tb2.c）：

1. 权重写入函数（第2601-2620行）
   - 原函数引用全局变量weight_data[][]，改造为参数传入：
   ```c
   void mac_load_weights(const uint32_t *weight_data, int rows, int length);
   ```

2. 特征图写入SRAM函数（第2622-2635行）
   - 原函数引用全局变量feature_data[][]，改造为参数传入：
   ```c
   void mac_load_features_to_sram(const uint32_t *feature_data, int rows);
   ```

3. 特征数据搬运函数（第2637-2665行）
   ```c
   void drive_feature_from_files(int cinIdx, int resolutionColIdx, int resolutionRowIdx,
                                  int groupSize, int groupNum, int resolutionRowIdxTotal);
   ```

**依赖**：mac_platform.h（write_reg, short_delay, long_delay, 地址宏）和mac_dma.h（dma_transfer）

**验收标准**：
- [ ] 函数接口改为参数传入（不依赖全局变量）
- [ ] 保留原始全局变量版本作为兼容（用#ifdef或注释说明）
- [ ] 有数据格式说明注释

---

### 3.5 学生5：计算执行模块 mac_compute

**文件**：c/demo/common/mac_compute.h + mac_compute.c

**提取内容**（mac_test_tb2.c）：

1. MAC等待函数（第2667-2697行）
   ```c
   int wait_mac_complete(void);  // 返回 0=成功, -1=错误, -2=超时
   ```

2. 推理执行函数（第2699-2784行）
   ```c
   void run_process(int cinIdx, int resolutionColIdx, int resolutionRowIdx,
                    int k, int cout, int groupSize, int groupNum, int stride,
                    int cinIdxTotal, int resolutionColIdxTotal, int resolutionRowIdxTotal,
                    int dataFlowMode, int truncateBits, int truncateEn,
                    unsigned int featurePingpongFlag, unsigned int weightPingpongFlag,
                    unsigned int outputPingpongFlag, unsigned int pingpongEnFlag,
                    int planeWorkMode);
   ```
   - 提取后改为调用学生2/3/4的模块函数

3. 输出结果读取函数（第2786-2836行）
   ```c
   void print_output_results(int resolutionColIdx, int resolutionRowIdx, int outputPingpongFlag);
   ```

**依赖**：mac_platform.h, mac_dma.h, mac_config.h, mac_data.h

**验收标准**：
- [ ] run_process()内部改为调用其他模块的函数
- [ ] print_output_results()提取正确
- [ ] 函数签名保持不变（方便后续集成）

---

### 3.6 学生6：单层测试主程序 mac_test_single

**文件**：c/demo/common/mac_test_single.c + Makefile

**工作内容**：

1. 重写main()函数（第2838-2922行）
   - 使用学生1-5的模块函数，实现与原版完全一致的功能
   - main()只负责：初始化 → 配置 → 加载数据 → 推理循环 → 读取结果

2. 编写Makefile
   - 编译所有.c文件为.elf
   - 生成.hex和.bin
   - 参考现有c/axi_test/Makefile

3. 验证
   - 确保编译通过
   - 确保链接正确（参考现有link.ld）

**main()结构**：
```c
#include "mac_platform.h"
#include "mac_dma.h"
#include "mac_config.h"
#include "mac_data.h"
#include "mac_compute.h"

// 测试数据（从原文件复制）
uint32_t weight_data[144][8] = { ... };
uint32_t feature_data[2048][16] = { ... };

int main(void) {
    // 1. 中断初始化
    dma_irq_ctx_t dma_ctx = {0};
    mac_irq_ctx_t mac_ctx = {0};
    dma_set_context(&dma_ctx);
    mac_set_context(&mac_ctx);
    plic_set_threshold(0);
    plic_init_mac_interrupts();
    plic_init_dma_interrupts();
    set_mtvec(trap_entry);
    enable_plic_interrupts();

    // 2. SRAM控制初始化
    set_sram_control(0, 0, 0, 0);

    // 3. 配置Tile和NoC
    config_tiles_and_noc(GROUP_SIZE_PARAM, K_PARAM);

    // 4. 加载权重
    int length = COUT_PARAM * CIN_IDX_TOTAL * GROUP_SIZE_PARAM;
    drive_weights_from_files(length);

    // 5. 加载特征图
    drive_features_to_sram();

    // 6. 推理循环
    for (row...) {
        for (col...) {
            run_process(...);
            for (cin...) {
                run_process(...);
            }
            print_output_results(...);
        }
    }

    return 0;
}
```

**依赖**：学生1-5的所有模块

**验收标准**：
- [ ] Makefile能编译所有模块
- [ ] 生成的.elf与原版功能一致
- [ ] 仿真结果与原版一致

---

## 四、模块依赖关系

```
学生1: mac_platform ─────────────────────────────────────┐
    │                                                     │
学生2: mac_dma ──── 依赖 mac_platform ───────────────────┤
    │                                                     │
学生3: mac_config ── 依赖 mac_platform ─────────────────┤
    │                                                     │
学生4: mac_data ──── 依赖 mac_platform + mac_dma ───────┤
    │                                                     │
学生5: mac_compute ─ 依赖 mac_platform + mac_dma        ├──► 学生6: mac_test_single
    │                   + mac_config + mac_data           │    (集成所有模块)
    │                                                     │
    └─────────────────────────────────────────────────────┘
```

**并行策略**：学生1先完成（半天），然后2-5可以并行开发，最后学生6集成。

---

## 五、时间安排

| 时间 | 学生1 | 学生2 | 学生3 | 学生4 | 学生5 | 学生6 |
|------|-------|-------|-------|-------|-------|-------|
| Day 1 | 提取platform | 阅读DMA代码 | 阅读配置代码 | 阅读数据加载代码 | 阅读run_process | 阅读main() |
| Day 2 | 完成platform | 编写mac_dma | 编写mac_config | 编写mac_data | 编写mac_compute | 编写Makefile框架 |
| Day 3 | Review | Review | Review | Review | Review | 集成 + 编译调试 |
| Day 4 | - | - | - | - | - | 仿真验证 |
| Day 5 | - | - | - | - | - | 修复问题 + 整理 |

学生1-5在Day 3完成后可协助学生6调试，或提前准备Week 2内容。

---

## 六、周五检查点

- [ ] 6个模块文件全部提交到Git
- [ ] make all编译通过，无warning
- [ ] 仿真运行结果与原版mac_test_tb2.c一致
- [ ] 每个模块有清晰的头文件注释

---

## 七、最终目录结构

```
c/demo/common/
├── mac_platform.h          # 学生1: 底层平台
├── mac_platform.c
├── mac_dma.h               # 学生2: DMA驱动
├── mac_dma.c
├── mac_config.h            # 学生3: 配置
├── mac_config.c
├── mac_data.h              # 学生4: 数据加载
├── mac_data.c
├── mac_compute.h           # 学生5: 计算
├── mac_compute.c
├── mac_test_single.c       # 学生6: 单层测试主程序
└── Makefile                # 学生6: 编译脚本
```

---

## 八、注意事项

1. **不要修改逻辑**：本周仅做代码拆分，不改动任何计算逻辑，确保结果一致
2. **保留调试标记**：原代码中的__asm__ volatile ("li x3, xxx")先全部保留，后续再清理
3. **头文件保护**：每个.h文件都要有#ifndef保护
4. **全局数据**：weight_data[][]和feature_data[][]放在mac_test_single.c中，通过extern声明给mac_data.c使用（或通过参数传入）
5. **编译顺序**：Makefile中注意依赖关系，先编译不依赖其他模块的文件

---

**文档版本**: v2.0  
**创建日期**: 2026-05-27  
**更新日期**: 2026-05-28  
**更新说明**: 精简表述，去除修饰性语言，改为直接、文书化风格
