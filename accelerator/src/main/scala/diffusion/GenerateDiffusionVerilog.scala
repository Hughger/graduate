package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.stage.ChiselStage
import chisel3.util._

class DiffusionContractTop(p: DiffusionParams) extends Module {
  val io = IO(new Bundle {
    val command = Flipped(Decoupled(new BlockCommand(p)))
    val status = Output(new BlockStatus)
    val counters = Output(new PerfCounters)
  })

  val busy = RegInit(false.B)
  val completedId = RegInit(0.U(32.W))
  val done = RegInit(false.B)

  io.command.ready := !busy
  done := false.B
  when(io.command.fire) {
    busy := true.B
    completedId := io.command.bits.commandId
  }
  when(busy) {
    busy := false.B
    done := true.B
  }

  io.status.busy := busy
  io.status.done := done
  io.status.error := false.B
  io.status.errorCode := 0.U
  io.status.completedId := completedId
  io.counters := 0.U.asTypeOf(new PerfCounters)
}

object GenerateDiffusionVerilog extends App {
  private val parsed = args.toList
  private val tileCount = parsed.sliding(2).collectFirst {
    case List("--tiles", value) => value.toInt
  }.getOrElse(8)
  private val targetDir = parsed.sliding(2).collectFirst {
    case List("--target-dir", value) => value
  }.getOrElse(s"generated/diffusion-$tileCount-tile")

  (new ChiselStage).emitVerilog(
    new DiffusionContractTop(DiffusionParams(tileCount)),
    Array("--target-dir", targetDir)
  )
}
