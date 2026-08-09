package FLOOD_Accelerator.diffusion

import org.scalatest.flatspec.AnyFlatSpec

class TensorDmaSpec extends AnyFlatSpec {
  "TensorDma" should "split 512-bit bursts at 4KB boundaries" in {
    assert(TensorDma.planBursts(BigInt(0), 256) == Seq(
      DmaBurst(BigInt(0), 256)
    ))
    assert(TensorDma.planBursts(BigInt(0xfc0), 128) == Seq(
      DmaBurst(BigInt(0xfc0), 64),
      DmaBurst(BigInt(0x1000), 64)
    ))
  }
}
