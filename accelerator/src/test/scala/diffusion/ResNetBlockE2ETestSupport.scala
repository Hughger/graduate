package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._

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

  def finalLanesWithRsqrt(input: Vector[Int], temb: Vector[Int], residual: Vector[Int], rsqrtQ30: BigInt): Vector[Int] = {
    require(input.length == 32 && temb.length == 32 && residual.length == 32)
    input.zipWithIndex.map { case (lane, index) =>
      val normalized = roundAwayFromZero(BigInt(lane) * rsqrtQ30, 30)
      val affine = roundAwayFromZero(normalized * 256, 8)
      val activation = silu16(saturateInt16(affine))
      saturateInt16(BigInt(activation) + temb(index) + residual(index))
    }
  }

  def finalLanes(input: Vector[Int], temb: Vector[Int], residual: Vector[Int]): Vector[Int] = {
    require(stats(input) == GroupStatsReference(0, 32, 32), "directed input must have variance one")
    finalLanesWithRsqrt(input, temb, residual, rsqrtVarianceOne)
  }
}

final case class Axi64DelayProfile(aw: Int, w: Int, b: Int, ar: Int, r: Int) {
  require(Seq(aw, w, b, ar, r).forall(_ >= 0), "AXI64 delays must be nonnegative")
}

object Axi64DelayProfile {
  val immediate: Axi64DelayProfile = Axi64DelayProfile(0, 0, 0, 0, 0)
  val staggered: Axi64DelayProfile = Axi64DelayProfile(1, 2, 1, 3, 2)
}

final class Axi64MemoryModel(axi: Axi4Master64, delays: Axi64DelayProfile) {
  private val bytes = scala.collection.mutable.Map.empty[BigInt, Int].withDefaultValue(0)
  private var writeAddress: Option[BigInt] = None
  private var writeBeat = 0
  private var writeDelay = 0
  private var addressDelay = delays.aw
  private var responseDelay = 0
  private var responsePending = false
  private var readAddressDelay = delays.ar
  private var readDelay = 0
  private var readWords = Vector.empty[BigInt]
  private var readBeat = 0
  private var protocolError: Option[String] = None
  private val delayed = scala.collection.mutable.Set.empty[String]
  private val readAddressHistory = scala.collection.mutable.ArrayBuffer.empty[BigInt]
  private val writeAddressHistory = scala.collection.mutable.ArrayBuffer.empty[BigInt]

  private def bit(value: BigInt, index: Int): Boolean = ((value >> index) & 1) == 1
  private def read64(address: BigInt): BigInt = (0 until 8).map { offset => BigInt(bytes(address + offset)) << (8 * offset) }.sum
  private def write64(address: BigInt, data: BigInt, strobe: BigInt): Unit = {
    for (offset <- 0 until 8 if bit(strobe, offset)) {
      bytes.update(address + offset, ((data >> (8 * offset)) & 0xff).toInt)
    }
  }
  private def fail(message: String): Unit = if (protocolError.isEmpty) protocolError = Some(message)
  private def lit(value: chisel3.Data): BigInt = value.peek().litValue
  private def bool(value: chisel3.Bool): Boolean = value.peek().litToBoolean

  def load512(address: BigInt, word: BigInt): Unit = {
    require(address % 64 == 0, "512-bit address must be 64-byte aligned")
    for (offset <- 0 until 64) bytes.update(address + offset, ((word >> (8 * offset)) & 0xff).toInt)
  }

  def read512(address: BigInt): BigInt = {
    require(address % 64 == 0, "512-bit address must be 64-byte aligned")
    (0 until 64).map(offset => BigInt(bytes(address + offset)) << (8 * offset)).sum
  }

  def delayedChannels: Set[String] = delayed.toSet
  def readBurstAddresses: Vector[BigInt] = readAddressHistory.toVector
  def writeBurstAddresses: Vector[BigInt] = writeAddressHistory.toVector

  def driveBeforeClock(): Unit = {
    axi.aw.ready.poke((writeAddress.isEmpty && addressDelay == 0).B)
    axi.w.ready.poke((writeAddress.nonEmpty && writeDelay == 0).B)
    axi.b.valid.poke((responsePending && responseDelay == 0).B)
    axi.b.bits.id.poke(0.U); axi.b.bits.resp.poke(0.U)
    axi.ar.ready.poke((readWords.isEmpty && readAddressDelay == 0).B)
    axi.r.valid.poke((readWords.nonEmpty && readDelay == 0).B)
    axi.r.bits.data.poke(readWords.lift(readBeat).getOrElse(BigInt(0)).U)
    axi.r.bits.id.poke(0.U); axi.r.bits.resp.poke(0.U)
    axi.r.bits.last.poke((readWords.nonEmpty && readBeat == 7).B)
  }

  def observeBeforeClock(): Unit = {
    if (writeAddress.isEmpty && bool(axi.aw.valid) && addressDelay > 0) { delayed += "AW"; addressDelay -= 1 }
    if (writeAddress.nonEmpty && bool(axi.w.valid) && writeDelay > 0) { delayed += "W"; writeDelay -= 1 }
    if (responsePending && responseDelay > 0) { if (bool(axi.b.ready)) delayed += "B"; responseDelay -= 1 }
    if (readWords.isEmpty && bool(axi.ar.valid) && readAddressDelay > 0) { delayed += "AR"; readAddressDelay -= 1 }
    if (readWords.nonEmpty && readDelay > 0) { if (bool(axi.r.ready)) delayed += "R"; readDelay -= 1 }

    if (bool(axi.aw.valid) && bool(axi.aw.ready)) {
      if (lit(axi.aw.bits.id) != 0 || lit(axi.aw.bits.len) != 7 || lit(axi.aw.bits.size) != 3) fail("invalid AXI write address burst")
      val base = lit(axi.aw.bits.addr)
      writeAddressHistory += base
      writeAddress = Some(base); writeBeat = 0; writeDelay = delays.w
    }
    if (bool(axi.w.valid) && bool(axi.w.ready)) {
      val base = writeAddress.getOrElse { fail("write data without address"); BigInt(0) }
      if (bool(axi.w.bits.last) != (writeBeat == 7)) fail("invalid AXI write last")
      write64(base + 8 * writeBeat, lit(axi.w.bits.data), lit(axi.w.bits.strb))
      if (writeBeat == 7) { writeAddress = None; responsePending = true; responseDelay = delays.b; addressDelay = delays.aw }
      else { writeBeat += 1; writeDelay = delays.w }
    }
    if (bool(axi.b.valid) && bool(axi.b.ready)) responsePending = false

    if (bool(axi.ar.valid) && bool(axi.ar.ready)) {
      if (lit(axi.ar.bits.id) != 0 || lit(axi.ar.bits.len) != 7 || lit(axi.ar.bits.size) != 3) fail("invalid AXI read address burst")
      val base = lit(axi.ar.bits.addr)
      readAddressHistory += base
      readWords = Vector.tabulate(8)(beat => read64(base + 8 * beat)); readBeat = 0; readDelay = delays.r; readAddressDelay = delays.ar
    }
    if (bool(axi.r.valid) && bool(axi.r.ready)) {
      if (bool(axi.r.bits.last) != (readBeat == 7)) fail("invalid AXI read last")
      if (readBeat == 7) { readWords = Vector.empty; readBeat = 0 }
      else { readBeat += 1; readDelay = delays.r }
    }
  }

  def assertNoProtocolError(): Unit = protocolError.foreach(message => throw new AssertionError(message))
}