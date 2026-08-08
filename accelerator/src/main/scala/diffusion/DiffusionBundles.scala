package FLOOD_Accelerator.diffusion

import chisel3._

class WeightBeat(p: DiffusionParams) extends Bundle {
  val address = UInt(p.addressWidth.W)
  val data = UInt(p.axiDataWidth.W)
  val last = Bool()
}

class BlockCommand(p: DiffusionParams) extends Bundle {
  val inputAddress = UInt(p.addressWidth.W)
  val outputAddress = UInt(p.addressWidth.W)
  val conv1WeightAddress = UInt(p.addressWidth.W)
  val conv2WeightAddress = UInt(p.addressWidth.W)
  val norm1Address = UInt(p.addressWidth.W)
  val norm2Address = UInt(p.addressWidth.W)
  val timeEmbeddingAddress = UInt(p.addressWidth.W)
  val batch = UInt(16.W)
  val channels = UInt(16.W)
  val height = UInt(16.W)
  val spatialWidth = UInt(16.W)
  val flags = UInt(32.W)
  val commandId = UInt(32.W)
}

class BlockStatus extends Bundle {
  val busy = Bool()
  val done = Bool()
  val error = Bool()
  val errorCode = UInt(8.W)
  val completedId = UInt(32.W)
}

class PerfCounters extends Bundle {
  val totalCycles = UInt(64.W)
  val readBytes = UInt(64.W)
  val writeBytes = UInt(64.W)
  val macCycles = UInt(64.W)
  val groupNormCycles = UInt(64.W)
  val stallCycles = UInt(64.W)
}
