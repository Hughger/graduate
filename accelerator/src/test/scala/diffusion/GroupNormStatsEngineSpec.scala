package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class GroupNormStatsEngineSpec extends AnyFlatSpec with ChiselScalatestTester {
  "GroupNormStatsEngine" should "accumulate a commanded vector group and retain stats under backpressure" in {
    test(new GroupNormStatsEngine) { dut =>
      dut.io.command.valid.poke(false.B); dut.io.input.valid.poke(false.B); dut.io.stats.ready.poke(false.B)
      dut.io.command.bits.vectors.poke(2.U); dut.io.command.valid.poke(true.B); dut.clock.step(); dut.io.command.valid.poke(false.B)
      for (value <- Seq(1, 2)) {
        for (lane <- 0 until 32) { dut.io.input.bits(lane).poke(value.S) }
        dut.io.input.valid.poke(true.B); dut.clock.step(); dut.io.input.valid.poke(false.B)
      }
      dut.io.stats.valid.expect(true.B)
      dut.io.stats.bits.sum.expect(96.S); dut.io.stats.bits.sumSquare.expect(160.U); dut.io.stats.bits.count.expect(64.U)
      dut.clock.step(2); dut.io.stats.valid.expect(true.B)
      dut.io.stats.ready.poke(true.B); dut.clock.step(); dut.io.done.expect(true.B)
    }
  }
}
