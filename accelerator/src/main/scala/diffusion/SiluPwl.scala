package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

object SiluPwl {
  private def table(segments: Int): Seq[SiluCoeffs.SiluSegment] = segments match {
    case 16 => SiluCoeffs.segments16
    case 32 => SiluCoeffs.segments32
    case _ => throw new IllegalArgumentException("only 16- and 32-segment SiLU tables are supported")
  }

  def apply(input: SInt, segments: Int): SInt = {
    var selected: SInt = (-71).S(48.W)
    for (segment <- table(segments)) {
      val product = input * segment.slopeQ16.S(32.W)
      val candidate = (
        DiffusionFixedPoint.roundShiftAwayFromZero(product, 16) + segment.interceptQ8.S(48.W)
      ).pad(48).asSInt
      val inRange = input >= segment.startQ8.S(16.W) && input < segment.endQ8.S(16.W)
      selected = Mux(inRange, candidate, selected).asSInt
    }
    val upper = Mux(input >= 2048.S(16.W), input.pad(48), selected).asSInt
    val capped = Mux(input <= 0.S(16.W) && upper > 0.S(48.W), 0.S(48.W), upper).asSInt
    DiffusionFixedPoint.saturateInt16(capped)
  }
}

class SiluPwl(lanes: Int, segments: Int = 16) extends Module {
  require(lanes > 0)
  require(segments == 16 || segments == 32)

  val io = IO(new Bundle {
    val input = Flipped(Decoupled(Vec(lanes, SInt(16.W))))
    val output = Decoupled(Vec(lanes, SInt(16.W)))
  })

  val result = RegInit(VecInit(Seq.fill(lanes)(0.S(16.W))))
  val outputValid = RegInit(false.B)
  io.input.ready := !outputValid || io.output.ready

  when(io.input.fire) {
    for (lane <- 0 until lanes) {
      result(lane) := SiluPwl(io.input.bits(lane), segments)
    }
    outputValid := true.B
  }.elsewhen(io.output.fire) {
    outputValid := false.B
  }

  io.output.bits := result
  io.output.valid := outputValid
}
