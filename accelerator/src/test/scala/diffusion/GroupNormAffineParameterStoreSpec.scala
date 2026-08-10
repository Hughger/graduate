package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class GroupNormAffineParameterStoreSpec extends AnyFlatSpec with ChiselScalatestTester {
  "GroupNormAffineParameterStore" should "reset to identity affine parameters and update an addressed channel" in {
    test(new GroupNormAffineParameterStore(lanes = 4)) { dut =>
      dut.io.write.valid.poke(false.B); dut.clock.step()
      for (lane <- 0 until 4) { dut.io.gamma(lane).expect(256.S); dut.io.beta(lane).expect(0.S) }
      dut.io.write.bits.channel.poke(2.U)
      dut.io.write.bits.gamma.poke((-128).S)
      dut.io.write.bits.beta.poke(37.S)
      dut.io.write.valid.poke(true.B); dut.io.write.ready.expect(true.B); dut.clock.step(); dut.io.write.valid.poke(false.B)
      dut.io.gamma(2).expect((-128).S); dut.io.beta(2).expect(37.S)
      dut.io.gamma(1).expect(256.S); dut.io.beta(1).expect(0.S)
    }
  }
}
