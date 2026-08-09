package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

/** A contiguous tensor-read request measured in 512-bit (64-byte) beats. */
class TensorReadCommand extends Bundle {
  val address = UInt(29.W)
  val beats = UInt(24.W)
}

/**
  * Converts a contiguous tensor read into ordered 512-bit MIG application
  * reads. Only one read is outstanding, so returned data can be safely held
  * until the downstream tile buffer accepts it.
  */
class TensorReadDma extends Module {
  val io = IO(new Bundle {
    val command = Flipped(Decoupled(new TensorReadCommand))
    val data = Decoupled(UInt(512.W))
    val busy = Output(Bool())
    val done = Output(Bool())
    val memoryRequest = Decoupled(new MigAppRequest)
    val memoryResponse = Flipped(Decoupled(UInt(512.W)))
  })

  val idle :: issueRead :: waitReadData :: emitData :: Nil = Enum(4)
  val state = RegInit(idle)
  val addressReg = Reg(UInt(29.W))
  val remainingReg = Reg(UInt(24.W))
  val dataReg = Reg(UInt(512.W))
  val doneReg = RegInit(false.B)

  io.command.ready := state === idle
  io.data.valid := state === emitData
  io.data.bits := dataReg
  io.busy := state =/= idle
  io.done := doneReg

  io.memoryRequest.valid := state === issueRead
  io.memoryRequest.bits.write := false.B
  io.memoryRequest.bits.address := addressReg
  io.memoryRequest.bits.writeData := 0.U
  io.memoryRequest.bits.writeMask := 0.U
  io.memoryResponse.ready := state === waitReadData

  doneReg := false.B
  when(io.command.fire) {
    addressReg := io.command.bits.address
    remainingReg := io.command.bits.beats
    when(io.command.bits.beats === 0.U) {
      doneReg := true.B
    }.otherwise {
      state := issueRead
    }
  }

  when(state === issueRead && io.memoryRequest.fire) {
    state := waitReadData
  }

  when(state === waitReadData && io.memoryResponse.fire) {
    dataReg := io.memoryResponse.bits
    state := emitData
  }

  when(state === emitData && io.data.fire) {
    when(remainingReg === 1.U) {
      state := idle
      doneReg := true.B
    }.otherwise {
      addressReg := addressReg + 64.U
      remainingReg := remainingReg - 1.U
      state := issueRead
    }
  }
}
