package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

class TileBufferWrite(addressWidth: Int, dataWidth: Int) extends Bundle {
  val address = UInt(addressWidth.W)
  val data = UInt(dataWidth.W)
}

class TensorTileBuffer(depth: Int, dataWidth: Int) extends Module {
  require(depth > 0)
  require(dataWidth > 0)

  private val addressWidth = math.max(1, log2Ceil(depth))
  private val occupancyWidth = math.max(1, log2Ceil(depth + 1))
  val io = IO(new Bundle {
    val write = Flipped(Decoupled(new TileBufferWrite(addressWidth, dataWidth)))
    val readReq = Flipped(Decoupled(UInt(addressWidth.W)))
    val readResp = Decoupled(UInt(dataWidth.W))
    val occupancy = Output(UInt(occupancyWidth.W))
    val highWater = Output(UInt(occupancyWidth.W))
  })

  val memory = SyncReadMem(depth, UInt(dataWidth.W))
  val validBits = RegInit(VecInit(Seq.fill(depth)(false.B)))
  val occupancy = RegInit(0.U(occupancyWidth.W))
  val highWater = RegInit(0.U(occupancyWidth.W))
  val readPending = RegInit(false.B)

  io.write.ready := true.B
  io.readReq.ready := !readPending && !io.write.valid
  val readData = memory.read(io.readReq.bits, io.readReq.fire)

  when(io.write.fire) {
    memory.write(io.write.bits.address, io.write.bits.data)
    when(!validBits(io.write.bits.address)) {
      validBits(io.write.bits.address) := true.B
      occupancy := occupancy + 1.U
      when(occupancy + 1.U > highWater) {
        highWater := occupancy + 1.U
      }
    }
  }

  when(io.readReq.fire) {
    readPending := true.B
  }.elsewhen(io.readResp.fire) {
    readPending := false.B
  }

  io.readResp.bits := readData
  io.readResp.valid := readPending
  io.occupancy := occupancy
  io.highWater := highWater
}
