# FLOOD CNN加速器 Demo部署与验证计划

> **状态说明（2026-08-08）**：本计划作为 FLOOD 通用 CNN Demo 的历史基线保留，不再作为当前毕设主计划。当前主线为 Stable Diffusion 1.5 U-Net ResNetBlock 的 AXKU15 FPGA 原型，设计范围和工程判据见[正式设计规格](../docs/superpowers/specs/2026-08-08-sd15-resnetblock-accelerator-design.md)。本文中的 AKU15/Hybrid-SDK、人员分组和 Demo 周期不自动迁移到新项目。

## 项目背景

- **当前状态**: mac_test_tb2已完成单层卷积验证
- **目标**: 验证加速器作为通用CNN加速器的能力，部署多个Demo
- **硬件状态**: 芯片已流片回来，可使用AKU15 FPGA + Vivado + Hybrid-SDK进行验证
- **团队规模**: 6名本科生

---

## 一、整体架构与任务分组

### 分组策略（3组并行，每组2人）

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         项目管理组 (你)                                  │
│  - 整体协调、代码Review、集成测试、文档审核                               │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
        ▼                           ▼                           ▼
┌───────────────┐         ┌───────────────┐         ┌───────────────┐
│   第1组       │         │   第2组       │         │   第3组       │
│  Demo应用组   │         │  工具链组     │         │  验证测试组   │
│   (2人)       │         │   (2人)       │         │   (2人)       │
├───────────────┤         ├───────────────┤         ├───────────────┤
│ • LeNet部署   │         │ • Python工具  │         │ • 单元测试    │
│ • MobileNet   │         │ • 量化工具    │         │ • 回归测试    │
│ • 图像分类Demo│         │ • 数据转换    │         │ • 性能测试    │
└───────────────┘         └───────────────┘         └───────────────┘
```

---

## 二、详细任务分解

### 🔷 第1组：Demo应用组（2人）

**核心目标**: 在加速器上部署可运行的CNN Demo

#### 阶段1: 轻量级Demo（第1-2周）

**任务1.1: LeNet-5部署** (负责人A)
- 实现MNIST手写数字识别
- 网络结构: Conv(1→6→16) + FC(120→84→10)
- 输入: 28×28 灰度图
- 输出: 10分类结果
- 交付物:
  - `demo/lenet/lenet_config.h` - 网络配置
  - `demo/lenet/lenet_weights.h` - 量化后权重
  - `demo/lenet/main.c` - 主程序
  - `demo/lenet/README.md` - 使用说明

**任务1.2: 简单CNN分类器** (负责人B)
- 实现CIFAR-10基础分类器
- 网络结构: 3层Conv + 2层FC
- 输入: 32×32 RGB图像
- 输出: 10分类结果
- 交付物:
  - `demo/cifar10/cifar10_config.h`
  - `demo/cifar10/cifar10_weights.h`
  - `demo/cifar10/main.c`
  - `demo/cifar10/README.md`

#### 阶段2: 复杂Demo（第3-4周）

**任务1.3: MobileNet-V1轻量化部署** (两人协作)
- 实现深度可分离卷积支持
- 网络结构: 精简版MobileNet
- 输入: 96×96 RGB图像
- 重点验证Depthwise Conv在加速器上的映射
- 交付物:
  - `demo/mobilenet/mobilenet_config.h`
  - `demo/mobilenet/dw_conv_adapter.c` - 深度卷积适配层
  - `demo/mobilenet/main.c`
  - 性能对比报告

**任务1.4: 多任务Demo框架** (两人协作)
- 设计通用CNN推理框架
- 支持动态加载不同网络配置
- 统一API接口设计
- 交付物:
  - `framework/cnn_inference.h` - 推理框架头文件
  - `framework/cnn_inference.c` - 推理框架实现
  - `framework/layer_ops.c` - 层操作封装

---

### 🔷 第2组：工具链组（2人）

**核心目标**: 建立从PyTorch/TensorFlow到加速器的完整工具链

#### 阶段1: 基础工具（第1-2周）

**任务2.1: 权重量化与转换工具** (负责人C)
- 实现INT8对称量化
- 支持逐通道量化（per-channel）
- 权重格式转换（PyTorch → C数组）
- 交付物:
  - `tools/quantization/quantize_weights.py`
  - `tools/quantization/calibrate.py` - 校准工具
  - `tools/quantization/README.md`

**任务2.2: 特征图数据生成工具** (负责人D)
- 实现图像预处理（归一化、缩放、量化）
- 生成测试输入数据
- 支持批量生成测试向量
- 交付物:
  - `tools/data_gen/image_preprocess.py`
  - `tools/data_gen/generate_test_data.py`
  - `tools/data_gen/batch_generator.py`

#### 阶段2: 高级工具（第3-4周）

**任务2.3: 网络解析与映射工具** (两人协作)
- 解析ONNX模型
- 映射到加速器支持的算子
- 生成网络配置文件
- 交付物:
  - `tools/converter/onnx_parser.py`
  - `tools/converter/op_mapping.py`
  - `tools/converter/generate_config.py`

**任务2.4: 结果验证与可视化工具** (两人协作)
- 对比软件推理与硬件推理结果
- 生成误差分析报告
- 可视化中间层输出
- 交付物:
  - `tools/validation/compare_results.py`
  - `tools/validation/visualize_featuremap.py`
  - `tools/validation/error_analysis.py`

---

### 🔷 第3组：验证测试组（2人）

**核心目标**: 建立完整的测试体系，确保加速器可靠性

#### 阶段1: 基础测试（第1-2周）

**任务3.1: 单元测试框架** (负责人E)
- 设计测试用例规范
- 实现基础算子测试（Conv、ReLU、Pool）
- 实现配置寄存器测试
- 交付物:
  - `tests/unit/test_conv.c` - 卷积测试
  - `tests/unit/test_activation.c` - 激活函数测试
  - `tests/unit/test_pooling.c` - 池化测试
  - `tests/unit/test_config.c` - 配置测试

**任务3.2: 集成测试与回归测试** (负责人F)
- 设计端到端测试用例
- 实现自动化测试脚本
- 建立回归测试基线
- 交付物:
  - `tests/integration/test_full_pipeline.c`
  - `tests/regression/run_regression.py`
  - `tests/regression/test_cases/` - 测试用例库

#### 阶段2: 性能测试（第3-4周）

**任务3.3: 性能基准测试** (两人协作)
- 测量不同配置下的延迟
- 测量功耗（如可能）
- 生成性能报告
- 交付物:
  - `tests/performance/benchmark.c`
  - `tests/performance/profile.py`
  - `tests/performance/results/` - 性能数据

**任务3.4: 边界条件测试** (两人协作)
- 测试最大/最小输入尺寸
- 测试极端权重值
- 测试异常处理
- 交付物:
  - `tests/stress/test_boundary.c`
  - `tests/stress/test_corner_cases.c`
  - 边界条件测试报告

---

## 三、协作接口定义

### 组间协作关系

```
┌────────────────────────────────────────────────────────────┐
│                      组间协作流程                           │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  第2组(工具链) ────────► 第1组(Demo)                       │
│  • 提供量化权重  ──────► • 集成到Demo                      │
│  • 提供测试数据  ──────► • 验证功能                        │
│  • 网络配置    ────────► • 部署运行                        │
│                                                            │
│  第3组(验证) ◄───────── 第1组(Demo)                        │
│  • 提供测试报告 ◄──────── • 提交测试                       │
│  • 反馈Bug    ◄───────── • 修复验证                        │
│                                                            │
│  第2组(工具链) ◄────────► 第3组(验证)                      │
│  • 提供验证数据 ────────► • 验证工具正确性                 │
│  • 修复工具Bug ◄───────── • 报告工具问题                   │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### 接口规范

