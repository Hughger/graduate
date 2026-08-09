package FLOOD_Accelerator.diffusion

import chisel3._

class DiffusionAccelTop extends Module {
  val io = IO(new Bundle {
    val axi = new AxiLitePort
    val phaseDone = Input(Bool())
    val phase = Output(UInt(3.W))
    val busy = Output(Bool())
    val done = Output(Bool())
  })
  val control = Module(new AxiLiteControl)
  val scheduler = Module(new BlockScheduler)
  control.io.axi <> io.axi
  control.io.busy := scheduler.io.busy
  scheduler.io.start := control.io.start
  scheduler.io.phaseDone := io.phaseDone
  io.phase := scheduler.io.phase
  io.busy := scheduler.io.busy
  io.done := scheduler.io.done
}
