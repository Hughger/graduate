package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class GroupNormActivationPathSpec extends AnyFlatSpec with ChiselScalatestTester {
  "GroupNormActivationPath" should "latch generated statistics before accepting vectors through affine GroupNorm and SiLU" in {
    test(new GroupNormActivationPath(lanes = 4)) { dut =>
      dut.io.stats.valid.poke(false.B); dut.io.affineWrite.valid.poke(false.B)
      dut.io.activation.valid.poke(false.B); dut.io.output.ready.poke(false.B); dut.clock.step()
      dut.io.stats.bits.sum.poke(0.S); dut.io.stats.bits.sumSquare.poke(0.U); dut.io.stats.bits.count.poke(1.U)
      dut.io.stats.valid.poke(true.B); dut.clock.step(); dut.io.stats.valid.poke(false.B); dut.clock.step()
      dut.io.parametersReady.expect(true.B)
      Seq(0, 256, -128, 3000).zipWithIndex.foreach { case (value, lane) => dut.io.activation.bits(lane).poke(value.S) }
      dut.io.activation.valid.poke(true.B); dut.io.activation.ready.expect(true.B); dut.clock.step(); dut.io.activation.valid.poke(false.B)
      dut.clock.step(); dut.io.output.valid.expect(true.B)
      Seq(0, 187, -33, 3000).zipWithIndex.foreach { case (value, lane) => dut.io.output.bits(lane).expect(value.S) }
    }
  }
}
