# SD1.5 ResNetBlock End-to-End Fixed-Point Verification Implementation Plan

**Goal:** Add a bit-exact AXI64-backed Chisel simulation proving one directed 32-lane ResNetBlock transaction completes from tensor read through final memory writeback before FPGA integration resumes.

**Architecture:** Keep `DiffusionAccelTop` unchanged and instantiate its AXI64 backend in a new test. Test-only Scala support supplies a single-outstanding AXI64 slave, byte-addressable memory, deterministic channel delays, and an integer reference for the selected variance-one workload. The E2E test drives the existing public control and Decoupled interfaces, then compares statistics, intermediate outputs, writeback storage, and completion timing.

**Tech stack:** Scala 2.12.13, Chisel 3.5.3, chiseltest 0.5.3, ScalaTest, SBT 1.12.15.

## Global constraints

- DUT: `new DiffusionAccelTop(memoryBackend = DiffusionMemoryBackend.Axi64)`.
- Do not modify production RTL, official AXKU15 demo/IP, Vivado Tcl, implementation flow, bitstream flow, or FPGA.
- A 512-bit tensor transfer is exactly eight ordered 64-bit AXI beats with `len == 7` and `size == 3`.
- Input lanes 0--15 are `-1`, lanes 16--31 are `+1`; therefore sum is 0, square sum is 32, count is 32, variance is 1, and Q2.30 rsqrt is `759250125`.
- Conv1/Conv2 use only diagonal W8 weights equal to one; both shifts are zero; GN2 gamma is 256, beta is zero, and `addResidual` is true.
- Every polling loop has a named finite bound. Completion may not be inferred from a fixed sleep.

---

### Task 1: Add test-side AXI64 memory and directed fixed-point reference

**Files:**
- Create: `accelerator/src/test/scala/diffusion/ResNetBlockE2ETestSupport.scala`
- Test: `accelerator/src/test/scala/diffusion/ResNetBlockE2ETestSupportSpec.scala`

**Interfaces:**
- Consumes: `DiffusionAccelTop.io.axi64`, `SiluCoeffs.segments16`.
- Produces: `Axi64MemoryModel`, `Axi64DelayProfile`, and `ResNetBlockE2EReference`.

- [ ] **Step 1: Write failing support tests**

Create `ResNetBlockE2ETestSupportSpec.scala`:

```scala
class ResNetBlockE2ETestSupportSpec extends AnyFlatSpec with Matchers {
  "ResNetBlockE2EReference" should "pack 32 signed lanes little-endian" in {
    val lanes = Vector.tabulate(32)(_ - 16)
    ResNetBlockE2EReference.unpackLanes(ResNetBlockE2EReference.packLanes(lanes)) shouldBe lanes
  }
  it should "derive the directed variance-one result" in {
    val input = Vector.fill(16)(-1) ++ Vector.fill(16)(1)
    ResNetBlockE2EReference.stats(input) shouldBe GroupStatsReference(0, 32, 32)
    ResNetBlockE2EReference.rsqrtVarianceOne shouldBe BigInt(759250125)
    ResNetBlockE2EReference.finalLanes(input, Vector.fill(32)(3), Vector.fill(32)(-2)).size shouldBe 32
  }
}
```

- [ ] **Step 2: Verify RED**

