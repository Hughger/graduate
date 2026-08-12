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
      val memory = new Axi64MemoryModel(dut.io.axi64, Axi64DelayProfile.staggered)
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
      memory.delayedChannels shouldBe Set("AW", "W", "B", "AR", "R")
    }
  }

  it should "preserve two DMA vectors and write both fixed-point results in order" in {
    test(new DiffusionAccelTop(memoryBackend = DiffusionMemoryBackend.Axi64)) { dut =>
      val memory = new Axi64MemoryModel(dut.io.axi64, Axi64DelayProfile.staggered)
      val input0 = Vector.fill(16)(-1) ++ Vector.fill(16)(1)
      val input1 = Vector.fill(16)(1) ++ Vector.fill(16)(-1)
      val inputs = Vector(input0, input1)
      val temb = Vector.fill(32)(3); val residual = Vector.fill(32)(-2)
      val expected = inputs.map(ResNetBlockE2EReference.finalLanes(_, temb, residual))
      val expectedActivation = inputs.map(_.map(lane => if (lane < 0) 0 else 2))
      val conv1 = scala.collection.mutable.ArrayBuffer.empty[Vector[Int]]
      val activation = scala.collection.mutable.ArrayBuffer.empty[Vector[Int]]
      val conv2 = scala.collection.mutable.ArrayBuffer.empty[Vector[Int]]
      def waitFor(label: String, limit: Int)(p: => Boolean): Unit = {
        var met = false
        for (_ <- 0 until limit if !met) { met = p; if (!met) tick(dut, memory) }
        assert(met, s"timeout waiting for $label")
      }
      def send(label: String, ready: => Boolean)(drive: Boolean => Unit): Unit = {
        drive(true); waitFor(label, 128)(ready); tick(dut, memory); drive(false)
      }
      def capture(output: Vec[SInt], valid: Bool, ready: Bool, target: scala.collection.mutable.ArrayBuffer[Vector[Int]]): Unit = {
        for (_ <- 0 until 1024 if target.size < 2) {
          ready.poke(false.B)
          if (valid.peek().litToBoolean) { target += Vector.tabulate(32)(i => output(i).peek().litValue.toInt); ready.poke(true.B) }
          tick(dut, memory)
        }
        ready.poke(false.B); target.size shouldBe 2
      }

      idle(dut)
      memory.load512(0x400, ResNetBlockE2EReference.packLanes(input0))
      memory.load512(0x440, ResNetBlockE2EReference.packLanes(input1))
      dut.io.axi.aw.bits.poke(0.U); dut.io.axi.aw.valid.poke(true.B)
      dut.io.axi.w.bits.data.poke(1.U); dut.io.axi.w.bits.strb.poke("hf".U); dut.io.axi.w.valid.poke(true.B); dut.io.axi.b.ready.poke(true.B)
      tick(dut, memory); dut.io.axi.aw.valid.poke(false.B); dut.io.axi.w.valid.poke(false.B); tick(dut, memory)
      dut.io.phase.expect(BlockPhase.LoadResidual.U)

      dut.io.tensorReadCommand.bits.address.poke("h400".U); dut.io.tensorReadCommand.bits.beats.poke(2.U)
      send("two-beat read command", dut.io.tensorReadCommand.ready.peek().litToBoolean)(v => dut.io.tensorReadCommand.valid.poke(v.B))
      waitFor("two-beat read", 1024)(dut.io.tensorReadDone.peek().litToBoolean)
      waitFor("Gn1Stats", 256)(dut.io.phase.peek().litValue == BlockPhase.Gn1Stats)
      dut.io.gn1StatsCommand.bits.baseAddress.poke(0.U); dut.io.gn1StatsCommand.bits.vectors.poke(2.U)
      send("GN1 stats command", dut.io.gn1StatsCommand.ready.peek().litToBoolean)(v => dut.io.gn1StatsCommand.valid.poke(v.B))
      waitFor("GN1 stats", 1024) {
        if (dut.io.gn1Stats.valid.peek().litToBoolean) { dut.io.gn1Stats.bits.sum.expect(0.S); dut.io.gn1Stats.bits.sumSquare.expect(64.U); dut.io.gn1Stats.bits.count.expect(64.U); dut.io.gn1Stats.ready.poke(true.B); tick(dut, memory); dut.io.gn1Stats.ready.poke(false.B); true } else false
      }
      waitFor("Gn1Conv1", 256)(dut.io.phase.peek().litValue == BlockPhase.Gn1Conv1)
      for (i <- 0 until 32) { dut.io.gn1ConvWeightWrite.bits.row.poke(i.U); dut.io.gn1ConvWeightWrite.bits.column.poke(i.U); dut.io.gn1ConvWeightWrite.bits.data.poke(1.S); dut.io.gn1ConvWeightWrite.valid.poke(true.B); tick(dut, memory) }
      dut.io.gn1ConvWeightWrite.valid.poke(false.B); dut.io.gn1ConvCommand.bits.baseAddress.poke(0.U); dut.io.gn1ConvCommand.bits.vectors.poke(2.U)
      send("GN1 conv command", dut.io.gn1ConvCommand.ready.peek().litToBoolean)(v => dut.io.gn1ConvCommand.valid.poke(v.B))
      capture(dut.io.gn1ConvOutput.bits, dut.io.gn1ConvOutput.valid, dut.io.gn1ConvOutput.ready, conv1); conv1.toVector shouldBe inputs
      waitFor("Gn2Stats", 256)(dut.io.phase.peek().litValue == BlockPhase.Gn2Stats)
      dut.io.gn2StatsCommand.bits.vectors.poke(2.U)
      send("GN2 stats command", dut.io.gn2StatsCommand.ready.peek().litToBoolean)(v => dut.io.gn2StatsCommand.valid.poke(v.B))
      waitFor("GN2 stats", 1024) {
        if (dut.io.gn2Stats.valid.peek().litToBoolean) { dut.io.gn2Stats.bits.sum.expect(0.S); dut.io.gn2Stats.bits.sumSquare.expect(64.U); dut.io.gn2Stats.bits.count.expect(64.U); dut.io.gn2Stats.ready.poke(true.B); tick(dut, memory); dut.io.gn2Stats.ready.poke(false.B); true } else false
      }
      waitFor("Gn2Conv2Residual", 256)(dut.io.phase.peek().litValue == BlockPhase.Gn2Conv2Residual)
      for (i <- 0 until 32) {
        dut.io.gn2AffineWrite.bits.channel.poke(i.U); dut.io.gn2AffineWrite.bits.gamma.poke(256.S); dut.io.gn2AffineWrite.bits.beta.poke(0.S); dut.io.gn2AffineWrite.valid.poke(true.B)
        dut.io.gn2ConvWeightWrite.bits.row.poke(i.U); dut.io.gn2ConvWeightWrite.bits.column.poke(i.U); dut.io.gn2ConvWeightWrite.bits.data.poke(1.S); dut.io.gn2ConvWeightWrite.valid.poke(true.B)
        dut.io.gn2Temb(i).poke(3.S); dut.io.gn2Residual(i).poke((-2).S); tick(dut, memory)
      }
      dut.io.gn2AffineWrite.valid.poke(false.B); dut.io.gn2ConvWeightWrite.valid.poke(false.B); dut.io.gn2AddResidual.poke(true.B)
      dut.io.gn2ConvCommand.bits.vectors.poke(2.U); send("GN2 conv command", dut.io.gn2ConvCommand.ready.peek().litToBoolean)(v => dut.io.gn2ConvCommand.valid.poke(v.B))
      dut.io.gn2ActivationCommand.bits.baseAddress.poke(0.U); dut.io.gn2ActivationCommand.bits.vectors.poke(2.U); send("GN2 activation command", dut.io.gn2ActivationCommand.ready.peek().litToBoolean)(v => dut.io.gn2ActivationCommand.valid.poke(v.B))
      for (_ <- 0 until 1024 if activation.size < 2 || conv2.size < 2) {
        dut.io.gn2Activation.ready.poke(false.B); dut.io.gn2ConvOutput.ready.poke(false.B)
        if (dut.io.gn2Activation.valid.peek().litToBoolean) { activation += Vector.tabulate(32)(i => dut.io.gn2Activation.bits(i).peek().litValue.toInt); dut.io.gn2Activation.ready.poke(true.B) }
        if (dut.io.gn2ConvOutput.valid.peek().litToBoolean) { conv2 += Vector.tabulate(32)(i => dut.io.gn2ConvOutput.bits(i).peek().litValue.toInt); dut.io.gn2ConvOutput.ready.poke(true.B) }
        tick(dut, memory)
      }
      dut.io.gn2Activation.ready.poke(false.B); dut.io.gn2ConvOutput.ready.poke(false.B)
      activation.toVector shouldBe expectedActivation; conv2.toVector shouldBe expected
      waitFor("StoreOutput", 256)(dut.io.phase.peek().litValue == BlockPhase.StoreOutput)
      dut.io.tensorWriteCommand.bits.address.poke("h800".U); dut.io.tensorWriteCommand.bits.beats.poke(2.U)
      send("two-beat write command", dut.io.tensorWriteCommand.ready.peek().litToBoolean)(v => dut.io.tensorWriteCommand.valid.poke(v.B))
      waitFor("ResNetBlock done", 1024)(dut.io.done.peek().litToBoolean)
      memory.read512(0x800) shouldBe ResNetBlockE2EReference.packLanes(expected(0)); memory.read512(0x840) shouldBe ResNetBlockE2EReference.packLanes(expected(1))
      memory.readBurstAddresses shouldBe Vector(BigInt(0x400), BigInt(0x440)); memory.writeBurstAddresses shouldBe Vector(BigInt(0x800), BigInt(0x840))
      memory.delayedChannels shouldBe Set("AW", "W", "B", "AR", "R"); memory.assertNoProtocolError()
    }
  }

  it should "complete two distinct transactions without stale tensor or DMA state" in {
    test(new DiffusionAccelTop(memoryBackend = DiffusionMemoryBackend.Axi64)) { dut =>
      val memory = new Axi64MemoryModel(dut.io.axi64, Axi64DelayProfile.staggered)
      final case class Transaction(
        readAddress: BigInt,
        writeAddress: BigInt,
        inputs: Vector[Vector[Int]],
        temb: Vector[Int],
        residual: Vector[Int],
        rsqrtQ30: BigInt,
        stats: GroupStatsReference
      )
      def expectedActivation(tx: Transaction): Vector[Vector[Int]] = tx.inputs.map(_.map { lane =>
        val normalized = ResNetBlockE2EReference.roundAwayFromZero(BigInt(lane) * tx.rsqrtQ30, 30)
        ResNetBlockE2EReference.silu16(ResNetBlockE2EReference.saturateInt16(
          ResNetBlockE2EReference.roundAwayFromZero(normalized * 256, 8)))
      })
      def expectedFinal(tx: Transaction): Vector[Vector[Int]] = tx.inputs.map(
        ResNetBlockE2EReference.finalLanesWithRsqrt(_, tx.temb, tx.residual, tx.rsqrtQ30))
      def waitFor(label: String, limit: Int)(p: => Boolean): Unit = {
        var met = false
        for (_ <- 0 until limit if !met) { met = p; if (!met) tick(dut, memory) }
        assert(met, s"timeout waiting for $label")
      }
      def send(label: String, ready: => Boolean)(drive: Boolean => Unit): Unit = {
        drive(true); waitFor(label, 128)(ready); tick(dut, memory); drive(false)
      }
      def start(label: String): Unit = {
        dut.io.axi.aw.bits.poke(0.U); dut.io.axi.aw.valid.poke(true.B)
        dut.io.axi.w.bits.data.poke(1.U); dut.io.axi.w.bits.strb.poke("hf".U); dut.io.axi.w.valid.poke(true.B)
        dut.io.axi.b.ready.poke(true.B)
        tick(dut, memory)
        dut.io.axi.aw.valid.poke(false.B); dut.io.axi.w.valid.poke(false.B)
        waitFor(s"$label LoadResidual", 128)(dut.io.phase.peek().litValue == BlockPhase.LoadResidual)
      }
      def capture(output: Vec[SInt], valid: Bool, ready: Bool, tx: Transaction, target: scala.collection.mutable.ArrayBuffer[Vector[Int]], label: String): Unit = {
        for (_ <- 0 until 1024 if target.size < 2) {
          ready.poke(false.B)
          if (valid.peek().litToBoolean) {
            target += Vector.tabulate(32)(i => output(i).peek().litValue.toInt)
            ready.poke(true.B)
          }
          tick(dut, memory)
        }
        ready.poke(false.B)
        target.size shouldBe 2
      }
      def runTransaction(tx: Transaction, label: String): Vector[Vector[Int]] = {
        val expected = expectedFinal(tx)
        val conv1 = scala.collection.mutable.ArrayBuffer.empty[Vector[Int]]
        val activation = scala.collection.mutable.ArrayBuffer.empty[Vector[Int]]
        val conv2 = scala.collection.mutable.ArrayBuffer.empty[Vector[Int]]
        start(label)
        dut.io.tensorReadCommand.bits.address.poke(tx.readAddress.U)
        dut.io.tensorReadCommand.bits.beats.poke(2.U)
        send(s"$label two-beat read command", dut.io.tensorReadCommand.ready.peek().litToBoolean)(v => dut.io.tensorReadCommand.valid.poke(v.B))
        dut.io.tensorBufferOccupancy.expect(0.U)
        waitFor(s"$label two-beat read", 1024)(dut.io.tensorReadDone.peek().litToBoolean)
        waitFor(s"$label Gn1Stats", 256)(dut.io.phase.peek().litValue == BlockPhase.Gn1Stats)
        dut.io.gn1StatsCommand.bits.baseAddress.poke(0.U); dut.io.gn1StatsCommand.bits.vectors.poke(2.U)
        send(s"$label GN1 stats command", dut.io.gn1StatsCommand.ready.peek().litToBoolean)(v => dut.io.gn1StatsCommand.valid.poke(v.B))
        waitFor(s"$label GN1 stats", 1024) {
          if (dut.io.gn1Stats.valid.peek().litToBoolean) {
            dut.io.gn1Stats.bits.sum.expect(tx.stats.sum.S); dut.io.gn1Stats.bits.sumSquare.expect(tx.stats.sumSquare.U); dut.io.gn1Stats.bits.count.expect(tx.stats.count.U)
            dut.io.gn1Stats.ready.poke(true.B); tick(dut, memory); dut.io.gn1Stats.ready.poke(false.B); true
          } else false
        }
        waitFor(s"$label Gn1Conv1", 256)(dut.io.phase.peek().litValue == BlockPhase.Gn1Conv1)
        for (i <- 0 until 32) {
          dut.io.gn1ConvWeightWrite.bits.row.poke(i.U); dut.io.gn1ConvWeightWrite.bits.column.poke(i.U); dut.io.gn1ConvWeightWrite.bits.data.poke(1.S)
          dut.io.gn1ConvWeightWrite.valid.poke(true.B); tick(dut, memory)
        }
        dut.io.gn1ConvWeightWrite.valid.poke(false.B)
        dut.io.gn1ConvCommand.bits.baseAddress.poke(0.U); dut.io.gn1ConvCommand.bits.vectors.poke(2.U)
        send(s"$label GN1 conv command", dut.io.gn1ConvCommand.ready.peek().litToBoolean)(v => dut.io.gn1ConvCommand.valid.poke(v.B))
        capture(dut.io.gn1ConvOutput.bits, dut.io.gn1ConvOutput.valid, dut.io.gn1ConvOutput.ready, tx, conv1, s"$label Conv1")
        conv1.toVector shouldBe tx.inputs
        waitFor(s"$label Gn2Stats", 256)(dut.io.phase.peek().litValue == BlockPhase.Gn2Stats)
        dut.io.gn2StatsCommand.bits.vectors.poke(2.U)
        send(s"$label GN2 stats command", dut.io.gn2StatsCommand.ready.peek().litToBoolean)(v => dut.io.gn2StatsCommand.valid.poke(v.B))
        waitFor(s"$label GN2 stats", 1024) {
          if (dut.io.gn2Stats.valid.peek().litToBoolean) {
            dut.io.gn2Stats.bits.sum.expect(tx.stats.sum.S); dut.io.gn2Stats.bits.sumSquare.expect(tx.stats.sumSquare.U); dut.io.gn2Stats.bits.count.expect(tx.stats.count.U)
            dut.io.gn2Stats.ready.poke(true.B); tick(dut, memory); dut.io.gn2Stats.ready.poke(false.B); true
          } else false
        }
        waitFor(s"$label Gn2Conv2Residual", 256)(dut.io.phase.peek().litValue == BlockPhase.Gn2Conv2Residual)
        for (i <- 0 until 32) {
          dut.io.gn2AffineWrite.bits.channel.poke(i.U); dut.io.gn2AffineWrite.bits.gamma.poke(256.S); dut.io.gn2AffineWrite.bits.beta.poke(0.S); dut.io.gn2AffineWrite.valid.poke(true.B)
          dut.io.gn2ConvWeightWrite.bits.row.poke(i.U); dut.io.gn2ConvWeightWrite.bits.column.poke(i.U); dut.io.gn2ConvWeightWrite.bits.data.poke(1.S); dut.io.gn2ConvWeightWrite.valid.poke(true.B)
          dut.io.gn2Temb(i).poke(tx.temb(i).S); dut.io.gn2Residual(i).poke(tx.residual(i).S); tick(dut, memory)
        }
        dut.io.gn2AffineWrite.valid.poke(false.B); dut.io.gn2ConvWeightWrite.valid.poke(false.B); dut.io.gn2AddResidual.poke(true.B)
        dut.io.gn2ConvCommand.bits.vectors.poke(2.U)
        send(s"$label GN2 conv command", dut.io.gn2ConvCommand.ready.peek().litToBoolean)(v => dut.io.gn2ConvCommand.valid.poke(v.B))
        dut.io.gn2ActivationCommand.bits.baseAddress.poke(0.U); dut.io.gn2ActivationCommand.bits.vectors.poke(2.U)
        send(s"$label GN2 activation command", dut.io.gn2ActivationCommand.ready.peek().litToBoolean)(v => dut.io.gn2ActivationCommand.valid.poke(v.B))
        for (_ <- 0 until 1024 if activation.size < 2 || conv2.size < 2) {
          dut.io.gn2Activation.ready.poke(false.B); dut.io.gn2ConvOutput.ready.poke(false.B)
          if (dut.io.gn2Activation.valid.peek().litToBoolean) { activation += Vector.tabulate(32)(i => dut.io.gn2Activation.bits(i).peek().litValue.toInt); dut.io.gn2Activation.ready.poke(true.B) }
          if (dut.io.gn2ConvOutput.valid.peek().litToBoolean) { conv2 += Vector.tabulate(32)(i => dut.io.gn2ConvOutput.bits(i).peek().litValue.toInt); dut.io.gn2ConvOutput.ready.poke(true.B) }
          tick(dut, memory)
        }
        dut.io.gn2Activation.ready.poke(false.B); dut.io.gn2ConvOutput.ready.poke(false.B)
        activation.toVector shouldBe expectedActivation(tx); conv2.toVector shouldBe expected
        waitFor(s"$label StoreOutput", 256)(dut.io.phase.peek().litValue == BlockPhase.StoreOutput)
        dut.io.tensorWriteCommand.bits.address.poke(tx.writeAddress.U); dut.io.tensorWriteCommand.bits.beats.poke(2.U)
        send(s"$label two-beat write command", dut.io.tensorWriteCommand.ready.peek().litToBoolean)(v => dut.io.tensorWriteCommand.valid.poke(v.B))
        waitFor(s"$label done", 1024)(dut.io.done.peek().litToBoolean)
        dut.io.busy.expect(false.B); dut.io.phase.expect(BlockPhase.Idle.U)
        memory.read512(tx.writeAddress) shouldBe ResNetBlockE2EReference.packLanes(expected(0))
        memory.read512(tx.writeAddress + 64) shouldBe ResNetBlockE2EReference.packLanes(expected(1))
        expected
      }

      val txA = Transaction(0x400, 0x800, Vector(Vector.fill(16)(-1) ++ Vector.fill(16)(1), Vector.fill(16)(1) ++ Vector.fill(16)(-1)), Vector.fill(32)(3), Vector.fill(32)(-2), BigInt(759250125), GroupStatsReference(0, 64, 64))
      val txB = Transaction(0x1000, 0x1800, Vector(Vector.fill(16)(-2) ++ Vector.fill(16)(2), Vector.fill(16)(2) ++ Vector.fill(16)(-2)), Vector.fill(32)(5), Vector.fill(32)(-3), BigInt(480191942), GroupStatsReference(0, 256, 64))
      idle(dut)
      txA.inputs.zipWithIndex.foreach { case (word, index) => memory.load512(txA.readAddress + 64 * index, ResNetBlockE2EReference.packLanes(word)) }
      txB.inputs.zipWithIndex.foreach { case (word, index) => memory.load512(txB.readAddress + 64 * index, ResNetBlockE2EReference.packLanes(word)) }
      val aExpected = runTransaction(txA, "transaction A")
      val aSnapshot = Vector(memory.read512(0x800), memory.read512(0x840))
      aSnapshot shouldBe aExpected.map(ResNetBlockE2EReference.packLanes)
      runTransaction(txB, "transaction B")
      Vector(memory.read512(0x800), memory.read512(0x840)) shouldBe aSnapshot
      memory.readBurstAddresses shouldBe Vector(BigInt(0x400), BigInt(0x440), BigInt(0x1000), BigInt(0x1040))
      memory.writeBurstAddresses shouldBe Vector(BigInt(0x800), BigInt(0x840), BigInt(0x1800), BigInt(0x1840))
      memory.delayedChannels shouldBe Set("AW", "W", "B", "AR", "R")
      memory.assertNoProtocolError()
    }
  }
}

