package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec
import org.scalatest.matchers.should.Matchers

class DiffusionAccelTopResNetBlockE2ESpec extends AnyFlatSpec with ChiselScalatestTester with Matchers {
  private def idle(dut: DiffusionAccelTop): Unit = {
    dut.io.phaseDone.poke(false.B)
    dut.io.axi.aw.bits.poke(0.U); dut.io.axi.aw.valid.poke(false.B)
    dut.io.axi.w.bits.data.poke(0.U); dut.io.axi.w.bits.strb.poke(0.U); dut.io.axi.w.valid.poke(false.B)
    dut.io.axi.b.ready.poke(false.B); dut.io.axi.ar.valid.poke(false.B); dut.io.axi.r.ready.poke(false.B)
    dut.io.memoryRequest.valid.poke(false.B); dut.io.memoryResponse.ready.poke(false.B)
    dut.io.tensorReadCommand.valid.poke(false.B)
    dut.io.activationReadCommand.valid.poke(false.B); dut.io.activationVector.ready.poke(false.B)
    dut.io.gn1StatsCommand.valid.poke(false.B); dut.io.gn1Stats.ready.poke(false.B)
    dut.io.gn1ConvCommand.valid.poke(false.B); dut.io.gn1ConvWeightWrite.valid.poke(false.B); dut.io.gn1ConvOutput.ready.poke(false.B)
    dut.io.gn1ConvShift.poke(0.U); dut.io.gn1ResultShift.poke(0.U)
    dut.io.gn2StatsCommand.valid.poke(false.B); dut.io.gn2Stats.ready.poke(false.B)
    dut.io.gn2AffineWrite.valid.poke(false.B)
    dut.io.gn2ActivationCommand.valid.poke(false.B); dut.io.gn2Activation.ready.poke(false.B)
    dut.io.gn2ConvCommand.valid.poke(false.B); dut.io.gn2ConvWeightWrite.valid.poke(false.B)
    dut.io.gn2ConvInputShift.poke(0.U); dut.io.gn2ConvOutputShift.poke(0.U)
    dut.io.gn2AddResidual.poke(false.B); dut.io.gn2ConvOutput.ready.poke(false.B)
    dut.io.tensorWriteCommand.valid.poke(false.B); dut.io.tensorWriteData.valid.poke(false.B)
    for (lane <- 0 until 32) {
      dut.io.gn2Temb(lane).poke(0.S); dut.io.gn2Residual(lane).poke(0.S)
    }
    dut.io.mig.rdy.poke(false.B); dut.io.mig.wdfRdy.poke(false.B)
    dut.io.mig.rdData.poke(0.U); dut.io.mig.rdDataValid.poke(false.B); dut.io.mig.rdDataEnd.poke(false.B)
  }

  private def tick(dut: DiffusionAccelTop, memory: Axi64MemoryModel): Unit = {
    memory.driveBeforeClock()
    memory.observeBeforeClock()
    dut.clock.step()
  }

