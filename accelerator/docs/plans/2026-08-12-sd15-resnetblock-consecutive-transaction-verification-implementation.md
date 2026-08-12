# SD1.5 ResNetBlock Consecutive Transaction Verification Implementation Plan

**Goal:** Add a test-only AXI64 Chisel simulation that proves two different
two-vector ResNetBlock transactions complete consecutively without state
carry-over.

**Architecture:** Keep `DiffusionAccelTop` and all production RTL unchanged.
Generalize the integer test reference from the current variance-one-only
directed input to a supplied `rsqrtQ30` value, then add one consecutive-run
case to the existing E2E suite. The case executes transaction A, requires
idle/empty state, then independently executes transaction B and checks the
complete four-read/four-write AXI64 history.

**Tech Stack:** Scala 2.12.13, Chisel 3.5.3, chiseltest 0.5.3, ScalaTest,
SBT 1.12.15.

## Global constraints

- DUT: `new DiffusionAccelTop(memoryBackend = DiffusionMemoryBackend.Axi64)`.
- Do not modify any file under `accelerator/src/main`, AXKU15 demo/IP, Vivado
  Tcl, implementation flow, bitstream flow, or FPGA.
- Transaction A is the existing two-vector input at `0x400`, `0x440`, with
  outputs at `0x800`, `0x840`; transaction B uses `0x1000`, `0x1040`, with
  outputs at `0x1800`, `0x1840`.
- A inputs are ±1 with aggregate statistics `(0, 64, 64)` and
  `rsqrtQ30 = 759250125`; B inputs are ±2 with aggregate statistics
  `(0, 256, 64)` and `rsqrtQ30 = 480191942`, the existing
  `RsqrtUnitReferenceSpec` hardware value for variance four.
- Both transactions use diagonal Conv1/Conv2 weights equal to one, zero shifts,
  GN2 gamma 256/beta zero, and staggered AXI64 delays.
- Every command/output wait is bounded; test code records outputs only when
  their Decoupled channel fires.

---

### Task 1: Generalize the test-side fixed-point reference for variance four

**Files:**
- Modify: `accelerator/src/test/scala/diffusion/ResNetBlockE2ETestSupport.scala`
- Modify: `accelerator/src/test/scala/diffusion/ResNetBlockE2ETestSupportSpec.scala`

**Interfaces:**
- Consumes: `roundAwayFromZero`, `saturateInt16`, `silu16`, and existing
  `finalLanes(input, temb, residual)`.
- Produces: `finalLanesWithRsqrt(input: Vector[Int], temb: Vector[Int],
  residual: Vector[Int], rsqrtQ30: BigInt): Vector[Int]`; retains
  `finalLanes` as the variance-one compatibility wrapper.

- [ ] **Step 1: Write failing variance-four reference test**

Add this test to `ResNetBlockE2ETestSupportSpec`:

```scala
it should "derive a symmetric variance-four directed result" in {
  val input = Vector.fill(16)(-2) ++ Vector.fill(16)(2)
  val temb = Vector.fill(32)(5)
  val residual = Vector.fill(32)(-3)
  ResNetBlockE2EReference.stats(input) shouldBe GroupStatsReference(0, 128, 32)
  ResNetBlockE2EReference.finalLanesWithRsqrt(
    input, temb, residual, BigInt(480191942)
  ).size shouldBe 32
}
```

- [ ] **Step 2: Verify RED**

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false -Xms512m -Xmx4G'
sbt 'testOnly FLOOD_Accelerator.diffusion.ResNetBlockE2ETestSupportSpec'
```

Expected: compilation fails because `finalLanesWithRsqrt` is absent.

- [ ] **Step 3: Add minimal reference generalization**

Implement the new method with exact existing lane arithmetic, replacing only
the hard-coded `rsqrtVarianceOne` multiplier by its `rsqrtQ30` argument:

```scala
def finalLanesWithRsqrt(input: Vector[Int], temb: Vector[Int], residual: Vector[Int], rsqrtQ30: BigInt): Vector[Int] = {
  require(input.length == 32 && temb.length == 32 && residual.length == 32)
  input.zipWithIndex.map { case (lane, index) =>
    val normalized = roundAwayFromZero(BigInt(lane) * rsqrtQ30, 30)
    val affine = roundAwayFromZero(normalized * 256, 8)
    saturateInt16(BigInt(silu16(saturateInt16(affine))) + temb(index) + residual(index))
  }
}
def finalLanes(input: Vector[Int], temb: Vector[Int], residual: Vector[Int]): Vector[Int] =
  finalLanesWithRsqrt(input, temb, residual, rsqrtVarianceOne)
