# SD1.5 ResNetBlock Three-Vector AXI64 Verification Implementation Plan

**Goal:** Prove a directed three-vector fixed-point ResNetBlock transaction
preserves vector order and bit-exact results across AXI64 DMA, compute, and
writeback under independent five-channel memory backpressure.

**Architecture:** Add one E2E test to the existing AXI64 behavioural-memory
suite.  It reuses the verified lane packing, fixed-point reference, staggered
AXI64 model, and command helpers; production RTL remains unchanged.  The
three input words have aggregate variance one, so the existing Q2.30 rsqrt
reference is exact for the selected workload.

**Tech Stack:** Scala 2.12.13, Chisel 3.5.3, chiseltest 0.5.3, ScalaTest, SBT
1.12.15, Eclipse Adoptium Java 17.

## Global Constraints

- DUT: `new DiffusionAccelTop(memoryBackend = DiffusionMemoryBackend.Axi64)`.
- Touch only the E2E test and design evidence documents.
- Never modify production RTL, AXKU15 demo/IP, Vivado Tcl, bitstream flow, or
  FPGA state.
- Use three 64-byte DMA beats at read addresses `0x400`, `0x440`, `0x480` and
  write addresses `0x800`, `0x840`, `0x880`.
- Use `Axi64DelayProfile.staggered` and require all `AW/W/B/AR/R` channels to
  have been delayed.
- All polling loops need named finite limits.

---

### Task 1: Add the three-vector directed E2E regression

**Files:**
- Modify: `accelerator/src/test/scala/diffusion/DiffusionAccelTopResNetBlockE2ESpec.scala`
- Test: `accelerator/src/test/scala/diffusion/DiffusionAccelTopResNetBlockE2ESpec.scala`

**Interfaces:**
- Consumes: `idle`, `tick`, `Axi64MemoryModel`, `Axi64DelayProfile.staggered`,
  `ResNetBlockE2EReference`, `DiffusionAccelTop` public IO.
- Produces: one test named `preserve three DMA vectors and write all fixed-point
  results in order`.

- [ ] **Step 1: Write the failing test**

Append a test whose inputs and expected aggregate statistics are:

```scala
val input0 = Vector.fill(16)(-1) ++ Vector.fill(16)(1)
val input1 = Vector.fill(16)(1) ++ Vector.fill(16)(-1)
val input2 = Vector.tabulate(32)(lane => if ((lane & 1) == 0) -1 else 1)
val inputs = Vector(input0, input1, input2)
ResNetBlockE2EReference.stats(inputs.flatten) shouldBe GroupStatsReference(0, 96, 96)
```

Drive read/write commands with `beats.poke(3.U)`, every compute command with
`vectors.poke(3.U)`, and collect three output vectors at each Decoupled
compute observation.  Require the exact read/write address history and three
writeback words.

- [ ] **Step 2: Verify RED**

Run:

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false -Xms512m -Xmx4G'
sbt 'testOnly FLOOD_Accelerator.diffusion.DiffusionAccelTopResNetBlockE2ESpec -- -z "three DMA vectors"'
```

Expected: the test fails before production-code edits because the existing
output capture/expectation bounds are two vectors.

- [ ] **Step 3: Implement the minimal test-only generalization**

Keep the existing two-vector and consecutive-transaction tests unchanged.
Within the new test, use a local `capture` helper parameterized with expected
vector count `3`; wait at most 1536 cycles for each three-vector compute
stream and fail with a named timeout.  Compare:

```scala
conv1.toVector shouldBe inputs
activation.toVector shouldBe inputs.map(_.map(lane => if (lane < 0) 0 else 2))
conv2.toVector shouldBe inputs.map(ResNetBlockE2EReference.finalLanes(_, temb, residual))
memory.readBurstAddresses shouldBe Vector(BigInt(0x400), BigInt(0x440), BigInt(0x480))
memory.writeBurstAddresses shouldBe Vector(BigInt(0x800), BigInt(0x840), BigInt(0x880))
memory.delayedChannels shouldBe Set("AW", "W", "B", "AR", "R")
memory.assertNoProtocolError()
```

- [ ] **Step 4: Verify GREEN**

Re-run the Step 2 command.  Expected: exactly one selected test passes with
zero failures.

- [ ] **Step 5: Commit test increment**

```powershell
git add accelerator/src/test/scala/diffusion/DiffusionAccelTopResNetBlockE2ESpec.scala
git commit -m "test: verify three-vector ResNetBlock DMA flow"
```

### Task 2: Record evidence and run the focused regression

**Files:**
- Modify: `accelerator/docs/plans/2026-08-12-sd15-resnetblock-three-vector-verification-design.md`
- Modify: `accelerator/docs/plans/2026-08-12-sd15-resnetblock-three-vector-verification-implementation.md`

**Interfaces:**
- Consumes: passing three-vector E2E result and the existing focused E2E,
  AXI64, bridge, compute, buffer, and rsqrt tests.
- Produces: reproducible evidence for the simulator-only three-vector boundary.

- [ ] **Step 1: Run focused regression**

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false -Xms512m -Xmx4G'
sbt 'testOnly FLOOD_Accelerator.diffusion.TensorTileBufferSpec FLOOD_Accelerator.diffusion.TensorLoadBufferSpec FLOOD_Accelerator.diffusion.ResNetBlockE2ETestSupportSpec FLOOD_Accelerator.diffusion.DiffusionAccelTopResNetBlockE2ESpec FLOOD_Accelerator.diffusion.Axi64MemoryModelSpec FLOOD_Accelerator.diffusion.DiffusionAccelTopAxi64Spec FLOOD_Accelerator.diffusion.MigAppToAxi64BridgeSpec FLOOD_Accelerator.diffusion.ConvToGroupNormStatsPathSpec FLOOD_Accelerator.diffusion.Conv2ResidualPathSpec FLOOD_Accelerator.diffusion.GroupNormActivationPathSpec FLOOD_Accelerator.diffusion.RsqrtUnitReferenceSpec'
```

Expected: all selected suites pass with zero failures.

- [ ] **Step 2: Elaborate the unchanged AXI64 top**

```powershell
sbt 'runMain FLOOD_Accelerator.diffusion.GenerateDiffusionAccelAxi64TopVerilog'
git diff --check
```

Expected: elaboration and diff check return zero; no generated tracked source
artifact is added.

- [ ] **Step 3: Update evidence wording**

Set the design status to `Implemented and simulation-validated`.  Record the
actual focused-test suite/count and elaboration result; identify the input,
statistics, addresses, fixed-point checks, staggered backpressure, and
explicit exclusions.  Mark this plan's completed checkboxes only after their
commands have succeeded.

- [ ] **Step 4: Commit evidence**

```powershell
git add accelerator/docs/plans/2026-08-12-sd15-resnetblock-three-vector-verification-design.md accelerator/docs/plans/2026-08-12-sd15-resnetblock-three-vector-verification-implementation.md
git commit -m "docs: record three-vector verification evidence"
```

## Plan self-review

- Scope: one simulator-only three-vector test plus its evidence; no production
  RTL or board-flow work.
- Coverage: each required input, aggregate statistic, command count, output
  stream, burst address, backpressure channel, protocol assertion, and
  bounded wait has an explicit Task 1 check.
- Consistency: all three input vectors produce aggregate variance one and use
  the existing Q2.30 reference `759250125`.
