package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

/**
  * Serializes debug/control, tensor-read and tensor-write clients onto one
  * MigAppTransfer. The selected client retains ownership until a read response
  * is consumed or a write completion pulse arrives. Priority is write, read,
  * then debug/control while no transaction is active.
  */
class MigAppRequestArbiter extends Module {
  val io = IO(new Bundle {
    val client0Request = Flipped(Decoupled(new MigAppRequest))
    val client0Response = Decoupled(UInt(512.W))
    val client0Done = Output(Bool())
    val client1Request = Flipped(Decoupled(new MigAppRequest))
    val client1Response = Decoupled(UInt(512.W))
    val client1Done = Output(Bool())
    val client2Request = Flipped(Decoupled(new MigAppRequest))
    val client2Response = Decoupled(UInt(512.W))
    val client2Done = Output(Bool())
    val memoryRequest = Decoupled(new MigAppRequest)
    val memoryResponse = Flipped(Decoupled(UInt(512.W)))
    val memoryDone = Input(Bool())
  })

  val active = RegInit(false.B)
  val owner = RegInit(0.U(2.W))
  val selectClient2 = io.client2Request.valid
  val selectClient1 = !selectClient2 && io.client1Request.valid
  val selectClient0 = !selectClient2 && !selectClient1 && io.client0Request.valid
  val selectedOwner = Mux(selectClient2, 2.U, Mux(selectClient1, 1.U, 0.U))

  io.memoryRequest.valid := !active && (selectClient0 || selectClient1 || selectClient2)
  io.memoryRequest.bits := Mux(selectClient2, io.client2Request.bits,
    Mux(selectClient1, io.client1Request.bits, io.client0Request.bits))
  io.client2Request.ready := !active && io.memoryRequest.ready && selectClient2
  io.client1Request.ready := !active && io.memoryRequest.ready && selectClient1
  io.client0Request.ready := !active && io.memoryRequest.ready && selectClient0

  io.client0Response.valid := active && owner === 0.U && io.memoryResponse.valid
  io.client0Response.bits := io.memoryResponse.bits
  io.client1Response.valid := active && owner === 1.U && io.memoryResponse.valid
  io.client1Response.bits := io.memoryResponse.bits
  io.client2Response.valid := active && owner === 2.U && io.memoryResponse.valid
  io.client2Response.bits := io.memoryResponse.bits
  io.memoryResponse.ready := active && MuxLookup(owner, io.client0Response.ready, Seq(
    1.U -> io.client1Response.ready,
    2.U -> io.client2Response.ready
  ))

  io.client0Done := active && owner === 0.U && io.memoryDone
  io.client1Done := active && owner === 1.U && io.memoryDone
  io.client2Done := active && owner === 2.U && io.memoryDone

  when(io.memoryRequest.fire) {
    active := true.B
    owner := selectedOwner
  }
  when(active && (io.memoryResponse.fire || io.memoryDone)) {
    active := false.B
  }
}