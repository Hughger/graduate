package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

/** Describes a bounded sequence of 32-lane convolution vectors. */
class ConvBatchCommand extends Bundle {
  val vectors = UInt(16.W)
}

/**
  * Provides command and completion ownership around the raw FLOOD MAC tile.
  *
  * One activation is admitted only after the preceding result has been
  * accepted.  This intentionally conservative scheduling makes each result
  * unambiguously count toward the issued command and preserves backpressure.
  */
class ConvBatchEngine(p: DiffusionParams) extends Module {
  val io = IO(new Bundle {
    val command = Flipped(Decoupled(new ConvBatchCommand))
    val weightWrite = Flipped(Decoupled(new ConvWeightWrite))
    val activation = Flipped(Decoupled(Vec(p.ciTile, SInt(p.activationWidth.W))))
    val output = Decoupled(Vec(p.coTile, SInt(p.accumWidth.W)))
    val busy = Output(Bool())
    val done = Output(Bool())
  })

  val idle :: execute :: Nil = Enum(2)
  val state = RegInit(idle)
  val remaining = Reg(UInt(16.W))
  val doneReg = RegInit(false.B)
  val conv = Module(new FloodConvAdapter(p))

  conv.io.weightWrite <> io.weightWrite
  io.command.ready := state === idle
  io.busy := state =/= idle
  io.done := doneReg
  doneReg := false.B

  val canAcceptActivation = state === execute && remaining =/= 0.U && !conv.io.output.valid
  conv.io.activation.valid := canAcceptActivation && io.activation.valid
  conv.io.activation.bits := io.activation.bits
  io.activation.ready := canAcceptActivation && conv.io.activation.ready
  io.output <> conv.io.output

  when(io.command.fire) {
    remaining := io.command.bits.vectors
    when(io.command.bits.vectors === 0.U) {
      doneReg := true.B
    }.otherwise {
      state := execute
    }
  }

  when(state === execute && conv.io.output.fire) {
    when(remaining === 1.U) {
      state := idle
      doneReg := true.B
    }.otherwise {
      remaining := remaining - 1.U
    }
  }
}
