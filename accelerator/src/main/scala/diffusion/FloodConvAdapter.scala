package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

class ConvWeightWrite extends Bundle {
  val row = UInt(5.W)
  val column = UInt(5.W)
  val data = SInt(8.W)
}

/**
  * Isolated 32x32 raw-MAC contract for diffusion convolution tiles.
  *
  * Legacy CIMCore quantizes its outputs, so this adapter deliberately keeps
  * the signed INT32 accumulation result available to the diffusion scheduler.
  */
class FloodConvAdapter(p: DiffusionParams) extends Module {
  require(p.ciTile == 32 && p.coTile == 32)

  val io = IO(new Bundle {
    val weightWrite = Flipped(Decoupled(new ConvWeightWrite))
    val activation = Flipped(Decoupled(Vec(p.ciTile, SInt(p.dataWidth.W))))
    val output = Decoupled(Vec(p.coTile, SInt(p.accumWidth.W)))
  })

  val weights = RegInit(VecInit(Seq.fill(p.ciTile)(VecInit(Seq.fill(p.coTile)(0.S(p.dataWidth.W))))))
  val result = RegInit(VecInit(Seq.fill(p.coTile)(0.S(p.accumWidth.W))))
  val outputValid = RegInit(false.B)

  io.weightWrite.ready := true.B
  when(io.weightWrite.fire) {
    weights(io.weightWrite.bits.row)(io.weightWrite.bits.column) := io.weightWrite.bits.data
  }

  io.activation.ready := !outputValid || io.output.ready
  val dotProducts = Wire(Vec(p.coTile, SInt(p.accumWidth.W)))
  for (column <- 0 until p.coTile) {
    val sum = (0 until p.ciTile)
      .map(row => io.activation.bits(row) * weights(row)(column))
      .reduce(_ +& _)
    dotProducts(column) := sum.pad(p.accumWidth).asSInt
  }

  when(io.activation.fire) {
    result := dotProducts
    outputValid := true.B
  }.elsewhen(io.output.fire) {
    outputValid := false.B
  }

  io.output.bits := result
  io.output.valid := outputValid
}
