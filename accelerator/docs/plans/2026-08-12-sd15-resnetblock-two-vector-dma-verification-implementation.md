# SD1.5 ResNetBlock Two-Vector AXI64 DMA Verification Implementation Plan

**Goal:** Add a directed AXI64 Chisel simulation that verifies two ordered
512-bit vectors traverse the existing ResNetBlock flow from two-beat DMA read
to two-beat writeback under independent channel backpressure.

**Architecture:** Production RTL remains unchanged. The test-side AXI64 memory
model gains accepted full-burst address history; a second test in the existing
ResNetBlock E2E suite drives public Decoupled controls with `vectors = 2`,
records output handshakes in order, and compares both stored words with the
integer reference.

**Tech Stack:** Scala 2.12.13, Chisel 3.5.3, chiseltest 0.5.3, ScalaTest,
SBT 1.12.15.

## Global constraints

- DUT: `new DiffusionAccelTop(memoryBackend = DiffusionMemoryBackend.Axi64)`.
- Do not change production RTL, AXKU15 demo/IP, Vivado Tcl, implementation,
  bitstream, or FPGA flows.
- Each 512-bit bridge request remains exactly eight ordered AXI4 64-bit beats
  with `len == 7` and `size == 3`.
- The two input words are at `0x400` and `0x440`; output words are at `0x800`
  and `0x840`.
- Input zero is 16 lanes `-1` then 16 lanes `+1`; input one reverses that
  order. Aggregate GroupNorm statistics are `(sum = 0, sumSquare = 64,
  count = 64)`.
- Diagonal Conv1/Conv2 weights equal one; all shifts are zero; GN2 affine is
  gamma 256/beta zero; `temb = +3`, `residual = -2`, and residual addition is
  enabled.
- Every wait has an explicit finite bound. Output data is recorded only on a
  Decoupled `fire`.

---

### Task 1: Record accepted AXI64 burst addresses

**Files:**
- Modify: `accelerator/src/test/scala/diffusion/ResNetBlockE2ETestSupport.scala`
- Modify: `accelerator/src/test/scala/diffusion/Axi64MemoryModelSpec.scala`

**Interfaces:**
- Consumes: existing `Axi64MemoryModel` channel driving and protocol checks.
- Produces: `readBurstAddresses: Vector[BigInt]` and
  `writeBurstAddresses: Vector[BigInt]`, each recording the accepted AR/AW
  base address exactly once.

- [ ] **Step 1: Write the failing address-history test**

Add one `Axi64MemoryModelSpec` test that completes two reads at `0x400`,
`0x440` and two writes at `0x800`, `0x840`, then asserts:

```scala
memory.readBurstAddresses shouldBe Vector(BigInt(0x400), BigInt(0x440))
memory.writeBurstAddresses shouldBe Vector(BigInt(0x800), BigInt(0x840))
```

Drive the current DMA/helper protocol. Each transfer waits for its `done` with
a bounded loop; no fixed-cycle completion assumption is allowed.

- [ ] **Step 2: Verify RED**

