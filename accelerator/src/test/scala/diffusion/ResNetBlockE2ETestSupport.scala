package FLOOD_Accelerator.diffusion

final case class GroupStatsReference(sum: BigInt, sumSquare: BigInt, count: BigInt)

object ResNetBlockE2EReference {
  val rsqrtVarianceOne: BigInt = BigInt(759250125)

  def packLanes(lanes: Seq[Int]): BigInt = {
    require(lanes.length == 32, "one tensor beat contains 32 INT16 lanes")
    lanes.zipWithIndex.map { case (lane, index) =>
      (BigInt(lane & 0xffff) << (16 * index))
    }.sum
  }

  def unpackLanes(word: BigInt): Vector[Int] = {
    Vector.tabulate(32) { index =>
      val bits = ((word >> (16 * index)) & 0xffff).toInt
      if ((bits & 0x8000) == 0) bits else bits - 0x10000
    }
  }

  def stats(lanes: Seq[Int]): GroupStatsReference = {
    GroupStatsReference(
      lanes.foldLeft(BigInt(0))((sum, lane) => sum + lane),
      lanes.foldLeft(BigInt(0))((sum, lane) => sum + BigInt(lane) * lane),
      BigInt(lanes.length)
    )
  }

  def roundAwayFromZero(value: BigInt, shift: Int): BigInt = {
    require(shift >= 0)
    if (shift == 0) value
    else {
      val magnitude = value.abs
      val rounded = (magnitude + (BigInt(1) << (shift - 1))) >> shift
      if (value < 0) -rounded else rounded
    }
  }

  def saturateInt16(value: BigInt): Int = value.max(-32768).min(32767).toInt

  def silu16(value: Int): Int = {
    val selected = SiluCoeffs.segments16.find(segment => value >= segment.startQ8 && value < segment.endQ8)
      .map { segment => roundAwayFromZero(BigInt(value) * segment.slopeQ16, 16) + segment.interceptQ8 }
      .getOrElse(BigInt(-71))
    val upper = if (value >= 2048) BigInt(value) else selected
    val capped = if (value <= 0 && upper > 0) BigInt(0) else upper
    saturateInt16(capped)
  }

  def finalLanes(input: Vector[Int], temb: Vector[Int], residual: Vector[Int]): Vector[Int] = {
    require(input.length == 32 && temb.length == 32 && residual.length == 32)
    val inputStats = stats(input)
    require(inputStats == GroupStatsReference(0, 32, 32), "directed input must have variance one")
    input.zipWithIndex.map { case (lane, index) =>
      val normalized = roundAwayFromZero(BigInt(lane) * rsqrtVarianceOne, 30)
      val affine = roundAwayFromZero(normalized * 256, 8)
      val activation = silu16(saturateInt16(affine))
      saturateInt16(BigInt(activation) + temb(index) + residual(index))
    }
  }
}
