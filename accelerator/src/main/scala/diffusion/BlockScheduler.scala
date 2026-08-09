package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

object BlockPhase {
  val Idle = 0
  val LoadResidual = 1
  val Gn1Stats = 2
  val Gn1Conv1 = 3
  val Gn2Stats = 4
  val Gn2Conv2Residual = 5
  val StoreOutput = 6
}

class BlockScheduler extends Module {
  val io = IO(new Bundle {
    val start = Input(Bool())
    val phaseDone = Input(Bool())
    val phase = Output(UInt(3.W))
    val busy = Output(Bool())
    val done = Output(Bool())
  })

  val phase = RegInit(BlockPhase.Idle.U(3.W))
  val done = RegInit(false.B)
  done := false.B

  when(phase === BlockPhase.Idle.U) {
    when(io.start) { phase := BlockPhase.LoadResidual.U }
  }.elsewhen(io.phaseDone) {
    switch(phase) {
      is(BlockPhase.LoadResidual.U) { phase := BlockPhase.Gn1Stats.U }
      is(BlockPhase.Gn1Stats.U) { phase := BlockPhase.Gn1Conv1.U }
      is(BlockPhase.Gn1Conv1.U) { phase := BlockPhase.Gn2Stats.U }
      is(BlockPhase.Gn2Stats.U) { phase := BlockPhase.Gn2Conv2Residual.U }
      is(BlockPhase.Gn2Conv2Residual.U) { phase := BlockPhase.StoreOutput.U }
      is(BlockPhase.StoreOutput.U) {
        phase := BlockPhase.Idle.U
        done := true.B
      }
    }
  }

  io.phase := phase
  io.busy := phase =/= BlockPhase.Idle.U
  io.done := done
}