  "DiffusionAccelTop AXI64 ResNetBlock" should "load one tensor beat from behavioral memory before Gn1Stats" in {
    test(new DiffusionAccelTop(memoryBackend = DiffusionMemoryBackend.Axi64)) { dut =>
      val memory = new Axi64MemoryModel(dut.io.axi64, Axi64DelayProfile.immediate)
      val input = Vector.fill(16)(-1) ++ Vector.fill(16)(1)
      idle(dut)
      memory.load512(0x400, ResNetBlockE2EReference.packLanes(input))

      dut.io.axi.aw.bits.poke(0.U); dut.io.axi.aw.valid.poke(true.B)
      dut.io.axi.w.bits.data.poke(1.U); dut.io.axi.w.bits.strb.poke("hf".U); dut.io.axi.w.valid.poke(true.B)
      dut.io.axi.b.ready.poke(true.B)
      tick(dut, memory)
      dut.io.axi.aw.valid.poke(false.B); dut.io.axi.w.valid.poke(false.B)
      tick(dut, memory)
      dut.io.phase.expect(BlockPhase.LoadResidual.U)

      dut.io.tensorReadCommand.bits.address.poke("h400".U)
      dut.io.tensorReadCommand.bits.beats.poke(1.U)
      dut.io.tensorReadCommand.valid.poke(true.B)
      tick(dut, memory)
      dut.io.tensorReadCommand.valid.poke(false.B)

      var completed = false
      for (_ <- 0 until 256 if !completed) {
        completed = dut.io.tensorReadDone.peek().litToBoolean
        tick(dut, memory)
      }
      completed shouldBe true
      dut.io.phase.expect(BlockPhase.Gn1Stats.U)

      dut.io.gn1StatsCommand.bits.baseAddress.poke(0.U)
      dut.io.gn1StatsCommand.bits.vectors.poke(1.U)
      dut.io.gn1StatsCommand.valid.poke(true.B)
      tick(dut, memory)
      dut.io.gn1StatsCommand.valid.poke(false.B)

      var statsSeen = false
      for (_ <- 0 until 256 if !statsSeen) {
        if (dut.io.gn1Stats.valid.peek().litToBoolean) {
          dut.io.gn1Stats.bits.sum.expect(0.S)
          dut.io.gn1Stats.bits.sumSquare.expect(32.U)
          dut.io.gn1Stats.bits.count.expect(32.U)
          dut.io.gn1Stats.ready.poke(true.B)
          statsSeen = true
        }
        tick(dut, memory)
      }
      statsSeen shouldBe true
      dut.io.gn1Stats.ready.poke(false.B)
      var conv1PhaseSeen = false
      for (_ <- 0 until 16 if !conv1PhaseSeen) {
        conv1PhaseSeen = dut.io.phase.peek().litValue == BlockPhase.Gn1Conv1
        tick(dut, memory)
      }
      conv1PhaseSeen shouldBe true

      for (lane <- 0 until 32) {
        dut.io.gn1ConvWeightWrite.bits.row.poke(lane.U)
        dut.io.gn1ConvWeightWrite.bits.column.poke(lane.U)
        dut.io.gn1ConvWeightWrite.bits.data.poke(1.S)
        dut.io.gn1ConvWeightWrite.valid.poke(true.B)
        tick(dut, memory)
      }
      dut.io.gn1ConvWeightWrite.valid.poke(false.B)
      dut.io.gn1ConvCommand.bits.baseAddress.poke(0.U)
      dut.io.gn1ConvCommand.bits.vectors.poke(1.U)
      dut.io.gn1ConvCommand.valid.poke(true.B)
      tick(dut, memory)
      dut.io.gn1ConvCommand.valid.poke(false.B)

      var conv1OutputSeen = false
      for (_ <- 0 until 256 if !conv1OutputSeen) {
        if (dut.io.gn1ConvOutput.valid.peek().litToBoolean) {
          input.zipWithIndex.foreach { case (value, lane) => dut.io.gn1ConvOutput.bits(lane).expect(value.S) }
          dut.io.gn1ConvOutput.ready.poke(true.B)
          conv1OutputSeen = true
        }
        tick(dut, memory)
      }
      conv1OutputSeen shouldBe true
      dut.io.gn1ConvOutput.ready.poke(false.B)

      var gn2StatsPhaseSeen = false
      for (_ <- 0 until 16 if !gn2StatsPhaseSeen) {
        gn2StatsPhaseSeen = dut.io.phase.peek().litValue == BlockPhase.Gn2Stats
        tick(dut, memory)
      }
      gn2StatsPhaseSeen shouldBe true
      dut.io.gn2StatsCommand.bits.vectors.poke(1.U)
      dut.io.gn2StatsCommand.valid.poke(true.B)
      tick(dut, memory)
      dut.io.gn2StatsCommand.valid.poke(false.B)

      var gn2StatsSeen = false
      for (_ <- 0 until 256 if !gn2StatsSeen) {
        if (dut.io.gn2Stats.valid.peek().litToBoolean) {
          dut.io.gn2Stats.bits.sum.expect(0.S)
          dut.io.gn2Stats.bits.sumSquare.expect(32.U)
          dut.io.gn2Stats.bits.count.expect(32.U)
          dut.io.gn2Stats.ready.poke(true.B)
          gn2StatsSeen = true
        }
        tick(dut, memory)
      }
      gn2StatsSeen shouldBe true
      dut.io.gn2Stats.ready.poke(false.B)

      var conv2PhaseSeen = false
      for (_ <- 0 until 16 if !conv2PhaseSeen) {
        conv2PhaseSeen = dut.io.phase.peek().litValue == BlockPhase.Gn2Conv2Residual
        tick(dut, memory)
      }
      conv2PhaseSeen shouldBe true

      for (lane <- 0 until 32) {
        dut.io.gn2AffineWrite.bits.channel.poke(lane.U)
        dut.io.gn2AffineWrite.bits.gamma.poke(256.S)
        dut.io.gn2AffineWrite.bits.beta.poke(0.S)
        dut.io.gn2AffineWrite.valid.poke(true.B)
        tick(dut, memory)
      }
      dut.io.gn2AffineWrite.valid.poke(false.B)
      for (lane <- 0 until 32) {
        dut.io.gn2ConvWeightWrite.bits.row.poke(lane.U)
        dut.io.gn2ConvWeightWrite.bits.column.poke(lane.U)
        dut.io.gn2ConvWeightWrite.bits.data.poke(1.S)
        dut.io.gn2ConvWeightWrite.valid.poke(true.B)
        dut.io.gn2Temb(lane).poke(3.S)
        dut.io.gn2Residual(lane).poke((-2).S)
        tick(dut, memory)
      }
      dut.io.gn2ConvWeightWrite.valid.poke(false.B)
      dut.io.gn2AddResidual.poke(true.B)
      dut.io.gn2ConvCommand.bits.vectors.poke(1.U)
      dut.io.gn2ConvCommand.valid.poke(true.B)
      tick(dut, memory)
      dut.io.gn2ConvCommand.valid.poke(false.B)

      dut.io.gn2ActivationCommand.bits.baseAddress.poke(0.U)
      dut.io.gn2ActivationCommand.bits.vectors.poke(1.U)
      dut.io.gn2ActivationCommand.valid.poke(true.B)
      tick(dut, memory)
      dut.io.gn2ActivationCommand.valid.poke(false.B)

      val expectedActivation = Vector.fill(16)(0) ++ Vector.fill(16)(2)
      val expectedFinal = ResNetBlockE2EReference.finalLanes(input, Vector.fill(32)(3), Vector.fill(32)(-2))
      var activationSeen = false
      var conv2OutputSeen = false
      for (_ <- 0 until 512 if !(activationSeen && conv2OutputSeen)) {
        if (dut.io.gn2Activation.valid.peek().litToBoolean) {
          expectedActivation.zipWithIndex.foreach { case (value, lane) => dut.io.gn2Activation.bits(lane).expect(value.S) }
          dut.io.gn2Activation.ready.poke(true.B)
          activationSeen = true
        }
        if (dut.io.gn2ConvOutput.valid.peek().litToBoolean) {
          expectedFinal.zipWithIndex.foreach { case (value, lane) => dut.io.gn2ConvOutput.bits(lane).expect(value.S) }
          dut.io.gn2ConvOutput.ready.poke(true.B)
          conv2OutputSeen = true
        }
        tick(dut, memory)
      }
      activationSeen shouldBe true
      conv2OutputSeen shouldBe true
      dut.io.gn2Activation.ready.poke(false.B)
      dut.io.gn2ConvOutput.ready.poke(false.B)

      var storePhaseSeen = false
      for (_ <- 0 until 16 if !storePhaseSeen) {
        storePhaseSeen = dut.io.phase.peek().litValue == BlockPhase.StoreOutput
        tick(dut, memory)
      }
      storePhaseSeen shouldBe true
      dut.io.tensorWriteCommand.bits.address.poke("h800".U)
      dut.io.tensorWriteCommand.bits.beats.poke(1.U)
      dut.io.tensorWriteCommand.valid.poke(true.B)
      tick(dut, memory)
      dut.io.tensorWriteCommand.valid.poke(false.B)

      var doneSeen = false
      for (_ <- 0 until 512 if !doneSeen) {
        doneSeen = dut.io.done.peek().litToBoolean
        tick(dut, memory)
      }
      doneSeen shouldBe true
      memory.read512(0x800) shouldBe ResNetBlockE2EReference.packLanes(expectedFinal)
      memory.assertNoProtocolError()
    }
  }
}

