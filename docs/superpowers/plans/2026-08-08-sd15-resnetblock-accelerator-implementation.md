# SD1.5 ResNetBlock AXKU15 Accelerator Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 ALINX AXKU15 上实现并验证面向 Stable Diffusion 1.5 U-Net ResNetBlock 的 W8A8 融合 FPGA 加速器，以真实张量证明片上驻留、算子融合和双缓冲能够降低中间 DDR 流量。

**Architecture:** 主机侧负责捕获真实 SD1.5 张量、定点量化、Blocked Layout、任务下发和结果核对；FPGA 侧通过独立 AXI 接口执行 `GN1—SiLU—Conv1—Time Embedding—GN2—SiLU—Conv2—Residual Add`。现有 FLOOD `CIMCore` 作为 INT8 卷积内核，通过新的 Diffusion 参数、适配器、片上 Buffer 和 BlockScheduler 封装，旧 CNN 默认配置保持不变。

**Tech Stack:** Python 3、NumPy、PyTorch/diffusers、pytest、Scala 2.12.13、Chisel 3.5.3、ChiselTest 0.5.3、SBT、Verilog/SystemVerilog、Vivado 2022.2、AXI4-Lite、AXI4-MM、AXKU15 XCKU15P。

## Global Constraints

- 目标固定为 SD1.5 U-Net ResNetBlock；第一阶段不实现 CLIP、VAE、采样器、Cross-Attention、Softmax 或 QKV。
- 必测形状为 `64×64×320`、`32×32×640`、`16×16×1280`、`8×8×1280`；GroupNorm 固定 32 组，激活函数为 SiLU。
- 第一阶段必须完成 `Cin == Cout`；`1×1` 残差投影属于增强项。
- 卷积权重和输入为 signed INT8，累加为 INT32，敏感算子中间值为 signed INT16；右移、舍入和饱和由 Python 黄金模型唯一规定。
- 第一版使用 8 Tile；16 Tile 只在综合、布局布线、时序和存储均达标后启用。
- 核心频率不低于 150 MHz；LUT、FF、BRAM、UltraRAM、DSP 单项原则上不超过 80%。
- 相对非融合基线，中间激活 DDR 流量降低不少于 50%；RTL 与定点黄金模型逐元素一致。
- 器件为 `XCKU15P-FFVE1517-2-I`；DDR4 为 5×1 GB、80-bit、2666 Mbps，MIG 使用板载 200 MHz 参考时钟。
- PCIe 是 x16 机械插槽、Gen3 x8 电气链路；XDMA 是增强项，计算核心不依赖 PCIe 信号。
- 模型权重、完整张量和 Vivado runs 不提交；提交 manifest、量化参数、小型向量、脚本和汇总。
- 当前目录没有 Git 元数据。执行前必须在真实源仓库建立隔离 worktree；若没有源仓库，先征得用户同意再初始化 Git。以下 commit 步骤只在该 worktree 运行。

---

## File and Interface Map

| 路径 | 职责 |
|---|---|
| `accelerator/diffusion/` | Python 黄金模型、真实张量捕获、向量和实验 |
| `accelerator/diffusion/config/sd15_resnetblock.json` | 形状、精度、量化、分块和 PWL 的唯一机器配置 |
| `accelerator/diffusion/python/sd_accel/fixedpoint.py` | 舍入、饱和和 requantize |
| `accelerator/diffusion/python/sd_accel/capture.py` | 真实 ResNetBlock 张量捕获 |
| `accelerator/diffusion/python/sd_accel/groupnorm.py` | 整数 GroupNorm 与 rsqrt |
| `accelerator/diffusion/python/sd_accel/silu.py` | 16/32 段 SiLU PWL |
| `accelerator/diffusion/python/sd_accel/resnetblock.py` | 完整定点 Block |
| `accelerator/diffusion/python/sd_accel/traffic.py` | 融合/非融合 DDR 流量 |
| `accelerator/src/main/scala/diffusion/` | 独立 Diffusion RTL |
| `accelerator/src/test/scala/diffusion/` | ChiselTest 单元与端到端回归 |
| `accelerator/fpga/AXKU15/diffusion/` | MIG、板级顶层、Tcl、XDC 和 JTAG 验证 |
| `accelerator/diffusion/results/` | 机器可读实验汇总 |

## Review Gates and Schedule

