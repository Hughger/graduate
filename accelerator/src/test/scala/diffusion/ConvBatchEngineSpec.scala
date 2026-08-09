package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class ConvBatchEngineSpec extends AnyFlatSpec with ChiselScalatestTester {
  behavior of "ConvBatchEngine"

  it should "execute exactly the commanded activation vectors and finish after the final result" in {
    test(new ConvBatchEngine(DiffusionParams.sd15EightTile)) { dut =>
      dut.io.command.valid.poke(false.B)
      dut.io.activation.valid.poke(false.B)
      dut.io.output.ready.poke(false.B)
      dut.io.weightWrite.valid.poke(false.B)
      dut.clock.step()

      for (channel <- 0 until 32) {
        dut.io.weightWrite.bits.row.poke(channel.U)
        dut.io.weightWrite.bits.column.poke(channel.U)
        dut.io.weightWrite.bits.data.poke(1.S)
        dut.io.weightWrite.valid.poke(true.B)
        dut.clock.step()
      }
      dut.io.weightWrite.valid.poke(false.B)

      dut.io.command.bits.vectors.poke(2.U)
      dut.io.command.valid.poke(true.B)
      dut.io.command.ready.expect(true.B)
      dut.clock.step()
      dut.io.command.valid.poke(false.B)
      dut.io.busy.expect(true.B)

      for (value <- 0 until 32) { dut.io.activation.bits(value).poke((value - 16).S) }
      dut.io.activation.valid.poke(true.B)
      dut.io.activation.ready.expect(true.B)
      dut.clock.step()
      dut.io.activation.valid.poke(false.B)
      dut.clock.step()
      dut.io.output.valid.expect(true.B)
      dut.io.done.expect(false.B)
      for (value <- 0 until 32) { dut.io.output.bits(value).expect((value - 16).S) }
      dut.clock.step(2)
      dut.io.output.valid.expect(true.B)

      dut.io.output.ready.poke(true.B)
      dut.clock.step()
      dut.io.output.ready.poke(false.B)
      dut.io.done.expect(false.B)

      for (value <- 0 until 32) { dut.io.activation.bits(value).poke((31 - value).S) }
      dut.io.activation.valid.poke(true.B)
      dut.io.activation.ready.expect(true.B)
      dut.clock.step()
      dut.io.activation.valid.poke(false.B)
      dut.clock.step()
      dut.io.output.valid.expect(true.B)
      for (value <- 0 until 32) { dut.io.output.bits(value).expect((31 - value).S) }
      dut.io.output.ready.poke(true.B)
      dut.clock.step()
      dut.io.output.ready.poke(false.B)
      dut.io.done.expect(true.B)
      dut.io.busy.expect(false.B)
    }
  }
}
