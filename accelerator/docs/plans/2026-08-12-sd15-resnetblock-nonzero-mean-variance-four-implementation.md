# SD1.5 ResNetBlock Nonzero-Mean Variance-Four AXI64 Verification Implementation Plan

**Goal:** Prove a nonzero-mean, non-unit-variance two-vector fixed-point
ResNetBlock transaction against an integer reference and AXI64 writeback.

**Architecture:** Extend the test-only `ResNetBlockE2EReference` with an
explicit `mean` argument and add one E2E test using the real AXI64 top.  The
arithmetic mirrors integer mean/variance division plus round-away-from-zero
normalization and affine scaling.  No production RTL changes.

**Tech Stack:** Scala 2.12.13, Chisel 3.5.3, chiseltest 0.5.3, ScalaTest, SBT
1.12.15, Eclipse Adoptium Java 17.

## Global Constraints

- DUT: `new DiffusionAccelTop(memoryBackend = DiffusionMemoryBackend.Axi64)`.
- Modify only test-side reference/E2E code and these two documents.
- Do not alter production RTL, AXKU15 demo/IP, Vivado Tcl, bitstream flow, or FPGA state.
- Inputs are `[1 x16, 2 x16]` then `[5 x32]`; stats `(208, 880, 64)`, mean `3`, variance `4`, rsqrt Q2.30 `480191942`.
- Use `temb = +5`, `residual = -3`, diagonal unit Conv weights, identity GN2 affine parameters, reads `0x400/0x440`, writes `0x800/0x840`.
- Use `Axi64DelayProfile.staggered`, require all five delayed channels, and bound all polling loops.

---

### Task 1: Add a mean-aware fixed-point test reference

**Files:**
- Modify: `accelerator/src/test/scala/diffusion/ResNetBlockE2ETestSupport.scala`
- Modify: `accelerator/src/test/scala/diffusion/ResNetBlockE2ETestSupportSpec.scala`

**Interfaces:**
- Produces: `finalLanesWithMeanAndRsqrt(input, temb, residual, mean, rsqrtQ30): Vector[Int]`.
- Consumes: existing `roundAwayFromZero`, `saturateInt16`, and `silu16`.

- [x] **Step 1: Write the failing reference test**

Use the two input words, `mean = 3`, `rsqrtQ30 = 480191942`, `temb = 5`, and
`residual = -3`.  Assert aggregate statistics `(208, 880, 64)` and that the
mean-aware result differs from `finalLanesWithRsqrt` on word 0.

- [x] **Step 2: Run RED**

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false -Xms512m -Xmx4G'
sbt 'testOnly FLOOD_Accelerator.diffusion.ResNetBlockE2ETestSupportSpec'
```

Expected: compilation fails because the mean-aware helper is absent.

- [x] **Step 3: Implement the minimal helper**

```scala
def finalLanesWithMeanAndRsqrt(
    input: Vector[Int], temb: Vector[Int], residual: Vector[Int],
    mean: Int, rsqrtQ30: BigInt): Vector[Int] =
  input.zipWithIndex.map { case (lane, index) =>
    val normalized = roundAwayFromZero(BigInt(lane - mean) * rsqrtQ30, 30)
    val affine = roundAwayFromZero(normalized * 256, 8)
    val activation = silu16(saturateInt16(affine))
    saturateInt16(BigInt(activation) + temb(index) + residual(index))
  }
