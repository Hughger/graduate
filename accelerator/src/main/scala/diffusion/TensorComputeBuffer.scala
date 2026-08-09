package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

/** Complete DDR-load to 32-lane compute-vector buffering path. */
class TensorComputeBuffer(depth: Int = 4096) extends Module {
  private val addressWidth = math.max(1, log2Ceil(depth))
  val io = IO(new Bundle {
    val loadStart = Input(Bool())
    val dmaData = Flipped(Decoupled(UInt(512.W)))
    val dmaDone = Input(Bool())
    val loadDone = Output(Bool())
    val occupancy = Output(UInt(math.max(1, log2Ceil(depth + 1)).W))
    val vectorCommand = Flipped(Decoupled(new TensorVectorReadCommand(addressWidth)))
    val activation = Decoupled(Vec(32, SInt(16.W)))
    val vectorDone = Output(Bool())
  })

  val loadBuffer = Module(new TensorLoadBuffer(depth))
  val vectorReader = Module(new TensorVectorReader(depth, 32))
  loadBuffer.io.start := io.loadStart
  loadBuffer.io.input <> io.dmaData
  loadBuffer.io.sourceDone := io.dmaDone
  io.loadDone := loadBuffer.io.done
  io.occupancy := loadBuffer.io.occupancy
  vectorReader.io.command <> io.vectorCommand
  loadBuffer.io.readReq <> vectorReader.io.bufferReadReq
  vectorReader.io.bufferReadResp <> loadBuffer.io.readResp
  io.activation <> vectorReader.io.output
  io.vectorDone := vectorReader.io.done
}
