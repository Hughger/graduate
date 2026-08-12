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

  it should "derive a symmetric variance-four directed result" in {
    val input = Vector.fill(16)(-2) ++ Vector.fill(16)(2)
    val temb = Vector.fill(32)(5)
    val residual = Vector.fill(32)(-3)
    ResNetBlockE2EReference.stats(input) shouldBe GroupStatsReference(0, 128, 32)
    ResNetBlockE2EReference.finalLanesWithRsqrt(
      input, temb, residual, BigInt(480191942)
    ).size shouldBe 32
  }

  it should "derive a nonzero-mean variance-four directed result" in {
    val input0 = Vector.fill(16)(1) ++ Vector.fill(16)(2)
    val input1 = Vector.fill(32)(5)
    val temb = Vector.fill(32)(5)
    val residual = Vector.fill(32)(-3)
    val rsqrtVarianceFour = BigInt(480191942)

    ResNetBlockE2EReference.stats(input0 ++ input1) shouldBe GroupStatsReference(208, 880, 64)

    val meanAware = ResNetBlockE2EReference.finalLanesWithMeanAndRsqrt(
      input0, temb, residual, mean = 3, rsqrtVarianceFour
    )
    val zeroMean = ResNetBlockE2EReference.finalLanesWithRsqrt(
      input0, temb, residual, rsqrtVarianceFour
    )

    meanAware.size shouldBe 32
    meanAware should not be zeroMean
  }
}