| 周期 | 主线 | 阶段出口 |
|---|---|---|
| 第 1–4 周 | 环境、捕获、定点基础 | Gate A：四种形状可复现 |
| 第 5–8 周 | 完整黄金模型、流量、卷积 RTL | 8 Tile 首次综合 |
| 第 9–12 周 | GN、rsqrt、SiLU RTL | Gate B：算子逐元素一致 |
| 第 13–16 周 | Buffer、Scheduler、AXI | 融合顶层仿真 |
| 第 17–20 周 | MIG、AXKU15、JTAG | Gate C：真实向量 RTL 一致 |
| 第 21–24 周 | 上板和优化 | Gate D：真实 Block 稳定运行 |
| 第 25–28 周 | 消融、复现、论文 | 完整证据链 |
| 第 29 周以后 | 风险缓冲 | 最低交付通过后再做 XDMA/Attention |

协作采用四个角色：黄金模型/量化、计算 RTL、系统/板级、验证/实验。人员少时合并角色，接口 manifest、寄存器表和结果 schema 不变。

### Task 1: Freeze Environment and Legacy FLOOD Baseline

**Files:**
- Create: `accelerator/diffusion/pyproject.toml`
- Create: `accelerator/diffusion/python/sd_accel/__init__.py`
- Create: `accelerator/diffusion/python/sd_accel/environment.py`
- Create: `accelerator/diffusion/scripts/check_environment.py`
- Create: `accelerator/diffusion/tests/test_environment.py`
- Create: `accelerator/diffusion/README.md`
- Modify: `accelerator/.gitignore`

**Interfaces:**
- Consumes: `accelerator/build.sbt` and `Config.scala`.
- Produces: `environment.collect() -> dict[str, object]` and `results/baseline/environment.json`.

- [ ] **Step 1: Write the failing contract test**

```python
from sd_accel.environment import collect

def test_environment_contract():
    report = collect()
    assert report["legacy_config"] == {
        "rowSize": 32, "colSize": 32, "dataWidth": 8,
        "pipeline": 2, "tLatency": 4,
        "compressionFactor": 4, "tileSize": 16}
    assert set(("python", "numpy", "torch", "java", "sbt", "vivado")) <= report
```

- [ ] **Step 2: Run it to verify failure**

Run: `cd accelerator/diffusion; python -m pytest tests/test_environment.py -v`  
Expected: FAIL importing `sd_accel.environment`.

- [ ] **Step 3: Implement deterministic collection**

```python
import platform, re, shutil, subprocess
from pathlib import Path

KEYS = ("rowSize", "colSize", "dataWidth", "pipeline",
        "tLatency", "compressionFactor", "tileSize")

def _version(command: list[str]) -> str:
    exe = shutil.which(command[0])
    if exe is None:
        return "unavailable"
    result = subprocess.run([exe, *command[1:]], text=True,
                            capture_output=True, check=False)
    lines = (result.stdout or result.stderr).splitlines()
    return lines[0].strip() if lines else "unavailable"

def collect(repo: Path | None = None) -> dict:
    root = repo or Path(__file__).resolve().parents[3]
    text = (root / "src/main/scala/core/Config.scala").read_text("utf-8")
    legacy = {}
    for key in KEYS:
        match = re.search(rf"val\s+{key}\s*=\s*(\d+)", text)
        if match is None:
            raise RuntimeError(f"missing Config.{key}")
        legacy[key] = int(match.group(1))
    import numpy
    try:
        import torch
        torch_version = torch.__version__
    except ImportError:
        torch_version = "unavailable"
    return {"python": platform.python_version(), "numpy": numpy.__version__,
            "torch": torch_version, "java": _version(["java", "-version"]),
            "sbt": _version(["sbt", "--script-version"]),
            "vivado": _version(["vivado", "-version"]),
            "legacy_config": legacy}
```

- [ ] **Step 4: Define dependencies and ignored outputs**

Set `requires-python = ">=3.10"`; runtime dependencies are NumPy and pytest, model extras are torch, diffusers, safetensors and transformers. Ignore `diffusion/artifacts/`, `results/raw/`, Vivado project runs, `*.bit`, `*.ltx` and model weight files.

- [ ] **Step 5: Run the baseline**

```powershell
cd accelerator
sbt test
sbt "runMain FLOOD_Accelerator.GenerateVerilog"
cd diffusion
python -m pytest tests/test_environment.py -v
python scripts/check_environment.py
```

Expected: existing tests pass, `generated/MacMachineWrapper.v` exists, Python reports `1 passed`, and missing external tools are recorded as `unavailable`.

- [ ] **Step 6: Commit**

```bash
git add accelerator/.gitignore accelerator/diffusion
git commit -m "chore: freeze diffusion environment baseline"
```

### Task 2: Capture Real SD1.5 ResNetBlock Tensors

