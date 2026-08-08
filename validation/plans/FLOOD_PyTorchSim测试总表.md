# FLOOD HPCA 重投：PyTorchSim 测试总表

> 本表用于统一确认“从哪些方面测试、测试哪些对象、采集哪些数据”。  
> 具体执行方法见 [FLOOD_PyTorchSim测试执行方案.md](./FLOOD_PyTorchSim测试执行方案.md)，结果填写见 [FLOOD_HPCA测试结果清单.md](./FLOOD_HPCA测试结果清单.md)。

## 一、完整测试表

| 编号 | 测试方面 | 测试目的 | 测试对象/模型 | 对比配置 | 需要采集的数据 |
|---|---|---|---|---|---|
| T1 | 端到端性能 | 证明 FLOOD 对 Diffusion 推理整体有效 | SD v1.5 UNet、VAE、DiT-B/4、DiT-S/4 | Base FLOOD、Full FLOOD、DiT-Accel-like、通用 systolic baseline | latency、throughput、speedup、energy、power、EDP、compute utilization、DRAM traffic、SRAM traffic、stall cycles |
| T2 | 算子级性能分解 | 确定 FLOOD 在不同算子上的收益来源 | Conv2d、Linear/GEMM、BMM、Softmax、Norm、Activation | Base vs Full；FLOOD-only vs PLANE-only | per-op cycles、compute cycles、memory cycles、stall cycles、op latency 占比、op energy 占比、MAC utilization |
| T3 | 稀疏分布统计 | 证明 Diffusion workload 中存在可利用的真实稀疏性 | SD UNet、VAE、DiT-B/4，不同 timestep | 原始模型 trace | activation sparsity、weight sparsity、32-channel group sparsity、layer-wise sparsity、timestep-wise sparsity、可跳过 MAC 比例 |
| T4 | 细粒度跳零收益 | 证明 zero skipping、adder pruning 和 GCSE 能转化为周期及能耗收益 | SD UNet、DiT-B/4 | Dense、ValueSkip、ValueSkip+AdderPrune、GCSE、FullSparse | skipped MAC ratio、cycle reduction、energy reduction、power reduction、SRAM traffic reduction、NoC traffic reduction、metadata overhead |
| T5 | GCSE 结构化稀疏 | 证明 channel-group sparsity 能减少取数和控制开销 | Conv 层、Linear 层、SD UNet 重点层 | no GCSE、GCSE group=8/16/32/64 | group sparsity、bitmap size、bitmap fetch cycles、weight SRAM access reduction、NoC traffic reduction、latency reduction、energy reduction |
| T6 | 混合精度收益 | 证明 INT4/INT8 mixed precision 存在性能与质量的最优点 | SD UNet、DiT-B/4、CelebA-HQ/FFHQ 子集 | FP16、INT8 all、INT4 all、10%/30%/50%/70% INT4、sensitivity-based mixed | latency、throughput、energy、peak memory、DRAM traffic、quality drop、FID、CLIP Score、PSNR、SSIM、LPIPS |
| T7 | Outlier bypass | 证明 outlier 模块能以低硬件成本恢复量化质量 | SD UNet、DiT-B/4、CelebA-HQ | INT8 truncation、mixed w/o outlier、mixed+outlier、wide-MAC baseline | outlier ratio、outlier collision ratio、extra cycles、queue occupancy、PSNR、SSIM、LPIPS、FID、extra area、extra power |
| T8 | Softmax 支持 | 证明 DiT/Attention 中 Softmax 的硬件近似精度与性能可接受 | DiT-B/4、DiT-S/4、SD UNet attention | FP16 Softmax、I-BERT-like、linear attention、FLOOD INT8 Softmax | vector length、Softmax latency、approximation error、KL divergence、max error、energy、area、generation quality drop |
| T9 | 双 dataflow 选择 | 证明 FLOOD/PLANE 自适应切换对混合 Conv/Matrix workload 必要 | SD UNet、VAE、DiT-B/4 | FLOOD-only、PLANE-only、rule-based adaptive、oracle adaptive、wrong mapping | selected dataflow per layer、switch count、switch overhead、latency、stall cycles、buffer usage、bandwidth demand、utilization |
| T10 | 存储和带宽敏感性 | 证明 FLOOD 在有限片上存储和外部带宽下仍有效 | SD UNet、DiT-B/4、完整 LDM pipeline | 不同 SRAM size、不同 DRAM bandwidth | latency、stall ratio、DRAM traffic、SRAM traffic、NoC traffic、ping-pong margin、buffer occupancy、utilization |
| T11 | 系统级增量消融 | 分解每项机制带来的系统级收益 | SD UNet、DiT-B/4 | Base、+Sparse、+GCSE、+Mixed Precision、+Outlier、+Softmax、+Adaptive Dataflow、Full | latency、energy、utilization、memory traffic、quality drop、各模块增量收益 |
| T12 | Leave-one-out 消融 | 证明每个模块在完整系统中的必要性 | SD UNet、DiT-B/4 | Full、Full-GCSE、Full-Mixed Precision、Full-Outlier、Full-Softmax、Full-Adaptive Dataflow | latency loss、energy loss、utilization loss、quality loss、traffic increase |
| T13 | 错误组合反例 | 证明 co-design 的必要性，而非简单叠加机制 | SD UNet、DiT-B/4 | 高稀疏+错误 dataflow、高 INT4 无 outlier、只跳 MAC 不跳 weight fetch | latency penalty、energy penalty、quality drop、extra traffic、stall cycles、utilization drop |
| T14 | Timestep 敏感性 | 分析 Diffusion 不同阶段的稀疏、outlier 和性能变化 | SD UNet，不同 denoising step | early、middle、late timestep | activation sparsity、outlier ratio、layer latency、total latency、energy、selected precision、selected dataflow |
| T15 | 模型规模扩展 | 证明结果不是单一模型特例 | SD v1.5、VAE、DiT-S/4、DiT-B/4、可选 DiT-XL/2 | Base FLOOD vs Full FLOOD | latency、speedup、energy、utilization、traffic、quality metrics、参数量、MACs |
| T16 | Baseline 公平性 | 回应 baseline 配置不清楚和比较不公平的问题 | 所有主实验 | Base FLOOD、Full FLOOD、DiT-Accel-like、systolic baseline、software reference | 工艺、频率、面积、PE/MAC 数、SRAM、DRAM 带宽、精度、稀疏支持、Softmax 支持、dataflow、数据来源 |
| T17 | 面积与功耗开销 | 证明新增模块实现成本可控 | GCSE 控制、Outlier bypass、Softmax、dataflow switch logic | Base hardware vs Full hardware | area、area breakdown、power、power breakdown、critical path、frequency、extra registers、extra SRAM/metadata storage |
| T18 | 数据来源与复现性 | 保证 HPCA 版本实验结果可信且可追溯 | 全部实验 | PyTorchSim、RTL、FPGA、ASIC synthesis/P&R | simulator version、hardware config、model config、seed、input size、data source、config hash、CSV 原始数据、图表生成脚本 |

