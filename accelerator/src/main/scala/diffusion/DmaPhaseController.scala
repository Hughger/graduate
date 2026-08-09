package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

/**
  * Makes DDR traffic part of the ResNetBlock phase contract. LoadResidual
  * advances only after its read DMA completes, and StoreOutput advances only
  * after its write DMA completes. Compute phases retain the external completion
  * signal until their datapaths are wired in.
  */
class DmaPhaseController extends Module {
  val io = IO(new Bundle {
    val phase = Input(UInt(3.W))
    val externalPhaseDone = Input(Bool())
    val phaseDone = Output(Bool())
    val readCommand = Flipped(Decoupled(new TensorReadCommand))
    val readDmaCommand = Decoupled(new TensorReadCommand)
    val readDone = Input(Bool())
    val writeCommand = Flipped(Decoupled(new TensorWriteCommand))
    val writeDmaCommand = Decoupled(new TensorWriteCommand)
    val writeDone = Input(Bool())
  })

  val readIssued = RegInit(false.B)
  val writeIssued = RegInit(false.B)
  val loading = io.phase === BlockPhase.LoadResidual.U
  val storing = io.phase === BlockPhase.StoreOutput.U

  io.readDmaCommand.valid := loading && !readIssued && io.readCommand.valid
  io.readDmaCommand.bits := io.readCommand.bits
  io.readCommand.ready := loading && !readIssued && io.readDmaCommand.ready
  io.writeDmaCommand.valid := storing && !writeIssued && io.writeCommand.valid
  io.writeDmaCommand.bits := io.writeCommand.bits
  io.writeCommand.ready := storing && !writeIssued && io.writeDmaCommand.ready

  when(!loading) { readIssued := false.B }
  when(!storing) { writeIssued := false.B }
  when(io.readDmaCommand.fire) { readIssued := true.B }
  when(io.writeDmaCommand.fire) { writeIssued := true.B }

  io.phaseDone := Mux(loading, readIssued && io.readDone,
    Mux(storing, writeIssued && io.writeDone, io.externalPhaseDone))
}
