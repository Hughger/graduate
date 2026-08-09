package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

class DiffusionAccelTop extends Module {
  val io = IO(new Bundle {
    val axi = new AxiLitePort
    // Completes compute-only scheduler phases; load/store are driven by DMA.
    val phaseDone = Input(Bool())
    val phase = Output(UInt(3.W))
    val busy = Output(Bool())
    val done = Output(Bool())
    // Debug/control access shares the physical MIG transaction engine with DMA.
    val memoryRequest = Flipped(Decoupled(new MigAppRequest))
    val memoryResponse = Decoupled(UInt(512.W))
    val memoryDone = Output(Bool())
    // Accepted only in LoadResidual and StoreOutput, respectively.
    val tensorReadCommand = Flipped(Decoupled(new TensorReadCommand))
    val tensorReadData = Decoupled(UInt(512.W))
    val tensorReadDone = Output(Bool())
    val tensorWriteCommand = Flipped(Decoupled(new TensorWriteCommand))
    val tensorWriteData = Flipped(Decoupled(UInt(512.W)))
    val tensorWriteDone = Output(Bool())
    // A board wrapper connects this seam to c0_ddr4_app_*.
    val mig = new MigAppPort
  })
  val control = Module(new AxiLiteControl)
  val scheduler = Module(new BlockScheduler)
  val phaseDma = Module(new DmaPhaseController)
  val memoryTransfer = Module(new MigAppTransfer)
  val memoryArbiter = Module(new MigAppRequestArbiter)
  val tensorReadDma = Module(new TensorReadDma)
  val tensorLoadBuffer = Module(new TensorLoadBuffer(4096))
  val tensorWriteDma = Module(new TensorWriteDma)
  control.io.axi <> io.axi
  control.io.busy := scheduler.io.busy
  scheduler.io.start := control.io.start
  scheduler.io.phaseDone := phaseDma.io.phaseDone
  io.phase := scheduler.io.phase
  io.busy := scheduler.io.busy
  io.done := scheduler.io.done

  phaseDma.io.phase := scheduler.io.phase
  phaseDma.io.externalPhaseDone := io.phaseDone
  phaseDma.io.readCommand <> io.tensorReadCommand
  phaseDma.io.readDone := tensorLoadBuffer.io.done
  phaseDma.io.writeCommand <> io.tensorWriteCommand
  phaseDma.io.writeDone := tensorWriteDma.io.done

  memoryArbiter.io.client0Request <> io.memoryRequest
  io.memoryResponse <> memoryArbiter.io.client0Response
  io.memoryDone := memoryArbiter.io.client0Done

  tensorReadDma.io.command <> phaseDma.io.readDmaCommand
  tensorLoadBuffer.io.start := phaseDma.io.readDmaCommand.fire
  tensorLoadBuffer.io.sourceDone := tensorReadDma.io.done
  tensorLoadBuffer.io.input.valid := tensorReadDma.io.data.valid && io.tensorReadData.ready
  tensorLoadBuffer.io.input.bits := tensorReadDma.io.data.bits
  io.tensorReadData.valid := tensorReadDma.io.data.valid && tensorLoadBuffer.io.input.ready
  io.tensorReadData.bits := tensorReadDma.io.data.bits
  tensorReadDma.io.data.ready := tensorLoadBuffer.io.input.ready && io.tensorReadData.ready
  io.tensorReadDone := tensorLoadBuffer.io.done
  tensorLoadBuffer.io.readReq.valid := false.B
  tensorLoadBuffer.io.readReq.bits := 0.U
  tensorLoadBuffer.io.readResp.ready := true.B
  memoryArbiter.io.client1Request <> tensorReadDma.io.memoryRequest
  tensorReadDma.io.memoryResponse <> memoryArbiter.io.client1Response

  tensorWriteDma.io.command <> phaseDma.io.writeDmaCommand
  tensorWriteDma.io.data <> io.tensorWriteData
  io.tensorWriteDone := tensorWriteDma.io.done
  memoryArbiter.io.client2Request <> tensorWriteDma.io.memoryRequest
  memoryArbiter.io.client2Response.ready := true.B
  tensorWriteDma.io.memoryDone := memoryArbiter.io.client2Done

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