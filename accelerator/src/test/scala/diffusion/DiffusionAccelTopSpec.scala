package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class DiffusionAccelTopSpec extends AnyFlatSpec with ChiselScalatestTester {
  "DiffusionAccelTop" should "start the fused scheduler from an AXI-Lite control write" in {
    test(new DiffusionAccelTop) { dut =>
      dut.io.phaseDone.poke(false.B)
      dut.io.axi.aw.bits.poke(0.U); dut.io.axi.aw.valid.poke(true.B)
      dut.io.axi.w.bits.data.poke(1.U); dut.io.axi.w.bits.strb.poke("hf".U); dut.io.axi.w.valid.poke(true.B)
      dut.io.axi.b.ready.poke(true.B); dut.io.axi.ar.valid.poke(false.B); dut.io.axi.r.ready.poke(false.B)
      dut.clock.step()
      dut.io.axi.aw.valid.poke(false.B); dut.io.axi.w.valid.poke(false.B)
      dut.clock.step()
      dut.io.busy.expect(true.B)
      dut.io.phase.expect(BlockPhase.LoadResidual.U)
    }
  }
}
