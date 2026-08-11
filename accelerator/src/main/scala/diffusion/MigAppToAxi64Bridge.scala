package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

class AxiWriteAddress extends Bundle {
  val addr = UInt(32.W)
  val id = UInt(4.W)
  val len = UInt(8.W)
  val size = UInt(3.W)
}

class AxiWriteData extends Bundle {
  val data = UInt(64.W)
  val strb = UInt(8.W)
  val last = Bool()
}

class AxiWriteResponse extends Bundle {
  val id = UInt(4.W)
  val resp = UInt(2.W)
}

class AxiReadAddress extends Bundle {
  val addr = UInt(32.W)
  val id = UInt(4.W)
  val len = UInt(8.W)
  val size = UInt(3.W)
}

class AxiReadData extends Bundle {
  val data = UInt(64.W)
  val id = UInt(4.W)
  val resp = UInt(2.W)
  val last = Bool()
}

/** A minimal AXI4 master interface matching the 64-bit vendor DDR4 demo. */
class Axi4Master64 extends Bundle {
  val aw = Decoupled(new AxiWriteAddress)
  val w = Decoupled(new AxiWriteData)
  val b = Flipped(Decoupled(new AxiWriteResponse))
  val ar = Decoupled(new AxiReadAddress)
  val r = Flipped(Decoupled(new AxiReadData))
}

/**
  * Converts one 512-bit accelerator memory operation at a time into the
  * eight 64-bit beats required by the AXKU15 vendor DDR4 demo.
  *
  * Read and write requests use a single outstanding AXI transaction, preserving
  * the ordering contract expected by the accelerator-side request arbiter.
  */
class MigAppToAxi64Bridge extends Module {
  val io = IO(new Bundle {
    val request = Flipped(Decoupled(new MigAppRequest))
    val response = Decoupled(UInt(512.W))
    val done = Output(Bool())
    val error = Output(Bool())
    val axi = new Axi4Master64
  })

  val idle :: writeAddress :: writeData :: writeResponse :: readAddress :: readData :: readErrorDrain :: readResponse :: Nil = Enum(8)
  val state = RegInit(idle)
  val requestReg = Reg(new MigAppRequest)
  val writeBeat = RegInit(0.U(3.W))
  val readBeat = RegInit(0.U(3.W))
  val readDataReg = RegInit(0.U(512.W))
  val doneReg = RegInit(false.B)
  val errorReg = RegInit(false.B)

  io.request.ready := state === idle
  io.response.valid := state === readResponse
  io.response.bits := readDataReg
  io.done := doneReg
  io.error := errorReg

  io.axi.aw.valid := false.B
  io.axi.aw.bits.addr := 0.U
  io.axi.aw.bits.id := 0.U
  io.axi.aw.bits.len := 0.U
  io.axi.aw.bits.size := 0.U
  io.axi.w.valid := false.B
  io.axi.w.bits.data := 0.U
  io.axi.w.bits.strb := 0.U
  io.axi.w.bits.last := false.B
  io.axi.b.ready := false.B
  io.axi.ar.valid := false.B
  io.axi.ar.bits.addr := 0.U
  io.axi.ar.bits.id := 0.U
  io.axi.ar.bits.len := 0.U
  io.axi.ar.bits.size := 0.U
  io.axi.r.ready := false.B

  val writeWords = requestReg.writeData.asTypeOf(Vec(8, UInt(64.W)))
  doneReg := false.B
  val writeMasks = requestReg.writeMask.asTypeOf(Vec(8, UInt(8.W)))
  val readWords = Wire(Vec(8, UInt(64.W)))
  readWords := readDataReg.asTypeOf(Vec(8, UInt(64.W)))

  when(io.request.fire) {
    requestReg := io.request.bits
    writeBeat := 0.U
    readBeat := 0.U
    state := Mux(io.request.bits.write, writeAddress, readAddress)
  }

  when(state === writeAddress) {
    io.axi.aw.valid := true.B
    io.axi.aw.bits.addr := requestReg.address
    io.axi.aw.bits.id := 0.U
    io.axi.aw.bits.len := 7.U
    io.axi.aw.bits.size := 3.U
    when(io.axi.aw.fire) {
      state := writeData
    }
  }

  when(state === writeData) {
    io.axi.w.valid := true.B
    io.axi.w.bits.data := writeWords(writeBeat)
    io.axi.w.bits.strb := ~writeMasks(writeBeat)
    io.axi.w.bits.last := writeBeat === 7.U
    when(io.axi.w.fire) {
      when(writeBeat === 7.U) {
        state := writeResponse
      }.otherwise {
        writeBeat := writeBeat + 1.U
      }
    }
  }

  when(state === writeResponse) {
    io.axi.b.ready := true.B
    when(io.axi.b.fire) {
      when(io.axi.b.bits.resp === 0.U) {
        doneReg := true.B
      }.otherwise {
        errorReg := true.B
      }
      state := idle
    }
  }
  when(state === readAddress) {
    io.axi.ar.valid := true.B
    io.axi.ar.bits.addr := requestReg.address
    io.axi.ar.bits.id := 0.U
    io.axi.ar.bits.len := 7.U
    io.axi.ar.bits.size := 3.U
    when(io.axi.ar.fire) {
      state := readData
    }
  }

  when(state === readData) {
    io.axi.r.ready := true.B
    when(io.axi.r.fire) {
      when(io.axi.r.bits.resp =/= 0.U) {
        errorReg := true.B
        state := Mux(io.axi.r.bits.last, idle, readErrorDrain)
      }.elsewhen(readBeat === 7.U) {
        when(io.axi.r.bits.last) {
          readWords(readBeat) := io.axi.r.bits.data
          readDataReg := readWords.asUInt
          state := readResponse
        }.otherwise {
          errorReg := true.B
          state := idle
        }
      }.elsewhen(io.axi.r.bits.last) {
        errorReg := true.B
        state := idle
      }.otherwise {
        readWords(readBeat) := io.axi.r.bits.data
        readDataReg := readWords.asUInt
        readBeat := readBeat + 1.U
      }
    }
  }

  when(state === readErrorDrain) {
    io.axi.r.ready := true.B
    when(io.axi.r.fire && io.axi.r.bits.last) {
      state := idle
    }
  }

  when(state === readResponse && io.response.fire) {
    state := idle
  }
}
