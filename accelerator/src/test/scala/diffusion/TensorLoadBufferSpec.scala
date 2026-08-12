package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class TensorLoadBufferSpec extends AnyFlatSpec with ChiselScalatestTester {
  private def idle(dut: TensorLoadBuffer): Unit = {
    dut.io.start.poke(false.B)
    dut.io.sourceDone.poke(false.B)
    dut.io.input.valid.poke(false.B)
    dut.io.readReq.valid.poke(false.B)
    dut.io.readResp.ready.poke(false.B)
  }

  "TensorLoadBuffer" should "unpack one 512-bit beat into 32 signed-activation words before completing" in {
    test(new TensorLoadBuffer(depth = 64)) { dut =>
      idle(dut)
      dut.io.start.poke(true.B)
      dut.clock.step()
      dut.io.start.poke(false.B)

      val beat = (0 until 32).map(i => BigInt(i) << (16 * i)).foldLeft(BigInt(0))(_ | _)
      dut.io.input.bits.poke(beat.U)
      dut.io.input.valid.poke(true.B)
      dut.io.input.ready.expect(true.B)
      dut.clock.step()
      dut.io.input.valid.poke(false.B)
      dut.io.sourceDone.poke(true.B)
      dut.clock.step()
      dut.io.sourceDone.poke(false.B)
      for (_ <- 0 until 31) { dut.clock.step() }
      dut.io.done.expect(true.B)
      dut.io.occupancy.expect(32.U)

      def read(address: Int, expected: Int): Unit = {
        dut.io.readReq.bits.poke(address.U)
        dut.io.readReq.valid.poke(true.B)
        dut.io.readReq.ready.expect(true.B)
        dut.clock.step()
        dut.io.readReq.valid.poke(false.B)
        dut.io.readResp.valid.expect(true.B)
        dut.io.readResp.bits.expect(expected.U)
        dut.io.readResp.ready.poke(true.B)
        dut.clock.step()
        dut.io.readResp.ready.poke(false.B)
      }
      read(0, 0)
      read(17, 17)
      read(31, 31)
    }
  }

  it should "clear occupancy before accepting a second load" in {
    test(new TensorLoadBuffer(depth = 64)) { dut =>
      idle(dut)
      val first = (0 until 32).map(i => BigInt(i) << (16 * i)).foldLeft(BigInt(0))(_ | _)
      val second = (0 until 32).map(i => BigInt(0x100 + i) << (16 * i)).foldLeft(BigInt(0))(_ | _)

      def load(word: BigInt): Unit = {
        dut.io.start.poke(true.B)
        dut.io.input.valid.poke(false.B)
        dut.clock.step()
        dut.io.start.poke(false.B)
        dut.io.input.bits.poke(word.U)
        dut.io.input.valid.poke(true.B)
        dut.io.input.ready.expect(true.B)
        dut.clock.step()
        dut.io.input.valid.poke(false.B)
        dut.io.sourceDone.poke(true.B)
        dut.clock.step()
        dut.io.sourceDone.poke(false.B)
        for (_ <- 0 until 31) { dut.clock.step() }
        dut.io.done.expect(true.B)
      }

      load(first)
      dut.io.occupancy.expect(32.U)
      dut.io.start.poke(true.B)
      dut.io.input.valid.poke(true.B)
      dut.io.input.ready.expect(false.B)
      dut.clock.step()
      dut.io.start.poke(false.B)
      dut.io.input.valid.poke(false.B)
      dut.io.occupancy.expect(0.U)
      dut.io.input.ready.expect(true.B)

      dut.io.input.bits.poke(second.U)
      dut.io.input.valid.poke(true.B)
      dut.clock.step()
      dut.io.input.valid.poke(false.B)
      dut.io.sourceDone.poke(true.B)
      dut.clock.step()
      dut.io.sourceDone.poke(false.B)
      for (_ <- 0 until 31) { dut.clock.step() }
      dut.io.done.expect(true.B)
      dut.io.occupancy.expect(32.U)
      dut.io.readReq.bits.poke(0.U)
      dut.io.readReq.valid.poke(true.B)
      dut.io.readReq.ready.expect(true.B)
      dut.clock.step()
      dut.io.readReq.valid.poke(false.B)
      dut.io.readResp.valid.expect(true.B)
      dut.io.readResp.bits.expect(0x100.U)
    }
  }
}
