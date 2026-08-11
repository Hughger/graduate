package FLOOD_Accelerator.diffusion

import org.scalatest.flatspec.AnyFlatSpec
import org.scalatest.matchers.should.Matchers

class ResNetBlockE2ETestSupportSpec extends AnyFlatSpec with Matchers {
  "ResNetBlockE2EReference" should "pack 32 signed lanes little-endian" in {
    val lanes = Vector.tabulate(32)(_ - 16)
    ResNetBlockE2EReference.unpackLanes(ResNetBlockE2EReference.packLanes(lanes)) shouldBe lanes
  }

  it should "derive the directed variance-one result" in {
    val input = Vector.fill(16)(-1) ++ Vector.fill(16)(1)
    ResNetBlockE2EReference.stats(input) shouldBe GroupStatsReference(0, 32, 32)
    ResNetBlockE2EReference.rsqrtVarianceOne shouldBe BigInt(759250125)
    ResNetBlockE2EReference.finalLanes(input, Vector.fill(32)(3), Vector.fill(32)(-2)).size shouldBe 32
  }

  it should "apply time and residual values by lane after duplicate activations" in {
    val input = Vector.fill(16)(-1) ++ Vector.fill(16)(1)
    val temb = Vector.tabulate(32)(identity)
    val output = ResNetBlockE2EReference.finalLanes(input, temb, Vector.fill(32)(0))
    output shouldBe Vector.tabulate(32) { lane => lane + (if (lane < 16) 0 else 2) }
  }
}
