package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class ConvToGroupNormStatsPathSpec extends AnyFlatSpec with ChiselScalatestTester {
  "ConvToGroupNormStatsPath" should "requantize and retain a convolution result before computing GN2 statistics" in {
    test(new ConvToGroupNormStatsPath(DiffusionParams.sd15EightTile, resultDepth = 4)) { dut =>
      dut.io.convCommand.valid.poke(false.B); dut.io.activation.valid.poke(false.B); dut.io.convOutput.ready.poke(true.B)
      dut.io.weightWrite.valid.poke(false.B); dut.io.statsCommand.valid.poke(false.B); dut.io.stats.ready.poke(false.B)
      dut.io.convShift.poke(0.U); dut.io.resultShift.poke(0.U)
      dut.clock.step()

      for (lane <- 0 until 32) {
        dut.io.weightWrite.bits.row.poke(lane.U); dut.io.weightWrite.bits.column.poke(lane.U); dut.io.weightWrite.bits.data.poke(1.S)
        dut.io.weightWrite.valid.poke(true.B); dut.clock.step()
      }
      dut.io.weightWrite.valid.poke(false.B)
      dut.io.convCommand.bits.vectors.poke(1.U); dut.io.convCommand.valid.poke(true.B); dut.clock.step(); dut.io.convCommand.valid.poke(false.B)
      for (lane <- 0 until 32) { dut.io.activation.bits(lane).poke((lane - 16).S) }
      dut.io.activation.valid.poke(true.B); dut.io.activation.ready.expect(true.B); dut.clock.step(); dut.io.activation.valid.poke(false.B)
      dut.clock.step(2); dut.io.convDone.expect(true.B)
      dut.clock.step(); dut.io.occupancy.expect(1.U)

      dut.io.statsCommand.bits.vectors.poke(1.U); dut.io.statsCommand.valid.poke(true.B); dut.clock.step(); dut.io.statsCommand.valid.poke(false.B)
      dut.clock.step(2); dut.io.stats.valid.expect(true.B)
      dut.io.stats.bits.sum.expect((-16).S); dut.io.stats.bits.sumSquare.expect(2736.U); dut.io.stats.bits.count.expect(32.U)
      dut.io.stats.ready.poke(true.B); dut.clock.step(); dut.io.statsDone.expect(true.B)
    }
  }
}
