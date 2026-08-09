package FLOOD_Accelerator.diffusion

case class DmaBurst(address: BigInt, bytes: Int)

object TensorDma {
  val BeatBytes = 64
  val MaxBurstBytes = 256 * BeatBytes

  /** Plan aligned AXI4-MM bursts without crossing a 4KB address boundary. */
  def planBursts(baseAddress: BigInt, bytes: Int): Seq[DmaBurst] = {
    require(baseAddress >= 0 && baseAddress % BeatBytes == 0, "DMA address must be 64-byte aligned")
    require(bytes >= 0 && bytes % BeatBytes == 0, "DMA byte count must be a multiple of 64")
    var address = baseAddress
    var remaining = bytes
    val bursts = scala.collection.mutable.ArrayBuffer.empty[DmaBurst]
    while (remaining > 0) {
      val toBoundary = 4096 - (address & 0xfff).toInt
      val burstBytes = math.min(remaining, math.min(toBoundary, MaxBurstBytes))
      bursts += DmaBurst(address, burstBytes)
      address += burstBytes
      remaining -= burstBytes
    }
    bursts.toSeq
  }
}
