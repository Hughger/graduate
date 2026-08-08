package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

class GroupNormApply(lanes: Int, affineShift: Int = 8) extends Module {
  require(lanes > 0)
  require(affineShift >= 0)

  val io = IO(new Bundle {
    val input = Flipped(Decoupled(Vec(lanes, SInt(16.W))))
    val mean = Input(SInt(16.W))
    val rsqrtQ30 = Input(UInt(32.W))
    val gamma = Input(Vec(lanes, SInt(16.W)))
    val beta = Input(Vec(lanes, SInt(16.W)))
    val output = Decoupled(Vec(lanes, SInt(16.W)))
  })

  val result = RegInit(VecInit(Seq.fill(lanes)(0.S(16.W))))
  val outputValid = RegInit(false.B)
  io.input.ready := !outputValid || io.output.ready

  when(io.input.fire) {
    for (lane <- 0 until lanes) {
      val centered = io.input.bits(lane) - io.mean
      val normalized = DiffusionFixedPoint.roundShiftAwayFromZero(
        centered * io.rsqrtQ30.asSInt,
        30
      )
      val affine = DiffusionFixedPoint.roundShiftAwayFromZero(
        normalized * io.gamma(lane),
        affineShift
      ) + io.beta(lane)
      result(lane) := DiffusionFixedPoint.saturateInt16(affine)
    }
    outputValid := true.B
  }.elsewhen(io.output.fire) {
    outputValid := false.B
  }

  io.output.bits := result
  io.output.valid := outputValid
}
