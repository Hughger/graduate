package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

class GroupNormAffineWrite(channelWidth: Int) extends Bundle {
  val channel = UInt(channelWidth.W)
  val gamma = SInt(16.W)
  val beta = SInt(16.W)
}

/** Holds one Q8.8 gamma/beta pair per activation channel. */
class GroupNormAffineParameterStore(lanes: Int) extends Module {
  require(lanes > 0)
  private val channelWidth = math.max(1, log2Ceil(lanes))
  val io = IO(new Bundle {
    val write = Flipped(Decoupled(new GroupNormAffineWrite(channelWidth)))
    val gamma = Output(Vec(lanes, SInt(16.W)))
    val beta = Output(Vec(lanes, SInt(16.W)))
  })

  val gamma = RegInit(VecInit(Seq.fill(lanes)(256.S(16.W))))
  val beta = RegInit(VecInit(Seq.fill(lanes)(0.S(16.W))))
  io.write.ready := true.B
  when(io.write.fire) {
    gamma(io.write.bits.channel) := io.write.bits.gamma
    beta(io.write.bits.channel) := io.write.bits.beta
  }
  io.gamma := gamma
  io.beta := beta
}
