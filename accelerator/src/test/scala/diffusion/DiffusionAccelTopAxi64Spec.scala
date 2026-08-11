package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class DiffusionAccelTopAxi64Spec extends AnyFlatSpec with ChiselScalatestTester {
  private def idle(dut: DiffusionAccelTop): Unit = {
    dut.io.phaseDone.poke(false.B)
    dut.io.axi.aw.bits.poke(0.U); dut.io.axi.aw.valid.poke(false.B)
    dut.io.axi.w.bits.data.poke(0.U); dut.io.axi.w.bits.strb.poke(0.U); dut.io.axi.w.valid.poke(false.B)
    dut.io.axi.b.ready.poke(false.B); dut.io.axi.ar.valid.poke(false.B); dut.io.axi.r.ready.poke(false.B)
    dut.io.memoryRequest.valid.poke(false.B)
    dut.io.memoryResponse.ready.poke(false.B)
    dut.io.mig.rdy.poke(false.B)
    dut.io.mig.wdfRdy.poke(false.B)
    dut.io.mig.rdData.poke(0.U)
    dut.io.mig.rdDataValid.poke(false.B)
    dut.io.mig.rdDataEnd.poke(false.B)
    dut.io.axi64.aw.ready.poke(false.B)
    dut.io.axi64.w.ready.poke(false.B)
    dut.io.axi64.b.valid.poke(false.B)
    dut.io.axi64.b.bits.id.poke(0.U)
    dut.io.axi64.b.bits.resp.poke(0.U)
    dut.io.axi64.ar.ready.poke(false.B)
    dut.io.axi64.r.valid.poke(false.B)
    dut.io.axi64.r.bits.data.poke(0.U)
    dut.io.axi64.r.bits.id.poke(0.U)
    dut.io.axi64.r.bits.resp.poke(0.U)
    dut.io.axi64.r.bits.last.poke(false.B)
  }

  private def submitRead(dut: DiffusionAccelTop, address: BigInt): Unit = {
    dut.io.memoryRequest.bits.write.poke(false.B)
    dut.io.memoryRequest.bits.address.poke(address.U)
    dut.io.memoryRequest.bits.writeData.poke(0.U)
    dut.io.memoryRequest.bits.writeMask.poke(0.U)
    dut.io.memoryRequest.valid.poke(true.B)
    dut.io.memoryRequest.ready.expect(true.B)
    dut.clock.step()
    dut.io.memoryRequest.valid.poke(false.B)
  }

  "DiffusionAccelTop" should "keep AXI64 inactive for the default MIG backend" in {
    test(new DiffusionAccelTop) { dut =>
      idle(dut)
      submitRead(dut, 0x180)
      dut.io.mig.en.expect(true.B)
      dut.io.mig.cmd.expect(MigAppCommand.Read.U)
      dut.io.axi64.aw.valid.expect(false.B)
      dut.io.axi64.w.valid.expect(false.B)
      dut.io.axi64.ar.valid.expect(false.B)
    }
  }

  it should "route a read through the AXI64 backend while MIG remains inactive" in {
    test(new DiffusionAccelTop(memoryBackend = DiffusionMemoryBackend.Axi64)) { dut =>
      idle(dut)
      submitRead(dut, 0x300)
      dut.io.mig.en.expect(false.B)
      dut.io.mig.wdfWren.expect(false.B)
      dut.io.axi64.ar.valid.expect(true.B)
      dut.io.axi64.ar.bits.addr.expect("h300".U)
      dut.io.axi64.ar.bits.id.expect(0.U)
      dut.io.axi64.ar.bits.len.expect(7.U)
      dut.io.axi64.ar.bits.size.expect(3.U)
      dut.io.axi64.ar.ready.poke(true.B)
      dut.clock.step()
      dut.io.axi64.ar.ready.poke(false.B)

      val beats = (0 until 8).map(index => BigInt(index + 1))
      for ((beat, index) <- beats.zipWithIndex) {
        dut.io.axi64.r.ready.expect(true.B)
        dut.io.axi64.r.bits.data.poke(beat.U)
        dut.io.axi64.r.bits.id.poke(0.U)
        dut.io.axi64.r.bits.resp.poke(0.U)
        dut.io.axi64.r.bits.last.poke((index == 7).B)
        dut.io.axi64.r.valid.poke(true.B)
        dut.clock.step()
        dut.io.axi64.r.valid.poke(false.B)
      }

      val expected = beats.zipWithIndex.map { case (value, index) => value << (64 * index) }.sum
      dut.io.memoryResponse.valid.expect(true.B)
      dut.io.memoryResponse.bits.expect(expected.U)
    }
  }
}
