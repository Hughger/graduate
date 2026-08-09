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
      dut.clock.step()
      dut.clock.step(32)
      dut.io.tensorReadDone.expect(true.B)
      dut.clock.step()
      dut.io.phase.expect(BlockPhase.Gn1Stats.U)
      dut.io.gn1StatsCommand.bits.baseAddress.poke(0.U)
      dut.io.gn1StatsCommand.bits.vectors.poke(1.U)
      dut.io.gn1StatsCommand.valid.poke(true.B)
      dut.clock.step()
      dut.io.gn1StatsCommand.valid.poke(false.B)
      dut.clock.step(70)
      dut.io.gn1Stats.valid.expect(true.B)
      dut.io.gn1Stats.bits.sum.expect((-1330).S)
      dut.io.gn1Stats.bits.sumSquare.expect(1768900.U)
      dut.io.gn1Stats.bits.count.expect(32.U)
      dut.io.gn1Stats.ready.poke(true.B)
      dut.clock.step()
      dut.io.gn1StatsDone.expect(true.B)
      dut.clock.step()
      dut.io.phase.expect(BlockPhase.Gn1Conv1.U)
      for (channel <- 0 until 32) {
        dut.io.gn1ConvWeightWrite.bits.row.poke(channel.U)
        dut.io.gn1ConvWeightWrite.bits.column.poke(channel.U)
        dut.io.gn1ConvWeightWrite.bits.data.poke(1.S)
        dut.io.gn1ConvWeightWrite.valid.poke(true.B)
        dut.clock.step()
      }
      dut.io.gn1ConvWeightWrite.valid.poke(false.B)
      dut.io.gn1ConvCommand.bits.baseAddress.poke(0.U)
      dut.io.gn1ConvCommand.bits.vectors.poke(1.U)
      dut.io.gn1ConvCommand.valid.poke(true.B)
      dut.clock.step()
      dut.io.gn1ConvCommand.valid.poke(false.B)
      dut.clock.step(70)
      dut.io.gn1ConvOutput.valid.expect(true.B)
      // FLOOD MAC consumes W8A8, so this is the low INT8 lane of 0xFACE.
      dut.io.gn1ConvOutput.bits(0).expect((-50).S)
      for (lane <- 1 until 32) { dut.io.gn1ConvOutput.bits(lane).expect(0.S) }
      dut.io.gn1ConvOutput.ready.poke(true.B)
      dut.clock.step()
      dut.io.gn1ConvDone.expect(true.B)
      dut.clock.step()
      dut.io.phase.expect(BlockPhase.Gn2Stats.U)
    }
  }
}