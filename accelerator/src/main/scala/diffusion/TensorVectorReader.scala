package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

class TensorVectorReadCommand(addressWidth: Int) extends Bundle {
  val baseAddress = UInt(addressWidth.W)
  val vectors = UInt(16.W)
}

/** Reassembles 32 sequential INT16 buffer words into one compute-lane vector. */
class TensorVectorReader(depth: Int, lanes: Int = 32) extends Module {
  require(depth > 0 && lanes > 0)
  private val addressWidth = math.max(1, log2Ceil(depth))
  private val laneWidth = math.max(1, log2Ceil(lanes))
  val io = IO(new Bundle {
    val command = Flipped(Decoupled(new TensorVectorReadCommand(addressWidth)))
    val bufferReadReq = Decoupled(UInt(addressWidth.W))
    val bufferReadResp = Flipped(Decoupled(UInt(16.W)))
    val output = Decoupled(Vec(lanes, SInt(16.W)))
    val busy = Output(Bool())
    val done = Output(Bool())
  })

  val idle :: issueRead :: waitRead :: emitVector :: Nil = Enum(4)
  val state = RegInit(idle)
  val address = Reg(UInt(addressWidth.W))
  val lane = Reg(UInt(laneWidth.W))
  val vectorsRemaining = Reg(UInt(16.W))
  val values = Reg(Vec(lanes, SInt(16.W)))
  val doneReg = RegInit(false.B)

  io.command.ready := state === idle
  io.bufferReadReq.valid := state === issueRead
  io.bufferReadReq.bits := address
  io.bufferReadResp.ready := state === waitRead
  io.output.valid := state === emitVector
  io.output.bits := values
  io.busy := state =/= idle
  io.done := doneReg
  doneReg := false.B

  when(io.command.fire) {
    address := io.command.bits.baseAddress
    lane := 0.U
    vectorsRemaining := io.command.bits.vectors
    when(io.command.bits.vectors === 0.U) { doneReg := true.B }
      .otherwise { state := issueRead }
  }
  when(state === issueRead && io.bufferReadReq.fire) { state := waitRead }
  when(state === waitRead && io.bufferReadResp.fire) {
    values(lane) := io.bufferReadResp.bits.asSInt
    address := address + 1.U
    when(lane === (lanes - 1).U) { state := emitVector }
      .otherwise { lane := lane + 1.U; state := issueRead }
  }
  when(state === emitVector && io.output.fire) {
    when(vectorsRemaining === 1.U) { state := idle; doneReg := true.B }
      .otherwise { vectorsRemaining := vectorsRemaining - 1.U; lane := 0.U; state := issueRead }
  }
}
