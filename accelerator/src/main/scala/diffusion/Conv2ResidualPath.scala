package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

/** Executes W8A8 Conv2, requantizes it, then applies time and residual fusion. */
class Conv2ResidualPath(p: DiffusionParams) extends Module {
  val io = IO(new Bundle {
    val command = Flipped(Decoupled(new ConvBatchCommand))
    val weightWrite = Flipped(Decoupled(new ConvWeightWrite))
    val activation = Flipped(Decoupled(Vec(p.ciTile, SInt(16.W))))
    val inputShift = Input(UInt(4.W))
    val outputShift = Input(UInt(5.W))
    val temb = Input(Vec(p.coTile, SInt(16.W)))
    val residual = Input(Vec(p.coTile, SInt(16.W)))
    val addResidual = Input(Bool())
    val output = Decoupled(Vec(p.coTile, SInt(16.W)))
    val done = Output(Bool())
  })

  val inputRequant = Module(new VectorRequantizeInt16ToInt8(p.ciTile))
  val conv = Module(new ConvBatchEngine(p))
  val outputRequant = Module(new VectorRequantizeInt32ToInt16(p.coTile))
  val fuse = Module(new TimeResidualFuse(p.coTile))
  val active = RegInit(false.B)
  val remaining = Reg(UInt(16.W))
  val doneReg = RegInit(false.B)

  conv.io.weightWrite <> io.weightWrite
  conv.io.command.valid := !active && io.command.valid
  conv.io.command.bits := io.command.bits
  io.command.ready := !active && conv.io.command.ready
  inputRequant.io.shift := io.inputShift
  inputRequant.io.input <> io.activation
  conv.io.activation <> inputRequant.io.output
  outputRequant.io.shift := io.outputShift
  outputRequant.io.input <> conv.io.output
  fuse.io.input <> outputRequant.io.output
  fuse.io.temb := io.temb
  fuse.io.residual := io.residual
  fuse.io.addResidual := io.addResidual
  io.output <> fuse.io.output
  io.done := doneReg
  doneReg := false.B

  when(conv.io.command.fire) {
    remaining := io.command.bits.vectors
    when(io.command.bits.vectors === 0.U) { doneReg := true.B }
      .otherwise { active := true.B }
  }
  when(active && fuse.io.output.fire) {
    when(remaining === 1.U) {
      active := false.B
      doneReg := true.B
    }.otherwise {
      remaining := remaining - 1.U
    }
  }
}
