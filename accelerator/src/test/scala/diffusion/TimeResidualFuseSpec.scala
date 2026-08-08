package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class TimeResidualFuseSpec extends AnyFlatSpec with ChiselScalatestTester {
  "TimeResidualFuse" should "broadcast time values and saturate the optional residual add" in {
    test(new TimeResidualFuse(lanes = 4)) { dut =>
      dut.io.input.valid.poke(false.B)
      dut.io.output.ready.poke(false.B)
      dut.io.addResidual.poke(true.B)
      Seq(10, -20, 1, 32767).zipWithIndex.foreach { case (value, lane) =>
        dut.io.temb(lane).poke(value.S)
      }
      Seq(5, 7, -2, 1).zipWithIndex.foreach { case (value, lane) =>
        dut.io.residual(lane).poke(value.S)
      }
      Seq(100, -100, 4, 100).zipWithIndex.foreach { case (value, lane) =>
        dut.io.input.bits(lane).poke(value.S)
      }
      dut.io.input.valid.poke(true.B)
      dut.clock.step()
      dut.io.input.valid.poke(false.B)

      dut.io.output.valid.expect(true.B)
      Seq(115, -113, 3, 32767).zipWithIndex.foreach { case (value, lane) =>
        dut.io.output.bits(lane).expect(value.S)
      }
      dut.clock.step(2)
      dut.io.output.valid.expect(true.B)
      dut.io.output.ready.poke(true.B)
      dut.clock.step()
      dut.io.output.valid.expect(false.B)
    }
  }
}
