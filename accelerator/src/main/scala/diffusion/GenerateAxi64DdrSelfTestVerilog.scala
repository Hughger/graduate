package FLOOD_Accelerator.diffusion

import chisel3.stage.ChiselStage

/** Emits the standalone AXKU15 AXI64 DDR4 transport self-test. */
object GenerateAxi64DdrSelfTestVerilog extends App {
  private val parsed = args.toList
  private val targetDir = parsed.sliding(2).collectFirst {
    case List("--target-dir", value) => value
  }.getOrElse("target/generated/axi64-ddr4-selftest")

  (new ChiselStage).emitVerilog(
    new Axi64DdrSelfTest,
    Array("--target-dir", targetDir)
  )
}
