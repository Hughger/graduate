package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

/** Conv1 result path: W8A8 MAC, INT32-to-INT16 requantization, buffering, then GN2 statistics. */
class ConvToGroupNormStatsPath(p: DiffusionParams, resultDepth: Int) extends Module {
  val io = IO(new Bundle {
    val convCommand = Flipped(Decoupled(new ConvBatchCommand))
    val weightWrite = Flipped(Decoupled(new ConvWeightWrite))
    val activation = Flipped(Decoupled(Vec(p.ciTile, SInt(16.W))))
    val convShift = Input(UInt(4.W))
    val resultShift = Input(UInt(5.W))
    val convOutput = Decoupled(Vec(p.coTile, SInt(p.accumWidth.W)))
    val convDone = Output(Bool())
    val occupancy = Output(UInt(log2Ceil(resultDepth + 1).W))
    val statsCommand = Flipped(Decoupled(new GroupNormStatsCommand))
    val stats = Decoupled(new GroupStats)
    val statsDone = Output(Bool())
  })

  val convInput = Module(new VectorRequantizeInt16ToInt8(p.ciTile))
  val conv = Module(new ConvBatchEngine(p))
  val result = Module(new VectorRequantizeInt32ToInt16(p.coTile))
  val buffer = Module(new VectorResultBuffer(resultDepth, p.coTile))
  val statsEngine = Module(new GroupNormStatsEngine(p.coTile))
  val loaded = RegInit(false.B)

  conv.io.weightWrite <> io.weightWrite
  conv.io.command <> io.convCommand
  convInput.io.shift := io.convShift
  convInput.io.input <> io.activation
  conv.io.activation <> convInput.io.output
  result.io.shift := io.resultShift
  io.convOutput.valid := conv.io.output.valid
  io.convOutput.bits := conv.io.output.bits
  result.io.input.valid := conv.io.output.valid && io.convOutput.ready
  result.io.input.bits := conv.io.output.bits
  conv.io.output.ready := result.io.input.ready && io.convOutput.ready
  buffer.io.input <> result.io.output
  buffer.io.clear := conv.io.command.fire
  io.convDone := conv.io.done
  io.occupancy := buffer.io.occupancy

  when(conv.io.command.fire) { loaded := false.B }
  when(conv.io.done) { loaded := true.B }

  val acceptStats = loaded && io.statsCommand.valid && statsEngine.io.command.ready
  buffer.io.command.valid := acceptStats
  buffer.io.command.bits.baseAddress := 0.U
  buffer.io.command.bits.vectors := io.statsCommand.bits.vectors
  statsEngine.io.command.valid := buffer.io.command.fire
  statsEngine.io.command.bits := io.statsCommand.bits
  io.statsCommand.ready := loaded && buffer.io.command.ready && statsEngine.io.command.ready
  statsEngine.io.input <> buffer.io.output
  io.stats <> statsEngine.io.stats
  io.statsDone := statsEngine.io.done
}
