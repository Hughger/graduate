package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class DiffusionAccelTopInternalStoreSpec extends AnyFlatSpec with ChiselScalatestTester {
  private def idle(dut: DiffusionAccelTop): Unit = {
    dut.io.phaseDone.poke(false.B); dut.io.axi.aw.bits.poke(0.U); dut.io.axi.aw.valid.poke(false.B)
    dut.io.axi.w.bits.data.poke(0.U); dut.io.axi.w.bits.strb.poke(0.U); dut.io.axi.w.valid.poke(false.B)
    dut.io.axi.b.ready.poke(false.B); dut.io.axi.ar.valid.poke(false.B); dut.io.axi.r.ready.poke(false.B)
    dut.io.memoryRequest.valid.poke(false.B); dut.io.memoryResponse.ready.poke(false.B); dut.io.tensorReadCommand.valid.poke(false.B)
    dut.io.activationReadCommand.valid.poke(false.B); dut.io.activationVector.ready.poke(false.B)
    dut.io.gn1StatsCommand.valid.poke(false.B); dut.io.gn1Stats.ready.poke(false.B)
    dut.io.gn1ConvCommand.valid.poke(false.B); dut.io.gn1ConvWeightWrite.valid.poke(false.B); dut.io.gn1ConvOutput.ready.poke(true.B)
    dut.io.gn1ConvShift.poke(0.U); dut.io.gn1ResultShift.poke(0.U)
    dut.io.gn2StatsCommand.valid.poke(false.B); dut.io.gn2Stats.ready.poke(true.B); dut.io.gn2AffineWrite.valid.poke(false.B)
    dut.io.gn2ActivationCommand.valid.poke(false.B); dut.io.gn2Activation.ready.poke(true.B)
    dut.io.gn2ConvCommand.valid.poke(false.B); dut.io.gn2ConvWeightWrite.valid.poke(false.B); dut.io.gn2ConvInputShift.poke(0.U); dut.io.gn2ConvOutputShift.poke(0.U)
    dut.io.gn2AddResidual.poke(false.B); dut.io.gn2ConvOutput.ready.poke(true.B)
    for (lane <- 0 until 32) { dut.io.gn2Temb(lane).poke(0.S); dut.io.gn2Residual(lane).poke(0.S) }
    dut.io.tensorWriteCommand.valid.poke(false.B); dut.io.tensorWriteData.valid.poke(false.B)
    dut.io.mig.rdy.poke(false.B); dut.io.mig.wdfRdy.poke(false.B); dut.io.mig.rdData.poke(0.U); dut.io.mig.rdDataValid.poke(false.B); dut.io.mig.rdDataEnd.poke(false.B)
  }

  "DiffusionAccelTop" should "write a fused internal vector through StoreOutput without external write data" in {
    test(new DiffusionAccelTop) { dut =>
      idle(dut)
      dut.io.axi.aw.bits.poke(0.U); dut.io.axi.aw.valid.poke(true.B); dut.io.axi.w.bits.data.poke(1.U); dut.io.axi.w.bits.strb.poke("hf".U); dut.io.axi.w.valid.poke(true.B); dut.io.axi.b.ready.poke(true.B)
      dut.clock.step(); dut.io.axi.aw.valid.poke(false.B); dut.io.axi.w.valid.poke(false.B); dut.clock.step()
      dut.io.tensorReadCommand.bits.address.poke("h300".U); dut.io.tensorReadCommand.bits.beats.poke(1.U); dut.io.tensorReadCommand.valid.poke(true.B); dut.clock.step(); dut.io.tensorReadCommand.valid.poke(false.B); dut.clock.step()
      dut.io.mig.rdy.poke(true.B); dut.clock.step(); dut.io.mig.rdy.poke(false.B)
      dut.io.mig.rdData.poke(0.U); dut.io.mig.rdDataValid.poke(true.B); dut.io.mig.rdDataEnd.poke(true.B); dut.clock.step(); dut.io.mig.rdDataValid.poke(false.B)
      dut.clock.step(36); dut.io.phase.expect(BlockPhase.Gn1Stats.U)

      dut.io.gn1StatsCommand.bits.baseAddress.poke(0.U); dut.io.gn1StatsCommand.bits.vectors.poke(1.U); dut.io.gn1StatsCommand.valid.poke(true.B); dut.clock.step(); dut.io.gn1StatsCommand.valid.poke(false.B)
      dut.clock.step(70); dut.io.gn1Stats.valid.expect(true.B)
      dut.io.gn1Stats.ready.poke(true.B); dut.clock.step(); dut.io.gn1StatsDone.expect(true.B)
      dut.clock.step(); dut.io.phase.expect(BlockPhase.Gn1Conv1.U)

      dut.io.gn1ConvCommand.bits.baseAddress.poke(0.U); dut.io.gn1ConvCommand.bits.vectors.poke(1.U); dut.io.gn1ConvCommand.valid.poke(true.B); dut.clock.step(); dut.io.gn1ConvCommand.valid.poke(false.B)
      dut.clock.step(72); dut.io.phase.expect(BlockPhase.Gn2Stats.U)

      dut.io.gn2StatsCommand.bits.vectors.poke(1.U); dut.io.gn2StatsCommand.valid.poke(true.B); dut.clock.step(); dut.io.gn2StatsCommand.valid.poke(false.B)
      dut.clock.step(4); dut.io.phase.expect(BlockPhase.Gn2Conv2Residual.U)

      dut.io.gn2ConvCommand.bits.vectors.poke(1.U); dut.io.gn2ConvCommand.valid.poke(true.B)
      dut.io.gn2ActivationCommand.bits.baseAddress.poke(0.U); dut.io.gn2ActivationCommand.bits.vectors.poke(1.U); dut.io.gn2ActivationCommand.valid.poke(true.B)
      dut.clock.step(); dut.io.gn2ConvCommand.valid.poke(false.B); dut.io.gn2ActivationCommand.valid.poke(false.B)
      dut.clock.step(8); dut.io.phase.expect(BlockPhase.StoreOutput.U)

      dut.io.tensorWriteCommand.bits.address.poke("h440".U); dut.io.tensorWriteCommand.bits.beats.poke(1.U); dut.io.tensorWriteCommand.valid.poke(true.B); dut.clock.step(); dut.io.tensorWriteCommand.valid.poke(false.B)
      dut.clock.step(5); dut.io.mig.en.expect(true.B); dut.io.mig.wdfWren.expect(true.B); dut.io.mig.wdfData.expect(0.U)
      dut.io.mig.rdy.poke(true.B); dut.io.mig.wdfRdy.poke(true.B); dut.clock.step(); dut.io.mig.rdy.poke(false.B); dut.io.mig.wdfRdy.poke(false.B)
      dut.clock.step(2); dut.io.done.expect(true.B)
    }
  }
}
