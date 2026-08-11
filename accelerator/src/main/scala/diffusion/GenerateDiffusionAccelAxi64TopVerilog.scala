package FLOOD_Accelerator.diffusion

import chisel3.stage.ChiselStage

/** Emits the real diffusion top with the 64-bit AXI4 memory backend selected.
  *
  * The resulting RTL is intended for a later AXKU15 wrapper that instantiates
  * the vendor DDR4 controller.  This generator does not copy or modify that
  * vendor project.
  */
object GenerateDiffusionAccelAxi64TopVerilog extends App {
  private val parsed = args.toList
  private val targetDir = parsed.sliding(2).collectFirst {
    case List("--target-dir", value) => value
  }.getOrElse("target/generated/diffusion-accel-axi64-top")

  (new ChiselStage).emitVerilog(
    new DiffusionAccelTop(memoryBackend = DiffusionMemoryBackend.Axi64),
    Array("--target-dir", targetDir)
  )
}
