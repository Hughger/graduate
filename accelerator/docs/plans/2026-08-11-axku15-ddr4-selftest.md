# AXKU15 AXI64 DDR4 self-test implementation plan

**Goal:** Build a generated AXI64 self-test RTL module and a non-invasive AXKU15 wrapper/build flow that can validate a calibrated vendor DDR4 core with a 512-bit write/read comparison.

**Architecture:** `Axi64DdrSelfTest` owns one `MigAppToAxi64Bridge` and auto-runs after calibration.  It produces a pass/fail status without a host connection.  The later SystemVerilog wrapper only maps its AXI64 and status ports to an externally supplied `ddr4_core`.

**Tech stack:** Scala, Chisel 3, chiseltest, ScalaTest, SystemVerilog, Vivado Tcl.

## Constraints

- Do not modify, copy, regenerate, or write under the official demo directory.
- Do not program the board or claim calibration/data integrity without explicit physical-board authorization.
- The self-test clock/reset are supplied by the eventual vendor UI clock/reset wrapper.
- No request is sent before `calibrated` is high; pass/fail are sticky until reset.

### Task 1: Simulate the calibration-gated self-test

**Files:**

- Create: `src/main/scala/diffusion/Axi64DdrSelfTest.scala`
- Create: `src/test/scala/diffusion/Axi64DdrSelfTestSpec.scala`

- [ ] **Step 1: Write failing pass/fail tests.**

```scala
"Axi64DdrSelfTest" should "wait for calibration then pass after a matching 512-bit write/read" in {
  test(new Axi64DdrSelfTest) { dut =>
    idle(dut); dut.io.calibrated.poke(false.B); dut.clock.step(3)
    dut.io.axi.aw.valid.expect(false.B); dut.io.axi.ar.valid.expect(false.B)
    dut.io.calibrated.poke(true.B)
    acceptWriteAndOkayB(dut); acceptRead(dut, selfTestWord)
    dut.io.passed.expect(true.B); dut.io.failed.expect(false.B)
  }
}
it should "latch failure after a mismatching read word" in {
  test(new Axi64DdrSelfTest) { dut =>
    idle(dut); dut.io.calibrated.poke(true.B)
    acceptWriteAndOkayB(dut); acceptRead(dut, selfTestWord ^ 1)
    dut.io.passed.expect(false.B); dut.io.failed.expect(true.B)
  }
}
```

- [ ] **Step 2: Verify RED.**

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false'
sbt 'testOnly FLOOD_Accelerator.diffusion.Axi64DdrSelfTestSpec'
```

Expected: compilation fails because `Axi64DdrSelfTest` does not exist.

- [ ] **Step 3: Implement the self-test state machine.**

```scala
val waitCalibration :: sendWrite :: waitWrite :: sendRead :: waitRead :: passed :: failed :: Nil = Enum(7)
val selfTestAddress = "h00000100".U(29.W)
val selfTestWord = Cat((0 until 8).reverse.map(index => (BigInt(index + 1) << 32 | BigInt(index + 1)).U(64.W)))
```

Use a `Decoupled[MigAppRequest]` request channel into `MigAppToAxi64Bridge`; issue full byte enables (`writeMask = 0`).  In `waitRead`, compare only when `response.fire`; bridge error transitions to `failed` from either wait state.

- [ ] **Step 4: Verify GREEN.** Run Task 1 test and `MigAppToAxi64BridgeSpec`; all must pass.

- [ ] **Step 5: Commit.**

```powershell
git add src/main/scala/diffusion/Axi64DdrSelfTest.scala src/test/scala/diffusion/Axi64DdrSelfTestSpec.scala
git commit -m "feat: add AXKU15 DDR4 bridge self-test"
```

### Task 2: Generate self-test RTL and create a vendor-neutral wrapper flow

**Files:**

- Create: `src/main/scala/diffusion/GenerateAxi64DdrSelfTestVerilog.scala`
- Create: `fpga/AXKU15/diffusion/rtl/axku15_axi64_ddr4_selftest.v`
- Create: `fpga/AXKU15/diffusion/scripts/build_axi64_ddr4_selftest.tcl`
- Create: `fpga/AXKU15/diffusion/docs/AXKU15_AXI64_DDR4_SELFTEST_BUILD.md`

- [ ] **Step 1: Add the standalone generator.**

```scala
object GenerateAxi64DdrSelfTestVerilog extends App {
  (new ChiselStage).emitVerilog(
    new Axi64DdrSelfTest,
    Array("--target-dir", "target/generated/axi64-ddr4-selftest")
  )
}
```

- [ ] **Step 2: Add a thin wrapper with this exact ownership split.**

```verilog
ddr4_core u_ddr4_core (/* vendor physical pins and complete AXI slave map */);
Axi64DdrSelfTest u_selftest (
  .clock(c0_ddr4_ui_clk),
  .reset(c0_ddr4_ui_clk_sync_rst | ~c0_ddr4_aresetn),
  .io_calibrated(c0_init_calib_complete),
  /* AXI64 map */
);
assign led[0] = c0_init_calib_complete;
assign led[1] = selftest_active;
assign led[2] = selftest_passed;
assign led[3] = selftest_failed;
```

The wrapper must tie `AWBURST`/`ARBURST` to `2'b01` (INCR) and all unsupported cache/prot/qos/user fields to zero.

- [ ] **Step 3: Add a parameterized Tcl build script.** It requires `DDR4_XCI` and `DDR4_XDC` arguments, reads generated self-test Verilog plus wrapper, creates output only beneath `fpga/AXKU15/diffusion/build/axi64_ddr4_selftest`, and ends after elaboration unless an explicit `RUN_IMPL=1` argument is supplied.

- [ ] **Step 4: Run generator and static port checks.**

```powershell
$env:SBT_OPTS='-Dsbt.server.autostart=false'
sbt 'runMain FLOOD_Accelerator.diffusion.GenerateAxi64DdrSelfTestVerilog'
Select-String -Path target/generated/axi64-ddr4-selftest/Axi64DdrSelfTest.v -Pattern 'io_axi_aw','io_axi_w','io_axi_b','io_axi_ar','io_axi_r','io_passed','io_failed'
```

Expected: generation succeeds and every named port group occurs.

- [ ] **Step 5: Record build prerequisites.** The document must distinguish static generation from Vivado implementation, and implementation from physical calibration/readback.

- [ ] **Step 6: Commit.**

```powershell
git add src/main/scala/diffusion/GenerateAxi64DdrSelfTestVerilog.scala fpga/AXKU15/diffusion/rtl/axku15_axi64_ddr4_selftest.v fpga/AXKU15/diffusion/scripts/build_axi64_ddr4_selftest.tcl fpga/AXKU15/diffusion/docs/AXKU15_AXI64_DDR4_SELFTEST_BUILD.md
git commit -m "build: add AXKU15 DDR4 self-test wrapper"
```

## Plan self-review

- Task 1 isolates and simulates bridge traffic before any board wrapper exists.
- Task 2 leaves vendor artifacts external and makes implementation opt-in.
- No task claims a bitstream, board programming, calibration, or read/write result without separately produced evidence.
