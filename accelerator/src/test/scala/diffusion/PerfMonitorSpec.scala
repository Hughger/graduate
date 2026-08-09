package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class PerfMonitorSpec extends AnyFlatSpec with ChiselScalatestTester {
  "PerfMonitor" should "accumulate and snapshot 64-bit counters" in {
    test(new PerfMonitor) { dut =>
      dut.io.active.poke(true.B); dut.io.readBytes.poke(64.U); dut.io.writeBytes.poke(128.U)
      dut.io.macActive.poke(true.B); dut.io.groupNormActive.poke(false.B); dut.io.stalled.poke(false.B); dut.io.snapshot.poke(false.B)
      dut.clock.step(2)
      dut.io.active.poke(false.B); dut.io.readBytes.poke(0.U); dut.io.writeBytes.poke(0.U)
      dut.io.macActive.poke(false.B); dut.io.groupNormActive.poke(true.B); dut.io.stalled.poke(true.B)
      dut.clock.step()
      dut.io.snapshot.poke(true.B); dut.clock.step(); dut.io.snapshot.poke(false.B)
      dut.io.counters.totalCycles.expect(2.U)
      dut.io.counters.readBytes.expect(128.U)
      dut.io.counters.writeBytes.expect(256.U)
      dut.io.counters.macCycles.expect(2.U)
      dut.io.counters.groupNormCycles.expect(1.U)
      dut.io.counters.stallCycles.expect(1.U)
    }
  }
}
