package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

/**
  * Requantizes stored INT16 activation lanes for the W8A8 FLOOD MAC.
  *
  * `shift` is supplied per command/layer by the integration logic.  The
  * conversion rounds ties away from zero before signed INT8 saturation.
  */
class VectorRequantizeInt16ToInt8(lanes: Int) extends Module {
  require(lanes > 0)

  val io = IO(new Bundle {
    val shift = Input(UInt(4.W))
    val input = Flipped(Decoupled(Vec(lanes, SInt(16.W))))
    val output = Decoupled(Vec(lanes, SInt(8.W)))
  })

  def saturateInt8(value: SInt): SInt = {
    val wide = value.pad(64)
    val maximum = 127.S(64.W)
    val minimum = (-128).S(64.W)
    val clipped = Mux(wide > maximum, maximum, Mux(wide < minimum, minimum, wide))
    clipped(7, 0).asSInt
  }

  val result = RegInit(VecInit(Seq.fill(lanes)(0.S(8.W))))
  val outputValid = RegInit(false.B)
  io.input.ready := !outputValid || io.output.ready

  val roundingShift = Mux(io.shift === 0.U, 0.U, io.shift - 1.U)
  val roundingUnit = (1.S(32.W) << roundingShift).asSInt
  val rounding = Mux(io.shift === 0.U, 0.S(32.W), roundingUnit)
  when(io.input.fire) {
    for (lane <- 0 until lanes) {
      val wide = io.input.bits(lane).pad(32)
      val negative = wide < 0.S(32.W)
      val magnitude = Mux(negative, (-wide).asSInt, wide)
      val shifted = ((magnitude + rounding) >> io.shift).asSInt
      val signed = Mux(negative, (-shifted).asSInt, shifted).asSInt
      result(lane) := saturateInt8(signed)
    }
    outputValid := true.B
  }.elsewhen(io.output.fire) {
    outputValid := false.B
  }

  io.output.bits := result
  io.output.valid := outputValid
}