**Files:**
- Create: `accelerator/diffusion/config/sd15_resnetblock.json`
- Create: `accelerator/diffusion/python/sd_accel/manifest.py`
- Create: `accelerator/diffusion/python/sd_accel/capture.py`
- Create: `accelerator/diffusion/scripts/capture_sd15.py`
- Create: `accelerator/diffusion/tests/test_capture.py`

**Interfaces:**
- Consumes a local model supplied through `--model-path`; no access token is stored.
- Produces `CaptureManifest` and NPZ fields `input`, `temb`, both conv/norm weights and biases, and `output_fp16`.

- [ ] **Step 1: Write a failing manifest round-trip test**

```python
from pathlib import Path
from sd_accel.manifest import CaptureManifest

def test_manifest_round_trip(tmp_path: Path):
    item = CaptureManifest("local-sd15", "down_blocks.0.resnets.1",
                           500, 921, (1, 320, 64, 64),
                           (1, 320, 64, 64), "float16")
    path = tmp_path / "manifest.json"
    item.save(path)
    assert CaptureManifest.load(path) == item
```

- [ ] **Step 2: Run and verify failure**

Run: `python -m pytest tests/test_capture.py::test_manifest_round_trip -v`  
Expected: FAIL because `CaptureManifest` is absent.

- [ ] **Step 3: Implement the immutable manifest**

```python
from dataclasses import asdict, dataclass
import json
from pathlib import Path

@dataclass(frozen=True)
class CaptureManifest:
    model_id: str
    block_path: str
    timestep: int
    seed: int
    input_shape: tuple[int, ...]
    output_shape: tuple[int, ...]
    dtype: str
    def save(self, path: Path) -> None:
        path.write_text(json.dumps(asdict(self), indent=2), "utf-8")
    @classmethod
    def load(cls, path: Path) -> "CaptureManifest":
        data = json.loads(path.read_text("utf-8"))
        data["input_shape"] = tuple(data["input_shape"])
        data["output_shape"] = tuple(data["output_shape"])
        return cls(**data)
```

- [ ] **Step 4: Implement deterministic hook capture**

Expose `capture_block(model_path, block_path, timestep, seed, output_dir)`. Use `torch.manual_seed(seed)`, deterministic algorithms, local-only loading, a pre-hook for hidden states/temb and a forward hook for output. Resolve numeric dotted paths by integer indexing. Save SHA-256 beside NPZ.

- [ ] **Step 5: Test without downloading**

Build a fake module with `down_blocks[0].resnets[0]` and assert captured input, temb and output are byte-identical to direct execution.

- [ ] **Step 6: Capture four required shapes**

```powershell
python scripts/capture_sd15.py --model-path D:\models\stable-diffusion-v1-5 --block-path down_blocks.0.resnets.1 --timestep 500 --seed 921 --output-dir artifacts/captures/64x64x320
python scripts/capture_sd15.py --model-path D:\models\stable-diffusion-v1-5 --block-path down_blocks.1.resnets.1 --timestep 500 --seed 921 --output-dir artifacts/captures/32x32x640
python scripts/capture_sd15.py --model-path D:\models\stable-diffusion-v1-5 --block-path down_blocks.2.resnets.1 --timestep 500 --seed 921 --output-dir artifacts/captures/16x16x1280
python scripts/capture_sd15.py --model-path D:\models\stable-diffusion-v1-5 --block-path down_blocks.3.resnets.1 --timestep 500 --seed 921 --output-dir artifacts/captures/8x8x1280
```

Expected: each directory contains manifest, checksum and NPZ; `Cin != Cout` is rejected unless projection is explicitly enabled.

- [ ] **Step 7: Commit**

```bash
git add accelerator/diffusion
git commit -m "feat: capture deterministic sd15 block tensors"
```

### Task 3: Lock Fixed-Point and Blocked-Layout Contracts

**Files:**
- Create: `accelerator/diffusion/python/sd_accel/fixedpoint.py`
- Create: `accelerator/diffusion/python/sd_accel/layout.py`
- Create: `accelerator/diffusion/tests/test_fixedpoint.py`
- Create: `accelerator/diffusion/tests/test_layout.py`
- Modify: `accelerator/diffusion/config/sd15_resnetblock.json`

**Interfaces:** Produces `saturate_signed`, `round_shift_away_from_zero`, `requantize`, `nchw_to_blocked32` and inverse layout.

- [ ] **Step 1: Write boundary tests**