## 二、结合讨论手稿的优先级分类

讨论手稿中的实验逻辑可以归纳为三条创新主线：

1. **稀疏优化**：主动稀疏（GCSE）与被动稀疏（运行时 zero/slice skipping）；
2. **低成本量化**：INT4/INT8 可配置计算与高精度 outlier 补偿；
3. **架构扩展**：FLOOD/PLANE 双 dataflow、Softmax、片上存储和多核调度。

实验优先级不按实现难度划分，而按“是否直接支撑论文核心创新和主图”划分。

### P0：必须完成——直接支撑三项创新和论文主结论

| 类别 | 测试内容 | 对应测试 | 必须获得的数据 | 预期支撑 |
|---|---|---|---|---|
| 系统主结果 | 多模型下 FLOOD 与 Base/baseline 的端到端对比 | T1、T2 | latency、energy/power、utilization、speedup、traffic、stall cycles | 手稿中的端到端“大图”，支撑摘要核心数字 |
| 创新一：被动稀疏 | 运行时 zero skipping、adder pruning、无效 slice/group 跳过 | T3、T4 | activation/weight sparsity、skipped MAC、cycle reduction、power reduction | 证明真实稀疏能够转化为计算和功耗收益 |
| 创新一：主动稀疏 | GCSE 训练形成硬件对齐的 channel-group sparsity | T5 | group sparsity、bitmap overhead、SRAM/NoC reduction、latency、energy | 证明 GCSE 不只是普通非结构化剪枝 |
| 创新二：4/8-bit 量化 | INT4/INT8 可配置和 sensitivity-based mixed precision | T6 | INT4 layer ratio、latency、throughput、memory、FID/CLIP/PSNR/SSIM/LPIPS | 找到性能—生成质量 Pareto 最优点 |
| 创新二：高精度 outlier | 少量高精度 outlier 的旁路补偿 | T7 | outlier ratio、quality recovery、extra cycles、area、power | 证明不扩大主计算阵列也能维持质量 |
| 创新三：双 dataflow | FLOOD/PLANE 固定映射、自适应映射和错误映射 | T9 | per-layer dataflow、switch count、latency、utilization、wrong-mapping penalty | 证明 Conv/Matrix 混合负载需要自适应 dataflow |
| 创新三：存储调度 | Buffer、带宽、ping-pong 和多核调度 | T10 | buffer occupancy、bandwidth demand、traffic、stall ratio、ping-pong margin | 支撑手稿中的存储与调度设计 |
| 系统协同 | 三项创新的增量消融和完整系统结果 | T11 | Base 到 Full 的 latency、energy、utilization、traffic、quality 变化 | 回应“创新点只是简单拼装” |
| 实现开销 | 三项创新集成后的面积、功耗和时序 | T17 | area/power breakdown、critical path、frequency、模块开销 | 证明“低成本”和可实现性 |
| 实验可信度 | 固定硬件参数、统一数据源和 baseline 配置 | T16、T18 | 工艺、频率、MAC 数、SRAM、带宽、版本、config hash、数据来源 | 回应 MICRO 审稿中的公平性和可信度质疑 |

