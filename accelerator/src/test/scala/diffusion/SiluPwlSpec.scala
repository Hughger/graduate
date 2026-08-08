package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class SiluPwlSpec extends AnyFlatSpec with ChiselScalatestTester {
  "SiluPwl" should "use the generated Q8/Q16 table and preserve output under stalls" in {
    test(new SiluPwl(lanes = 4, segments = 16)) { dut =>
      dut.io.input.valid.poke(false.B)
      dut.io.output.ready.poke(false.B)
      Seq(0, 256, -128, 3000).zipWithIndex.foreach { case (value, lane) =>
        dut.io.input.bits(lane).poke(value.S)
      }
      dut.io.input.valid.poke(true.B)
      dut.clock.step()
      dut.io.input.valid.poke(false.B)

      dut.io.output.valid.expect(true.B)
      Seq(0, 187, -33, 3000).zipWithIndex.foreach { case (value, lane) =>
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