#### 1. 权重数据格式 (第2组 → 第1组)
```c
// weights.h 格式规范
#ifndef WEIGHTS_H
#define WEIGHTS_H

#define LAYER1_WEIGHTS_COUNT 864    // 3×3×3×32
#define LAYER1_BIAS_COUNT 32

// INT8量化权重，按加速器存储格式排列
extern const int8_t layer1_weights[LAYER1_WEIGHTS_COUNT];
extern const int32_t layer1_bias[LAYER1_BIAS_COUNT];

// 量化参数
extern const float layer1_scale;
extern const int layer1_zero_point;

#endif
```

#### 2. 网络配置格式 (第2组 → 第1组)
```c
// network_config.h 格式规范
typedef struct {
    int layer_id;
    int type;           // CONV, FC, POOL, etc.
    int input_h, input_w, input_c;
    int output_h, output_w, output_c;
    int kernel_size;
    int stride;
    int padding;
    // 加速器特定配置
    int group_size;
    int group_num;
    int tile_config[16];
} LayerConfig;
```

#### 3. 测试报告格式 (第3组 → 所有组)
```markdown
## 测试报告模板
- 测试项: [名称]
- 测试日期: [日期]
- 测试人员: [姓名]
- 测试结果: [PASS/FAIL]
- 详细数据: [具体数值]
- 问题描述: [如有]
- 建议改进: [如有]
```

