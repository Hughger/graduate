package FLOOD_Accelerator.diffusion

import chisel3.stage.ChiselStage

/** Emits the implementation top, rather than the lightweight contract-only top.
  *
  * The generated module keeps the AXI-Lite control plane, tensor DMA ports and
  * MIG application-port seam intact so it can be integrated by an AXKU15 board
  * wrapper once the physical DDR4 controller has been qualified.
  */
object GenerateDiffusionAccelTopVerilog extends App {
  private val parsed = args.toList
  private val targetDir = parsed.sliding(2).collectFirst {
    case List("--target-dir", value) => value
  }.getOrElse("target/generated/diffusion-accel-top")

  (new ChiselStage).emitVerilog(
    new DiffusionAccelTop,
    Array("--target-dir", targetDir)
  )
}