Run:

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false'
sbt 'testOnly FLOOD_Accelerator.diffusion.ResNetBlockE2ETestSupportSpec'
```

Expected: compilation fails because the support types are absent.

- [ ] **Step 3: Implement minimal test-only support**

Create `ResNetBlockE2ETestSupport.scala` with these exact test-side contracts:

| Symbol | Required contract |
| --- | --- |
| `Axi64DelayProfile(aw, w, b, ar, r)` | five nonnegative per-channel delay counts; `immediate = (0,0,0,0,0)` and `staggered = (1,2,1,3,2)` |
| `GroupStatsReference(sum, sumSquare, count)` | immutable integer reduction result |
| `ResNetBlockE2EReference.packLanes/unpackLanes` | 32 signed INT16 lanes with lane 0 in bits 15:0, round-trip exact |
| `stats` | signed sum, unsigned sum of squares, and lane count |
| `roundAwayFromZero`, `saturateInt8`, `saturateInt16`, `silu16` | exact integer behavior matching `DiffusionFixedPoint`, `VectorRequantizeInt16ToInt8`, and `SiluPwl` |
| `finalLanes(input, temb, residual)` | directed variance-one GN/SiLU, diagonal Conv1/Conv2, then saturating `silu + temb + residual` |
| `Axi64MemoryModel.load512/read512` | seed and inspect 64-byte aligned, byte-addressable storage |
| `driveBeforeClock/observeAfterClock` | drive then observe one AXI64 cycle, maintaining one outstanding burst |
| `assertNoProtocolError/delayedChannels` | expose protocol assertions and the set of deliberately delayed channel names |
Implement lane zero at word bits `15:0`, with two's-complement decode. Implement SiLU from `SiluCoeffs.segments16`, `roundAwayFromZero(product, 16)`, the `input >= 2048` override, negative-positive cap, and INT16 saturation used in `SiluPwl`. Compute the directed reference with rsqrt `759250125`, gamma 256, beta zero, diagonal convolutions, then saturating `silu + temb + residual`.

The memory model records `aw.fire`, accepts exactly eight `w.fire` beats at `address + 8 * beat`, applies active `strb` bytes, emits one OKAY B response, and returns eight OKAY R beats after `ar.fire`. Assert ID zero, `len == 7`, `size == 3`, incrementing addresses, and `last` only on beat seven.

- [ ] **Step 4: Verify GREEN**

Run the Step 2 command.

Expected: two tests pass with zero failures.

- [ ] **Step 5: Commit**

```powershell
git add accelerator/src/test/scala/diffusion/ResNetBlockE2ETestSupport.scala accelerator/src/test/scala/diffusion/ResNetBlockE2ETestSupportSpec.scala
git commit -m "test: add ResNetBlock E2E verification support"
```

### Task 2: Drive the baseline end-to-end AXI64 ResNetBlock transaction

**Files:**
- Create: `accelerator/src/test/scala/diffusion/DiffusionAccelTopResNetBlockE2ESpec.scala`
- Uses: `accelerator/src/test/scala/diffusion/ResNetBlockE2ETestSupport.scala`

**Interfaces:**
- Consumes: `Axi64MemoryModel.load512/read512/driveBeforeClock/observeAfterClock` and `ResNetBlockE2EReference`.
- Produces: a baseline proof through scheduler, DMA, AXI64 bridge, both convolutions, GroupNorm, fusion, and StoreOutput.

- [ ] **Step 1: Write the failing E2E test**

```scala
"DiffusionAccelTop AXI64 ResNetBlock" should "write the directed bit-exact result" in {
  test(new DiffusionAccelTop(memoryBackend = DiffusionMemoryBackend.Axi64)) { dut =>
    val memory = new Axi64MemoryModel(dut, Axi64DelayProfile.immediate)
    val input = Vector.fill(16)(-1) ++ Vector.fill(16)(1)
    val temb = Vector.fill(32)(3)
    val residual = Vector.fill(32)(-2)
    memory.load512(0x400, ResNetBlockE2EReference.packLanes(input))
    runDirectedBlock(dut, memory, input, temb, residual)
    memory.read512(0x800) shouldBe ResNetBlockE2EReference.packLanes(
      ResNetBlockE2EReference.finalLanes(input, temb, residual))
  }
}
```

- [ ] **Step 2: Verify RED**

Run:

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false'
sbt 'testOnly FLOOD_Accelerator.diffusion.DiffusionAccelTopResNetBlockE2ESpec'
```

Expected: compilation fails because `runDirectedBlock` is not implemented.

- [ ] **Step 3: Implement runDirectedBlock**

Add a private `untilCondition(label, limit)(condition)(body)` helper. Each iteration calls `memory.driveBeforeClock()`, advances one DUT clock, then calls `memory.observeAfterClock()`; it fails with `label` at the limit.

Drive and assert this exact sequence:

1. AXI-Lite start; wait for `LoadResidual`.
2. `tensorReadCommand(address = 0x400, beats = 1)`; wait for `tensorReadDone` and `Gn1Stats`.
3. `gn1StatsCommand(vectors = 1)`; consume and compare `(0, 32, 32)`; wait for `Gn1Conv1`.
4. Write 32 Conv1 diagonal weights; issue `gn1ConvCommand(vectors = 1)`; compare its accepted output to input; wait for `Gn2Stats`.
5. `gn2StatsCommand(vectors = 1)`; consume and compare `(0, 32, 32)`.
6. Write 32 GN2 affine entries `(channel, 256, 0)`; issue `gn2ActivationCommand(vectors = 1)`; compare the accepted vector to `silu16` of variance-one normalized input.
7. Write 32 Conv2 diagonal weights; drive temb/residual/addResidual; issue `gn2ConvCommand(vectors = 1)`; compare accepted `gn2ConvOutput` to `finalLanes`.
8. Wait for `StoreOutput`; issue `tensorWriteCommand(address = 0x800, beats = 1)`; wait for `tensorWriteDone` and one `done` pulse; call `memory.assertNoProtocolError()`.

Use a 4096-cycle limit for phase/transaction completion and a 128-cycle limit for every command/output handshake. Assert an output `ready` only when the test records that output.

- [ ] **Step 4: Verify GREEN**

Run the Step 2 command.

Expected: one E2E test passes without timeout or protocol assertion.

- [ ] **Step 5: Commit**

```powershell
git add accelerator/src/test/scala/diffusion/DiffusionAccelTopResNetBlockE2ESpec.scala
git commit -m "test: verify AXI64 ResNetBlock end to end"
```