### P1：强烈建议——用于证明联合设计必要性

| 类别 | 测试内容 | 对应测试 | 需要获得的数据 | 主要作用 |
|---|---|---|---|---|
| 完整系统反向消融 | 从 Full FLOOD 中逐项移除 GCSE、量化、outlier、dataflow | T12 | latency/energy/utilization/quality 损失 | 证明每个模块在完整系统中不可替代 |
| 错误组合反例 | 高稀疏+错误 dataflow；高 INT4 无 outlier；只跳 MAC 不跳访存 | T13 | latency/energy penalty、quality drop、extra traffic | 最直接回应“已有技术拼装”的质疑 |
| Diffusion 阶段变化 | early/middle/late timestep 的稀疏和 outlier 变化 | T14 | timestep-wise sparsity、outlier、latency、precision/dataflow selection | 证明动态策略比固定策略更合理 |
| Softmax 支持 | 32–2048 长度下 INT8 Softmax 的性能和精度 | T8 | latency、energy、KL divergence、approximation error、质量下降 | 完善 DiT/attention 的端到端算子支持 |
| 模型扩展 | LDM 与不同规模 DiT 的结果 | T15 | speedup、energy、utilization、quality、traffic | 证明结果不是单一 UNet 模型特例 |

### P2：补充实验——用于增强完整性，不阻塞论文主线

| 类别 | 测试内容 | 对应测试或扩展项 | 需要获得的数据 | 使用位置 |
|---|---|---|---|---|
| 更大模型 | DiT-XL/2 或更大分辨率 Stable Diffusion | T15 扩展 | scaling trend、memory、latency、energy | 扩展性图或附录 |
| 大范围参数扫描 | 11×11 稀疏网格、更多 group size、更多 SRAM/带宽点 | T4、T5、T10 扩展 | heatmap 数据、敏感性曲线 | 机制图或附录 |
| 软件参考 | A100、TensorRT、xDiT、PipeFusion 等 | T16 扩展 | software latency、throughput、GPU 配置 | 单独参考，不与等资源硬件结果混比 |
| 通用模型验证 | CNN、ViT、BERT | 可选扩展 | throughput、accuracy、energy | 仅在仍保留“通用性”主张时使用 |
| 更多质量样本 | 扩大生成图像数量和数据集 | T6、T7 扩展 | FID、CLIP、LPIPS 置信区间 | 质量评估附录 |

## 三、按三项创新组织测试

### 创新一：主动与被动稀疏协同

| 层次 | 配置 | 重点数据 |
|---|---|---|
| 稀疏基础特征 | 原始 dense/pruned 模型 | 每层 activation、weight、channel-group sparsity |
| 被动稀疏 | ValueSkip | skipped MAC、动态功耗，不应夸大访存收益 |
| 被动稀疏增强 | ValueSkip + AdderPrune | adder activity、energy、critical path |
| 主动稀疏 | GCSE | group sparsity、bitmap、weight fetch、NoC traffic |
| 主动+被动 | GCSE + ValueSkip + AdderPrune | latency、energy、utilization、traffic |
| 参数选择 | group=8/16/32/64 | sparsity enrichment、metadata 和执行收益的权衡 |