Run:

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false -Xms512m -Xmx4G'
sbt 'testOnly FLOOD_Accelerator.diffusion.Axi64MemoryModelSpec'
```

Expected: compilation failure because the address-history accessors are absent.

- [ ] **Step 3: Add minimal test-side address history**

Add to `Axi64MemoryModel`:

```scala
private val readAddressHistory = scala.collection.mutable.ArrayBuffer.empty[BigInt]
private val writeAddressHistory = scala.collection.mutable.ArrayBuffer.empty[BigInt]
def readBurstAddresses: Vector[BigInt] = readAddressHistory.toVector
def writeBurstAddresses: Vector[BigInt] = writeAddressHistory.toVector
```

At the existing AR fire branch append `axi.ar.bits.addr.peek().litValue`; at
the existing AW fire branch append `axi.aw.bits.addr.peek().litValue`. Do not
append for valid-only, W, B, R, or any retry cycle.

- [ ] **Step 4: Verify GREEN**

Run the Step 2 command.

Expected: all `Axi64MemoryModelSpec` cases pass and address history contains
exactly the four accepted base addresses in direction-local order.

- [ ] **Step 5: Commit**

```powershell
git add accelerator/src/test/scala/diffusion/ResNetBlockE2ETestSupport.scala accelerator/src/test/scala/diffusion/Axi64MemoryModelSpec.scala
git commit -m "test: record AXI64 burst address history"
```

### Task 2: Add the two-vector, two-beat ResNetBlock E2E test

**Files:**
- Modify: `accelerator/src/test/scala/diffusion/DiffusionAccelTopResNetBlockE2ESpec.scala`
- Uses: `accelerator/src/test/scala/diffusion/ResNetBlockE2ETestSupport.scala`

**Interfaces:**
- Consumes: `load512`, `read512`, `readBurstAddresses`,
  `writeBurstAddresses`, `assertNoProtocolError`, and
  `ResNetBlockE2EReference.finalLanes`.
- Produces: one two-vector E2E case covering ordered DMA read, GN1, Conv1,
  GN2, activation, Conv2/residual, internal store, and ordered DMA writeback.

- [ ] **Step 1: Write the failing test shell**

Add this named test:

```scala
it should "preserve two DMA vectors and write both fixed-point results in order" in
```

Seed inputs and expected values:

```scala
val input0 = Vector.fill(16)(-1) ++ Vector.fill(16)(1)
val input1 = Vector.fill(16)(1) ++ Vector.fill(16)(-1)
val inputs = Vector(input0, input1)
val temb = Vector.fill(32)(3)
val residual = Vector.fill(32)(-2)
val expected = inputs.map(ResNetBlockE2EReference.finalLanes(_, temb, residual))
memory.load512(0x400, ResNetBlockE2EReference.packLanes(input0))
memory.load512(0x440, ResNetBlockE2EReference.packLanes(input1))
```

Issue read and write commands with addresses `0x400`, `0x800` and `beats = 2`.

- [ ] **Step 2: Verify RED**

Run:

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false -Xms512m -Xmx4G'
sbt 'testOnly FLOOD_Accelerator.diffusion.DiffusionAccelTopResNetBlockE2ESpec -- -z "preserve two DMA vectors"'
```

Expected: FAIL because all two-vector phase commands and handshake handling
are not present yet.

- [ ] **Step 3: Implement the bounded two-vector driver**

Use the suite's existing one-cycle memory tick discipline. Define:

```scala
val commandLimit = 128
val phaseLimit = 256
val dmaLimit = 1024
val computeLimit = 1024
val conv1Outputs = scala.collection.mutable.ArrayBuffer.empty[Vector[Int]]
val activationOutputs = scala.collection.mutable.ArrayBuffer.empty[Vector[Int]]
val conv2Outputs = scala.collection.mutable.ArrayBuffer.empty[Vector[Int]]
```

Drive the current scheduler phases in this exact order:

1. Start AXI-Lite control and submit `tensorReadCommand(0x400, 2)`.
2. In GN1, submit `gn1StatsCommand(vectors = 2)`, consume one statistics
   handshake, and require `(0, 64, 64)`.
3. Write 32 diagonal Conv1 weights, submit `gn1ConvCommand(vectors = 2)`,
   and collect exactly two fired Conv1 results. Require `conv1Outputs ==
   inputs`.
4. In GN2 stats, submit `gn2StatsCommand(vectors = 2)`, consume one
   handshake, and require `(0, 64, 64)`.
5. Write 32 GN2 affine entries; write 32 diagonal Conv2 weights; drive all
   `temb` and residual lanes; submit both `gn2ActivationCommand(vectors = 2)`
   and `gn2ConvCommand(vectors = 2)` during the existing combined phase.
   Collect two fired activation and Conv2 outputs. Require activation outputs
   equal the reference variance-one SiLU vectors and Conv2 outputs equal
   `expected`, each in input order.
