package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class DiffusionAccelTopMemorySpec extends AnyFlatSpec with ChiselScalatestTester {
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
  }

  "DiffusionAccelTop" should "route a memory read through its MIG application port" in {
    test(new DiffusionAccelTop) { dut =>
      idle(dut)
      dut.io.memoryRequest.bits.write.poke(false.B)
      dut.io.memoryRequest.bits.address.poke("h180".U)
      dut.io.memoryRequest.bits.writeData.poke(0.U)
      dut.io.memoryRequest.bits.writeMask.poke(0.U)
      dut.io.memoryRequest.valid.poke(true.B)
      dut.io.memoryRequest.ready.expect(true.B)
      dut.clock.step()
      dut.io.memoryRequest.valid.poke(false.B)

      dut.io.mig.en.expect(true.B)
      dut.io.mig.cmd.expect(MigAppCommand.Read.U)
      dut.io.mig.address.expect("h180".U)
      dut.io.mig.rdy.poke(true.B)
      dut.clock.step()
      dut.io.mig.rdy.poke(false.B)

      dut.io.mig.rdData.poke("h1234".U)
      dut.io.mig.rdDataValid.poke(true.B)
      dut.io.mig.rdDataEnd.poke(true.B)
      dut.clock.step()
      dut.io.mig.rdDataValid.poke(false.B)
      dut.io.memoryResponse.valid.expect(true.B)
      dut.io.memoryResponse.bits.expect("h1234".U)
    }
  }

  it should "keep a write request pending until both MIG channels accept it" in {
    test(new DiffusionAccelTop) { dut =>
      idle(dut)
      dut.io.memoryRequest.bits.write.poke(true.B)
      dut.io.memoryRequest.bits.address.poke("h200".U)
      dut.io.memoryRequest.bits.writeData.poke("h5a".U)
      dut.io.memoryRequest.bits.writeMask.poke(0.U)
      dut.io.memoryRequest.valid.poke(true.B)
      dut.clock.step()
      dut.io.memoryRequest.valid.poke(false.B)

      dut.io.mig.en.expect(true.B)
      dut.io.mig.wdfWren.expect(true.B)
      dut.io.mig.rdy.poke(true.B)
      dut.clock.step()
      dut.io.mig.rdy.poke(false.B)
      dut.io.mig.en.expect(false.B)
      dut.io.mig.wdfWren.expect(true.B)
      dut.io.memoryDone.expect(false.B)

      dut.io.mig.wdfRdy.poke(true.B)
      dut.clock.step()
      dut.io.mig.wdfRdy.poke(false.B)
      dut.io.memoryDone.expect(true.B)
    }
  }
}
