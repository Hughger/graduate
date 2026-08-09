package FLOOD_Accelerator.diffusion

import chisel3._

class PerfMonitor extends Module {
  val io = IO(new Bundle {
    val active = Input(Bool())
    val readBytes = Input(UInt(64.W))
    val writeBytes = Input(UInt(64.W))
    val macActive = Input(Bool())
    val groupNormActive = Input(Bool())
    val stalled = Input(Bool())
    val snapshot = Input(Bool())
    val counters = Output(new PerfCounters)
  })
  def increment(value: UInt, amount: UInt): UInt = {
    val sum = value +& amount
    Mux(sum(64), "hffffffffffffffff".U(64.W), sum(63, 0))
  }
  val live = RegInit(0.U.asTypeOf(new PerfCounters))
  val saved = RegInit(0.U.asTypeOf(new PerfCounters))
  when(io.active) { live.totalCycles := increment(live.totalCycles, 1.U) }
  live.readBytes := increment(live.readBytes, io.readBytes)
  live.writeBytes := increment(live.writeBytes, io.writeBytes)
  when(io.macActive) { live.macCycles := increment(live.macCycles, 1.U) }
  when(io.groupNormActive) { live.groupNormCycles := increment(live.groupNormCycles, 1.U) }
  when(io.stalled) { live.stallCycles := increment(live.stallCycles, 1.U) }
  when(io.snapshot) { saved := live }
  io.counters := saved
}
