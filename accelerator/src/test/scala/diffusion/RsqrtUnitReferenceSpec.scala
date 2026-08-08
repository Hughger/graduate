package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class RsqrtUnitReferenceSpec extends AnyFlatSpec with ChiselScalatestTester {
  "RsqrtUnit" should "match selected non-power-of-two Python Q2.30 reference values" in {
    test(new RsqrtUnit) { dut =>
      dut.io.input.valid.poke(false.B)
      dut.io.output.ready.poke(true.B)
      dut.clock.step()
      Seq(
        (1, BigInt(759250125)),
        (2, BigInt(619925131)),
        (4, BigInt(480191942)),
        (10, BigInt(323745341)),
        (31, BigInt(189812531)),
        (255, BigInt(67108864))
      ).foreach { case (variance, expected) =>
        dut.io.input.bits.poke(variance.U)
        dut.io.input.valid.poke(true.B)
        dut.clock.step()
        dut.io.input.valid.poke(false.B)
        while (!dut.io.output.valid.peek().litToBoolean) { dut.clock.step() }
        dut.io.output.bits.expect(expected.U)
        dut.clock.step()
      }
    }
  }
}
