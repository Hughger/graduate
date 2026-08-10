package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

class DiffusionAccelTop(resultDepth: Int = 128) extends Module {
  val io = IO(new Bundle {
    val axi = new AxiLitePort
    // Completes compute-only scheduler phases; load/store are driven by DMA.
    val phaseDone = Input(Bool())
    val phase = Output(UInt(3.W))
    val busy = Output(Bool())
    val done = Output(Bool())
    // Debug/control access shares the physical MIG transaction engine with DMA.
    val memoryRequest = Flipped(Decoupled(new MigAppRequest))
    val memoryResponse = Decoupled(UInt(512.W))
    val memoryDone = Output(Bool())
    // Accepted only in LoadResidual and StoreOutput, respectively.
    val tensorReadCommand = Flipped(Decoupled(new TensorReadCommand))
    val tensorReadDone = Output(Bool())
    val activationReadCommand = Flipped(Decoupled(new TensorVectorReadCommand(12)))
    val activationVector = Decoupled(Vec(32, SInt(16.W)))
    val activationReadDone = Output(Bool())
    // GN1 owns the statistics vector stream while this phase is active.
    val gn1StatsCommand = Flipped(Decoupled(new TensorVectorReadCommand(12)))
    val gn1Stats = Decoupled(new GroupStats)
    val gn1StatsDone = Output(Bool())
    // GN1 convolution consumes tensor vectors after GN1 statistics complete.
    val gn1ConvCommand = Flipped(Decoupled(new TensorVectorReadCommand(12)))
    val gn1ConvShift = Input(UInt(4.W))
    val gn1ResultShift = Input(UInt(5.W))
    val gn1ConvWeightWrite = Flipped(Decoupled(new ConvWeightWrite))
    val gn1ConvOutput = Decoupled(Vec(32, SInt(32.W)))
    val gn1ConvDone = Output(Bool())
    val gn2StatsCommand = Flipped(Decoupled(new GroupNormStatsCommand))
    val gn2Stats = Decoupled(new GroupStats)
    val gn2StatsDone = Output(Bool())
    val gn2AffineWrite = Flipped(Decoupled(new GroupNormAffineWrite(5)))
    val gn2ActivationCommand = Flipped(Decoupled(new TensorVectorReadCommand(12)))
    val gn2Activation = Decoupled(Vec(32, SInt(16.W)))
    val gn2ActivationDone = Output(Bool())
    val gn2ConvCommand = Flipped(Decoupled(new ConvBatchCommand))
    val gn2ConvWeightWrite = Flipped(Decoupled(new ConvWeightWrite))
    val gn2ConvInputShift = Input(UInt(4.W))
    val gn2ConvOutputShift = Input(UInt(5.W))
    val gn2Temb = Input(Vec(32, SInt(16.W)))
    val gn2Residual = Input(Vec(32, SInt(16.W)))
    val gn2AddResidual = Input(Bool())
    val gn2ConvOutput = Decoupled(Vec(32, SInt(16.W)))
    val gn2ConvDone = Output(Bool())
    val tensorBufferOccupancy = Output(UInt(13.W))
    val tensorWriteCommand = Flipped(Decoupled(new TensorWriteCommand))
    val tensorWriteData = Flipped(Decoupled(UInt(512.W)))
    val tensorWriteDone = Output(Bool())
    // A board wrapper connects this seam to c0_ddr4_app_*.
    val mig = new MigAppPort
  })
  val control = Module(new AxiLiteControl)
  val scheduler = Module(new BlockScheduler)
  val phaseDma = Module(new DmaPhaseController)
  val memoryTransfer = Module(new MigAppTransfer)
  val memoryArbiter = Module(new MigAppRequestArbiter)
  val tensorReadDma = Module(new TensorReadDma)
  val tensorComputeBuffer = Module(new TensorComputeBuffer(4096))
  val vectorReaderArbiter = Module(new TensorVectorReaderThreeWayArbiter(12, 32))
  val gn1StatsEngine = Module(new GroupNormStatsEngine(32))
  val convToGn2Stats = Module(new ConvToGroupNormStatsPath(DiffusionParams.sd15EightTile, resultDepth))
  val gn2ActivationPath = Module(new GroupNormActivationPath(32))
  val gn2ConvPath = Module(new Conv2ResidualPath(DiffusionParams.sd15EightTile))
  val tensorWriteDma = Module(new TensorWriteDma)
  control.io.axi <> io.axi
  control.io.busy := scheduler.io.busy
  scheduler.io.start := control.io.start
  scheduler.io.phaseDone := MuxLookup(scheduler.io.phase, phaseDma.io.phaseDone, Seq(
    BlockPhase.Gn1Stats.U -> gn1StatsEngine.io.done,
    BlockPhase.Gn1Conv1.U -> convToGn2Stats.io.convDone,
    BlockPhase.Gn2Stats.U -> convToGn2Stats.io.statsDone,
    BlockPhase.Gn2Conv2Residual.U -> gn2ConvPath.io.done
  ))
  io.phase := scheduler.io.phase
  io.busy := scheduler.io.busy
  io.done := scheduler.io.done

