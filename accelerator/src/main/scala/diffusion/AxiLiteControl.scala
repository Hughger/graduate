package FLOOD_Accelerator.diffusion

import chisel3._
import chisel3.util._

object DiffusionRegisterMap {
  val Control = 0x000
  val Status = 0x004
  val PerfSnapshot = 0x008
  val PerfTotalCyclesLo = 0x010
  val PerfTotalCyclesHi = 0x014
  val PerfReadBytesLo = 0x018
  val PerfReadBytesHi = 0x01c
  val PerfWriteBytesLo = 0x020
  val PerfWriteBytesHi = 0x024
  val PerfMacCyclesLo = 0x028
  val PerfMacCyclesHi = 0x02c
  val PerfGroupNormCyclesLo = 0x030
  val PerfGroupNormCyclesHi = 0x034
  val PerfStallCyclesLo = 0x038
  val PerfStallCyclesHi = 0x03c
  val Okay = 0
  val SlvErr = 2
}

class AxiLiteWriteData extends Bundle {
  val data = UInt(32.W)
  val strb = UInt(4.W)
}

class AxiLiteReadData extends Bundle {
  val data = UInt(32.W)
  val resp = UInt(2.W)
}

class AxiLitePort extends Bundle {
  val aw = Flipped(Decoupled(UInt(32.W)))
  val w = Flipped(Decoupled(new AxiLiteWriteData))
  val b = Decoupled(UInt(2.W))
  val ar = Flipped(Decoupled(UInt(32.W)))
  val r = Decoupled(new AxiLiteReadData)
}

class AxiLiteControl extends Module {
  val io = IO(new Bundle {
    val axi = new AxiLitePort
    val busy = Input(Bool())
    val perfCounters = Input(new PerfCounters)
    val start = Output(Bool())
    val perfSnapshot = Output(Bool())
  })

  val awHeld = RegInit(false.B)
  val awAddress = Reg(UInt(32.W))
  val wHeld = RegInit(false.B)
  val wData = Reg(new AxiLiteWriteData)
  val bValid = RegInit(false.B)
  val bResp = RegInit(DiffusionRegisterMap.Okay.U(2.W))
  val rValid = RegInit(false.B)
  val rData = RegInit(0.U.asTypeOf(new AxiLiteReadData))
  val start = RegInit(false.B)
  val perfSnapshot = RegInit(false.B)

  io.axi.aw.ready := !awHeld && !bValid
  io.axi.w.ready := !wHeld && !bValid
  val haveAw = awHeld || io.axi.aw.fire
  val haveW = wHeld || io.axi.w.fire
  val selectedAddress = Mux(io.axi.aw.fire, io.axi.aw.bits, awAddress)
  val selectedData = Mux(io.axi.w.fire, io.axi.w.bits.data, wData.data)
  val selectedStrb = Mux(io.axi.w.fire, io.axi.w.bits.strb, wData.strb)
  val commitWrite = haveAw && haveW && !bValid

  start := false.B
  perfSnapshot := false.B
  when(io.axi.aw.fire) { awHeld := true.B; awAddress := io.axi.aw.bits }
  when(io.axi.w.fire) { wHeld := true.B; wData := io.axi.w.bits }
  when(io.axi.b.fire) { bValid := false.B }
  when(commitWrite) {
    awHeld := false.B
    wHeld := false.B
    bValid := true.B
    bResp := Mux(
      selectedAddress === DiffusionRegisterMap.Control.U && selectedData(0) && selectedStrb(0),
      Mux(io.busy, DiffusionRegisterMap.SlvErr.U, DiffusionRegisterMap.Okay.U),
      DiffusionRegisterMap.Okay.U
    )
    when(selectedAddress === DiffusionRegisterMap.Control.U && selectedData(0) && selectedStrb(0) && !io.busy) {
      start := true.B
    }
    when(selectedAddress === DiffusionRegisterMap.PerfSnapshot.U && selectedData(0) && selectedStrb(0)) {
      perfSnapshot := true.B
    }
  }
  io.axi.b.valid := bValid
  io.axi.b.bits := bResp

  io.axi.ar.ready := !rValid
  when(io.axi.ar.fire) {
    rValid := true.B
    rData.data := MuxLookup(io.axi.ar.bits, 0.U(32.W), Seq(
      DiffusionRegisterMap.Status.U -> io.busy.asUInt,
      DiffusionRegisterMap.PerfTotalCyclesLo.U -> io.perfCounters.totalCycles(31, 0),
      DiffusionRegisterMap.PerfTotalCyclesHi.U -> io.perfCounters.totalCycles(63, 32),
      DiffusionRegisterMap.PerfReadBytesLo.U -> io.perfCounters.readBytes(31, 0),
      DiffusionRegisterMap.PerfReadBytesHi.U -> io.perfCounters.readBytes(63, 32),
      DiffusionRegisterMap.PerfWriteBytesLo.U -> io.perfCounters.writeBytes(31, 0),
      DiffusionRegisterMap.PerfWriteBytesHi.U -> io.perfCounters.writeBytes(63, 32),
      DiffusionRegisterMap.PerfMacCyclesLo.U -> io.perfCounters.macCycles(31, 0),
      DiffusionRegisterMap.PerfMacCyclesHi.U -> io.perfCounters.macCycles(63, 32),
      DiffusionRegisterMap.PerfGroupNormCyclesLo.U -> io.perfCounters.groupNormCycles(31, 0),
      DiffusionRegisterMap.PerfGroupNormCyclesHi.U -> io.perfCounters.groupNormCycles(63, 32),
      DiffusionRegisterMap.PerfStallCyclesLo.U -> io.perfCounters.stallCycles(31, 0),
      DiffusionRegisterMap.PerfStallCyclesHi.U -> io.perfCounters.stallCycles(63, 32)
    ))
    rData.resp := DiffusionRegisterMap.Okay.U
  }.elsewhen(io.axi.r.fire) { rValid := false.B }
  io.axi.r.valid := rValid
  io.axi.r.bits := rData
  io.start := start
  io.perfSnapshot := perfSnapshot
}
