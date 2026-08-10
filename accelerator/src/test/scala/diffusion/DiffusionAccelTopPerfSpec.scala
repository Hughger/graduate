package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class DiffusionAccelTopPerfSpec extends AnyFlatSpec with ChiselScalatestTester {
  "DiffusionAccelTop" should "snapshot nonzero active-cycle performance counters after a block starts" in {
    test(new DiffusionAccelTop) { dut =>
      dut.io.phaseDone.poke(false.B); dut.io.perfSnapshot.poke(false.B)
      dut.io.axi.aw.bits.poke(0.U); dut.io.axi.aw.valid.poke(true.B)
      dut.io.axi.w.bits.data.poke(1.U); dut.io.axi.w.bits.strb.poke("hf".U); dut.io.axi.w.valid.poke(true.B)
      dut.io.axi.b.ready.poke(true.B); dut.io.axi.ar.valid.poke(false.B); dut.io.axi.r.ready.poke(false.B)
      dut.clock.step(); dut.io.axi.aw.valid.poke(false.B); dut.io.axi.w.valid.poke(false.B)
      dut.clock.step(3); dut.io.busy.expect(true.B)
      dut.io.perfSnapshot.poke(true.B); dut.clock.step(); dut.io.perfSnapshot.poke(false.B)
      assert(dut.io.perfCounters.totalCycles.peek().litValue > 0)
    }
  }

  it should "snapshot and read active-cycle counters through its AXI-Lite port" in {
    test(new DiffusionAccelTop) { dut =>
      dut.io.phaseDone.poke(false.B); dut.io.perfSnapshot.poke(false.B)
      dut.io.axi.b.ready.poke(true.B); dut.io.axi.ar.valid.poke(false.B); dut.io.axi.r.ready.poke(false.B)

      def write(address: Int, data: Int): Unit = {
        dut.io.axi.aw.bits.poke(address.U); dut.io.axi.aw.valid.poke(true.B)
        dut.io.axi.w.bits.data.poke(data.U); dut.io.axi.w.bits.strb.poke("hf".U); dut.io.axi.w.valid.poke(true.B)
        dut.clock.step()
        dut.io.axi.aw.valid.poke(false.B); dut.io.axi.w.valid.poke(false.B)
        dut.io.axi.b.valid.expect(true.B)
        dut.clock.step()
      }

      write(DiffusionRegisterMap.Control, 1)
      dut.clock.step(3); dut.io.busy.expect(true.B)
      write(DiffusionRegisterMap.PerfSnapshot, 1)
      val snappedCycles = dut.io.perfCounters.totalCycles.peek().litValue
      assert(snappedCycles > 0)
      dut.clock.step(4)
      dut.io.perfCounters.totalCycles.expect(snappedCycles.U)
      dut.io.axi.ar.bits.poke(DiffusionRegisterMap.PerfTotalCyclesLo.U)
      dut.io.axi.ar.valid.poke(true.B); dut.io.axi.ar.ready.expect(true.B)
      dut.clock.step(); dut.io.axi.ar.valid.poke(false.B)
      dut.io.axi.r.valid.expect(true.B)
      dut.io.axi.r.bits.data.expect((snappedCycles & BigInt("ffffffff", 16)).U)
      dut.io.axi.r.ready.poke(true.B); dut.clock.step(); dut.io.axi.r.ready.poke(false.B)
    }
  }
}
