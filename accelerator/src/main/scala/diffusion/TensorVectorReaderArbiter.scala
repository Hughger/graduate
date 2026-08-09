package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

/** Gives the statistics path priority over debug vector reads while preserving response ownership. */
class TensorVectorReaderArbiter(addressWidth: Int = 12, lanes: Int = 32) extends Module {
  val io = IO(new Bundle {
    val debugCommand = Flipped(Decoupled(new TensorVectorReadCommand(addressWidth)))
    val debugVector = Decoupled(Vec(lanes, SInt(16.W)))
    val debugDone = Output(Bool())
    val statsCommand = Flipped(Decoupled(new TensorVectorReadCommand(addressWidth)))
    val statsVector = Decoupled(Vec(lanes, SInt(16.W)))
    val statsDone = Output(Bool())
    val readerCommand = Decoupled(new TensorVectorReadCommand(addressWidth))
    val readerVector = Flipped(Decoupled(Vec(lanes, SInt(16.W))))
    val readerDone = Input(Bool())
  })
  val active = RegInit(false.B)
  val ownerStats = RegInit(false.B)
  val selectStats = io.statsCommand.valid
  io.readerCommand.valid := !active && (io.debugCommand.valid || io.statsCommand.valid)
  io.readerCommand.bits := Mux(selectStats, io.statsCommand.bits, io.debugCommand.bits)
  io.statsCommand.ready := !active && io.readerCommand.ready && selectStats
  io.debugCommand.ready := !active && io.readerCommand.ready && !selectStats
  io.debugVector.valid := active && !ownerStats && io.readerVector.valid
  io.debugVector.bits := io.readerVector.bits
  io.statsVector.valid := active && ownerStats && io.readerVector.valid
  io.statsVector.bits := io.readerVector.bits
  io.readerVector.ready := active && Mux(ownerStats, io.statsVector.ready, io.debugVector.ready)
  io.debugDone := active && !ownerStats && io.readerDone
  io.statsDone := active && ownerStats && io.readerDone
  when(io.readerCommand.fire) { active := true.B; ownerStats := selectStats }
  when(active && io.readerDone) { active := false.B }
}
