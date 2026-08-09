package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

class TensorGroupNormStatsCommand(addressWidth: Int) extends Bundle {
  val baseAddress = UInt(addressWidth.W)
  val vectors = UInt(16.W)
}

/** End-to-end loaded-tensor to GroupNorm-statistics path. */
class TensorGroupNormStatsPath(depth: Int = 4096, lanes: Int = 32) extends Module {
  private val addressWidth = math.max(1, log2Ceil(depth))
  val io = IO(new Bundle {
    val loadStart = Input(Bool())
    val dmaData = Flipped(Decoupled(UInt(512.W)))
    val dmaDone = Input(Bool())
    val loadDone = Output(Bool())
    val occupancy = Output(UInt(math.max(1, log2Ceil(depth + 1)).W))
    val statsCommand = Flipped(Decoupled(new TensorGroupNormStatsCommand(addressWidth)))
    val stats = Decoupled(new GroupStats)
    val statsDone = Output(Bool())
  })

  val buffer = Module(new TensorComputeBuffer(depth))
  val statsEngine = Module(new GroupNormStatsEngine(lanes))
  val loaded = RegInit(false.B)

  buffer.io.loadStart := io.loadStart
  buffer.io.dmaData <> io.dmaData
  buffer.io.dmaDone := io.dmaDone
  io.loadDone := buffer.io.loadDone
  io.occupancy := buffer.io.occupancy
  when(io.loadStart) { loaded := false.B }
  when(buffer.io.loadDone) { loaded := true.B }

  val launchReady = loaded && buffer.io.vectorCommand.ready && statsEngine.io.command.ready
  io.statsCommand.ready := launchReady
  buffer.io.vectorCommand.valid := io.statsCommand.valid && launchReady
  buffer.io.vectorCommand.bits.baseAddress := io.statsCommand.bits.baseAddress
  buffer.io.vectorCommand.bits.vectors := io.statsCommand.bits.vectors
  statsEngine.io.command.valid := io.statsCommand.valid && launchReady
  statsEngine.io.command.bits.vectors := io.statsCommand.bits.vectors
  statsEngine.io.input <> buffer.io.activation
  io.stats <> statsEngine.io.stats
  io.statsDone := statsEngine.io.done
}
