package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class VectorResultBufferSpec extends AnyFlatSpec with ChiselScalatestTester {
  "VectorResultBuffer" should "retain sequential convolution vectors and return them under output backpressure" in {
    test(new VectorResultBuffer(depthVectors = 4, lanes = 4, addressWidth = 4)) { dut =>
      dut.io.clear.poke(false.B)
      dut.io.input.valid.poke(false.B)
      dut.io.command.valid.poke(false.B)
      dut.io.output.ready.poke(false.B)
      dut.clock.step()

      for (vector <- 0 until 2) {
        for (lane <- 0 until 4) { dut.io.input.bits(lane).poke((vector * 10 + lane).S) }
        dut.io.input.valid.poke(true.B)
        dut.io.input.ready.expect(true.B)
        dut.clock.step()
      }
      dut.io.input.valid.poke(false.B)
      dut.io.occupancy.expect(2.U)

      dut.io.command.bits.baseAddress.poke(0.U)
      dut.io.command.bits.vectors.poke(2.U)
      dut.io.command.valid.poke(true.B)
      dut.io.command.ready.expect(true.B)
      dut.clock.step()
      dut.io.command.valid.poke(false.B)
      dut.io.output.valid.expect(true.B)
      for (lane <- 0 until 4) { dut.io.output.bits(lane).expect(lane.S) }
      dut.clock.step(2)
      dut.io.output.valid.expect(true.B)

      dut.io.output.ready.poke(true.B)
      dut.clock.step()
      for (lane <- 0 until 4) { dut.io.output.bits(lane).expect((10 + lane).S) }
      dut.clock.step()
      dut.io.output.ready.poke(false.B)
      dut.io.done.expect(true.B)
      dut.clock.step()
      dut.io.done.expect(false.B)
    }
  }
}
