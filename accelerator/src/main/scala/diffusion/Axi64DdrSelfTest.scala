package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

object Axi64DdrSelfTest {
  val Address: BigInt = BigInt("100", 16)
  val Data: BigInt = (0 until 8).map(index => BigInt(index + 1) << (64 * index)).sum
}

/**
  * Autonomous 512-bit DDR4 transport check for the AXKU15 AXI64 integration.
  *
  * It waits for a calibrated controller, writes one fixed 512-bit word, then
  * reads and compares it.  The module has no host command path by design: it
  * is a focused board bring-up harness rather than the diffusion control plane.
  */
class Axi64DdrSelfTest extends Module {
  val io = IO(new Bundle {
    val calibrated = Input(Bool())
    val axi = new Axi4Master64
    val active = Output(Bool())
    val passed = Output(Bool())
    val failed = Output(Bool())
  })

  val bridge = Module(new MigAppToAxi64Bridge)
  val waitCalibration :: sendWrite :: waitWrite :: sendRead :: waitRead :: passed :: failed :: Nil = Enum(7)
  val state = RegInit(waitCalibration)

  bridge.io.request.valid := false.B
  bridge.io.request.bits := 0.U.asTypeOf(new MigAppRequest)
  bridge.io.response.ready := state === waitRead
  io.axi <> bridge.io.axi

  io.active := state =/= waitCalibration && state =/= passed && state =/= failed
  io.passed := state === passed
  io.failed := state === failed

  when(state === waitCalibration && io.calibrated) {
    state := sendWrite
  }

  when(state === sendWrite) {
    bridge.io.request.valid := true.B
    bridge.io.request.bits.write := true.B
    bridge.io.request.bits.address := Axi64DdrSelfTest.Address.U(29.W)
    bridge.io.request.bits.writeData := Axi64DdrSelfTest.Data.U(512.W)
    bridge.io.request.bits.writeMask := 0.U
    when(bridge.io.request.fire) {
      state := waitWrite
    }
  }

  when(state === waitWrite) {
    when(bridge.io.error) {
      state := failed
    }.elsewhen(bridge.io.done) {
      state := sendRead
    }
  }

  when(state === sendRead) {
    bridge.io.request.valid := true.B
    bridge.io.request.bits.write := false.B
    bridge.io.request.bits.address := Axi64DdrSelfTest.Address.U(29.W)
    bridge.io.request.bits.writeData := 0.U
    bridge.io.request.bits.writeMask := 0.U
    when(bridge.io.request.fire) {
      state := waitRead
    }
  }

  when(state === waitRead) {
    when(bridge.io.error) {
      state := failed
    }.elsewhen(bridge.io.response.fire) {
      state := Mux(bridge.io.response.bits === Axi64DdrSelfTest.Data.U(512.W), passed, failed)
    }
  }
}
