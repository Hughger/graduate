package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class TensorComputeBufferSpec extends AnyFlatSpec with ChiselScalatestTester {
  "TensorComputeBuffer" should "load a DDR beat and reproduce it as a 32-lane activation vector" in {
    test(new TensorComputeBuffer(depth = 64)) { dut =>
      dut.io.loadStart.poke(true.B); dut.io.dmaData.valid.poke(false.B); dut.io.dmaDone.poke(false.B)
      dut.io.vectorCommand.valid.poke(false.B); dut.io.activation.ready.poke(false.B)
      dut.clock.step(); dut.io.loadStart.poke(false.B)
      val beat = (0 until 32).map(i => BigInt((i + 1) & 0xffff) << (16 * i)).foldLeft(BigInt(0))(_ | _)
      dut.io.dmaData.bits.poke(beat.U); dut.io.dmaData.valid.poke(true.B)
      dut.clock.step(); dut.io.dmaData.valid.poke(false.B); dut.io.dmaDone.poke(true.B)
      dut.clock.step(); dut.io.dmaDone.poke(false.B); dut.clock.step(31)
      dut.io.loadDone.expect(true.B); dut.io.occupancy.expect(32.U)

      dut.io.vectorCommand.bits.baseAddress.poke(0.U); dut.io.vectorCommand.bits.vectors.poke(1.U)
      dut.io.vectorCommand.valid.poke(true.B); dut.clock.step(); dut.io.vectorCommand.valid.poke(false.B)
      dut.clock.step(64)
      dut.io.activation.valid.expect(true.B)
      for (lane <- 0 until 32) { dut.io.activation.bits(lane).expect((lane + 1).S) }
      dut.io.activation.ready.poke(true.B); dut.clock.step(); dut.io.vectorDone.expect(true.B)
    }
  }
}
