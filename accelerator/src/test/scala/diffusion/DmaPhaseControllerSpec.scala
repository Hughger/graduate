package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class DmaPhaseControllerSpec extends AnyFlatSpec with ChiselScalatestTester {
  private def idle(dut: DmaPhaseController): Unit = {
    dut.io.phase.poke(BlockPhase.Idle.U)
    dut.io.externalPhaseDone.poke(false.B)
    dut.io.readCommand.valid.poke(false.B)
    dut.io.readDmaCommand.ready.poke(false.B)
    dut.io.readDone.poke(false.B)
    dut.io.writeCommand.valid.poke(false.B)
    dut.io.writeDmaCommand.ready.poke(false.B)
    dut.io.writeDone.poke(false.B)
  }

  "DmaPhaseController" should "gate load and store phase completion on their DMA engines" in {
    test(new DmaPhaseController) { dut =>
      idle(dut)
      dut.io.phase.poke(BlockPhase.LoadResidual.U)
      dut.io.externalPhaseDone.poke(true.B)
      dut.io.readCommand.bits.address.poke("h80".U)
      dut.io.readCommand.bits.beats.poke(1.U)
      dut.io.readCommand.valid.poke(true.B)
      dut.io.readDmaCommand.ready.poke(true.B)
      dut.io.readDmaCommand.valid.expect(true.B)
      dut.io.phaseDone.expect(false.B)
      dut.clock.step()
      dut.io.readCommand.valid.poke(false.B)
      dut.io.readDmaCommand.valid.expect(false.B)
      dut.io.readDone.poke(true.B)
      dut.io.phaseDone.expect(true.B)

      dut.io.phase.poke(BlockPhase.Gn1Stats.U)
      dut.io.readDone.poke(false.B)
      dut.io.phaseDone.expect(true.B)

      dut.io.phase.poke(BlockPhase.StoreOutput.U)
      dut.io.writeCommand.bits.address.poke("h100".U)
      dut.io.writeCommand.bits.beats.poke(1.U)
      dut.io.writeCommand.valid.poke(true.B)
      dut.io.writeDmaCommand.ready.poke(true.B)
      dut.io.writeDmaCommand.valid.expect(true.B)
      dut.io.phaseDone.expect(false.B)
      dut.clock.step()
      dut.io.writeCommand.valid.poke(false.B)
      dut.io.writeDone.poke(true.B)
      dut.io.phaseDone.expect(true.B)
    }
  }
}
