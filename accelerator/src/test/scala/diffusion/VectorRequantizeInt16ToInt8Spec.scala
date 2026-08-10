package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class VectorRequantizeInt16ToInt8Spec extends AnyFlatSpec with ChiselScalatestTester {
  "VectorRequantizeInt16ToInt8" should "round away from zero after a configurable shift and saturate to INT8" in {
    test(new VectorRequantizeInt16ToInt8(lanes = 4)) { dut =>
      dut.io.input.valid.poke(false.B)
      dut.io.output.ready.poke(false.B)
      dut.io.shift.poke(0.U)
      dut.clock.step()

      Seq(127, 128, -128, -129).zipWithIndex.foreach { case (value, lane) => dut.io.input.bits(lane).poke(value.S) }
      dut.io.input.valid.poke(true.B)
      dut.clock.step()
      dut.io.input.valid.poke(false.B)
      dut.io.output.valid.expect(true.B)
      Seq(127, 127, -128, -128).zipWithIndex.foreach { case (value, lane) => dut.io.output.bits(lane).expect(value.S) }
      dut.io.output.ready.poke(true.B)
      dut.clock.step()
      dut.io.output.ready.poke(false.B)

      dut.io.shift.poke(2.U)
      Seq(6, -6, 5, 511).zipWithIndex.foreach { case (value, lane) => dut.io.input.bits(lane).poke(value.S) }
      dut.io.input.valid.poke(true.B)
      dut.clock.step()
      dut.io.input.valid.poke(false.B)
      dut.io.output.valid.expect(true.B)
      Seq(2, -2, 1, 127).zipWithIndex.foreach { case (value, lane) => dut.io.output.bits(lane).expect(value.S) }
    }
  }
}
