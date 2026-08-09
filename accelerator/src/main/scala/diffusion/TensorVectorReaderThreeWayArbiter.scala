package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

/**
  * Arbitrates one tensor-vector reader between the phase-owned stats and
  * convolution paths plus the non-intrusive debug path.
  */
class TensorVectorReaderThreeWayArbiter(addressWidth: Int = 12, lanes: Int = 32) extends Module {
  val io = IO(new Bundle {
    val debugCommand = Flipped(Decoupled(new TensorVectorReadCommand(addressWidth)))
    val debugVector = Decoupled(Vec(lanes, SInt(16.W)))
    val debugDone = Output(Bool())
    val computeCommand = Flipped(Decoupled(new TensorVectorReadCommand(addressWidth)))
    val computeVector = Decoupled(Vec(lanes, SInt(16.W)))
    val computeDone = Output(Bool())
    val statsCommand = Flipped(Decoupled(new TensorVectorReadCommand(addressWidth)))
    val statsVector = Decoupled(Vec(lanes, SInt(16.W)))
    val statsDone = Output(Bool())
    val readerCommand = Decoupled(new TensorVectorReadCommand(addressWidth))
    val readerVector = Flipped(Decoupled(Vec(lanes, SInt(16.W))))
    val readerDone = Input(Bool())
  })

  val debugOwner = 0.U(2.W)
  val computeOwner = 1.U(2.W)
  val statsOwner = 2.U(2.W)
  val active = RegInit(false.B)
  val owner = RegInit(debugOwner)
  val selectStats = io.statsCommand.valid
  val selectCompute = !selectStats && io.computeCommand.valid
  val selectedOwner = Mux(selectStats, statsOwner, Mux(selectCompute, computeOwner, debugOwner))

  io.readerCommand.valid := !active && (io.debugCommand.valid || io.computeCommand.valid || io.statsCommand.valid)
  io.readerCommand.bits := Mux(selectStats, io.statsCommand.bits,
    Mux(selectCompute, io.computeCommand.bits, io.debugCommand.bits))
  io.statsCommand.ready := !active && io.readerCommand.ready && selectStats
  io.computeCommand.ready := !active && io.readerCommand.ready && selectCompute
  io.debugCommand.ready := !active && io.readerCommand.ready && !selectStats && !selectCompute

  io.debugVector.valid := active && owner === debugOwner && io.readerVector.valid
  io.debugVector.bits := io.readerVector.bits
  io.computeVector.valid := active && owner === computeOwner && io.readerVector.valid
  io.computeVector.bits := io.readerVector.bits
  io.statsVector.valid := active && owner === statsOwner && io.readerVector.valid
  io.statsVector.bits := io.readerVector.bits
  io.readerVector.ready := active && MuxLookup(owner, io.debugVector.ready, Seq(
    computeOwner -> io.computeVector.ready,
    statsOwner -> io.statsVector.ready
  ))
  io.debugDone := active && owner === debugOwner && io.readerDone
  io.computeDone := active && owner === computeOwner && io.readerDone
  io.statsDone := active && owner === statsOwner && io.readerDone

  when(io.readerCommand.fire) {
    active := true.B
    owner := selectedOwner
  }
  when(active && io.readerDone) { active := false.B }
}
