package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

object RsqrtUnit {
  private val q30 = BigInt(1) << 30
  private val invSqrt2Q30 = BigInt(759250125)
  private val mantissaLutValues = (0 until 256).map { index =>
    val value = math.floor(q30.toDouble / math.sqrt(1.0 + (index + 0.5) / 256.0) + 0.5).toLong
    BigInt(value)
  }

  private def newton(estimate: UInt, mantissaQ31: UInt): UInt = {
    val squareQ30 = ((estimate * estimate) >> 30).asUInt
    val productQ31 = ((mantissaQ31 * squareQ30) >> 30).asUInt
    val factor = Wire(SInt(34.W))
    factor := (3L << 29).S(34.W) - (productQ31 >> 2).pad(34).asSInt
    val updated = ((estimate.asSInt * factor + (BigInt(1) << 29).S(66.W)) >> 30).asSInt
    updated.pad(32).asUInt
  }

  def compute(variance: UInt): UInt = {
    val mantissaLut = VecInit(mantissaLutValues.map(_.U(31.W)))
    val adjusted = Cat(0.U(1.W), variance) + 1.U
    val exponent = Wire(UInt(6.W))
    exponent := 0.U
    for (bit <- 0 until 33) {
      when(adjusted(bit)) { exponent := bit.U }
    }
    val mantissaQ31 = Wire(UInt(64.W))
    when(exponent <= 31.U) {
      mantissaQ31 := (adjusted << (31.U - exponent)).pad(64)
    }.otherwise {
      mantissaQ31 := adjusted >> (exponent - 31.U)
    }
    val estimate0 = mantissaLut(mantissaQ31(30, 23))
    val estimate1 = newton(estimate0, mantissaQ31)
    val estimate2 = newton(estimate1(30, 0), mantissaQ31)
    val oddAdjusted = Wire(UInt(64.W))
    oddAdjusted := estimate2
    when(exponent(0)) {
      oddAdjusted := ((estimate2 * invSqrt2Q30.U(31.W)) >> 30).pad(64)
    }
    (oddAdjusted >> exponent(5, 1))(31, 0)
  }
}

class RsqrtUnit extends Module {
  val io = IO(new Bundle {
    val input = Flipped(Decoupled(UInt(32.W)))
    val output = Decoupled(UInt(32.W))
  })

  val result = RegInit(0.U(32.W))
  val outputValid = RegInit(false.B)
  io.input.ready := !outputValid || io.output.ready
  when(io.input.fire) {
    result := RsqrtUnit.compute(io.input.bits)
    outputValid := true.B
  }.elsewhen(io.output.fire) {
    outputValid := false.B
  }
  io.output.bits := result
  io.output.valid := outputValid
}