```

Do not add a mathematical rsqrt approximation: `480191942` is locked to the
existing `RsqrtUnit` reference behavior.

- [ ] **Step 4: Verify GREEN**

Run the Step 2 command.

Expected: all reference support tests pass, including variance one wrappers
and the new variance-four directed contract.

- [ ] **Step 5: Commit**

```powershell
git add accelerator/src/test/scala/diffusion/ResNetBlockE2ETestSupport.scala accelerator/src/test/scala/diffusion/ResNetBlockE2ETestSupportSpec.scala
git commit -m "test: support variance-four ResNetBlock reference"
```

### Task 2: Add consecutive two-transaction AXI64 ResNetBlock E2E coverage

**Files:**
- Modify: `accelerator/src/test/scala/diffusion/DiffusionAccelTopResNetBlockE2ESpec.scala`
- Uses: `accelerator/src/test/scala/diffusion/ResNetBlockE2ETestSupport.scala`

**Interfaces:**
- Consumes: the existing E2E memory tick/AXI-Lite control style,
  `finalLanesWithRsqrt`, `readBurstAddresses`, `writeBurstAddresses`,
  `read512`, and `assertNoProtocolError`.
- Produces: one test named `complete two distinct transactions without stale
  tensor or DMA state`.

- [ ] **Step 1: Write the failing consecutive E2E shell**

Add the named test with the four input words and two separate references:

```scala
val a0 = Vector.fill(16)(-1) ++ Vector.fill(16)(1)
val a1 = Vector.fill(16)(1) ++ Vector.fill(16)(-1)
val b0 = Vector.fill(16)(-2) ++ Vector.fill(16)(2)
val b1 = Vector.fill(16)(2) ++ Vector.fill(16)(-2)
val aExpected = Vector(a0, a1).map(ResNetBlockE2EReference.finalLanes(_, Vector.fill(32)(3), Vector.fill(32)(-2)))
val bExpected = Vector(b0, b1).map(ResNetBlockE2EReference.finalLanesWithRsqrt(_, Vector.fill(32)(5), Vector.fill(32)(-3), BigInt(480191942)))
```

Seed `a0/a1` at `0x400/0x440` and `b0/b1` at `0x1000/0x1040`. Start A,
then add initial assertions expecting A and B output words/history; leave B
unissued so the test initially fails.

- [ ] **Step 2: Verify RED**

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false -Xms512m -Xmx4G'
sbt 'testOnly FLOOD_Accelerator.diffusion.DiffusionAccelTopResNetBlockE2ESpec'
```

Expected: the new case fails because transaction B has not yet been started or
written, while existing one- and two-vector cases remain passing.

- [ ] **Step 3: Implement a parameterized bounded transaction driver**

Extract test-local helpers accepting this immutable transaction description:

```scala
final case class DirectedTransaction(
  readAddress: BigInt, writeAddress: BigInt, inputs: Vector[Vector[Int]],
  temb: Vector[Int], residual: Vector[Int], rsqrtQ30: BigInt,
  stats: GroupStatsReference
)
```

`runTransaction` must: AXI-Lite start; issue a two-beat tensor read; drive
GN1 statistics/Conv1 and GN2 statistics/activation/Conv2 each with
`vectors = 2`; collect exactly two outputs for each stream in order; issue a
two-beat write; wait for exactly one `done`; and compare writeback with the
reference. It writes existing diagonal weights/affine entries for every run,
sets `gn2Temb`/`gn2Residual` from the supplied transaction, and uses the same
finite command (128), phase (256), DMA/compute (1024) limits as the current
two-vector test.

