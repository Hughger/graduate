package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class GroupNormParameterGeneratorSpec extends AnyFlatSpec with ChiselScalatestTester {
  "GroupNormParameterGenerator" should "derive integer mean, nonnegative variance, and Q2.30 rsqrt from statistics" in {
    test(new GroupNormParameterGenerator) { dut =>
      dut.io.input.valid.poke(false.B); dut.io.output.ready.poke(false.B); dut.clock.step()
      dut.io.input.bits.sum.poke(32.S)
      dut.io.input.bits.sumSquare.poke(32.U)
      dut.io.input.bits.count.poke(32.U)
      dut.io.input.valid.poke(true.B); dut.clock.step(); dut.io.input.valid.poke(false.B)
      dut.io.output.valid.expect(true.B)
      dut.io.output.bits.mean.expect(1.S)
      dut.io.output.bits.variance.expect(0.U)
      dut.io.output.bits.rsqrtQ30.expect((BigInt(1) << 30).U)
      dut.clock.step(2); dut.io.output.valid.expect(true.B)
      dut.io.output.ready.poke(true.B); dut.clock.step(); dut.io.output.valid.expect(false.B)
    }
  }
}
