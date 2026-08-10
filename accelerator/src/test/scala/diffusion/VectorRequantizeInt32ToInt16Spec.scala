package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class VectorRequantizeInt32ToInt16Spec extends AnyFlatSpec with ChiselScalatestTester {
  "VectorRequantizeInt32ToInt16" should "round after a programmable shift and saturate for GroupNorm storage" in {
    test(new VectorRequantizeInt32ToInt16(lanes = 4)) { dut =>
      dut.io.input.valid.poke(false.B)
      dut.io.output.ready.poke(false.B)
      dut.io.shift.poke(0.U)
      dut.clock.step()

      Seq(32767, 32768, -32768, -32769).zipWithIndex.foreach { case (value, lane) => dut.io.input.bits(lane).poke(value.S) }
      dut.io.input.valid.poke(true.B)
      dut.clock.step()
      dut.io.input.valid.poke(false.B)
      dut.io.output.valid.expect(true.B)
      Seq(32767, 32767, -32768, -32768).zipWithIndex.foreach { case (value, lane) => dut.io.output.bits(lane).expect(value.S) }
      dut.io.output.ready.poke(true.B)
      dut.clock.step()
      dut.io.output.ready.poke(false.B)

      dut.io.shift.poke(2.U)
      Seq(6, -6, 131070, -131070).zipWithIndex.foreach { case (value, lane) => dut.io.input.bits(lane).poke(value.S) }
      dut.io.input.valid.poke(true.B)
      dut.clock.step()
      dut.io.input.valid.poke(false.B)
      dut.io.output.valid.expect(true.B)
      Seq(2, -2, 32767, -32768).zipWithIndex.foreach { case (value, lane) => dut.io.output.bits(lane).expect(value.S) }
    }
  }
}
