package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class FloodConvAdapterSpec extends AnyFlatSpec with ChiselScalatestTester {
  behavior of "FloodConvAdapter"

  it should "emit signed INT32 channel sums and retain them under output backpressure" in {
    test(new FloodConvAdapter(DiffusionParams.sd15EightTile)) { dut =>
      dut.io.activation.valid.poke(false.B)
      dut.io.output.ready.poke(false.B)
      dut.io.weightWrite.valid.poke(false.B)
      dut.clock.step()

      for (channel <- 0 until 32) {
        dut.io.weightWrite.bits.row.poke(channel.U)
        dut.io.weightWrite.bits.column.poke(channel.U)
        dut.io.weightWrite.bits.data.poke((if (channel % 2 == 0) 2 else -3).S)
        dut.io.weightWrite.valid.poke(true.B)
        dut.io.weightWrite.ready.expect(true.B)
        dut.clock.step()
      }
      dut.io.weightWrite.valid.poke(false.B)

      val input = (0 until 32).map(_ - 16)
      for ((value, channel) <- input.zipWithIndex) {
        dut.io.activation.bits(channel).poke(value.S)
      }
      dut.io.activation.valid.poke(true.B)
      dut.io.activation.ready.expect(true.B)
      dut.clock.step()
      dut.io.activation.valid.poke(false.B)

      while (!dut.io.output.valid.peek().litToBoolean) {
        dut.clock.step()
      }
      for ((value, channel) <- input.zipWithIndex) {
        dut.io.output.bits(channel).expect((value * (if (channel % 2 == 0) 2 else -3)).S)
      }
      dut.clock.step(3)
      dut.io.output.valid.expect(true.B)

      dut.io.output.ready.poke(true.B)
      dut.clock.step()
      dut.io.output.valid.expect(false.B)
    }
  }
}
