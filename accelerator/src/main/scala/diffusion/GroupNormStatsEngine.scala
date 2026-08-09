package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

/** Converts a commanded sequence of 32-lane activation vectors into GroupNorm statistics. */
class GroupNormStatsCommand extends Bundle {
  val vectors = UInt(16.W)
}

class GroupNormStatsEngine(lanes: Int = 32) extends Module {
  val io = IO(new Bundle {
    val command = Flipped(Decoupled(new GroupNormStatsCommand))
    val input = Flipped(Decoupled(Vec(lanes, SInt(16.W))))
    val stats = Decoupled(new GroupStats)
    val busy = Output(Bool())
    val done = Output(Bool())
  })
  val idle :: collect :: emit :: Nil = Enum(3)
  val state = RegInit(idle)
  val remaining = Reg(UInt(16.W))
  val statsUnit = Module(new GroupNormStats(lanes))
  val doneReg = RegInit(false.B)

  io.command.ready := state === idle
  io.input.ready := state === collect && statsUnit.io.input.ready
  statsUnit.io.input.valid := state === collect && io.input.valid
  statsUnit.io.input.bits.values := io.input.bits
  statsUnit.io.input.bits.last := remaining === 1.U
  io.stats <> statsUnit.io.stats
  io.busy := state =/= idle
  io.done := doneReg
  doneReg := false.B

  when(io.command.fire) {
    remaining := io.command.bits.vectors
    when(io.command.bits.vectors === 0.U) { doneReg := true.B }
      .otherwise { state := collect }
  }
  when(state === collect && io.input.fire) {
    when(remaining === 1.U) { state := emit }
      .otherwise { remaining := remaining - 1.U }
  }
  when(state === emit && io.stats.fire) { state := idle; doneReg := true.B }
}
