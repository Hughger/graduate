package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class Axi64DdrSelfTestSpec extends AnyFlatSpec with ChiselScalatestTester {
  private val selfTestWord = (0 until 8).map(index => BigInt(index + 1) << (64 * index)).sum

  private def idle(dut: Axi64DdrSelfTest): Unit = {
    dut.io.calibrated.poke(false.B)
    dut.io.axi.aw.ready.poke(false.B)
    dut.io.axi.w.ready.poke(false.B)
    dut.io.axi.b.valid.poke(false.B)
    dut.io.axi.b.bits.id.poke(0.U)
    dut.io.axi.b.bits.resp.poke(0.U)
    dut.io.axi.ar.ready.poke(false.B)
    dut.io.axi.r.valid.poke(false.B)
    dut.io.axi.r.bits.data.poke(0.U)
    dut.io.axi.r.bits.id.poke(0.U)
    dut.io.axi.r.bits.resp.poke(0.U)
    dut.io.axi.r.bits.last.poke(false.B)
  }

  private def waitFor(dut: Axi64DdrSelfTest, label: String)(ready: => Boolean): Unit = {
    var cycles = 0
    while (!ready && cycles < 12) {
      dut.clock.step()
      cycles += 1
    }
    assert(ready, s"timed out waiting for $label")
  }

  private def acceptWriteAndOkayB(dut: Axi64DdrSelfTest): Unit = {
    waitFor(dut, "write address") { dut.io.axi.aw.valid.peek().litToBoolean }
    dut.io.axi.aw.bits.addr.expect("h100".U)
    dut.io.axi.aw.bits.len.expect(7.U)
    dut.io.axi.aw.bits.size.expect(3.U)
    dut.io.axi.aw.ready.poke(true.B)
    dut.clock.step()
    dut.io.axi.aw.ready.poke(false.B)

    for (beat <- 0 until 8) {
      waitFor(dut, s"write beat $beat") { dut.io.axi.w.valid.peek().litToBoolean }
      dut.io.axi.w.bits.data.expect(((selfTestWord >> (64 * beat)) & ((BigInt(1) << 64) - 1)).U)
      dut.io.axi.w.bits.strb.expect("hff".U)
      dut.io.axi.w.bits.last.expect((beat == 7).B)
      dut.io.axi.w.ready.poke(true.B)
      dut.clock.step()
      dut.io.axi.w.ready.poke(false.B)
    }

    waitFor(dut, "write response") { dut.io.axi.b.ready.peek().litToBoolean }
    dut.io.axi.b.bits.resp.poke(0.U)
    dut.io.axi.b.valid.poke(true.B)
    dut.clock.step()
    dut.io.axi.b.valid.poke(false.B)
  }

  private def acceptRead(dut: Axi64DdrSelfTest, word: BigInt): Unit = {
    waitFor(dut, "read address") { dut.io.axi.ar.valid.peek().litToBoolean }
    dut.io.axi.ar.bits.addr.expect("h100".U)
    dut.io.axi.ar.bits.len.expect(7.U)
    dut.io.axi.ar.bits.size.expect(3.U)
    dut.io.axi.ar.ready.poke(true.B)
    dut.clock.step()
    dut.io.axi.ar.ready.poke(false.B)

    for (beat <- 0 until 8) {
      waitFor(dut, s"read beat $beat") { dut.io.axi.r.ready.peek().litToBoolean }
      dut.io.axi.r.bits.data.poke(((word >> (64 * beat)) & ((BigInt(1) << 64) - 1)).U)
      dut.io.axi.r.bits.id.poke(0.U)
      dut.io.axi.r.bits.resp.poke(0.U)
      dut.io.axi.r.bits.last.poke((beat == 7).B)
      dut.io.axi.r.valid.poke(true.B)
      dut.clock.step()
      dut.io.axi.r.valid.poke(false.B)
    }
  }

  "Axi64DdrSelfTest" should "wait for calibration then pass after a matching 512-bit write and read" in {
    test(new Axi64DdrSelfTest) { dut =>
      idle(dut)
      dut.clock.step(3)
      dut.io.axi.aw.valid.expect(false.B)
      dut.io.axi.ar.valid.expect(false.B)
      dut.io.active.expect(false.B)

      dut.io.calibrated.poke(true.B)
      dut.clock.step()
      dut.io.active.expect(true.B)
      acceptWriteAndOkayB(dut)
      acceptRead(dut, selfTestWord)
      dut.clock.step()
      dut.io.passed.expect(true.B)
      dut.io.failed.expect(false.B)
      dut.io.active.expect(false.B)
    }
  }

  it should "latch failure after a mismatching read word" in {
    test(new Axi64DdrSelfTest) { dut =>
      idle(dut)
      dut.io.calibrated.poke(true.B)
      acceptWriteAndOkayB(dut)
      acceptRead(dut, selfTestWord ^ 1)
      dut.clock.step()
      dut.io.passed.expect(false.B)
      dut.io.failed.expect(true.B)
    }
  }

  it should "latch failure after an AXI write error" in {
    test(new Axi64DdrSelfTest) { dut =>
      idle(dut)
      dut.io.calibrated.poke(true.B)
      waitFor(dut, "write address") { dut.io.axi.aw.valid.peek().litToBoolean }
      dut.io.axi.aw.ready.poke(true.B)
      dut.clock.step()
      dut.io.axi.aw.ready.poke(false.B)
      for (_ <- 0 until 8) {
        waitFor(dut, "write data") { dut.io.axi.w.valid.peek().litToBoolean }
        dut.io.axi.w.ready.poke(true.B)
        dut.clock.step()
        dut.io.axi.w.ready.poke(false.B)
      }
      waitFor(dut, "write response") { dut.io.axi.b.ready.peek().litToBoolean }
      dut.io.axi.b.bits.resp.poke(2.U)
      dut.io.axi.b.valid.poke(true.B)
      dut.clock.step()
      dut.io.axi.b.valid.poke(false.B)
      dut.clock.step()
      dut.io.passed.expect(false.B)
      dut.io.failed.expect(true.B)
      dut.io.axi.ar.valid.expect(false.B)
    }
  }
}
