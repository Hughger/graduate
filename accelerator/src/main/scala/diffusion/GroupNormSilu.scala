package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

/** Applies one affine GroupNorm vector followed by the prototype SiLU PWL. */
class GroupNormSilu(lanes: Int, affineShift: Int = 8, siluSegments: Int = 16) extends Module {
  val io = IO(new Bundle {
    val input = Flipped(Decoupled(Vec(lanes, SInt(16.W))))
    val mean = Input(SInt(16.W))
    val rsqrtQ30 = Input(UInt(32.W))
    val gamma = Input(Vec(lanes, SInt(16.W)))
    val beta = Input(Vec(lanes, SInt(16.W)))
    val output = Decoupled(Vec(lanes, SInt(16.W)))
  })

  val groupNorm = Module(new GroupNormApply(lanes, affineShift))
  val silu = Module(new SiluPwl(lanes, siluSegments))
  groupNorm.io.input <> io.input
  groupNorm.io.mean := io.mean
  groupNorm.io.rsqrtQ30 := io.rsqrtQ30
  groupNorm.io.gamma := io.gamma
  groupNorm.io.beta := io.beta
  silu.io.input <> groupNorm.io.output
  io.output <> silu.io.output
}
