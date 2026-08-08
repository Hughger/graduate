package FLOOD_Accelerator.diffusion

import org.scalatest.flatspec.AnyFlatSpec

class DiffusionParamsSpec extends AnyFlatSpec {
  "sd15EightTile" should "lock the AXKU15 prototype contract" in {
    val params = DiffusionParams.sd15EightTile
    assert(params.tileCount == 8)
    assert(params.ciTile == 32 && params.coTile == 32)
    assert(params.dataWidth == 8 && params.accumWidth == 32)
    assert(params.activationWidth == 16 && params.groupCount == 32)
    assert(params.axiDataWidth == 512 && params.addressWidth == 64)
  }

  it should "reject unsupported tile and channel configurations" in {
    assertThrows[IllegalArgumentException](DiffusionParams(tileCount = 4))
    assertThrows[IllegalArgumentException](DiffusionParams(tileCount = 8, ciTile = 16))
  }
}
