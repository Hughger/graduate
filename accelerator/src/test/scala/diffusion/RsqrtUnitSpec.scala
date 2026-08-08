package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class RsqrtUnitSpec extends AnyFlatSpec with ChiselScalatestTester {
  "RsqrtUnit" should "match the Q2.30 integer reference for exact power-of-two variances" in {
    test(new RsqrtUnit) { dut =>
      dut.io.input.valid.poke(false.B)
      dut.io.output.ready.poke(true.B)
      dut.clock.step()

      Seq((0, BigInt(1) << 30), (3, BigInt(1) << 29), (15, BigInt(1) << 28)).foreach {
        case (variance, expected) =>
          dut.io.input.bits.poke(variance.U)
          dut.io.input.valid.poke(true.B)
          while (!dut.io.input.ready.peek().litToBoolean) { dut.clock.step() }
          dut.clock.step()
          dut.io.input.valid.poke(false.B)
          while (!dut.io.output.valid.peek().litToBoolean) { dut.clock.step() }
          dut.io.output.bits.expect(expected.U)
          dut.clock.step()
      }
    }
  }
}