---

## 四、开发环境与工具链

### 硬件环境
- **FPGA开发板**: 黑金AKU15 (Kintex UltraScale+)
- **芯片**: FLOOD加速器已流片芯片
- **调试器**: JTAG + UART

### 软件环境
- **FPGA工具**: Vivado 2020.2+
- **SDK**: Hybrid-SDK (RISC-V GCC)
- **仿真**: Verilator / VCS
- **Python**: 3.8+ (PyTorch/ONNX)

### 代码仓库结构
```
flood_accelerator/
├── rtl/                    # RTL代码（已有）
├── c/
│   ├── axi_test/          # 基础测试（已有）
│   └── demo/              # ⭐ Demo应用（第1组）
│       ├── lenet/
│       ├── cifar10/
│       └── mobilenet/
├── tools/                 # ⭐ 工具链（第2组）
│   ├── quantization/
│   ├── data_gen/
│   ├── converter/
│   └── validation/
├── tests/                 # ⭐ 测试套件（第3组）
│   ├── unit/
│   ├── integration/
│   ├── regression/
│   ├── performance/
│   └── stress/
├── fpga/                  # FPGA工程（已有）
├── doc/                   # 文档
└── scripts/               # 自动化脚本
```

---

## 五、里程碑与时间节点

### 第1阶段：基础搭建（Week 1-2）

| 周次 | 任务 | 负责组 | 交付物 | 检查点 |
|------|------|--------|--------|--------|
| W1 | 环境搭建 | 所有组 | 开发环境就绪 | 能编译运行mac_test_tb2 |
| W1 | LeNet配置 | 第1组 | lenet_config.h | 配置参数正确 |
| W1 | 量化工具v1 | 第2组 | quantize_weights.py | 能生成INT8权重 |
| W1 | 单元测试框架 | 第3组 | test_conv.c | 基础测试通过 |
| W2 | LeNet Demo | 第1组 | 可运行的LeNet | 在仿真环境通过 |
| W2 | 数据生成工具 | 第2组 | image_preprocess.py | 能生成测试数据 |
| W2 | 集成测试v1 | 第3组 | test_full_pipeline.c | 端到端测试通过 |

### 第2阶段：功能完善（Week 3-4）

