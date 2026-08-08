package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class GroupNormApplySpec extends AnyFlatSpec with ChiselScalatestTester {
  "GroupNormApply" should "apply Q2.30 normalization, affine parameters, and INT16 saturation" in {
    test(new GroupNormApply(lanes = 4)) { dut =>
      dut.io.input.valid.poke(false.B)
      dut.io.output.ready.poke(false.B)
      dut.io.mean.poke(0.S)
      dut.io.rsqrtQ30.poke((BigInt(1) << 30).U)
      Seq(256, 256, 256, 256).zipWithIndex.foreach { case (value, lane) => dut.io.gamma(lane).poke(value.S) }
      Seq(3, -4, 0, 1).zipWithIndex.foreach { case (value, lane) => dut.io.beta(lane).poke(value.S) }
      Seq(10, -10, 32767, -32768).zipWithIndex.foreach { case (value, lane) => dut.io.input.bits(lane).poke(value.S) }

      dut.io.input.valid.poke(true.B)
      dut.clock.step()
      dut.io.input.valid.poke(false.B)

      dut.io.output.valid.expect(true.B)
      Seq(13, -14, 32767, -32767).zipWithIndex.foreach { case (value, lane) => dut.io.output.bits(lane).expect(value.S) }
      dut.clock.step(2)
      dut.io.output.ready.poke(true.B)
      dut.clock.step()
      dut.io.output.valid.expect(false.B)
    }
  }
}