6. In StoreOutput, submit `tensorWriteCommand(0x800, 2)` and wait for one
   `done` pulse.

After completion require:

```scala
memory.read512(0x800) shouldBe ResNetBlockE2EReference.packLanes(expected(0))
memory.read512(0x840) shouldBe ResNetBlockE2EReference.packLanes(expected(1))
memory.readBurstAddresses shouldBe Vector(BigInt(0x400), BigInt(0x440))
memory.writeBurstAddresses shouldBe Vector(BigInt(0x800), BigInt(0x840))
memory.delayedChannels shouldBe Set("AW", "W", "B", "AR", "R")
memory.assertNoProtocolError()
```

No file under `accelerator/src/main` may change.

- [ ] **Step 4: Verify GREEN**

Run the Step 2 command.

Expected: the selected test passes under staggered AW/W/B/AR/R delays, with
both 512-bit result words and all four full-burst addresses exact.

- [ ] **Step 5: Commit**

```powershell
git add accelerator/src/test/scala/diffusion/DiffusionAccelTopResNetBlockE2ESpec.scala
git commit -m "test: verify two-vector ResNetBlock DMA flow"
```

### Task 3: Run focused regression and record evidence

**Files:**
- Modify: `accelerator/docs/plans/2026-08-12-sd15-resnetblock-two-vector-dma-verification-design.md`

**Interfaces:**
- Consumes: passing address-history and two-vector E2E cases.
- Produces: reproducible simulation evidence while retaining FPGA exclusions.

- [ ] **Step 1: Run focused regression**

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false -Xms512m -Xmx4G'
sbt 'testOnly FLOOD_Accelerator.diffusion.DiffusionAccelTopResNetBlockE2ESpec FLOOD_Accelerator.diffusion.Axi64MemoryModelSpec FLOOD_Accelerator.diffusion.DiffusionAccelTopAxi64Spec FLOOD_Accelerator.diffusion.MigAppToAxi64BridgeSpec FLOOD_Accelerator.diffusion.ConvToGroupNormStatsPathSpec FLOOD_Accelerator.diffusion.Conv2ResidualPathSpec FLOOD_Accelerator.diffusion.GroupNormActivationPathSpec'
```

Expected: every selected suite passes with zero failures.

- [ ] **Step 2: Regenerate unchanged AXI64 top**

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false -Xms512m -Xmx4G'
sbt 'runMain FLOOD_Accelerator.diffusion.GenerateDiffusionAccelAxi64TopVerilog'
git status --short
```

Expected: elaboration succeeds. Do not stage generated outputs or Vivado
journal files.

- [ ] **Step 3: Update evidence wording**

Set the design status to `Implemented and simulation-validated`. Record the
exact Step 1 command and passing count. State that ordered read addresses
`0x400`, `0x440`, ordered write addresses `0x800`, `0x840`, both expected
512-bit words, and every staggered AXI64 channel were verified. Preserve all
existing exclusions.

- [ ] **Step 4: Final verification**

```powershell
git diff --check
git status --short
```

Expected: no whitespace errors; only intended test/evidence files are
candidates for staging, apart from pre-existing untracked Vivado journals.

- [ ] **Step 5: Commit and push**

```powershell
git add accelerator/docs/plans/2026-08-12-sd15-resnetblock-two-vector-dma-verification-design.md
git commit -m "test: validate two-vector ResNetBlock DMA flow"
git push origin sd15-resnetblock
```

## Plan self-review

- Coverage: Task 1 verifies accepted bridge transaction addresses; Task 2
  proves ordered dual-vector DMA and compute behavior under independent
  backpressure; Task 3 supplies regression and elaboration evidence.
- Scope: no production RTL, Vivado, bitstream, or FPGA operation is included.
- Consistency: all tasks use `Vector[BigInt]` address history and the existing
  `BigInt` lane-packed reference words; all command vector counts are two.
- No incomplete requirements, ambiguous addresses, or open placeholders are
  present.