After A completes, require `busy == false`, phase `Idle`,
`tensorBufferOccupancy == 0`, and preserve A writeback snapshots. Then execute
B and require A snapshots unchanged. At the end require:

```scala
memory.readBurstAddresses shouldBe Vector(BigInt(0x400), BigInt(0x440), BigInt(0x1000), BigInt(0x1040))
memory.writeBurstAddresses shouldBe Vector(BigInt(0x800), BigInt(0x840), BigInt(0x1800), BigInt(0x1840))
memory.delayedChannels shouldBe Set("AW", "W", "B", "AR", "R")
memory.assertNoProtocolError()
```

Count `done` pulses in the test loop and require exactly two total. Do not
change `DiffusionAccelTop` or any production source.

- [ ] **Step 4: Verify GREEN**

Run the Step 2 command.

Expected: all E2E cases pass. The consecutive case proves separate A/B
statistics, output words, idle transition, empty tensor buffer, and four
ordered read/write burst bases under staggered AXI64 timing.

- [ ] **Step 5: Commit**

```powershell
git add accelerator/src/test/scala/diffusion/DiffusionAccelTopResNetBlockE2ESpec.scala
git commit -m "test: verify consecutive ResNetBlock transactions"
```

### Task 3: Run regression and record consecutive-transaction evidence

**Files:**
- Modify: `accelerator/docs/plans/2026-08-12-sd15-resnetblock-consecutive-transaction-verification-design.md`

**Interfaces:**
- Consumes: passing support and consecutive E2E test cases.
- Produces: reproducible simulation evidence with all FPGA exclusions retained.

- [ ] **Step 1: Run focused regression**

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false -Xms512m -Xmx4G'
sbt 'testOnly FLOOD_Accelerator.diffusion.ResNetBlockE2ETestSupportSpec FLOOD_Accelerator.diffusion.DiffusionAccelTopResNetBlockE2ESpec FLOOD_Accelerator.diffusion.Axi64MemoryModelSpec FLOOD_Accelerator.diffusion.DiffusionAccelTopAxi64Spec FLOOD_Accelerator.diffusion.MigAppToAxi64BridgeSpec FLOOD_Accelerator.diffusion.ConvToGroupNormStatsPathSpec FLOOD_Accelerator.diffusion.Conv2ResidualPathSpec FLOOD_Accelerator.diffusion.GroupNormActivationPathSpec FLOOD_Accelerator.diffusion.RsqrtUnitReferenceSpec'
```

Expected: every selected test passes with zero failures.

- [ ] **Step 2: Elaborate unchanged AXI64 top**

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false -Xms512m -Xmx4G'
sbt 'runMain FLOOD_Accelerator.diffusion.GenerateDiffusionAccelAxi64TopVerilog'
git status --short
```

Expected: elaboration succeeds and no generated artifact is staged.

- [ ] **Step 3: Record evidence**

Set the design status to `Implemented and simulation-validated`. Record the
exact Step 1 command/count, both transactions' statistics and read/write
address histories, preserved A writeback, idle/zero-occupancy boundary, and
successful elaboration. Retain exclusions verbatim.

- [ ] **Step 4: Final diff check and commit**

```powershell
git diff --check
git status --short
git add accelerator/docs/plans/2026-08-12-sd15-resnetblock-consecutive-transaction-verification-design.md
git commit -m "test: validate consecutive ResNetBlock transactions"
git push origin sd15-resnetblock
```

Expected: no whitespace errors; only intended support, E2E, and evidence files
are committed, excluding pre-existing untracked Vivado journals.

## Plan self-review

- Coverage: Task 1 locks the variance-four hardware reference; Task 2 proves
  no cross-transaction tensor, result, DMA, or scheduler state carry-over;
  Task 3 records regression and elaboration evidence.
- Scope: no task changes production RTL or begins Vivado, bitstream, or FPGA
  operations.
- Consistency: B's ±2 vectors have per-vector square sum 128, aggregate square
  sum 256, and use the existing variance-four Q2.30 rsqrt value 480191942.