```

- [x] **Step 4: Run GREEN and commit**

Re-run Step 2; expected all support tests pass.  Commit the reference update.

### Task 2: Add the nonzero-mean E2E regression

**Files:**
- Modify: `accelerator/src/test/scala/diffusion/DiffusionAccelTopResNetBlockE2ESpec.scala`

**Interfaces:**
- Consumes: mean-aware reference helper, AXI64 behavioural memory, and existing `idle`/`tick` helpers.
- Produces: test `preserve nonzero-mean variance-four vectors through AXI64 ResNetBlock`.

- [x] **Step 1: Write the failing E2E case**

Drive reads at `0x400`, `0x440`; GN1/GN2 `vectors=2`; and writes at
`0x800`, `0x840`.  Assert both statistics outputs equal `(208, 880, 64)`;
capture two Conv1 vectors equal to inputs, two mean-aware activations, and two
final outputs/writeback words.

- [x] **Step 2: Run RED**

```powershell
sbt 'testOnly FLOOD_Accelerator.diffusion.DiffusionAccelTopResNetBlockE2ESpec'
```

Expected: failure until the mean-aware helper and E2E comparisons are connected; do not change RTL to force it.

- [x] **Step 3: Complete capture and handshake checks**

Use the validated two-vector capture pattern.  Activation observation must
continue accepting valid beats while paired Conv2 output completes; record
only the first two vectors.  Require read history `[0x400, 0x440]`, write
history `[0x800, 0x840]`, delayed channel set `AW/W/B/AR/R`, and no protocol error.

- [x] **Step 4: Run GREEN and commit**

Re-run Step 2 with all E2E cases; expected zero failures.  Commit the E2E
regression together with the reference helper if not already committed.

### Task 3: Record evidence and run focused regression

**Files:**
- Modify: `accelerator/docs/plans/2026-08-12-sd15-resnetblock-nonzero-mean-variance-four-design.md`
- Modify: `accelerator/docs/plans/2026-08-12-sd15-resnetblock-nonzero-mean-variance-four-implementation.md`

- [x] **Step 1: Run focused suites and elaborate the AXI64 top**

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false -Xms512m -Xmx4G'
sbt 'testOnly FLOOD_Accelerator.diffusion.TensorTileBufferSpec FLOOD_Accelerator.diffusion.TensorLoadBufferSpec FLOOD_Accelerator.diffusion.ResNetBlockE2ETestSupportSpec FLOOD_Accelerator.diffusion.DiffusionAccelTopResNetBlockE2ESpec FLOOD_Accelerator.diffusion.Axi64MemoryModelSpec FLOOD_Accelerator.diffusion.DiffusionAccelTopAxi64Spec FLOOD_Accelerator.diffusion.MigAppToAxi64BridgeSpec FLOOD_Accelerator.diffusion.ConvToGroupNormStatsPathSpec FLOOD_Accelerator.diffusion.Conv2ResidualPathSpec FLOOD_Accelerator.diffusion.GroupNormActivationPathSpec FLOOD_Accelerator.diffusion.RsqrtUnitReferenceSpec'
sbt 'runMain FLOOD_Accelerator.diffusion.GenerateDiffusionAccelAxi64TopVerilog'
git diff --check
```

Expected: zero test failures, successful elaboration, and no formatting error.

- [x] **Step 2: Record evidence and commit**

Set design status to `Implemented and simulation-validated`; record actual test/suite counts, statistics, mean/variance/rsqrt, addresses, all E2E checks, and exclusions.  Mark checkboxes only after success and commit evidence.

## Plan self-review

- The helper mirrors mean subtraction, rounding, affine scaling, SiLU, and saturation in RTL.
- The workload makes integer mean subtraction observable because mean-aware and zero-mean references differ.
- Scope is test/reference/documentation only; no board-flow work.

## Execution record

- Reference RED: compilation failed because `finalLanesWithMeanAndRsqrt` was absent.
- Reference GREEN: 5/5 support tests passed after adding the test-only helper.
- E2E GREEN: 6/6 ResNetBlock AXI64 cases passed, including the nonzero-mean,
  variance-four two-vector workload.
- Focused regression: 30/30 tests passed across 11 suites, with zero failures
  and zero errors; AXI64 top Verilog generation completed successfully.
- Scope remained test/reference/documentation only. No production RTL, Vivado
  implementation, bitstream, or FPGA programming change was made.
