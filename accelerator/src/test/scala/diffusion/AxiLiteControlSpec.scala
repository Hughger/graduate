package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class AxiLiteControlSpec extends AnyFlatSpec with ChiselScalatestTester {
  "AxiLiteControl" should "accept independent AW/W channels and reject start while busy" in {
    test(new AxiLiteControl) { dut =>
      dut.io.busy.poke(false.B)
      dut.io.axi.aw.valid.poke(false.B); dut.io.axi.w.valid.poke(false.B); dut.io.axi.b.ready.poke(false.B)
      dut.io.axi.ar.valid.poke(false.B); dut.io.axi.r.ready.poke(false.B)
      dut.clock.step()

      dut.io.axi.aw.bits.poke(0.U)
      dut.io.axi.aw.valid.poke(true.B)
      dut.io.axi.aw.ready.expect(true.B)
      dut.clock.step()
      dut.io.axi.aw.valid.poke(false.B)
      dut.io.start.expect(false.B)

      dut.io.axi.w.bits.data.poke(1.U)
      dut.io.axi.w.bits.strb.poke("hf".U)
      dut.io.axi.w.valid.poke(true.B)
      dut.io.axi.w.ready.expect(true.B)
      dut.clock.step()
      dut.io.axi.w.valid.poke(false.B)
      dut.io.start.expect(true.B)
      dut.io.axi.b.valid.expect(true.B)
      dut.io.axi.b.bits.expect(0.U)
      dut.io.axi.b.ready.poke(true.B)
      dut.clock.step()
      dut.io.start.expect(false.B)

      dut.io.busy.poke(true.B)
      dut.io.axi.aw.bits.poke(0.U); dut.io.axi.aw.valid.poke(true.B)
      dut.io.axi.w.bits.data.poke(1.U); dut.io.axi.w.valid.poke(true.B)
      dut.clock.step()
      dut.io.axi.aw.valid.poke(false.B); dut.io.axi.w.valid.poke(false.B)
      dut.io.axi.b.valid.expect(true.B)
      dut.io.axi.b.bits.expect(2.U)
    }
  }

  it should "snapshot and expose 64-bit performance counters through AXI-Lite reads" in {
    test(new AxiLiteControl) { dut =>
      dut.io.busy.poke(false.B)
      dut.io.perfCounters.totalCycles.poke("h1122334455667788".U)
      dut.io.perfCounters.readBytes.poke(0.U)
      dut.io.perfCounters.writeBytes.poke(0.U)
      dut.io.perfCounters.macCycles.poke(0.U)
      dut.io.perfCounters.groupNormCycles.poke(0.U)
      dut.io.perfCounters.stallCycles.poke(0.U)
      dut.io.axi.aw.valid.poke(false.B); dut.io.axi.w.valid.poke(false.B); dut.io.axi.b.ready.poke(false.B)
      dut.io.axi.ar.valid.poke(false.B); dut.io.axi.r.ready.poke(false.B)
      dut.clock.step()

      def write(address: Int, data: Int): Unit = {
        dut.io.axi.aw.bits.poke(address.U); dut.io.axi.aw.valid.poke(true.B)
        dut.io.axi.w.bits.data.poke(data.U); dut.io.axi.w.bits.strb.poke("hf".U); dut.io.axi.w.valid.poke(true.B)
        dut.clock.step()
        dut.io.axi.aw.valid.poke(false.B); dut.io.axi.w.valid.poke(false.B)
        dut.io.axi.b.valid.expect(true.B)
        if (address == DiffusionRegisterMap.PerfSnapshot) { dut.io.perfSnapshot.expect(true.B) }
        dut.io.axi.b.ready.poke(true.B); dut.clock.step(); dut.io.axi.b.ready.poke(false.B)
      }
      def read(address: Int, expected: BigInt): Unit = {
        dut.io.axi.ar.bits.poke(address.U); dut.io.axi.ar.valid.poke(true.B)
        dut.io.axi.ar.ready.expect(true.B); dut.clock.step(); dut.io.axi.ar.valid.poke(false.B)
        dut.io.axi.r.valid.expect(true.B); dut.io.axi.r.bits.data.expect(expected.U)
        dut.io.axi.r.ready.poke(true.B); dut.clock.step(); dut.io.axi.r.ready.poke(false.B)
      }

      write(DiffusionRegisterMap.PerfSnapshot, 1)
      dut.io.perfSnapshot.expect(false.B)
      read(DiffusionRegisterMap.PerfTotalCyclesLo, BigInt("55667788", 16))
      read(DiffusionRegisterMap.PerfTotalCyclesHi, BigInt("11223344", 16))
    }
  }
}
