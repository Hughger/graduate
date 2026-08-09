package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class TensorGroupNormStatsPathSpec extends AnyFlatSpec with ChiselScalatestTester {
  "TensorGroupNormStatsPath" should "compute GroupNorm statistics from a loaded DDR beat" in {
    test(new TensorGroupNormStatsPath(depth = 64)) { dut =>
      dut.io.loadStart.poke(true.B); dut.io.dmaData.valid.poke(false.B); dut.io.dmaDone.poke(false.B)
      dut.io.statsCommand.valid.poke(false.B); dut.io.stats.ready.poke(false.B)
      dut.clock.step(); dut.io.loadStart.poke(false.B)
      val beat = BigInt("0003" * 32, 16)
      dut.io.dmaData.bits.poke(beat.U); dut.io.dmaData.valid.poke(true.B); dut.clock.step()
      dut.io.dmaData.valid.poke(false.B); dut.io.dmaDone.poke(true.B); dut.clock.step()
      dut.io.dmaDone.poke(false.B); dut.clock.step(31); dut.io.loadDone.expect(true.B)
      dut.clock.step()
      dut.io.statsCommand.bits.baseAddress.poke(0.U); dut.io.statsCommand.bits.vectors.poke(1.U)
      dut.io.statsCommand.valid.poke(true.B); dut.io.statsCommand.ready.expect(true.B); dut.clock.step()
      dut.io.statsCommand.valid.poke(false.B); dut.clock.step(66)
      dut.io.stats.valid.expect(true.B)
      dut.io.stats.bits.sum.expect(96.S); dut.io.stats.bits.sumSquare.expect(288.U); dut.io.stats.bits.count.expect(32.U)
      dut.io.stats.ready.poke(true.B); dut.clock.step(); dut.io.statsDone.expect(true.B)
    }
  }
}
