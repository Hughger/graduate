package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class TensorTileBufferSpec extends AnyFlatSpec with ChiselScalatestTester {
  "TensorTileBuffer" should "prioritize writes, return synchronous reads, and track occupancy" in {
    test(new TensorTileBuffer(depth = 8, dataWidth = 16)) { dut =>
      dut.io.write.valid.poke(false.B)
      dut.io.readReq.valid.poke(false.B)
      dut.io.readResp.ready.poke(false.B)
      dut.clock.step()

      def write(address: Int, value: Int): Unit = {
        dut.io.write.bits.address.poke(address.U)
        dut.io.write.bits.data.poke(value.U)
        dut.io.write.valid.poke(true.B)
        dut.io.write.ready.expect(true.B)
        dut.clock.step()
        dut.io.write.valid.poke(false.B)
      }
      write(3, 0x1234)
      write(5, 0x00ff)
      dut.io.occupancy.expect(2.U)
      dut.io.highWater.expect(2.U)

      dut.io.write.bits.address.poke(1.U)
      dut.io.write.bits.data.poke(0.U)
      dut.io.write.valid.poke(true.B)
      dut.io.readReq.bits.poke(3.U)
      dut.io.readReq.valid.poke(true.B)
      dut.io.write.ready.expect(true.B)
      dut.io.readReq.ready.expect(false.B)
      dut.clock.step()
      dut.io.write.valid.poke(false.B)

      dut.io.readReq.valid.poke(true.B)
      dut.io.readReq.bits.poke(3.U)
      dut.io.readReq.ready.expect(true.B)
      dut.clock.step()
      dut.io.readReq.valid.poke(false.B)
      while (!dut.io.readResp.valid.peek().litToBoolean) { dut.clock.step() }
      dut.io.readResp.bits.expect(0x1234.U)
      dut.clock.step(2)
      dut.io.readResp.valid.expect(true.B)
      dut.io.readResp.ready.poke(true.B)
      dut.clock.step()
      dut.io.readResp.valid.expect(false.B)
      dut.io.occupancy.expect(3.U)
      dut.io.highWater.expect(3.U)
    }
  }
}
