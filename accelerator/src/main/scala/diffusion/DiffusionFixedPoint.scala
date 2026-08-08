package FLOOD_Accelerator.diffusion

import chisel3._

object DiffusionFixedPoint {
  def saturateInt16(value: SInt): SInt = {
    val wide = value.pad(64)
    val maximum = 32767.S(64.W)
    val minimum = (-32768).S(64.W)
    val clipped = Mux(wide > maximum, maximum, Mux(wide < minimum, minimum, wide))
    clipped(15, 0).asSInt
  }

  def roundShiftAwayFromZero(value: SInt, shift: Int): SInt = {
    require(shift >= 0)
    if (shift == 0) {
      value
    } else {
      val wide = value.pad(64)
      val negative = wide < 0.S(64.W)
      val magnitude = Mux(negative, (-wide).asSInt, wide)
      val rounded = ((magnitude + (1 << (shift - 1)).S(64.W)) >> shift).asSInt
      Mux(negative, (-rounded).asSInt, rounded).asSInt
    }
  }
}