  phaseDma.io.phase := scheduler.io.phase
  phaseDma.io.externalPhaseDone := io.phaseDone
  phaseDma.io.readCommand <> io.tensorReadCommand
  phaseDma.io.readDone := tensorComputeBuffer.io.loadDone
  phaseDma.io.writeCommand <> io.tensorWriteCommand
  phaseDma.io.writeDone := tensorWriteDma.io.done

  memoryArbiter.io.client0Request <> io.memoryRequest
  io.memoryResponse <> memoryArbiter.io.client0Response
  io.memoryDone := memoryArbiter.io.client0Done

  tensorReadDma.io.command <> phaseDma.io.readDmaCommand
  tensorComputeBuffer.io.loadStart := phaseDma.io.readDmaCommand.fire
  tensorComputeBuffer.io.dmaDone := tensorReadDma.io.done
  tensorComputeBuffer.io.dmaData <> tensorReadDma.io.data
  io.tensorReadDone := tensorComputeBuffer.io.loadDone
  vectorReaderArbiter.io.debugCommand <> io.activationReadCommand
  io.activationVector <> vectorReaderArbiter.io.debugVector
  io.activationReadDone := vectorReaderArbiter.io.debugDone
  vectorReaderArbiter.io.readerCommand <> tensorComputeBuffer.io.vectorCommand
  vectorReaderArbiter.io.readerVector <> tensorComputeBuffer.io.activation
  vectorReaderArbiter.io.readerDone := tensorComputeBuffer.io.vectorDone

  val acceptGn1StatsCommand = scheduler.io.phase === BlockPhase.Gn1Stats.U &&
    io.gn1StatsCommand.valid && gn1StatsEngine.io.command.ready
  vectorReaderArbiter.io.statsCommand.valid := acceptGn1StatsCommand
  vectorReaderArbiter.io.statsCommand.bits := io.gn1StatsCommand.bits
  gn1StatsEngine.io.command.valid := vectorReaderArbiter.io.statsCommand.fire
  gn1StatsEngine.io.command.bits.vectors := io.gn1StatsCommand.bits.vectors
  io.gn1StatsCommand.ready := scheduler.io.phase === BlockPhase.Gn1Stats.U &&
    vectorReaderArbiter.io.statsCommand.ready && gn1StatsEngine.io.command.ready
  gn1StatsEngine.io.input <> vectorReaderArbiter.io.statsVector
  io.gn1Stats <> gn1StatsEngine.io.stats
  io.gn1StatsDone := gn1StatsEngine.io.done

  convToGn2Stats.io.weightWrite <> io.gn1ConvWeightWrite
  convToGn2Stats.io.convShift := io.gn1ConvShift
  convToGn2Stats.io.resultShift := io.gn1ResultShift
  val acceptGn1ConvCommand = scheduler.io.phase === BlockPhase.Gn1Conv1.U &&
    io.gn1ConvCommand.valid && convToGn2Stats.io.convCommand.ready
  vectorReaderArbiter.io.computeCommand.valid := acceptGn1ConvCommand
  vectorReaderArbiter.io.computeCommand.bits := io.gn1ConvCommand.bits
  convToGn2Stats.io.convCommand.valid := vectorReaderArbiter.io.computeCommand.fire
  convToGn2Stats.io.convCommand.bits.vectors := io.gn1ConvCommand.bits.vectors
  io.gn1ConvCommand.ready := scheduler.io.phase === BlockPhase.Gn1Conv1.U &&
    vectorReaderArbiter.io.computeCommand.ready && convToGn2Stats.io.convCommand.ready
  convToGn2Stats.io.activation <> vectorReaderArbiter.io.computeVector
  io.gn1ConvOutput <> convToGn2Stats.io.convOutput
  io.gn1ConvDone := convToGn2Stats.io.convDone

