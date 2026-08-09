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
    // Exposes the controller-to-DDR seam while TensorDma is being integrated
    // with the block scheduler. A board wrapper connects `mig` to c0_ddr4_app_*.
    val memoryRequest = Flipped(Decoupled(new MigAppRequest))
    val memoryResponse = Decoupled(UInt(512.W))
    val memoryDone = Output(Bool())
    val mig = new MigAppPort
  })
  val control = Module(new AxiLiteControl)
  val scheduler = Module(new BlockScheduler)
  val memoryTransfer = Module(new MigAppTransfer)
  control.io.axi <> io.axi
  control.io.busy := scheduler.io.busy
  scheduler.io.start := control.io.start
  scheduler.io.phaseDone := io.phaseDone
  io.phase := scheduler.io.phase
  io.busy := scheduler.io.busy
  io.done := scheduler.io.done

  memoryTransfer.io.request <> io.memoryRequest
  io.memoryResponse <> memoryTransfer.io.response
  io.memoryDone := memoryTransfer.io.done

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