必须区分：

- ValueSkip 主要减少无效计算和动态翻转；
- GCSE 可以进一步减少权重读取、NoC 传输和控制状态；
- 只有二者结合后，才能同时覆盖非结构化动态零值和结构化静态零组。

### 创新二：4/8-bit 量化与高精度 outlier

| 层次 | 配置 | 重点数据 |
|---|---|---|
| 精度基线 | FP16、INT8 all、INT4 all | latency、energy、memory、生成质量 |
| 固定比例混合 | 10%/30%/50%/70% INT4 | quality–performance 曲线 |
| 敏感度量化 | sensitivity-based INT4/INT8 | layer assignment、Pareto 最优点 |
| 无 outlier 补偿 | mixed w/o outlier | outlier 分布、质量损失 |
| 高精度补偿 | mixed + outlier bypass | quality recovery、extra cycles、queue collision |
| 高成本对照 | wide-MAC baseline | area、power、frequency、quality |

必须证明：

- INT4/INT8 的切换带来实际吞吐和访存收益；
- outlier 数量足够少，使共享高精度通路不会成为瓶颈；
- bypass 相比统一加宽 MAC 具有更好的面积/功耗收益。

### 创新三：FLOOD 架构、双 dataflow 与存储调度

| 层次 | 配置 | 重点数据 |
|---|---|---|
| 固定 dataflow | FLOOD-only、PLANE-only | Conv/Matrix 各自 latency、utilization、traffic |
| 自适应 dataflow | rule-based adaptive | 每层选择结果、端到端收益、切换次数 |
| 理想上界 | oracle adaptive | rule-based 与 oracle 的差距 |
| 错误映射 | wrong mapping | latency、stall、utilization penalty |
| 存储敏感性 | SRAM 0.5×/1×/2× | buffer occupancy、spill traffic、latency |
| 带宽敏感性 | 8/16/32/64 B/cycle | stall ratio、ping-pong margin、throughput |
| Softmax | vector length 32–2048 | latency、energy、误差和端到端质量 |

必须给出清晰的 dataflow 选择准则，例如依据算子类型、矩阵维度、数据复用、SRAM 容量和带宽压力进行选择。

## 四、数据类别汇总

| 数据类别 | 具体指标 |
|---|---|
| 性能 | latency、throughput、speedup、compute utilization、MAC utilization |
| 能耗 | energy、power、EDP、各模块 energy/power breakdown |
| 周期 | compute cycles、memory cycles、stall cycles、switch cycles、metadata cycles、outlier cycles |
| 访存 | DRAM traffic、SRAM traffic、NoC traffic、buffer occupancy、bandwidth demand |
| 稀疏 | activation sparsity、weight sparsity、group sparsity、skipped MAC ratio、bitmap overhead |
| 量化质量 | FID、CLIP Score、PSNR、SSIM、LPIPS、quality drop |
| Outlier | outlier ratio、collision ratio、queue occupancy、extra cycles、quality recovery |
| Dataflow | per-layer selection、switch count、switch overhead、wrong-mapping penalty |
| 硬件开销 | area、power、critical path、frequency、register/SRAM/metadata overhead |
| 公平性 | 工艺、频率、面积、MAC 数、SRAM、带宽、精度、baseline 功能支持 |
| 复现信息 | simulator version、config hash、model/input/seed、数据来源、原始 CSV |

## 五、数据来源标签

每项结果必须明确使用以下一种数据来源，禁止笼统标注为“实验结果”：

| 标签 | 含义 |
|---|---|
| PyTorch measurement | PyTorch 模型运行、质量评估或张量统计 |
| PyTorchSim cycle simulation | PyTorchSim 周期、利用率和活动统计 |
| RTL simulation | RTL 功能或功耗活动仿真 |
| FPGA measurement | FPGA 板级实测 |
| ASIC synthesis | ASIC 综合结果 |
| Post-layout estimate | 布局布线后估算 |
| Analytical estimate | 公式或解析模型估算 |
| Literature-reported | 直接引用已有论文公开结果 |

## 六、测试结果统一记录字段

```text
experiment_id
model
model_version
input_resolution
batch_size
diffusion_steps
seed
precision_config
sparsity_config
dataflow_config
hardware_config
baseline
latency
throughput
energy
power
utilization
dram_traffic
sram_traffic
noc_traffic
quality_metrics
data_source
simulator_version
config_hash
notes
```