  convToGn2Stats.io.statsCommand.valid := scheduler.io.phase === BlockPhase.Gn2Stats.U && io.gn2StatsCommand.valid
  convToGn2Stats.io.statsCommand.bits := io.gn2StatsCommand.bits
  io.gn2StatsCommand.ready := scheduler.io.phase === BlockPhase.Gn2Stats.U && convToGn2Stats.io.statsCommand.ready
  io.gn2Stats.valid := convToGn2Stats.io.stats.valid
  io.gn2Stats.bits := convToGn2Stats.io.stats.bits
  gn2ActivationPath.io.stats.valid := convToGn2Stats.io.stats.valid && io.gn2Stats.ready
  gn2ActivationPath.io.stats.bits := convToGn2Stats.io.stats.bits
  convToGn2Stats.io.stats.ready := io.gn2Stats.ready && gn2ActivationPath.io.stats.ready
  io.gn2StatsDone := convToGn2Stats.io.statsDone
  gn2ActivationPath.io.affineWrite <> io.gn2AffineWrite
  convToGn2Stats.io.activationCommand.valid := scheduler.io.phase === BlockPhase.Gn2Conv2Residual.U && io.gn2ActivationCommand.valid
  convToGn2Stats.io.activationCommand.bits := io.gn2ActivationCommand.bits
  io.gn2ActivationCommand.ready := scheduler.io.phase === BlockPhase.Gn2Conv2Residual.U && convToGn2Stats.io.activationCommand.ready
  gn2ActivationPath.io.activation <> convToGn2Stats.io.activationOutput
  io.gn2Activation.valid := gn2ActivationPath.io.output.valid
  io.gn2Activation.bits := gn2ActivationPath.io.output.bits
  gn2ConvPath.io.activation.valid := gn2ActivationPath.io.output.valid && io.gn2Activation.ready
  gn2ConvPath.io.activation.bits := gn2ActivationPath.io.output.bits
  gn2ActivationPath.io.output.ready := io.gn2Activation.ready && gn2ConvPath.io.activation.ready
  io.gn2ActivationDone := convToGn2Stats.io.activationDone
  gn2ConvPath.io.command.valid := scheduler.io.phase === BlockPhase.Gn2Conv2Residual.U && io.gn2ConvCommand.valid
  gn2ConvPath.io.command.bits := io.gn2ConvCommand.bits
  io.gn2ConvCommand.ready := scheduler.io.phase === BlockPhase.Gn2Conv2Residual.U && gn2ConvPath.io.command.ready
  gn2ConvPath.io.weightWrite <> io.gn2ConvWeightWrite
  gn2ConvPath.io.inputShift := io.gn2ConvInputShift
  gn2ConvPath.io.outputShift := io.gn2ConvOutputShift
  gn2ConvPath.io.temb := io.gn2Temb
  gn2ConvPath.io.residual := io.gn2Residual
  gn2ConvPath.io.addResidual := io.gn2AddResidual
  io.gn2ConvOutput <> gn2ConvPath.io.output
  io.gn2ConvDone := gn2ConvPath.io.done
  io.tensorBufferOccupancy := tensorComputeBuffer.io.occupancy
  memoryArbiter.io.client1Request <> tensorReadDma.io.memoryRequest
  tensorReadDma.io.memoryResponse <> memoryArbiter.io.client1Response

  tensorWriteDma.io.command <> phaseDma.io.writeDmaCommand
  tensorWriteDma.io.data <> io.tensorWriteData
  io.tensorWriteDone := tensorWriteDma.io.done
  memoryArbiter.io.client2Request <> tensorWriteDma.io.memoryRequest
  memoryArbiter.io.client2Response.ready := true.B
  tensorWriteDma.io.memoryDone := memoryArbiter.io.client2Done

  memoryTransfer.io.request <> memoryArbiter.io.memoryRequest
  memoryArbiter.io.memoryResponse <> memoryTransfer.io.response
  memoryArbiter.io.memoryDone := memoryTransfer.io.done

  io.mig.en := memoryTransfer.io.app.en
  io.mig.cmd := memoryTransfer.io.app.cmd
  io.mig.address := memoryTransfer.io.app.address
  io.mig.wdfWren := memoryTransfer.io.app.wdfWren
  io.mig.wdfEnd := memoryTransfer.io.app.wdfEnd
  io.mig.wdfData := memoryTransfer.io.app.wdfData
  io.mig.wdfMask := memoryTransfer.io.app.wdfMask
  memoryTransfer.io.app.rdy := io.mig.rdy
  memoryTransfer.io.app.wdfRdy := io.mig.wdfRdy
  memoryTransfer.io.app.rdData := io.mig.rdData
  memoryTransfer.io.app.rdDataValid := io.mig.rdDataValid
  memoryTransfer.io.app.rdDataEnd := io.mig.rdDataEnd
}