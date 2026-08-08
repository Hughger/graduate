package FLOOD_Accelerator.diffusion

case class DiffusionParams(
  tileCount: Int,
  ciTile: Int = 32,
  coTile: Int = 32,
  dataWidth: Int = 8,
  accumWidth: Int = 32,
  activationWidth: Int = 16,
  groupCount: Int = 32,
  axiDataWidth: Int = 512,
  addressWidth: Int = 64
) {
  require(tileCount == 8 || tileCount == 16, "only 8- and 16-tile configurations are supported")
  require(ciTile == 32 && coTile == 32, "SD1.5 channel tiles are fixed at 32")
  require(dataWidth == 8 && activationWidth == 16, "prototype precision is W8A8 with INT16 activations")
  require(accumWidth >= 32, "accumulator must hold INT32 products")
  require(groupCount == 32, "SD1.5 GroupNorm uses 32 groups")
  require(axiDataWidth % 8 == 0 && addressWidth >= 32, "AXI widths must be byte addressable")
}

object DiffusionParams {
  val sd15EightTile: DiffusionParams = DiffusionParams(tileCount = 8)
  val sd15SixteenTile: DiffusionParams = DiffusionParams(tileCount = 16)
}
