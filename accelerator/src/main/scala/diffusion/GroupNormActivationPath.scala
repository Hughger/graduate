package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

/** Turns completed GroupNorm statistics plus affine parameters into SiLU activations. */
class GroupNormActivationPath(lanes: Int, affineShift: Int = 8, siluSegments: Int = 16) extends Module {
  val io = IO(new Bundle {
    val stats = Flipped(Decoupled(new GroupStats))
    val affineWrite = Flipped(Decoupled(new GroupNormAffineWrite(math.max(1, log2Ceil(lanes)))))
    val activation = Flipped(Decoupled(Vec(lanes, SInt(16.W))))
    val output = Decoupled(Vec(lanes, SInt(16.W)))
    val parametersReady = Output(Bool())
  })

  val parameters = Module(new GroupNormParameterGenerator)
  val affine = Module(new GroupNormAffineParameterStore(lanes))
  val activation = Module(new GroupNormSilu(lanes, affineShift, siluSegments))
  val parameterReg = RegInit(0.U.asTypeOf(new GroupNormParameters))
  val parametersReady = RegInit(false.B)

  parameters.io.input <> io.stats
  parameters.io.output.ready := !parametersReady
  when(parameters.io.output.fire) {
    parameterReg := parameters.io.output.bits
    parametersReady := true.B
  }
  affine.io.write <> io.affineWrite
  activation.io.mean := parameterReg.mean
  activation.io.rsqrtQ30 := parameterReg.rsqrtQ30
  activation.io.gamma := affine.io.gamma
  activation.io.beta := affine.io.beta
  activation.io.input.valid := parametersReady && io.activation.valid
  activation.io.input.bits := io.activation.bits
  io.activation.ready := parametersReady && activation.io.input.ready
  io.output <> activation.io.output
  io.parametersReady := parametersReady
}
