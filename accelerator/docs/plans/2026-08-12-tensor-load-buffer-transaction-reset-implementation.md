# Tensor Load Buffer Transaction Reset Implementation Plan

**Goal:** Reset tensor tile-buffer logical state at every new DMA load so
consecutive ResNetBlock transactions start with zero occupancy and no stale
valid entries.

**Architecture:** Add a synchronous `clear` control to `TensorTileBuffer`.
Clear resets valid bits, occupancy, high-water, and any pending read state
without erasing RAM. `TensorLoadBuffer.start` drives this control; its existing
one-cycle startup gap prevents a clear/write collision. Complete the existing
consecutive AXI64 E2E RED test after the buffer semantics are verified.

**Tech Stack:** Scala 2.12.13, Chisel 3.5.3, chiseltest 0.5.3, ScalaTest,
SBT 1.12.15.

## Global constraints

- Production change scope is only `TensorTileBuffer` and its direct
  `TensorLoadBuffer` connection.
- `clear` resets logical visibility/capacity, not physical `SyncReadMem`
  contents.
- During `clear`, tile-buffer write and read-request readiness are false and
  no read response is valid.
- Existing AXI64 protocol, arithmetic, scheduler phase sequence, vendor IP,
  Vivado, bitstream, and FPGA flows must remain unchanged.
- Existing untracked Vivado journal files must never be staged.

---

### Task 1: Add and verify tile-buffer logical clear

**Files:**
- Modify: `accelerator/src/main/scala/diffusion/TensorTileBuffer.scala`
- Modify: `accelerator/src/test/scala/diffusion/TensorTileBufferSpec.scala`

**Interfaces:**
- Consumes: `TensorTileBuffer(depth, dataWidth)` existing Decoupled write/read
  ports.
- Produces: `io.clear: Input(Bool())`; when true, zero `occupancy`,
  `highWater`, `validBits`, and `readPending`; deassert write/read readiness
  and read response validity.

- [ ] **Step 1: Write failing clear test**

Extend the existing tile-buffer test or add a second test. Write addresses 3
and 5, require occupancy/high-water two, then pulse `clear` while presenting a
write and read request:

```scala
dut.io.clear.poke(true.B)
dut.io.write.valid.poke(true.B)
dut.io.readReq.valid.poke(true.B)
dut.io.write.ready.expect(false.B)
dut.io.readReq.ready.expect(false.B)
dut.io.readResp.valid.expect(false.B)
dut.clock.step()
dut.io.clear.poke(false.B)
dut.io.write.valid.poke(false.B)
dut.io.readReq.valid.poke(false.B)
dut.io.occupancy.expect(0.U)
dut.io.highWater.expect(0.U)
```

Then write address 3 once and require occupancy/high-water both one, proving
the old valid bit was cleared.

- [ ] **Step 2: Verify RED**

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false -Xms512m -Xmx4G'
sbt 'testOnly FLOOD_Accelerator.diffusion.TensorTileBufferSpec'
```

Expected: compilation fails because `io.clear` is absent.

- [ ] **Step 3: Implement minimal synchronous clear**

Add `val clear = Input(Bool())` to the IO bundle. Gate interfaces:

```scala
io.write.ready := !io.clear
io.readReq.ready := !io.clear && !readPending && !io.write.valid
io.readResp.valid := !io.clear && readPending
```

Make clear priority over writes and read-state updates:

```scala
when(io.clear) {
  validBits.foreach(_ := false.B)
  occupancy := 0.U
  highWater := 0.U
  readPending := false.B
}.otherwise {
  // retain existing write-valid accounting and read pending transitions
}
```

Keep `memory` unmodified; do not issue `memory.read` while `clear` is high.

- [ ] **Step 4: Verify GREEN**

Run the Step 2 command.

Expected: tile-buffer tests pass; the new case proves no handshake during
clear, zero logical state after clear, and fresh occupancy after rewrite.

- [ ] **Step 5: Commit**

```powershell
git add accelerator/src/main/scala/diffusion/TensorTileBuffer.scala accelerator/src/test/scala/diffusion/TensorTileBufferSpec.scala
git commit -m "fix: reset tensor tile buffer per transaction"
```

### Task 2: Connect load start and verify second-load boundary

**Files:**
- Modify: `accelerator/src/main/scala/diffusion/TensorLoadBuffer.scala`
- Modify: `accelerator/src/test/scala/diffusion/TensorLoadBufferSpec.scala`

**Interfaces:**
- Consumes: `TensorLoadBuffer.io.start` and `TensorTileBuffer.io.clear`.
- Produces: a new load start that clears tile-buffer logical occupancy before
  the next DMA beat can fire.

- [ ] **Step 1: Write failing second-load test**

After the existing one-beat load completes and occupancy is 32, pulse a second
`start` with no input data. Require occupancy zero immediately after the start
clock edge and `input.ready` false in the start/clear cycle. On the next cycle,
require `input.ready` true, send one new 512-bit beat, and require final
occupancy 32 (not 64). Read lane zero and require its new-word value.

- [ ] **Step 2: Verify RED**

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false -Xms512m -Xmx4G'
sbt 'testOnly FLOOD_Accelerator.diffusion.TensorLoadBufferSpec'
```

Expected: the second-load test fails because `TensorLoadBuffer` does not yet
drive tile-buffer clear.

- [ ] **Step 3: Wire the transaction boundary**

In `TensorLoadBuffer`, connect exactly:

```scala
loadBuffer.io.clear := io.start
```

Do not alter load FSM states, DMA Decoupled behavior, lane address sequence,
or read routing.

- [ ] **Step 4: Verify GREEN**

Run the Step 2 command.

