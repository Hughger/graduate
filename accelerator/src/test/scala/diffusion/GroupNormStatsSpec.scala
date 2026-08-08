package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class GroupNormStatsSpec extends AnyFlatSpec with ChiselScalatestTester {
  "GroupNormStats" should "accumulate signed sums, squared sums, and count through the final token" in {
    test(new GroupNormStats(lanes = 4)) { dut =>
      dut.io.input.valid.poke(false.B)
      dut.io.stats.ready.poke(false.B)
      dut.clock.step()

      def send(values: Seq[Int], last: Boolean): Unit = {
        values.zipWithIndex.foreach { case (value, lane) => dut.io.input.bits.values(lane).poke(value.S) }
        dut.io.input.bits.last.poke(last.B)
        dut.io.input.valid.poke(true.B)
        dut.io.input.ready.expect(true.B)
        dut.clock.step()
        dut.io.input.valid.poke(false.B)
      }

      send(Seq(1, -2, 3, -4), last = false)
      dut.io.stats.valid.expect(false.B)
      send(Seq(5, -6, 7, -8), last = true)

      dut.io.stats.valid.expect(true.B)
      dut.io.stats.bits.sum.expect((-4).S)
      dut.io.stats.bits.sumSquare.expect(204.U)
      dut.io.stats.bits.count.expect(8.U)
      dut.clock.step(2)
      dut.io.stats.valid.expect(true.B)
      dut.io.stats.ready.poke(true.B)
      dut.clock.step()
      dut.io.stats.valid.expect(false.B)
    }
  }
}