### Task 3: Prove the same result under independent AXI64 backpressure

**Files:**
- Modify: `accelerator/src/test/scala/diffusion/DiffusionAccelTopResNetBlockE2ESpec.scala`
- Modify: `accelerator/src/test/scala/diffusion/ResNetBlockE2ETestSupport.scala`

**Interfaces:**
- Consumes: baseline `runDirectedBlock` and `Axi64DelayProfile.staggered`.
- Produces: timing-independent final-writeback evidence.

- [ ] **Step 1: Write the failing stalled-memory test**

Add the baseline workload with:

```scala
val memory = new Axi64MemoryModel(dut, Axi64DelayProfile.staggered)
runDirectedBlock(dut, memory, input, temb, residual)
memory.read512(0x800) shouldBe expectedWord
memory.delayedChannels shouldBe Set("AW", "W", "B", "AR", "R")
```

- [ ] **Step 2: Verify RED**

Run:

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false'
sbt 'testOnly FLOOD_Accelerator.diffusion.DiffusionAccelTopResNetBlockE2ESpec -- -z backpressure'
```

Expected: fails until separate AW/W/B/AR/R countdowns and history are implemented.

- [ ] **Step 3: Complete delay scheduling**

Maintain independent countdowns for AW acceptance, every W beat, B visibility, AR acceptance, and every R visibility. Do not alter stored bytes or response data while a channel is delayed. Add a channel name to `delayedChannels` only when a valid transaction waits on that configured delay.

- [ ] **Step 4: Verify both E2E modes**

Run:

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false'
sbt 'testOnly FLOOD_Accelerator.diffusion.DiffusionAccelTopResNetBlockE2ESpec'
```

Expected: two tests pass, final words are equal, and all five channel names appear in the stalled test.

- [ ] **Step 5: Commit**

```powershell
git add accelerator/src/test/scala/diffusion/ResNetBlockE2ETestSupport.scala accelerator/src/test/scala/diffusion/DiffusionAccelTopResNetBlockE2ESpec.scala
git commit -m "test: cover ResNetBlock AXI64 backpressure"
```

### Task 4: Record simulation evidence and run regression

**Files:**
- Modify: `accelerator/docs/plans/2026-08-11-sd15-resnetblock-e2e-verification-design.md`

**Interfaces:**
- Consumes: passing E2E and existing focused AXI64/compute suites.
- Produces: the simulation prerequisite for later AXKU15 top work.

- [ ] **Step 1: Run focused suites**

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false'
sbt 'testOnly FLOOD_Accelerator.diffusion.DiffusionAccelTopResNetBlockE2ESpec FLOOD_Accelerator.diffusion.DiffusionAccelTopAxi64Spec FLOOD_Accelerator.diffusion.MigAppToAxi64BridgeSpec FLOOD_Accelerator.diffusion.ConvToGroupNormStatsPathSpec FLOOD_Accelerator.diffusion.Conv2ResidualPathSpec FLOOD_Accelerator.diffusion.GroupNormActivationPathSpec'
```

Expected: all selected suites pass with zero failures.

- [ ] **Step 2: Generate unchanged accelerator Verilog**

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false'
sbt 'runMain FLOOD_Accelerator.diffusion.GenerateDiffusionAccelAxi64TopVerilog'
```

Expected: Chisel elaboration succeeds. Inspect `git status --short`; do not commit generated artifacts unless already version-controlled.

- [ ] **Step 3: Update evidence wording**

Set the verification design status to `Implemented and simulation-validated`. Record the exact focused command and successful result. State that evidence covers one directed fixed-point vector under immediate and staggered AXI64 timing; retain exclusions for floating-point SD1.5 accuracy, Vivado implementation, bitstream generation, and FPGA programming.

- [ ] **Step 4: Run final regression and diff check**

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false'
sbt test
git diff --check
git status --short
```

Expected: tests pass, diff check emits nothing, and only intended support/test/evidence files are staged.

- [ ] **Step 5: Commit evidence**

```powershell
git add accelerator/src/test/scala/diffusion/ResNetBlockE2ETestSupport.scala accelerator/src/test/scala/diffusion/ResNetBlockE2ETestSupportSpec.scala accelerator/src/test/scala/diffusion/DiffusionAccelTopResNetBlockE2ESpec.scala accelerator/docs/plans/2026-08-11-sd15-resnetblock-e2e-verification-design.md
git commit -m "test: validate fixed-point ResNetBlock flow"
```

## Plan self-review

- Spec coverage: Task 1 supplies behavioural memory and integer reference; Task 2 covers the complete directed scheduler path and writeback; Task 3 supplies independent channel backpressure; Task 4 records focused and regression evidence.
- Scope: no task changes production RTL or starts board, Vivado, bitstream, or programming actions.
- Consistency: all tasks use the same AXI64 model, variance-one vector, diagonal weights, and `runDirectedBlock` sequence.

