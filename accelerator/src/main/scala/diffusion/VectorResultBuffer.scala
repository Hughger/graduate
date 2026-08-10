package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

/** Stores requantized convolution vectors for a later GroupNorm/read phase. */
class VectorResultBuffer(depthVectors: Int, lanes: Int, addressWidth: Int = 12) extends Module {
  require(depthVectors > 0)
  require(lanes > 0)

  private val indexWidth = math.max(1, log2Ceil(depthVectors))
  private val countWidth = math.max(1, log2Ceil(depthVectors + 1))
  val io = IO(new Bundle {
    val clear = Input(Bool())
    val input = Flipped(Decoupled(Vec(lanes, SInt(16.W))))
    val occupancy = Output(UInt(countWidth.W))
    val command = Flipped(Decoupled(new TensorVectorReadCommand(addressWidth)))
    val output = Decoupled(Vec(lanes, SInt(16.W)))
    val done = Output(Bool())
  })

  val storage = Reg(Vec(depthVectors, Vec(lanes, SInt(16.W))))
  val writeIndex = RegInit(0.U(indexWidth.W))
  val occupancy = RegInit(0.U(countWidth.W))
  val reading = RegInit(false.B)
  val readIndex = Reg(UInt(indexWidth.W))
  val remaining = Reg(UInt(16.W))
  val doneReg = RegInit(false.B)

  io.input.ready := !io.clear && occupancy =/= depthVectors.U
  io.occupancy := occupancy
  io.command.ready := !reading && !io.clear
  io.output.valid := reading
  io.output.bits := storage(readIndex)
  io.done := doneReg
  doneReg := false.B

  when(io.clear) {
    writeIndex := 0.U
    occupancy := 0.U
    reading := false.B
    remaining := 0.U
  }.elsewhen(io.input.fire) {
    storage(writeIndex) := io.input.bits
    writeIndex := Mux(writeIndex === (depthVectors - 1).U, 0.U, writeIndex + 1.U)
    occupancy := occupancy + 1.U
  }

  when(io.command.fire) {
    readIndex := io.command.bits.baseAddress(indexWidth - 1, 0)
    remaining := io.command.bits.vectors
    when(io.command.bits.vectors === 0.U) {
      doneReg := true.B
    }.otherwise {
      reading := true.B
    }
  }
  when(io.output.fire) {
    when(remaining === 1.U) {
      reading := false.B
      doneReg := true.B
    }.otherwise {
      readIndex := Mux(readIndex === (depthVectors - 1).U, 0.U, readIndex + 1.U)
      remaining := remaining - 1.U
    }
  }
}
