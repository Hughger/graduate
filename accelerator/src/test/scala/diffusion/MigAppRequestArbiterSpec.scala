package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util.DecoupledIO
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class MigAppRequestArbiterSpec extends AnyFlatSpec with ChiselScalatestTester {
  private def idle(dut: MigAppRequestArbiter): Unit = {
    dut.io.client0Request.valid.poke(false.B)
    dut.io.client0Response.ready.poke(true.B)
    dut.io.client1Request.valid.poke(false.B)
    dut.io.client1Response.ready.poke(true.B)
    dut.io.client2Request.valid.poke(false.B)
    dut.io.client2Response.ready.poke(true.B)
    dut.io.memoryRequest.ready.poke(false.B)
    dut.io.memoryResponse.valid.poke(false.B)
    dut.io.memoryResponse.bits.poke(0.U)
    dut.io.memoryDone.poke(false.B)
  }

  private def driveWrite(request: DecoupledIO[MigAppRequest], address: BigInt): Unit = {
    request.bits.write.poke(true.B)
    request.bits.address.poke(address.U)
    request.bits.writeData.poke(0.U)
    request.bits.writeMask.poke(0.U)
  }

  "MigAppRequestArbiter" should "prioritize tensor writes, then reads, then debug requests" in {
    test(new MigAppRequestArbiter) { dut =>
      idle(dut)
      driveWrite(dut.io.client0Request, 0)
      driveWrite(dut.io.client1Request, 1)
      driveWrite(dut.io.client2Request, 2)
      dut.io.client0Request.valid.poke(true.B)
      dut.io.client1Request.valid.poke(true.B)
      dut.io.client2Request.valid.poke(true.B)
      dut.io.memoryRequest.ready.poke(true.B)
      dut.io.memoryRequest.valid.expect(true.B)
      dut.io.memoryRequest.bits.address.expect(2.U)
      dut.io.client2Request.ready.expect(true.B)
      dut.io.client1Request.ready.expect(false.B)
      dut.io.client0Request.ready.expect(false.B)
      dut.clock.step()

      dut.io.client0Request.valid.poke(false.B)
      dut.io.client1Request.valid.poke(false.B)
      dut.io.client2Request.valid.poke(false.B)
      dut.io.memoryDone.poke(true.B)
      dut.io.client2Done.expect(true.B)
      dut.clock.step()
      dut.io.memoryDone.poke(false.B)
      dut.io.memoryRequest.valid.expect(false.B)
    }
  }
}