package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class DiffusionAccelTopTensorWriteDmaSpec extends AnyFlatSpec with ChiselScalatestTester {
  private def idle(dut: DiffusionAccelTop): Unit = {
    dut.io.phaseDone.poke(false.B)
    dut.io.axi.aw.bits.poke(0.U); dut.io.axi.aw.valid.poke(false.B)
    dut.io.axi.w.bits.data.poke(0.U); dut.io.axi.w.bits.strb.poke(0.U); dut.io.axi.w.valid.poke(false.B)
    dut.io.axi.b.ready.poke(false.B); dut.io.axi.ar.valid.poke(false.B); dut.io.axi.r.ready.poke(false.B)
    dut.io.memoryRequest.valid.poke(false.B)
    dut.io.memoryResponse.ready.poke(false.B)
    dut.io.tensorReadCommand.valid.poke(false.B)
    dut.io.activationReadCommand.valid.poke(false.B)
    dut.io.activationVector.ready.poke(false.B)
    dut.io.gn1StatsCommand.valid.poke(false.B)
    dut.io.gn1Stats.ready.poke(false.B)
    dut.io.gn1ConvCommand.valid.poke(false.B)
    dut.io.gn1ConvWeightWrite.valid.poke(false.B)
    dut.io.gn1ConvOutput.ready.poke(false.B)
    dut.io.tensorWriteCommand.valid.poke(false.B)
    dut.io.tensorWriteData.valid.poke(false.B)
    dut.io.mig.rdy.poke(false.B)
    dut.io.mig.wdfRdy.poke(false.B)
    dut.io.mig.rdData.poke(0.U)
    dut.io.mig.rdDataValid.poke(false.B)
    dut.io.mig.rdDataEnd.poke(false.B)
  }

  private def startAndReachStore(dut: DiffusionAccelTop): Unit = {
    dut.io.axi.aw.bits.poke(0.U); dut.io.axi.aw.valid.poke(true.B)
    dut.io.axi.w.bits.data.poke(1.U); dut.io.axi.w.bits.strb.poke("hf".U); dut.io.axi.w.valid.poke(true.B)
    dut.io.axi.b.ready.poke(true.B)
    dut.clock.step()
    dut.io.axi.aw.valid.poke(false.B); dut.io.axi.w.valid.poke(false.B)
    dut.clock.step()
    dut.io.phase.expect(BlockPhase.LoadResidual.U)

    // A zero-beat load still proves that LoadResidual is DMA-controlled.
    dut.io.tensorReadCommand.bits.address.poke(0.U)
    dut.io.tensorReadCommand.bits.beats.poke(0.U)
    dut.io.tensorReadCommand.valid.poke(true.B)
    dut.clock.step()
    dut.io.tensorReadCommand.valid.poke(false.B)
    dut.clock.step(2)
    dut.io.phase.expect(BlockPhase.Gn1Stats.U)

    dut.io.gn1StatsCommand.bits.baseAddress.poke(0.U)
    dut.io.gn1StatsCommand.bits.vectors.poke(0.U)
    dut.io.gn1StatsCommand.valid.poke(true.B)
    dut.clock.step()
    dut.io.gn1StatsCommand.valid.poke(false.B)
    dut.clock.step()

    dut.io.phase.expect(BlockPhase.Gn1Conv1.U)
    dut.io.gn1ConvCommand.bits.baseAddress.poke(0.U)
    dut.io.gn1ConvCommand.bits.vectors.poke(0.U)
    dut.io.gn1ConvCommand.valid.poke(true.B)
    dut.clock.step()
    dut.io.gn1ConvCommand.valid.poke(false.B)
    dut.clock.step()

    dut.io.phaseDone.poke(true.B)
    dut.clock.step(2)
    dut.io.phaseDone.poke(false.B)
    dut.io.phase.expect(BlockPhase.StoreOutput.U)
  }

  "DiffusionAccelTop" should "serve tensor-write DMA during StoreOutput through the shared MIG transfer" in {
    test(new DiffusionAccelTop) { dut =>
      idle(dut)
      startAndReachStore(dut)
      dut.io.tensorWriteCommand.bits.address.poke("h440".U)
      dut.io.tensorWriteCommand.bits.beats.poke(1.U)
      dut.io.tensorWriteCommand.valid.poke(true.B)
      dut.clock.step()
      dut.io.tensorWriteCommand.valid.poke(false.B)
      dut.io.tensorWriteData.ready.expect(true.B)

      dut.io.tensorWriteData.bits.poke("hcafe".U)
      dut.io.tensorWriteData.valid.poke(true.B)
      dut.clock.step()
      dut.io.tensorWriteData.valid.poke(false.B)
      dut.clock.step()
      dut.io.mig.en.expect(true.B)
      dut.io.mig.wdfWren.expect(true.B)
      dut.io.mig.cmd.expect(MigAppCommand.Write.U)
      dut.io.mig.address.expect("h440".U)
      dut.io.mig.wdfData.expect("hcafe".U)

      dut.io.mig.rdy.poke(true.B)
      dut.io.mig.wdfRdy.poke(true.B)
      dut.clock.step()
      dut.io.mig.rdy.poke(false.B)
      dut.io.mig.wdfRdy.poke(false.B)
      dut.clock.step()
      dut.io.tensorWriteDone.expect(true.B)
      dut.clock.step()
      dut.io.done.expect(true.B)
    }
  }
}