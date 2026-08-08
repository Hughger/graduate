package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

class TimeResidualFuse(lanes: Int) extends Module {
  require(lanes > 0)

  val io = IO(new Bundle {
    val input = Flipped(Decoupled(Vec(lanes, SInt(16.W))))
    val temb = Input(Vec(lanes, SInt(16.W)))
    val residual = Input(Vec(lanes, SInt(16.W)))
    val addResidual = Input(Bool())
    val output = Decoupled(Vec(lanes, SInt(16.W)))
  })

  val result = RegInit(VecInit(Seq.fill(lanes)(0.S(16.W))))
  val outputValid = RegInit(false.B)
  io.input.ready := !outputValid || io.output.ready

  when(io.input.fire) {
    for (lane <- 0 until lanes) {
      val residualTerm = Mux(io.addResidual, io.residual(lane), 0.S(16.W))
      result(lane) := DiffusionFixedPoint.saturateInt16(
        (io.input.bits(lane) +& io.temb(lane)) +& residualTerm
      )
    }
    outputValid := true.B
  }.elsewhen(io.output.fire) {
    outputValid := false.B
  }

  io.output.bits := result
  io.output.valid := outputValid
}