Expected: load-buffer tests pass and second-load occupancy is reset before new
data is accepted.

- [ ] **Step 5: Commit**

```powershell
git add accelerator/src/main/scala/diffusion/TensorLoadBuffer.scala accelerator/src/test/scala/diffusion/TensorLoadBufferSpec.scala
git commit -m "fix: clear tensor load state on DMA start"
```

### Task 3: Complete consecutive AXI64 ResNetBlock E2E verification

**Files:**
- Modify: `accelerator/src/test/scala/diffusion/DiffusionAccelTopResNetBlockE2ESpec.scala`

**Interfaces:**
- Consumes: the existing uncommitted RED case, `finalLanesWithRsqrt`, AXI64
  memory address history, and resettable `tensorBufferOccupancy`.
- Produces: a passing case named `complete two distinct transactions without
  stale tensor or DMA state`.

- [ ] **Step 1: Retain the existing RED failure**

The current skeleton must fail before the helper is added because transaction
B has no writeback. Keep B at `0x1000/0x1040`, B writeback at
`0x1800/0x1840`, and its reference `rsqrtQ30 = 480191942`.

- [ ] **Step 2: Implement bounded parameterized test driver**

Add test-local `DirectedTransaction` with read/write addresses, two input
vectors, temb, residual, rsqrt, and expected aggregate statistics. Implement
`runTransaction` with existing public controls: AXI-Lite start, two-beat read,
two-vector GN1/Conv1/GN2/activation/Conv2, two-beat write, and one done pulse.
Each output collection must contain exactly two values in order; each command,
phase, DMA, and compute wait must keep the existing 128/256/1024 bounds.

Run A at `0x400 -> 0x800` with statistics `(0,64,64)`. Between runs require:

```scala
dut.io.busy.expect(false.B)
dut.io.phase.expect(BlockPhase.Idle.U)
dut.io.tensorBufferOccupancy.expect(0.U)
```

Snapshot A output words. Then run B at `0x1000 -> 0x1800` with statistics
`(0,256,64)`, B temb `+5`, B residual `-3`, and rsqrt `480191942`. Require A
snapshots unchanged, B expected words exact, exactly two total done pulses,
and the ordered four-entry read/write histories required by the design.

- [ ] **Step 3: Verify GREEN**

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false -Xms512m -Xmx4G'
sbt 'testOnly FLOOD_Accelerator.diffusion.DiffusionAccelTopResNetBlockE2ESpec'
```

Expected: all one-vector, two-vector, and consecutive-transaction E2E tests
pass under staggered AXI64 timing.

- [ ] **Step 4: Commit**

```powershell
git add accelerator/src/test/scala/diffusion/DiffusionAccelTopResNetBlockE2ESpec.scala
git commit -m "test: verify consecutive ResNetBlock transactions"
```

### Task 4: Regress and record reset evidence

**Files:**
- Modify: `accelerator/docs/plans/2026-08-12-tensor-load-buffer-transaction-reset-design.md`
- Modify: `accelerator/docs/plans/2026-08-12-sd15-resnetblock-consecutive-transaction-verification-design.md`

**Interfaces:**
- Consumes: passing buffer and E2E tests.
- Produces: exact simulation evidence for the RTL reset and consecutive flow.

- [ ] **Step 1: Run focused regression**

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false -Xms512m -Xmx4G'
sbt 'testOnly FLOOD_Accelerator.diffusion.TensorTileBufferSpec FLOOD_Accelerator.diffusion.TensorLoadBufferSpec FLOOD_Accelerator.diffusion.ResNetBlockE2ETestSupportSpec FLOOD_Accelerator.diffusion.DiffusionAccelTopResNetBlockE2ESpec FLOOD_Accelerator.diffusion.Axi64MemoryModelSpec FLOOD_Accelerator.diffusion.DiffusionAccelTopAxi64Spec FLOOD_Accelerator.diffusion.MigAppToAxi64BridgeSpec FLOOD_Accelerator.diffusion.ConvToGroupNormStatsPathSpec FLOOD_Accelerator.diffusion.Conv2ResidualPathSpec FLOOD_Accelerator.diffusion.GroupNormActivationPathSpec FLOOD_Accelerator.diffusion.RsqrtUnitReferenceSpec'
```

Expected: every selected test passes with zero failures.

- [ ] **Step 2: Elaborate AXI64 top**

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false -Xms512m -Xmx4G'
sbt 'runMain FLOOD_Accelerator.diffusion.GenerateDiffusionAccelAxi64TopVerilog'
git status --short
```

Expected: Chisel elaboration succeeds without staging generated artifacts.

- [ ] **Step 3: Record evidence and commit**

Set both design statuses to `Implemented and simulation-validated`. Record the
exact regression command/count, clear behavior, B's statistics and addresses,
idle/zero-occupancy boundary, A writeback preservation, and elaboration
result. Retain exclusions verbatim.

```powershell
git diff --check
git add accelerator/docs/plans/2026-08-12-tensor-load-buffer-transaction-reset-design.md accelerator/docs/plans/2026-08-12-sd15-resnetblock-consecutive-transaction-verification-design.md
git commit -m "test: validate resettable consecutive transactions"
git push origin sd15-resnetblock
```

## Plan self-review

- Coverage: Task 1 resets all stale tile-buffer logical state; Task 2 proves
  `start` enforces that boundary; Task 3 proves it at top-level across two
  distinct AXI64 transactions; Task 4 records regression evidence.
- Scope: only the tile/load buffer production modules change; all other work
  is tests/docs. No Vivado, bitstream, or FPGA operation is included.
- Safety: RAM is not erased, while valid bits and counters reset before data
  acceptance; this preserves physical memory efficiency and removes stale
  logical state.
