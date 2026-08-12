# SD1.5 ResNetBlock Four-Vector AXI64 Verification Implementation Plan

**Goal:** Add a four-vector fixed-point AXI64 E2E regression and record
reproducible simulator-only evidence without modifying production RTL.

**Architecture:** Extend `DiffusionAccelTopResNetBlockE2ESpec` with one local
four-vector workload.  Reuse `ResNetBlockE2EReference` and
`Axi64MemoryModel.staggered`; collect exactly four vectors per observation
stream while continuing required Decoupled handshakes to avoid injecting
observer backpressure into Conv2.

**Tech Stack:** Scala 2.12.13, Chisel 3.5.3, chiseltest 0.5.3, ScalaTest, SBT
1.12.15, Eclipse Adoptium Java 17.

## Global Constraints

- DUT: `new DiffusionAccelTop(memoryBackend = DiffusionMemoryBackend.Axi64)`.
- Change only the E2E test and four-vector design/verification documents.
- Do not modify production RTL, AXKU15 demo/IP, Vivado Tcl, bitstream flow, or
  FPGA state.
- Four 64-byte reads are `0x400`, `0x440`, `0x480`, `0x4C0`; four writes are
  `0x800`, `0x840`, `0x880`, `0x8C0`.
- All command vectors/beats are four; aggregate stats are `(0, 128, 128)`.
- Use `Axi64DelayProfile.staggered`, require all `AW/W/B/AR/R`, and retain
  named finite polling limits.

---

### Task 1: Add and validate the four-vector E2E regression

**Files:**
- Modify: `accelerator/src/test/scala/diffusion/DiffusionAccelTopResNetBlockE2ESpec.scala`
- Test: `accelerator/src/test/scala/diffusion/DiffusionAccelTopResNetBlockE2ESpec.scala`

**Interfaces:**
- Consumes: `idle`, `tick`, `Axi64MemoryModel`, `Axi64DelayProfile.staggered`,
  and `ResNetBlockE2EReference`.
- Produces: test `preserve four DMA vectors and write all fixed-point results
  in order`.

- [ ] **Step 1: Add a failing four-vector test**

Declare and assert the following test workload:

```scala
val input0 = Vector.fill(16)(-1) ++ Vector.fill(16)(1)
val input1 = Vector.fill(16)(1) ++ Vector.fill(16)(-1)
val input2 = Vector.tabulate(32)(lane => if ((lane & 1) == 0) -1 else 1)
val input3 = Vector.tabulate(32)(lane => if ((lane & 1) == 0) 1 else -1)
val inputs = Vector(input0, input1, input2, input3)
ResNetBlockE2EReference.stats(inputs.flatten) shouldBe GroupStatsReference(0, 128, 128)
```

Drive `beats = 4` and every compute `vectors = 4`; collect/compare four
Conv1, activation, and Conv2 vectors; require four read/write burst bases and
four writeback words.

- [ ] **Step 2: Run RED**

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false -Xms512m -Xmx4G'
sbt 'testOnly FLOOD_Accelerator.diffusion.DiffusionAccelTopResNetBlockE2ESpec'
```

Expected: the new test initially fails until its test-side capture and
handshake handling are complete; do not modify production RTL to force it.

- [ ] **Step 3: Complete minimal test-side capture**

Use 4 as the capture bound.  Set `dut.clock.setTimeout(0)` only in the new
long-running test; each named wait must remain finite.  Keep output `ready`
high for each valid activation/Conv2 transfer required to advance the pipeline,
but append to its result buffer only while `size < 4`.  Assert:

```scala
memory.readBurstAddresses shouldBe Vector(BigInt(0x400), BigInt(0x440), BigInt(0x480), BigInt(0x4C0))
memory.writeBurstAddresses shouldBe Vector(BigInt(0x800), BigInt(0x840), BigInt(0x880), BigInt(0x8C0))
memory.delayedChannels shouldBe Set("AW", "W", "B", "AR", "R")
memory.assertNoProtocolError()
```

- [ ] **Step 4: Run GREEN and commit**

Re-run Step 2.  Expected: all ResNetBlock E2E tests pass with zero failures.

```powershell
git add accelerator/src/test/scala/diffusion/DiffusionAccelTopResNetBlockE2ESpec.scala
git commit -m "test: verify four-vector ResNetBlock DMA flow"
```

### Task 2: Run regression and record evidence

**Files:**
- Modify: `accelerator/docs/plans/2026-08-12-sd15-resnetblock-four-vector-verification-design.md`
- Modify: `accelerator/docs/plans/2026-08-12-sd15-resnetblock-four-vector-verification-implementation.md`

- [ ] **Step 1: Run focused regression**

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false -Xms512m -Xmx4G'
sbt 'testOnly FLOOD_Accelerator.diffusion.TensorTileBufferSpec FLOOD_Accelerator.diffusion.TensorLoadBufferSpec FLOOD_Accelerator.diffusion.ResNetBlockE2ETestSupportSpec FLOOD_Accelerator.diffusion.DiffusionAccelTopResNetBlockE2ESpec FLOOD_Accelerator.diffusion.Axi64MemoryModelSpec FLOOD_Accelerator.diffusion.DiffusionAccelTopAxi64Spec FLOOD_Accelerator.diffusion.MigAppToAxi64BridgeSpec FLOOD_Accelerator.diffusion.ConvToGroupNormStatsPathSpec FLOOD_Accelerator.diffusion.Conv2ResidualPathSpec FLOOD_Accelerator.diffusion.GroupNormActivationPathSpec FLOOD_Accelerator.diffusion.RsqrtUnitReferenceSpec'
sbt 'runMain FLOOD_Accelerator.diffusion.GenerateDiffusionAccelAxi64TopVerilog'
git diff --check
```

Expected: focused suites pass with zero failures, top elaboration succeeds,
and diff check emits nothing.

- [ ] **Step 2: Record evidence and commit**

Set the design status to `Implemented and simulation-validated`; record actual
test/suite counts, four input/result checks, burst histories, backpressure,
and elaboration outcome.  Mark completed plan steps only after their commands
succeed.

```powershell
git add accelerator/docs/plans/2026-08-12-sd15-resnetblock-four-vector-verification-design.md accelerator/docs/plans/2026-08-12-sd15-resnetblock-four-vector-verification-implementation.md
git commit -m "docs: record four-vector verification evidence"
```

## Plan self-review

- All four inputs, statistics, command sizes, addresses, output streams,
  protocol checks, and finite waits have explicit test requirements.
- Scope is restricted to a test and evidence documents; no board-flow work.
- Activation handshake behavior matches the validated three-vector observation
  rule, but the captured output limit is four.
