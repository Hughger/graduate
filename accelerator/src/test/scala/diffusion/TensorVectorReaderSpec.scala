package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class TensorVectorReaderSpec extends AnyFlatSpec with ChiselScalatestTester {
  "TensorVectorReader" should "assemble 32 signed words and hold the vector under backpressure" in {
    test(new TensorVectorReader(depth = 64)) { dut =>
      dut.io.command.valid.poke(false.B)
      dut.io.bufferReadReq.ready.poke(false.B)
      dut.io.bufferReadResp.valid.poke(false.B)
      dut.io.output.ready.poke(false.B)
      dut.io.command.bits.baseAddress.poke(4.U)
      dut.io.command.bits.vectors.poke(1.U)
      dut.io.command.valid.poke(true.B)
      dut.clock.step()
      dut.io.command.valid.poke(false.B)

      for (lane <- 0 until 32) {
        dut.io.bufferReadReq.valid.expect(true.B)
        dut.io.bufferReadReq.bits.expect((4 + lane).U)
        dut.io.bufferReadReq.ready.poke(true.B)
        dut.clock.step()
        dut.io.bufferReadReq.ready.poke(false.B)
        val encoded = BigInt((lane - 16) & 0xffff)
        dut.io.bufferReadResp.bits.poke(encoded.U)
        dut.io.bufferReadResp.valid.poke(true.B)
        dut.clock.step()
        dut.io.bufferReadResp.valid.poke(false.B)
      }
      dut.io.output.valid.expect(true.B)
      for (lane <- 0 until 32) { dut.io.output.bits(lane).expect((lane - 16).S) }
      dut.clock.step(2)
      dut.io.output.valid.expect(true.B)
      dut.io.output.ready.poke(true.B)
      dut.clock.step()
      dut.io.done.expect(true.B)
    }
  }
}