```python
import numpy as np
from sd_accel.fixedpoint import saturate_signed, round_shift_away_from_zero

def test_fixed_boundaries():
    x = np.array([-40000, -32768, 32767, 40000], dtype=np.int64)
    np.testing.assert_array_equal(
        saturate_signed(x, 16), [-32768, -32768, 32767, 32767])
    np.testing.assert_array_equal(
        round_shift_away_from_zero(np.array([-7, -5, 5, 7]), 1),
        [-4, -3, 3, 4])
```

- [ ] **Step 2: Run and verify failure**

Run: `python -m pytest tests/test_fixedpoint.py tests/test_layout.py -v`  
Expected: FAIL because modules are absent.

- [ ] **Step 3: Implement canonical primitives**

```python
import numpy as np

def saturate_signed(x, bits):
    return np.clip(np.asarray(x, dtype=np.int64),
                   -(1 << (bits - 1)), (1 << (bits - 1)) - 1)

def round_shift_away_from_zero(x, shift):
    x = np.asarray(x, dtype=np.int64)
    if shift == 0:
        return x
    y = (np.abs(x) + (1 << (shift - 1))) >> shift
    return np.where(x < 0, -y, y)

def requantize(x, multiplier, shift, bits):
    return saturate_signed(
        round_shift_away_from_zero(np.asarray(x) * np.int64(multiplier), shift),
        bits)
```

- [ ] **Step 4: Implement layout `[N,Cb,H,W,32]`**

Round-trip all four required shapes and assert padded lanes are zero. JSON locks symmetric zero-point 0, per-output-channel weight scales, per-stage activation scales, INT32 accumulation, INT16 intermediates, channel block 32 and rounding `away_from_zero`.

- [ ] **Step 5: Run tests**

Run: `python -m pytest tests/test_fixedpoint.py tests/test_layout.py -v`  
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add accelerator/diffusion
git commit -m "feat: define fixed point and layout contracts"
```

### Task 4: Build Integer GroupNorm, SiLU and Time References

**Files:**
- Create: `accelerator/diffusion/python/sd_accel/groupnorm.py`
- Create: `accelerator/diffusion/python/sd_accel/silu.py`
- Create: `accelerator/diffusion/python/sd_accel/resnet_ops.py`
- Create: `accelerator/diffusion/scripts/generate_silu_coeffs.py`
- Create: `accelerator/diffusion/tests/test_groupnorm.py`
- Create: `accelerator/diffusion/tests/test_silu.py`

**Interfaces:** Produces `groupnorm_int16`, `rsqrt_q30`, `silu_pwl_int16` and `add_time_embedding_int16`.

- [ ] **Step 1: Write exact-vector tests**

Constant groups normalize to beta; variance never becomes negative; `SiLU(0)=0`; PWL is monotonic; time embedding broadcasts over N/H/W; all outputs saturate rather than wrap.

- [ ] **Step 2: Run and verify failure**

Run: `python -m pytest tests/test_groupnorm.py tests/test_silu.py -v`  
Expected: collection FAIL.

- [ ] **Step 3: Implement integer GroupNorm**

Use INT64 sum/sum-square, rounded mean, non-negative variance clamp, epsilon in the variance Q-domain, a 256-entry mantissa LUT and two Q2.30 Newton iterations. Apply gamma/beta in INT64 and saturate to INT16. Optional trace returns sum, sum-square, mean, variance and reciprocal standard deviation.

- [ ] **Step 4: Generate deterministic PWL coefficients**

Generate both 16- and 32-segment coefficient JSON and `SiluCoeffs.scala` from one script. A test runs the generator twice and compares SHA-256.

- [ ] **Step 5: Characterize FP32 error**

Record max/mean error and cosine similarity, while retaining integer equality as the RTL criterion.

- [ ] **Step 6: Commit**

```bash
git add accelerator/diffusion
git commit -m "feat: add integer normalization and activation references"
```

### Task 5: Complete Fixed ResNetBlock and DDR Traffic Model

**Files:**
- Create: `accelerator/diffusion/python/sd_accel/conv.py`
- Create: `accelerator/diffusion/python/sd_accel/resnetblock.py`
- Create: `accelerator/diffusion/python/sd_accel/traffic.py`
- Create: `accelerator/diffusion/python/sd_accel/vectors.py`
- Create: `accelerator/diffusion/scripts/generate_vectors.py`
- Create: `accelerator/diffusion/tests/test_resnetblock.py`
- Create: `accelerator/diffusion/tests/test_traffic.py`

**Interfaces:** Produces `resnetblock_int(..., trace=False)`, `estimate_traffic(...)` and vector manifests with offsets, scales and hashes.

- [ ] **Step 1: Write a `C=32,H=W=4` toy Block test**

Use center-tap identity-like weights, zero temb and deterministic gamma/beta. Assert full output equals explicit stage composition and the trace contains every stage.

- [ ] **Step 2: Write traffic invariants**

Both baselines count input, weights, temb and final output. Non-fused additionally writes and rereads GN1, SiLU1, Conv1/time, GN2 and SiLU2. Assert fused bytes are lower and compute `1 - fused/unfused`.

- [ ] **Step 3: Implement 3×3 W8A8 convolution**

Accumulate with INT64 to detect overflow, assert INT32 range, then canonical requantize. Support stride 1, padding 1 and channels multiple of 32.

- [ ] **Step 4: Implement full sequence**

Execute `GN1 → SiLU → Conv1 → time → GN2 → SiLU → Conv2 → residual` and preserve residual until final add.

- [ ] **Step 5: Enforce Gate A**

```powershell
python -m pytest tests -v
python scripts/generate_vectors.py --capture artifacts/captures/64x64x320 --output artifacts/vectors/64x64x320
python -m sd_accel.traffic --all-required-shapes --output results/baseline/traffic.json
```

Expected: deterministic hashes and predicted traffic reduction of at least 50% for every shape.

- [ ] **Step 6: Commit**

```bash
git add accelerator/diffusion
git commit -m "feat: add bit exact block and traffic model"
```

### Task 6: Add Isolated Diffusion Hardware Contracts

**Files:**
- Create: `accelerator/src/main/scala/diffusion/DiffusionParams.scala`
- Create: `accelerator/src/main/scala/diffusion/DiffusionBundles.scala`
- Create: `accelerator/src/main/scala/diffusion/GenerateDiffusionVerilog.scala`
- Create: `accelerator/src/test/scala/diffusion/DiffusionParamsSpec.scala`

**Interfaces:** Produces `DiffusionParams`, `WeightBeat`, `BlockCommand`, `BlockStatus` and `PerfCounters`; does not change legacy `Config.tileSize=16`.

- [ ] **Step 1: Write a failing elaboration test**

```scala
package FLOOD_Accelerator.diffusion
import org.scalatest.flatspec.AnyFlatSpec

