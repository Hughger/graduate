package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

object MigAppCommand {
  val Write = 0
  val Read = 1
}

/** One 512-bit operation on the application interface emitted by the DDR4 MIG candidate. */
class MigAppRequest extends Bundle {
  val write = Bool()
  val address = UInt(29.W)
  val writeData = UInt(512.W)
  val writeMask = UInt(64.W)
}

/** Directional view of the c0_ddr4_app_* interface in the generated MIG template. */
class MigAppPort extends Bundle {
  val en = Output(Bool())
  val cmd = Output(UInt(3.W))
  val address = Output(UInt(29.W))
  val rdy = Input(Bool())
  val wdfWren = Output(Bool())
  val wdfEnd = Output(Bool())
  val wdfData = Output(UInt(512.W))
  val wdfMask = Output(UInt(64.W))
  val wdfRdy = Input(Bool())
  val rdData = Input(UInt(512.W))
  val rdDataValid = Input(Bool())
  val rdDataEnd = Input(Bool())
}

/**
  * Serializes one request at a time onto the MIG application interface.
  *
  * The MIG command and write-data channels have independent ready signals;
  * this block keeps both valids asserted until their own handshakes complete.
  */
class MigAppTransfer extends Module {
  val io = IO(new Bundle {
    val request = Flipped(Decoupled(new MigAppRequest))
    val response = Decoupled(UInt(512.W))
    val done = Output(Bool())
    val app = new MigAppPort
  })

  val idle :: readCommand :: readData :: readResponse :: writeData :: Nil = Enum(5)
  val state = RegInit(idle)
  val requestReg = Reg(new MigAppRequest)
  val commandAccepted = RegInit(false.B)
  val dataAccepted = RegInit(false.B)
  val readDataReg = Reg(UInt(512.W))
  val doneReg = RegInit(false.B)

  io.request.ready := state === idle
  io.response.valid := state === readResponse
  io.response.bits := readDataReg
  io.done := doneReg

  io.app.en := false.B
  io.app.cmd := 0.U
  io.app.address := 0.U
  io.app.wdfWren := false.B
  io.app.wdfEnd := false.B
  io.app.wdfData := 0.U
  io.app.wdfMask := 0.U

  doneReg := false.B
  when(io.request.fire) {
    requestReg := io.request.bits
    commandAccepted := false.B
    dataAccepted := false.B
    state := Mux(io.request.bits.write, writeData, readCommand)
  }

  when(state === readCommand) {
    io.app.en := true.B
    io.app.cmd := MigAppCommand.Read.U
    io.app.address := requestReg.address
    when(io.app.rdy) {
      state := readData
    }
  }

  when(state === readData) {
    when(io.app.rdDataValid && io.app.rdDataEnd) {
      readDataReg := io.app.rdData
      state := readResponse
    }
  }

  when(state === readResponse && io.response.fire) {
    state := idle
  }

  when(state === writeData) {
    io.app.en := !commandAccepted
    io.app.cmd := MigAppCommand.Write.U
    io.app.address := requestReg.address
    io.app.wdfWren := !dataAccepted
    io.app.wdfEnd := !dataAccepted
    io.app.wdfData := requestReg.writeData
    io.app.wdfMask := requestReg.writeMask

    val commandCompletes = commandAccepted || io.app.rdy
    val dataCompletes = dataAccepted || io.app.wdfRdy
    when(!commandAccepted && io.app.rdy) {
      commandAccepted := true.B
    }
    when(!dataAccepted && io.app.wdfRdy) {
      dataAccepted := true.B
    }
    when(commandCompletes && dataCompletes) {
      state := idle
      doneReg := true.B
    }
  }
}
