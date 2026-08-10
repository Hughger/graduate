package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class GroupNormSiluSpec extends AnyFlatSpec with ChiselScalatestTester {
  "GroupNormSilu" should "apply affine GroupNorm before the existing SiLU PWL under output backpressure" in {
    test(new GroupNormSilu(lanes = 4)) { dut =>
      dut.io.input.valid.poke(false.B); dut.io.output.ready.poke(false.B)
      dut.io.mean.poke(0.S); dut.io.rsqrtQ30.poke((BigInt(1) << 30).U)
      for (lane <- 0 until 4) { dut.io.gamma(lane).poke(256.S); dut.io.beta(lane).poke(0.S) }
      Seq(0, 256, -128, 3000).zipWithIndex.foreach { case (value, lane) => dut.io.input.bits(lane).poke(value.S) }
      dut.io.input.valid.poke(true.B); dut.clock.step(); dut.io.input.valid.poke(false.B)
      dut.clock.step()
      dut.io.output.valid.expect(true.B)
      Seq(0, 187, -33, 3000).zipWithIndex.foreach { case (value, lane) => dut.io.output.bits(lane).expect(value.S) }
      dut.clock.step(2); dut.io.output.valid.expect(true.B)
      dut.io.output.ready.poke(true.B); dut.clock.step(); dut.io.output.valid.expect(false.B)
    }
  }
}
