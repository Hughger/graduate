# 512-bit MIG application to AXI64 bridge implementation plan

**Goal:** Add a simulation-verified Chisel bridge that converts one 512-bit `MigAppRequest` at a time into eight ordered 64-bit AXI4 beats and reassembles one 512-bit read response.

**Architecture:** `MigAppToAxi64Bridge` owns a request from input handshake until a write response or a retained read response. A local AXI4 bundle gives the vendor-demo wrapper a stable seam, while preserving the accelerator's one-request ordering.

**Tech stack:** Scala, Chisel 3, chiseltest, ScalaTest, SBT 1.12.15, JDK 17.

## Global constraints

- Do not modify the vendor demo, `ddr4_core.xci`, generated IP RTL, or XDC files.
- Preserve `MigAppRequest`'s 29-bit byte address and 512-bit data conventions.
- Each request uses exactly eight 64-bit beats; AXI IDs are zero and no transaction overlaps another.
- AXI byte strobe is the inverse of the corresponding eight MIG write-mask bits.
- Non-OKAY AXI responses raise sticky `error` without a normal `done` or read response.
- DDR4 traffic remains gated by `c0_init_calib_complete` in a later board-wrapper milestone.

---

### Task 1: Define the AXI64 seam and split writes

**Files:**

- Create: `src/main/scala/diffusion/MigAppToAxi64Bridge.scala`
- Create: `src/test/scala/diffusion/MigAppToAxi64BridgeSpec.scala`

**Interfaces:**

- Consumes `MigAppRequest`.
- Produces `Axi4Master64` (AW/W/B/AR/R channels), `MigAppToAxi64Bridge.request`, `.response`, `.done`, `.error`, and `.axi`.

- [ ] **Step 1: Write the failing write-splitting test.**

```scala
it should "split a masked 512-bit write into eight ordered AXI beats" in {
  test(new MigAppToAxi64Bridge) { dut =>
    idle(dut); submitWrite(dut, 0x100, patterned512, BigInt("ff00000000000000", 16))
    dut.io.axi.aw.valid.expect(true.B)
    dut.io.axi.aw.bits.addr.expect("h100".U)
    dut.io.axi.aw.bits.len.expect(7.U)
    acceptWriteAddress(dut)
    for (beat <- 0 until 8) {
      dut.io.axi.w.valid.expect(true.B)
      dut.io.axi.w.bits.data.expect(word64(patterned512, beat).U)
      dut.io.axi.w.bits.strb.expect((if (beat == 7) 0 else 255).U)
      dut.io.axi.w.bits.last.expect((beat == 7).B)
      acceptWriteData(dut)
    }
  }
}
```

- [ ] **Step 2: Verify RED.**

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false'
sbt 'testOnly FLOOD_Accelerator.diffusion.MigAppToAxi64BridgeSpec -- -z "split a masked"'
```

Expected: compilation fails because `MigAppToAxi64Bridge` does not yet exist.

- [ ] **Step 3: Implement the minimum write path.**

```scala
class AxiWriteAddress extends Bundle { val addr = UInt(32.W); val id = UInt(4.W); val len = UInt(8.W); val size = UInt(3.W) }
class AxiWriteData extends Bundle { val data = UInt(64.W); val strb = UInt(8.W); val last = Bool() }
class AxiWriteResponse extends Bundle { val id = UInt(4.W); val resp = UInt(2.W) }
class AxiReadAddress extends Bundle { val addr = UInt(32.W); val id = UInt(4.W); val len = UInt(8.W); val size = UInt(3.W) }
class AxiReadData extends Bundle { val data = UInt(64.W); val id = UInt(4.W); val resp = UInt(2.W); val last = Bool() }
class Axi4Master64 extends Bundle {
  val aw = Decoupled(new AxiWriteAddress); val w = Decoupled(new AxiWriteData)
  val b = Flipped(Decoupled(new AxiWriteResponse)); val ar = Decoupled(new AxiReadAddress)
  val r = Flipped(Decoupled(new AxiReadData))
}
```

Latch `request` on `fire`. In write-address state, hold `aw.valid` until `aw.fire`. In write-data state, advance a three-bit beat counter only on `w.fire`; drive `data := requestReg.writeData(64*beat+63, 64*beat)`, `strb := ~requestReg.writeMask(8*beat+7, 8*beat)`, and `last := beat === 7.U`. Leave read states inactive in this task.

- [ ] **Step 4: Verify GREEN.** Run the Step 2 command and `sbt 'testOnly FLOOD_Accelerator.diffusion.MigAppTransferSpec'`; both must pass.

- [ ] **Step 5: Commit.**

```powershell
git add src/main/scala/diffusion/MigAppToAxi64Bridge.scala src/test/scala/diffusion/MigAppToAxi64BridgeSpec.scala
git commit -m "feat: split accelerator writes onto AXI64"
```

### Task 2: Add write completion, backpressure, and errors

**Files:**

- Modify: `src/main/scala/diffusion/MigAppToAxi64Bridge.scala`
- Modify: `src/test/scala/diffusion/MigAppToAxi64BridgeSpec.scala`

**Interfaces:** Produces a one-cycle `done` only after an OKAY B handshake and a sticky `error` after non-OKAY B.

- [ ] **Step 1: Write failing backpressure/error tests.**

```scala
it should "retain write channels through independent backpressure" in {
  test(new MigAppToAxi64Bridge) { dut =>
    idle(dut); submitWrite(dut, 0x180, patterned512, 0)
    dut.io.axi.aw.ready.poke(false.B); dut.clock.step(2); dut.io.axi.aw.valid.expect(true.B)
    acceptWriteAddress(dut); holdThenAcceptFirstWriteBeat(dut); acceptRemainingWriteBeats(dut)
    dut.io.axi.b.bits.resp.poke(0.U); dut.io.axi.b.valid.poke(true.B); dut.clock.step()
    dut.io.done.expect(true.B); dut.io.error.expect(false.B)
  }
}
it should "latch an AXI write error without reporting done" in {
  test(new MigAppToAxi64Bridge) { dut =>
    idle(dut); submitAndDrainWrite(dut)
    dut.io.axi.b.bits.resp.poke(2.U); dut.io.axi.b.valid.poke(true.B); dut.clock.step()
    dut.io.done.expect(false.B); dut.io.error.expect(true.B)
  }
}
```

- [ ] **Step 2: Verify RED.**

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false'
sbt 'testOnly FLOOD_Accelerator.diffusion.MigAppToAxi64BridgeSpec -- -z "independent backpressure"'
```

