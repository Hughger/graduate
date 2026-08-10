package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class Conv2ResidualPathSpec extends AnyFlatSpec with ChiselScalatestTester {
  "Conv2ResidualPath" should "requantize Conv2 and signal done only after time/residual fusion is consumed" in {
    test(new Conv2ResidualPath(DiffusionParams.sd15EightTile)) { dut =>
      dut.io.command.valid.poke(false.B); dut.io.weightWrite.valid.poke(false.B); dut.io.activation.valid.poke(false.B); dut.io.output.ready.poke(false.B)
      dut.io.inputShift.poke(0.U); dut.io.outputShift.poke(0.U); dut.io.addResidual.poke(true.B)
      for (lane <- 0 until 32) { dut.io.temb(lane).poke(1.S); dut.io.residual(lane).poke(2.S) }
      dut.clock.step()
      for (lane <- 0 until 32) {
        dut.io.weightWrite.bits.row.poke(lane.U); dut.io.weightWrite.bits.column.poke(lane.U); dut.io.weightWrite.bits.data.poke(1.S)
        dut.io.weightWrite.valid.poke(true.B); dut.clock.step()
      }
      dut.io.weightWrite.valid.poke(false.B)
      dut.io.command.bits.vectors.poke(1.U); dut.io.command.valid.poke(true.B); dut.clock.step(); dut.io.command.valid.poke(false.B)
      for (lane <- 0 until 32) { dut.io.activation.bits(lane).poke((lane - 16).S) }
      dut.io.activation.valid.poke(true.B); dut.io.activation.ready.expect(true.B); dut.clock.step(); dut.io.activation.valid.poke(false.B)
      dut.clock.step(4); dut.io.output.valid.expect(true.B); dut.io.done.expect(false.B)
      for (lane <- 0 until 32) { dut.io.output.bits(lane).expect((lane - 13).S) }
      dut.clock.step(2); dut.io.output.valid.expect(true.B)
      dut.io.output.ready.poke(true.B); dut.clock.step(); dut.io.done.expect(true.B)
    }
  }
}