class DiffusionParamsSpec extends AnyFlatSpec {
  "sd15EightTile" should "lock the prototype" in {
    val p = DiffusionParams.sd15EightTile
    assert(p.tileCount == 8)
    assert(p.ciTile == 32 && p.coTile == 32)
    assert(p.dataWidth == 8 && p.accumWidth == 32)
    assert(p.activationWidth == 16 && p.groupCount == 32)
  }
}
```

- [ ] **Step 2: Run and verify failure**

Run: `sbt "testOnly FLOOD_Accelerator.diffusion.DiffusionParamsSpec"`  
Expected: compilation FAIL.

- [ ] **Step 3: Implement parameters**

```scala
package FLOOD_Accelerator.diffusion

case class DiffusionParams(
  tileCount: Int, ciTile: Int = 32, coTile: Int = 32,
  dataWidth: Int = 8, accumWidth: Int = 32,
  activationWidth: Int = 16, groupCount: Int = 32,
  axiDataWidth: Int = 512, addressWidth: Int = 64) {
  require(tileCount == 8 || tileCount == 16)
  require(ciTile == 32 && coTile == 32)
  require(accumWidth >= 32 && axiDataWidth % 8 == 0)
}
object DiffusionParams {
  val sd15EightTile = DiffusionParams(8)
  val sd15SixteenTile = DiffusionParams(16)
}
```

- [ ] **Step 4: Lock Bundle fields**

Command contains tensor/weight/scale addresses, N/C/H/W, flags and command ID. Status contains busy/done/error/errorCode/completed ID. Counters are 64-bit saturating total cycles, read/write bytes, MAC/GN/stall cycles.

- [ ] **Step 5: Test and generate**

Run: `sbt "testOnly FLOOD_Accelerator.diffusion.DiffusionParamsSpec"` and then generate both accepted configurations.  
Expected: the test passes, each target directory contains one top-level Verilog file, and legacy `Config.scala` remains unchanged.

- [ ] **Step 6: Commit**

```bash
git add accelerator/src/main/scala/diffusion accelerator/src/test/scala/diffusion
git commit -m "feat: define diffusion hardware contracts"
```

### Task 7: Wrap CIMCore as INT8/INT32 Convolution Adapter

**Files:**
- Create: `accelerator/src/main/scala/diffusion/FloodConvAdapter.scala`
- Create: `accelerator/src/test/scala/diffusion/FloodConvAdapterSpec.scala`
- Modify: `accelerator/src/main/scala/core/CIMcore.scala` only when a failing adapter test proves a defect.

**Interfaces:** Uses `CIMCore(32,32,8,32,256,2,4)`; consumes weight writes and 32-lane activations; emits 32 INT32 partial sums.

- [ ] **Step 1: Write 4×4 ping/pong and backpressure tests**
- [ ] **Step 2: Run and verify missing adapter**
- [ ] **Step 3: Implement sign extension, weight-bank control and Decoupled output without requantization**
- [ ] **Step 4: Compare seeds 921–923, 100 vectors each, including -128/127 and random stalls**
- [ ] **Step 5: Synthesize an 8 Tile harness and save DSP/LUT/FF/Fmax JSON**

Expected: Scala BigInt reference equality; no 16 Tile attempt if projected resources exceed 80%.

- [ ] **Step 6: Commit**

```bash
git add accelerator/src
git commit -m "feat: adapt flood cim for diffusion convolution"
```

### Task 8: Implement GroupNorm, Rsqrt and Fused Elementwise RTL

**Files:**
- Create: `accelerator/src/main/scala/diffusion/GroupNormStats.scala`
- Create: `accelerator/src/main/scala/diffusion/RsqrtUnit.scala`
- Create: `accelerator/src/main/scala/diffusion/GroupNormApply.scala`
- Create: `accelerator/src/main/scala/diffusion/SiluPwl.scala`
- Create: `accelerator/src/main/scala/diffusion/SiluCoeffs.scala`
- Create: `accelerator/src/main/scala/diffusion/TimeResidualFuse.scala`
- Create tests with matching names under `src/test/scala/diffusion`.

**Interfaces:** Decoupled INT16 lanes; `GroupStats(sum,sumSq,count)`; rsqrt output Q2.30; coefficient file generated by Task 4.

- [ ] **Step 1: Export Python trace vectors for constant, impulse, extrema and seeded random input**
- [ ] **Step 2: Implement statistics widths derived from maximum `64×64×320/32` group size**
- [ ] **Step 3: Implement LUT normalization and exactly two Newton iterations**
- [ ] **Step 4: Implement normalize/gamma/beta, 16/32 PWL, temb and residual saturation**
- [ ] **Step 5: Run Gate B**

```powershell
sbt "testOnly FLOOD_Accelerator.diffusion.GroupNormSpec"
sbt "testOnly FLOOD_Accelerator.diffusion.SiluPwlSpec"
sbt "testOnly FLOOD_Accelerator.diffusion.TimeResidualFuseSpec"
```

Expected: every integer output and debug statistic equals Python.

- [ ] **Step 6: Commit**

```bash
git add accelerator/src
git commit -m "feat: add bit exact normalization and fused rtl"
```

### Task 9: Add Tile Buffers and Fused Scheduler

**Files:**
- Create: `accelerator/src/main/scala/diffusion/TensorTileBuffer.scala`
- Create: `accelerator/src/main/scala/diffusion/BlockScheduler.scala`
- Create corresponding Specs.

**Interfaces:** Residual/Mid INT16, Accumulator INT32, ping/pong banks; phases `LoadResidual`, `Gn1Stats`, `Gn1Conv1`, `Gn2Stats`, `Gn2Conv2Residual`, `StoreOutput`.

- [ ] **Step 1: Test collisions, two-cycle reads, bank swaps, clear and residual persistence**
- [ ] **Step 2: Test exact phase sequence for one spatial tile and two channel tiles**
- [ ] **Step 3: Implement `SyncReadMem` buffers with high-water counters**
- [ ] **Step 4: Reject zero/misaligned dimensions, stride !=1, channels not multiple of 32 and `Cin != Cout`**
- [ ] **Step 5: Prove load N+1 overlaps compute N and beats a single-buffer cycle count**
- [ ] **Step 6: Commit**

```bash
git add accelerator/src
git commit -m "feat: schedule fused block with on chip residency"
```

### Task 10: Implement AXI Control, DMA and Observability

**Files:**
- Create: `DiffusionRegisterMap.scala`, `AxiLiteControl.scala`, `TensorDma.scala` and `PerfMonitor.scala` under the diffusion package.
- Create `AxiLiteControlSpec.scala` and `TensorDmaSpec.scala`.

**Interfaces:**
- AXI4-Lite 32-bit; AXI4-MM 512-bit/64-bit.
- Offsets: `0x000 CONTROL`, `0x004 STATUS`, `0x008 ERROR`, `0x00C COMMAND_ID`, `0x010–0x04C` addresses/dimensions, `0x050 FLAGS`, `0x080–0x0B8` counters.
- Error codes: 1 invalid dimension, 2 misalignment, 3 projection, 4 read error, 5 write error, 6 watchdog.

- [ ] **Step 1: Test independent AW/W, strobes, busy writes, self-clear start and SLVERR**
- [ ] **Step 2: Test 4 KB burst splitting, 64-byte alignment, backpressure and AXI errors**
- [ ] **Step 3: Implement skid buffers, bounded bursts and PCIe-independent interfaces**
- [ ] **Step 4: Snapshot saturating counters when done asserts**
- [ ] **Step 5: Run randomized protocol tests**

Run: `sbt "testOnly FLOOD_Accelerator.diffusion.AxiLiteControlSpec FLOOD_Accelerator.diffusion.TensorDmaSpec"`  
Expected: PASS under randomized ready/valid stalls.

- [ ] **Step 6: Commit**

```bash
git add accelerator/src
git commit -m "feat: add axi dma control and counters"
```

### Task 11: Integrate and Verify AXI-Independent Top

**Files:**
- Create: `accelerator/src/main/scala/diffusion/DiffusionAccelTop.scala`
- Create: `DiffusionAccelTopSpec.scala` and `ResNetBlockVectorSpec.scala`.
- Create: `accelerator/diffusion/scripts/compare_rtl.py`

**Interfaces:** clock/reset, AXI4-Lite slave, AXI4-MM master and interrupt.

- [ ] **Step 1: Write a failing end-to-end `32×4×4` AXI-memory test**
- [ ] **Step 2: Wire control → scheduler → DMA/buffers → operators → output DMA**
- [ ] **Step 3: Inject SLVERR, timeout, misalignment and unsupported channels; verify exact errors and no output write**
- [ ] **Step 4: Run `8×8×1280` then `64×64×320` real vectors with Verilator**
- [ ] **Step 5: Enforce Gate C**

```powershell
cd accelerator
sbt test
sbt "runMain FLOOD_Accelerator.diffusion.GenerateDiffusionVerilog --tiles 8"
cd diffusion
python scripts/compare_rtl.py --manifest artifacts/vectors/8x8x1280/manifest.json --rtl-output results/raw/rtl_output.bin
```

Expected: bit-exact output and DMA counters equal the traffic model.

- [ ] **Step 6: Commit**

```bash
git add accelerator/src accelerator/diffusion
git commit -m "feat: integrate axi resnetblock accelerator"
```

### Task 12: Build AXKU15 DDR4 Shell and Synthesis Flow

**Files:**
- Create: `accelerator/fpga/AXKU15/diffusion/README.md`
- Create: `scripts/extract_ddr4_pins.py`, `create_project.tcl` and `report_impl.tcl` below that directory.
- Create: `rtl/axku15_diffusion_top.v`, `constrs/axku15_diffusion.xdc` and `tests/test_board_pins.py`.
- Generate: `ip/ddr4_0.xci`.

**Interfaces:** two 200 MHz differential inputs; exact 80-bit five-device MIG; accelerator connects only to MIG AXI UI; JTAG-to-AXI is the first host bridge.

- [ ] **Step 1: Parse local manual pin rows**

The test requires 80 data pins, 10 DM, 10 DQS P/N pairs, unique package pins and all address/control/reference-clock pins.

- [ ] **Step 2: Configure reproducible MIG**

Vivado 2022.2 settings: `XCKU15P-FFVE1517-2-I`, `MT40A512M16LY-062E`, five x16 devices, 80-bit width, 2666 Mbps, 200 MHz reference. Export `ddr4_0.xci` and `write_ip_tcl` output; a second batch creation must match properties.

- [ ] **Step 3: Implement board top**

Instantiate clock buffers, reset synchronizers, MIG, AXI interconnect, JTAG-to-AXI and accelerator. Map calibration/done/error to three LEDs. PCIe ports remain out until JTAG succeeds.

- [ ] **Step 4: Add clocks and CDC constraints**

Core clock is at least 150 MHz. False-path only asynchronous reset assertion; asynchronous groups only across an instantiated AXI clock converter. Run `report_cdc`.

- [ ] **Step 5: Run implementation**

```powershell
vivado -mode batch -source accelerator/fpga/AXKU15/diffusion/scripts/create_project.tcl
vivado -mode batch -source accelerator/fpga/AXKU15/diffusion/scripts/report_impl.tcl
```

Expected: calibrated MIG, no unconstrained paths, non-negative WNS and each resource class <=80%.

- [ ] **Step 6: Compare 16 Tile only after 8 Tile passes; keep reports separate**
- [ ] **Step 7: Commit**

```bash
git add accelerator/fpga/AXKU15/diffusion
git commit -m "feat: add reproducible axku15 board shell"
```

### Task 13: Run a Real Block on AXKU15

**Files:**
- Create: `accelerator/diffusion/python/sd_accel/host.py`
- Create: `accelerator/diffusion/scripts/run_jtag_block.py`
- Create: `accelerator/fpga/AXKU15/diffusion/scripts/program_and_run.tcl`
- Create: `accelerator/diffusion/tests/test_host_descriptor.py`
- Create: `accelerator/diffusion/results/board/README.md`

**Interfaces:** `BlockDescriptor.pack() -> bytes` and transport methods `write(address,data)` / `read(address,size)`.

- [ ] **Step 1: Test byte layout, split 64-bit addresses, four shapes and invalid descriptors**
- [ ] **Step 2: Implement transport-neutral host**

```python
class Transport:
    def write(self, address: int, data: bytes) -> None:
        raise NotImplementedError
    def read(self, address: int, size: int) -> bytes:
        raise NotImplementedError