Expected: failure because B completion/error handling is absent.

- [ ] **Step 3: Implement B handling.** Drive `axi.b.ready` only in a write-response state. On `axi.b.fire`, pulse `done` if `resp === 0.U`; otherwise set `error := true.B`; return to idle in both cases. Reset clears all state and `error`.

- [ ] **Step 4: Verify GREEN.** Run the two focused test names and the whole bridge spec; all must pass.

- [ ] **Step 5: Commit.**

```powershell
git add src/main/scala/diffusion/MigAppToAxi64Bridge.scala src/test/scala/diffusion/MigAppToAxi64BridgeSpec.scala
git commit -m "feat: handle AXI64 write responses"
```

### Task 3: Add read splitting and response assembly

**Files:**

- Modify: `src/main/scala/diffusion/MigAppToAxi64Bridge.scala`
- Modify: `src/test/scala/diffusion/MigAppToAxi64BridgeSpec.scala`

**Interfaces:** Consumes `MigAppRequest(write = false)` and eight R handshakes. Produces one retained 512-bit response after eight OKAY beats.

- [ ] **Step 1: Write the failing read test.**

```scala
it should "assemble eight AXI read beats in little-endian beat order" in {
  test(new MigAppToAxi64Bridge) { dut =>
    idle(dut); submitRead(dut, 0x200); acceptReadAddress(dut)
    for (beat <- 0 until 8) { presentReadBeat(dut, BigInt(beat + 1), beat == 7) }
    dut.io.response.valid.expect(true.B)
    dut.io.response.bits.expect((0 until 8).map(i => BigInt(i + 1) << (64 * i)).sum.U)
  }
}
```

- [ ] **Step 2: Verify RED.**

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false'
sbt 'testOnly FLOOD_Accelerator.diffusion.MigAppToAxi64BridgeSpec -- -z "assemble eight"'
```

Expected: failure because AR/R states and response assembly are absent.

- [ ] **Step 3: Implement the read path.** Hold AR until `ar.fire`. Capture each accepted `r.bits.data` into `readDataReg(64*beat+63, 64*beat)`. Require `r.last` on beat seven. After eight OKAY beats, hold `response.valid` until `response.fire`. On non-OKAY R, set `error` and return idle without a valid response.

- [ ] **Step 4: Verify GREEN.** Run the full bridge spec plus `sbt 'testOnly FLOOD_Accelerator.diffusion.MigAppRequestArbiterSpec FLOOD_Accelerator.diffusion.MigAppTransferSpec'`; all must pass.

- [ ] **Step 5: Commit.**

```powershell
git add src/main/scala/diffusion/MigAppToAxi64Bridge.scala src/test/scala/diffusion/MigAppToAxi64BridgeSpec.scala
git commit -m "feat: assemble AXI64 reads for diffusion memory"
```

### Task 4: Generate RTL and update verified boundary documentation

**Files:**

- Modify: `docs/AXI512_TO_AXI64_BRIDGE_DESIGN.md`
- Modify: `fpga/AXKU15/diffusion/docs/OFFICIAL_DDR4_DEMO_ASSESSMENT.md`

- [ ] **Step 1: Run the bridge regression and real-top generator.**

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false'
sbt 'testOnly FLOOD_Accelerator.diffusion.MigAppToAxi64BridgeSpec FLOOD_Accelerator.diffusion.MigAppTransferSpec FLOOD_Accelerator.diffusion.MigAppRequestArbiterSpec'
sbt 'runMain FLOOD_Accelerator.diffusion.GenerateDiffusionAccelTopVerilog'
```

Expected: selected simulations and Verilog generation pass.

- [ ] **Step 2: Record verified facts only.** State that the standalone bridge has simulation coverage; retain the explicit statement that vendor IP remains unmodified and physical DDR4 calibration is not proven.

- [ ] **Step 3: Commit.**

```powershell
git add docs/AXI512_TO_AXI64_BRIDGE_DESIGN.md fpga/AXKU15/diffusion/docs/OFFICIAL_DDR4_DEMO_ASSESSMENT.md
git commit -m "docs: record AXI64 bridge verification"
```

## Plan self-review

- Tasks 1--3 cover split/assembly, byte masking, independent backpressure, held responses, and errors.
- Task 4 verifies the focused test scope and preserves the vendor/IP boundary.
- No task claims board calibration, modifies the vendor demo, or leaves unresolved implementation placeholders.
