package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

class DiffusionAccelTop extends Module {
  val io = IO(new Bundle {
    val axi = new AxiLitePort
    val phaseDone = Input(Bool())
    val phase = Output(UInt(3.W))
    val busy = Output(Bool())
    val done = Output(Bool())
    // Debug/control access shares the physical MIG transaction engine with DMA.
    val memoryRequest = Flipped(Decoupled(new MigAppRequest))
    val memoryResponse = Decoupled(UInt(512.W))
    val memoryDone = Output(Bool())
    // TensorReadDma is the first scheduler-side MIG client.
    val tensorReadCommand = Flipped(Decoupled(new TensorReadCommand))
    val tensorReadData = Decoupled(UInt(512.W))
    val tensorReadDone = Output(Bool())
    // A board wrapper connects this seam to c0_ddr4_app_*.
    val mig = new MigAppPort
  })
  val control = Module(new AxiLiteControl)
  val scheduler = Module(new BlockScheduler)
  val memoryTransfer = Module(new MigAppTransfer)
  val memoryArbiter = Module(new MigAppRequestArbiter)
  val tensorReadDma = Module(new TensorReadDma)
  control.io.axi <> io.axi
  control.io.busy := scheduler.io.busy
  scheduler.io.start := control.io.start
  scheduler.io.phaseDone := io.phaseDone
  io.phase := scheduler.io.phase
  io.busy := scheduler.io.busy
  io.done := scheduler.io.done

  memoryArbiter.io.client0Request <> io.memoryRequest
  io.memoryResponse <> memoryArbiter.io.client0Response
  io.memoryDone := memoryArbiter.io.client0Done

  tensorReadDma.io.command <> io.tensorReadCommand
  io.tensorReadData <> tensorReadDma.io.data
  io.tensorReadDone := tensorReadDma.io.done
  memoryArbiter.io.client1Request <> tensorReadDma.io.memoryRequest
  tensorReadDma.io.memoryResponse <> memoryArbiter.io.client1Response

  memoryTransfer.io.request <> memoryArbiter.io.memoryRequest
  memoryArbiter.io.memoryResponse <> memoryTransfer.io.response
  memoryArbiter.io.memoryDone := memoryTransfer.io.done

  io.mig.en := memoryTransfer.io.app.en
  io.mig.cmd := memoryTransfer.io.app.cmd
  io.mig.address := memoryTransfer.io.app.address
  io.mig.wdfWren := memoryTransfer.io.app.wdfWren
  io.mig.wdfEnd := memoryTransfer.io.app.wdfEnd
  io.mig.wdfData := memoryTransfer.io.app.wdfData
  io.mig.wdfMask := memoryTransfer.io.app.wdfMask
  memoryTransfer.io.app.rdy := io.mig.rdy
  memoryTransfer.io.app.wdfRdy := io.mig.wdfRdy
  memoryTransfer.io.app.rdData := io.mig.rdData
  memoryTransfer.io.app.rdDataValid := io.mig.rdDataValid
  memoryTransfer.io.app.rdDataEnd := io.mig.rdDataEnd
}