| 周次 | 任务 | 负责组 | 交付物 | 检查点 |
|------|------|--------|--------|--------|
| W3 | CIFAR-10 Demo | 第1组 | 可运行的CIFAR-10 | 准确率>60% |
| W3 | ONNX转换工具 | 第2组 | onnx_parser.py | 能解析简单网络 |
| W3 | 性能测试框架 | 第3组 | benchmark.c | 能测量延迟 |
| W4 | MobileNet适配 | 第1组 | dw_conv_adapter.c | 深度卷积支持 |
| W4 | 验证工具链 | 第2组 | compare_results.py | 误差<1% |
| W4 | 边界测试 | 第3组 | 边界测试报告 | 覆盖主要边界 |

### 第3阶段：集成优化（Week 5-6）

| 周次 | 任务 | 负责组 | 交付物 | 检查点 |
|------|------|--------|--------|--------|
| W5 | Demo优化 | 第1组 | 优化后的Demo | 性能提升>20% |
| W5 | 工具链完善 | 第2组 | 完整工具链 | 一键转换 |
| W5 | 回归测试 | 第3组 | 回归测试基线 | 全部通过 |
| W6 | FPGA验证 | 所有组 | FPGA运行Demo | 板上运行成功 |
| W6 | 文档整理 | 所有组 | 完整文档 | 文档齐全 |
| W6 | 最终汇报 | 所有组 | 演示Demo | 现场演示 |

---

## 六、每周例会制度

### 会议安排
- **时间**: 每周五下午 14:00-16:00
- **形式**: 线下会议 + 线上同步
- **参与者**: 6名本科生 + 你

### 会议议程
1. **进度汇报** (每人5分钟)
   - 本周完成任务
   - 遇到的问题
   - 需要的帮助

2. **技术讨论** (30分钟)
   - 跨组协作问题
   - 技术难点攻关

3. **下周计划** (15分钟)
   - 明确下周任务
   - 确认接口交付

### 协作工具
- **代码管理**: Git (Gitee/GitHub)
- **文档协作**: 飞书/腾讯文档
- **问题跟踪**: Issue系统
- **即时通讯**: 微信群

---

## 七、风险管理

| 风险 | 可能性 | 影响 | 应对措施 |
|------|--------|------|----------|
| 芯片回片测试不通过 | 中 | 高 | 先用FPGA验证，准备回片测试方案 |
| 工具链开发延期 | 中 | 中 | 准备手动转换的Plan B |
| Demo精度不达标 | 低 | 中 | 准备简化网络，确保基础功能 |
| 人员变动 | 低 | 中 | 代码文档化，知识共享 |
| 跨组协作不畅 | 中 | 中 | 每周例会，明确接口规范 |

---

## 八、成功标准

### 最低目标（必须完成）
- [ ] LeNet-5在仿真环境运行成功
- [ ] 基础量化工具可用
- [ ] 单元测试覆盖主要算子
- [ ] 代码提交到Git仓库

### 期望目标（努力完成）
- [ ] CIFAR-10 Demo运行成功
- [ ] 完整工具链（PyTorch → 加速器）
- [ ] 回归测试自动化
- [ ] FPGA上运行Demo

### 挑战目标（力争完成）
- [ ] MobileNet部署成功
- [ ] 多网络动态切换
- [ ] 性能优化报告
- [ ] 技术博客/论文

---

## 九、附录

### A. 参考资源
- [mac_test_tb2.c] - 单层卷积测试参考
- [cnn_multilayer.c] - 多层网络框架参考
- [Config.scala] - 加速器配置参数
- [AXI_Integration_Guide.md] - AXI接口说明

### B. 学习资料
- RISC-V汇编基础
- CNN量化原理
- AXI4协议规范
- Vivado使用指南

### C. 联系人
- 项目负责人: [你的名字]
- 技术支持: [FPGA/芯片支持人员]

---

**文档版本**: v1.0  
**创建日期**: 2026-05-22  
**最后更新**: 2026-05-22  
**作者**: AI Assistant
