package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

/**
  * Serializes a debug/control client and the tensor-read DMA onto one
  * MigAppTransfer. The selected client retains ownership until a read response
  * is consumed or a write completion pulse arrives. Tensor DMA has priority
  * when both clients become valid in the same cycle.
  */
class MigAppRequestArbiter extends Module {
  val io = IO(new Bundle {
    val client0Request = Flipped(Decoupled(new MigAppRequest))
    val client0Response = Decoupled(UInt(512.W))
    val client0Done = Output(Bool())
    val client1Request = Flipped(Decoupled(new MigAppRequest))
    val client1Response = Decoupled(UInt(512.W))
    val client1Done = Output(Bool())
    val memoryRequest = Decoupled(new MigAppRequest)
    val memoryResponse = Flipped(Decoupled(UInt(512.W)))
    val memoryDone = Input(Bool())
  })

  val active = RegInit(false.B)
  val ownerIsClient1 = RegInit(false.B)
  val selectClient1 = io.client1Request.valid

  io.memoryRequest.valid := !active && (io.client0Request.valid || io.client1Request.valid)
  io.memoryRequest.bits := Mux(selectClient1, io.client1Request.bits, io.client0Request.bits)
  io.client1Request.ready := !active && io.memoryRequest.ready && selectClient1
  io.client0Request.ready := !active && io.memoryRequest.ready && !selectClient1

  io.client0Response.valid := active && !ownerIsClient1 && io.memoryResponse.valid
  io.client0Response.bits := io.memoryResponse.bits
  io.client1Response.valid := active && ownerIsClient1 && io.memoryResponse.valid
  io.client1Response.bits := io.memoryResponse.bits
  io.memoryResponse.ready := Mux(ownerIsClient1, io.client1Response.ready, io.client0Response.ready) && active

  io.client0Done := active && !ownerIsClient1 && io.memoryDone
  io.client1Done := active && ownerIsClient1 && io.memoryDone

  when(io.memoryRequest.fire) {
    active := true.B
    ownerIsClient1 := selectClient1
  }
  when(active && (io.memoryResponse.fire || io.memoryDone)) {
    active := false.B
  }
}
