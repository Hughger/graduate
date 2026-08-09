package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class DiffusionAccelTopTensorDmaSpec extends AnyFlatSpec with ChiselScalatestTester {
  private def idle(dut: DiffusionAccelTop): Unit = {
    dut.io.phaseDone.poke(false.B)
    dut.io.axi.aw.bits.poke(0.U); dut.io.axi.aw.valid.poke(false.B)
    dut.io.axi.w.bits.data.poke(0.U); dut.io.axi.w.bits.strb.poke(0.U); dut.io.axi.w.valid.poke(false.B)
    dut.io.axi.b.ready.poke(false.B); dut.io.axi.ar.valid.poke(false.B); dut.io.axi.r.ready.poke(false.B)
    dut.io.memoryRequest.valid.poke(false.B)
    dut.io.memoryResponse.ready.poke(false.B)
    dut.io.tensorReadCommand.valid.poke(false.B)
    dut.io.tensorReadData.ready.poke(false.B)
    dut.io.tensorWriteCommand.valid.poke(false.B)
    dut.io.tensorWriteData.valid.poke(false.B)
    dut.io.mig.rdy.poke(false.B)
    dut.io.mig.wdfRdy.poke(false.B)
    dut.io.mig.rdData.poke(0.U)
    dut.io.mig.rdDataValid.poke(false.B)
    dut.io.mig.rdDataEnd.poke(false.B)
  }

  private def start(dut: DiffusionAccelTop): Unit = {
    dut.io.axi.aw.bits.poke(0.U); dut.io.axi.aw.valid.poke(true.B)
    dut.io.axi.w.bits.data.poke(1.U); dut.io.axi.w.bits.strb.poke("hf".U); dut.io.axi.w.valid.poke(true.B)
    dut.io.axi.b.ready.poke(true.B)
    dut.clock.step()
    dut.io.axi.aw.valid.poke(false.B); dut.io.axi.w.valid.poke(false.B)
    dut.clock.step()
    dut.io.phase.expect(BlockPhase.LoadResidual.U)
  }

  "DiffusionAccelTop" should "serve tensor-read DMA during LoadResidual through the shared MIG transfer" in {
    test(new DiffusionAccelTop) { dut =>
      idle(dut)
      start(dut)
      dut.io.tensorReadCommand.bits.address.poke("h300".U)
      dut.io.tensorReadCommand.bits.beats.poke(1.U)
      dut.io.tensorReadCommand.valid.poke(true.B)
      dut.io.tensorReadCommand.ready.expect(true.B)
      dut.clock.step()
      dut.io.tensorReadCommand.valid.poke(false.B)
      dut.clock.step()

      dut.io.mig.en.expect(true.B)
      dut.io.mig.cmd.expect(MigAppCommand.Read.U)
      dut.io.mig.address.expect("h300".U)
      dut.io.mig.rdy.poke(true.B)
      dut.clock.step()
      dut.io.mig.rdy.poke(false.B)

      dut.io.mig.rdData.poke("hface".U)
      dut.io.mig.rdDataValid.poke(true.B)
      dut.io.mig.rdDataEnd.poke(true.B)
      dut.clock.step()
      dut.io.mig.rdDataValid.poke(false.B)
      dut.clock.step()
      dut.io.tensorReadData.valid.expect(true.B)
      dut.io.tensorReadData.bits.expect("hface".U)
      dut.io.tensorReadData.ready.poke(true.B)
      dut.clock.step()
      dut.io.tensorReadDone.expect(true.B)
      dut.clock.step()
      dut.io.phase.expect(BlockPhase.Gn1Stats.U)
    }
  }
}