package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

/** A contiguous full-beat tensor-write request measured in 64-byte beats. */
class TensorWriteCommand extends Bundle {
  val address = UInt(29.W)
  val beats = UInt(24.W)
}

/**
  * Accepts 512-bit tensor beats and writes them in order through MigAppTransfer.
  * A new beat is not accepted until the prior write has completed on both MIG
  * command and write-data channels.
  */
class TensorWriteDma extends Module {
  val io = IO(new Bundle {
    val command = Flipped(Decoupled(new TensorWriteCommand))
    val data = Flipped(Decoupled(UInt(512.W)))
    val busy = Output(Bool())
    val done = Output(Bool())
    val memoryRequest = Decoupled(new MigAppRequest)
    val memoryDone = Input(Bool())
  })

  val idle :: waitData :: issueWrite :: waitWriteDone :: Nil = Enum(4)
  val state = RegInit(idle)
  val addressReg = Reg(UInt(29.W))
  val remainingReg = Reg(UInt(24.W))
  val dataReg = Reg(UInt(512.W))
  val doneReg = RegInit(false.B)

  io.command.ready := state === idle
  io.data.ready := state === waitData
  io.busy := state =/= idle
  io.done := doneReg

  io.memoryRequest.valid := state === issueWrite
  io.memoryRequest.bits.write := true.B
  io.memoryRequest.bits.address := addressReg
  io.memoryRequest.bits.writeData := dataReg
  io.memoryRequest.bits.writeMask := 0.U

  doneReg := false.B
  when(io.command.fire) {
    addressReg := io.command.bits.address
    remainingReg := io.command.bits.beats
    when(io.command.bits.beats === 0.U) {
      doneReg := true.B
    }.otherwise {
      state := waitData
    }
  }

  when(state === waitData && io.data.fire) {
    dataReg := io.data.bits
    state := issueWrite
  }

  when(state === issueWrite && io.memoryRequest.fire) {
    state := waitWriteDone
  }

  when(state === waitWriteDone && io.memoryDone) {
    when(remainingReg === 1.U) {
      state := idle
      doneReg := true.B
    }.otherwise {
      addressReg := addressReg + 64.U
      remainingReg := remainingReg - 1.U
      state := waitData
    }
  }
}
