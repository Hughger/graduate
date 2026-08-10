package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

/** Fixed-point parameters derived from one GroupNorm statistics reduction. */
class GroupNormParameters extends Bundle {
  val mean = SInt(16.W)
  val variance = UInt(32.W)
  val rsqrtQ30 = UInt(32.W)
}

/** Converts sum/square/count statistics into the parameters consumed by GroupNormApply. */
class GroupNormParameterGenerator extends Module {
  val io = IO(new Bundle {
    val input = Flipped(Decoupled(new GroupStats))
    val output = Decoupled(new GroupNormParameters)
  })

  def saturateInt16(value: SInt): SInt = {
    val wide = value.pad(64)
    val clipped = Mux(wide > 32767.S(64.W), 32767.S(64.W), Mux(wide < (-32768).S(64.W), (-32768).S(64.W), wide))
    clipped(15, 0).asSInt
  }

  val result = RegInit(0.U.asTypeOf(new GroupNormParameters))
  val outputValid = RegInit(false.B)
  io.input.ready := !outputValid || io.output.ready

  when(io.input.fire) {
    val countNonZero = io.input.bits.count =/= 0.U
    val meanWide = Wire(SInt(64.W))
    meanWide := Mux(countNonZero, (io.input.bits.sum / io.input.bits.count.asSInt).asSInt, 0.S)
    val averageSquare = Wire(UInt(64.W))
    averageSquare := Mux(countNonZero, io.input.bits.sumSquare / io.input.bits.count, 0.U)
    val meanSquareWide = (meanWide * meanWide).asUInt
    val meanSquare = Wire(UInt(64.W))
    meanSquare := Mux(meanSquareWide > "hffffffffffffffff".U, "hffffffffffffffff".U, meanSquareWide(63, 0))
    val varianceWide = Mux(averageSquare > meanSquare, averageSquare - meanSquare, 0.U)
    val variance = Mux(varianceWide > "hffffffff".U, "hffffffff".U, varianceWide(31, 0))
    result.mean := saturateInt16(meanWide)
    result.variance := variance
    result.rsqrtQ30 := RsqrtUnit.compute(variance)
    outputValid := true.B
  }.elsewhen(io.output.fire) {
    outputValid := false.B
  }

  io.output.bits := result
  io.output.valid := outputValid
}