def run_block(transport: Transport, descriptor, tensors) -> dict:
    """Load tensors, start one bounded command, read output and counters."""
```

- [ ] **Step 3: Bring up in order**

Program → clocks/resets → calibration → DDR walking-one/address tests → accelerator ID → toy vector → `8×8×1280` → `64×64×320`.

- [ ] **Step 4: Repeat 100 times**

Require identical output hashes, zero error codes, stable cycles and exact equality to Task 5. Compare measured DMA bytes with the traffic model.

- [ ] **Step 5: Enforce Gate D**

Report bitstream/manifest/model hashes, clock, cycles, latency, resources, power method, DDR bytes and 100/100 result.

- [ ] **Step 6: Add Gen3 x8 XDMA only after Gate D; reuse the same Transport API**
- [ ] **Step 7: Commit**

```bash
git add accelerator/diffusion accelerator/fpga/AXKU15/diffusion
git commit -m "feat: validate real sd15 block on axku15"
```

### Task 14: Automate Ablations and Thesis Evidence

**Files:**
- Create: `accelerator/diffusion/scripts/run_experiments.py`
- Create: `accelerator/diffusion/python/sd_accel/results.py`
- Create: `accelerator/diffusion/tests/test_results_schema.py`
- Create: `accelerator/diffusion/results/experiment_schema.json`
- Create: `accelerator/diffusion/results/summary.csv`
- Create: `accelerator/diffusion/results/README.md`
- Modify formal spec only to link measured reports.

**Interfaces:** Each CSV row contains commit, bitstream hash, manifest hash, shape, timestep, tiles, spatial tile, SiLU segments, fusion/double-buffer flags, frequency, cycles, latency, DDR bytes, LUT/FF/BRAM/URAM/DSP, power method/value, error metrics and pass count.

- [ ] **Step 1: Reject missing fields, invalid percentages, negative metrics, pass count below 100 and fused rows lacking baseline**
- [ ] **Step 2: Join Python, Vivado and board JSON only on manifest/bitstream hashes**
- [ ] **Step 3: Run four shapes, timesteps 50/500/950, 8 Tile, passing 16 Tile, two spatial tiles, SiLU 16/32, fused/unfused and single/double buffer**
- [ ] **Step 4: Report traffic, latency, throughput, resource efficiency, energy method, error and stability; label measured/estimated/simulated values**
- [ ] **Step 5: Reproduce from a clean worktree and record tool versions, commands, hashes and runtime**
- [ ] **Step 6: Commit**

```bash
git add accelerator/diffusion docs/superpowers/specs
git commit -m "docs: publish reproducible diffusion accelerator evidence"
```

## Final Acceptance Checklist

- [ ] Four SD1.5 shapes have deterministic captures and manifests.
- [ ] Python fixed model documents every Q format.
- [ ] Conv, GroupNorm, rsqrt, SiLU, temb and residual RTL equal the integer model.
- [ ] AXI-independent top passes toy and at least two real-vector regressions.
- [ ] DMA counters match the model and fused traffic is reduced by at least 50%.
- [ ] AXKU15 8 Tile meets at least 150 MHz and every resource class is at or below 80%.
- [ ] At least one real ResNetBlock passes 100 repeated board runs.
- [ ] Every result is linked to manifest, commit and bitstream hashes.
- [ ] Cross-Attention and XDMA do not delay the minimum deliverable.
