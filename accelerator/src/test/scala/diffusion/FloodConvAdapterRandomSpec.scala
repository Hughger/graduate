package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

import scala.util.Random

class FloodConvAdapterRandomSpec extends AnyFlatSpec with ChiselScalatestTester {
  behavior of "FloodConvAdapter"

  it should "match 100 signed vectors with randomized output stalls" in {
    test(new FloodConvAdapter(DiffusionParams.sd15EightTile)) { dut =>
      val random = new Random(921)
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

      val vectors = Seq(Seq.fill(32)(-128), Seq.fill(32)(127)) ++
        Seq.fill(98)(Seq.fill(32)(random.nextInt(256) - 128))
      for (input <- vectors) {
        while (!dut.io.activation.ready.peek().litToBoolean) {
          dut.clock.step()
        }
        for ((value, channel) <- input.zipWithIndex) {
          dut.io.activation.bits(channel).poke(value.S)
        }
        dut.io.activation.valid.poke(true.B)
        dut.clock.step()
        dut.io.activation.valid.poke(false.B)

        while (!dut.io.output.valid.peek().litToBoolean) {
          dut.clock.step()
        }
        for ((value, channel) <- input.zipWithIndex) {
          dut.io.output.bits(channel).expect(value.S)
        }
        dut.clock.step(random.nextInt(4))
        dut.io.output.valid.expect(true.B)
        dut.io.output.ready.poke(true.B)
        dut.clock.step()
        dut.io.output.ready.poke(false.B)
      }
    }
  }
}
