# AXI64 memory-backend implementation plan

**Goal:** Add a selectable AXI64 backend to the diffusion top while retaining the current MIG application-port backend as the default.

**Architecture:** The existing request arbiter remains the sole memory client mux.  Construction selects `MigAppTransfer` or `MigAppToAxi64Bridge` immediately after that arbiter.  Both physical seams remain named in top-level IO; the unselected one is held inactive.

**Tech stack:** Scala, Chisel 3, chiseltest, ScalaTest, SBT 1.12.15, JDK 17.

## Constraints

- Do not edit the official demo, XCI, generated IP, or XDC.
- `new DiffusionAccelTop()` remains MIG-compatible.
- AXI64 backend accepts/returns the existing `MigAppRequest`, 512-bit response, and done semantics.
- AXI64 traffic must use the already tested `MigAppToAxi64Bridge`; no second converter is introduced.

### Task 1: Add top-level AXI64 integration tests

**Files:**

- Create: `src/test/scala/diffusion/DiffusionAccelTopAxi64Spec.scala`

- [ ] **Step 1: Write failing AXI64-backend request tests.**

```scala
"DiffusionAccelTop" should "route a read through the AXI64 backend while MIG remains inactive" in {
  test(new DiffusionAccelTop(memoryBackend = DiffusionMemoryBackend.Axi64)) { dut =>
    idle(dut); submitRead(dut, 0x300)
    dut.io.mig.en.expect(false.B)
    dut.io.axi64.ar.valid.expect(true.B)
    dut.io.axi64.ar.bits.addr.expect("h300".U)
    dut.io.axi64.ar.bits.len.expect(7.U)
    acceptArAndEightReadBeats(dut, expected512)
    dut.io.memoryResponse.valid.expect(true.B)
    dut.io.memoryResponse.bits.expect(expected512.U)
  }
}
```

- [ ] **Step 2: Verify RED.**

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false'
sbt 'testOnly FLOOD_Accelerator.diffusion.DiffusionAccelTopAxi64Spec'
```

Expected: compile failure because the backend enum, constructor parameter, and `axi64` IO do not exist.

- [ ] **Step 3: Add a default-MIG preservation test.**

```scala
it should "keep AXI64 inactive for the default MIG backend" in {
  test(new DiffusionAccelTop) { dut =>
    idle(dut); submitRead(dut, 0x180)
    dut.io.mig.en.expect(true.B)
    dut.io.axi64.aw.valid.expect(false.B)
    dut.io.axi64.w.valid.expect(false.B)
    dut.io.axi64.ar.valid.expect(false.B)
  }
}
```

### Task 2: Select the memory backend inside the top

**Files:**

- Modify: `src/main/scala/diffusion/DiffusionAccelTop.scala`
- Test: `src/test/scala/diffusion/DiffusionAccelTopAxi64Spec.scala`

- [ ] **Step 1: Define the backend type and constructor.**

```scala
sealed trait DiffusionMemoryBackend
object DiffusionMemoryBackend {
  case object MigApp extends DiffusionMemoryBackend
  case object Axi64 extends DiffusionMemoryBackend
}
class DiffusionAccelTop(
    resultDepth: Int = 128,
    memoryBackend: DiffusionMemoryBackend = DiffusionMemoryBackend.MigApp
) extends Module
```

- [ ] **Step 2: Add `axi64: new Axi4Master64` to top IO.** Tie every unselected seam to safe defaults; do not change names or directions of `io.mig`.

- [ ] **Step 3: Route arbiter traffic by elaboration-time backend selection.**

```scala
if (memoryBackend == DiffusionMemoryBackend.MigApp) {
  val transfer = Module(new MigAppTransfer)
  transfer.io.request <> memoryArbiter.io.memoryRequest
  memoryArbiter.io.memoryResponse <> transfer.io.response
  memoryArbiter.io.memoryDone := transfer.io.done
  // Preserve existing io.mig assignments; tie io.axi64 master outputs inactive.
} else {
  val bridge = Module(new MigAppToAxi64Bridge)
  bridge.io.request <> memoryArbiter.io.memoryRequest
  memoryArbiter.io.memoryResponse <> bridge.io.response
  memoryArbiter.io.memoryDone := bridge.io.done
  io.axi64 <> bridge.io.axi
  // Tie io.mig command outputs inactive and ignore its return inputs.
}
```

- [ ] **Step 4: Select backend-specific memory backpressure for `PerfMonitor`.** MIG observes command/write-data ready; AXI64 observes asserted AW/W/AR with ready low plus B/R waiting.

- [ ] **Step 5: Verify GREEN.** Run Task 1 test, then:

```powershell
sbt 'testOnly FLOOD_Accelerator.diffusion.DiffusionAccelTopMemorySpec FLOOD_Accelerator.diffusion.DiffusionAccelTopAxi64Spec FLOOD_Accelerator.diffusion.MigAppToAxi64BridgeSpec'
```

Expected: all tests pass.

- [ ] **Step 6: Commit.**

```powershell
git add src/main/scala/diffusion/DiffusionAccelTop.scala src/test/scala/diffusion/DiffusionAccelTopAxi64Spec.scala
git commit -m "feat: select AXI64 memory backend"
```

### Task 3: Add and verify the AXI64 RTL generator

**Files:**

- Create: `src/main/scala/diffusion/GenerateDiffusionAccelAxi64TopVerilog.scala`
- Modify: `docs/AXI64_MEMORY_BACKEND_DESIGN.md`
- Modify: `fpga/AXKU15/diffusion/docs/OFFICIAL_DDR4_DEMO_ASSESSMENT.md`

- [ ] **Step 1: Add a generator.**

```scala
object GenerateDiffusionAccelAxi64TopVerilog extends App {
  (new ChiselStage).emitVerilog(
    new DiffusionAccelTop(memoryBackend = DiffusionMemoryBackend.Axi64),
    Array("--target-dir", "target/generated/diffusion-accel-axi64-top")
  )
}
```

- [ ] **Step 2: Run generators and inspect the AXI64 port names.**

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false'
sbt 'runMain FLOOD_Accelerator.diffusion.GenerateDiffusionAccelTopVerilog'
sbt 'runMain FLOOD_Accelerator.diffusion.GenerateDiffusionAccelAxi64TopVerilog'
Select-String -Path target/generated/diffusion-accel-axi64-top/DiffusionAccelTop.v -Pattern 'axi64_aw|axi64_w|axi64_b|axi64_ar|axi64_r'
```

Expected: both generators exit 0 and all five AXI64 channel name groups occur.

- [ ] **Step 3: Record verified facts only.** State that AXI64 top RTL is generated and simulated, while official vendor integration and board calibration remain pending.

- [ ] **Step 4: Commit.**

```powershell
git add src/main/scala/diffusion/GenerateDiffusionAccelAxi64TopVerilog.scala docs/AXI64_MEMORY_BACKEND_DESIGN.md fpga/AXKU15/diffusion/docs/OFFICIAL_DDR4_DEMO_ASSESSMENT.md
git commit -m "build: generate AXI64 diffusion top"
```

## Plan self-review

- The first test fails before top changes, then validates both selected and default paths.
- The selected backend reuses the tested request-level bridge and leaves vendor artifacts untouched.
- Final verification checks simulation plus exact generated AXI64 port evidence; no step claims a board-level result.
