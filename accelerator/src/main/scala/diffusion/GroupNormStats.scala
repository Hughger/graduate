package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

class GroupStats extends Bundle {
  val sum = SInt(64.W)
  val sumSquare = UInt(64.W)
  val count = UInt(64.W)
}

class GroupNormStatsInput(lanes: Int) extends Bundle {
  val values = Vec(lanes, SInt(16.W))
  val last = Bool()
}

class GroupNormStats(lanes: Int) extends Module {
  require(lanes > 0)

  val io = IO(new Bundle {
    val input = Flipped(Decoupled(new GroupNormStatsInput(lanes)))
    val stats = Decoupled(new GroupStats)
  })

  val sumAccumulator = RegInit(0.S(64.W))
  val squareAccumulator = RegInit(0.U(64.W))
  val countAccumulator = RegInit(0.U(64.W))
  val result = RegInit(0.U.asTypeOf(new GroupStats))
  val resultValid = RegInit(false.B)

  io.input.ready := !resultValid || io.stats.ready
  val laneSum = io.input.bits.values.map(_.pad(64)).reduce(_ +& _).pad(64).asSInt
  val laneSquare = io.input.bits.values
    .map(value => (value * value).asUInt.pad(64))
    .reduce(_ +& _)
    .pad(64)
  val nextSum = (sumAccumulator +& laneSum).pad(64).asSInt
  val nextSquare = (squareAccumulator +& laneSquare).pad(64)
  val nextCount = countAccumulator + lanes.U

  when(io.input.fire) {
    when(io.input.bits.last) {
      result.sum := nextSum
      result.sumSquare := nextSquare
      result.count := nextCount
      resultValid := true.B
      sumAccumulator := 0.S
      squareAccumulator := 0.U
      countAccumulator := 0.U
    }.otherwise {
      sumAccumulator := nextSum
      squareAccumulator := nextSquare
      countAccumulator := nextCount
    }
  }.elsewhen(io.stats.fire) {
    resultValid := false.B
  }

  io.stats.bits := result
  io.stats.valid := resultValid
}
