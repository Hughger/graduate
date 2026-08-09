package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

/** Buffers DMA beats as 32 little-endian INT16 tensor words for compute stages. */
class TensorLoadBuffer(depth: Int) extends Module {
  require(depth >= 32)
  private val addressWidth = math.max(1, log2Ceil(depth))
  val io = IO(new Bundle {
    val start = Input(Bool())
    val input = Flipped(Decoupled(UInt(512.W)))
    val sourceDone = Input(Bool())
    val done = Output(Bool())
    val busy = Output(Bool())
    val readReq = Flipped(Decoupled(UInt(addressWidth.W)))
    val readResp = Decoupled(UInt(16.W))
    val occupancy = Output(UInt(math.max(1, log2Ceil(depth + 1)).W))
  })

  val buffer = Module(new TensorTileBuffer(depth, 16))
  val active = RegInit(false.B)
  val writing = RegInit(false.B)
  val sourceDoneSeen = RegInit(false.B)
  val lane = RegInit(0.U(5.W))
  val address = RegInit(0.U(addressWidth.W))
  val beat = Reg(UInt(512.W))
  val doneReg = RegInit(false.B)
  val lanes = beat.asTypeOf(Vec(32, UInt(16.W)))

  io.input.ready := active && !writing
  io.busy := active || writing
  io.done := doneReg

  buffer.io.write.valid := writing
  buffer.io.write.bits.address := address
  buffer.io.write.bits.data := lanes(lane)
  buffer.io.readReq.valid := io.readReq.valid
  buffer.io.readReq.bits := io.readReq.bits
  io.readReq.ready := buffer.io.readReq.ready
  io.readResp.valid := buffer.io.readResp.valid
  io.readResp.bits := buffer.io.readResp.bits
  buffer.io.readResp.ready := io.readResp.ready
  io.occupancy := buffer.io.occupancy

  doneReg := false.B
  when(io.start) {
    active := true.B
    writing := false.B
    sourceDoneSeen := false.B
    address := 0.U
  }
  when(active && io.sourceDone) { sourceDoneSeen := true.B }
  when(active && !writing && io.sourceDone) {
    active := false.B
    doneReg := true.B
  }
  when(io.input.fire) {
    beat := io.input.bits
    lane := 0.U
    writing := true.B
  }
  when(buffer.io.write.fire && writing) {
    address := address + 1.U
    when(lane === 31.U) {
      writing := false.B
      when(sourceDoneSeen || io.sourceDone) {
        active := false.B
        doneReg := true.B
      }
    }.otherwise {
      lane := lane + 1.U
    }
  }
}
