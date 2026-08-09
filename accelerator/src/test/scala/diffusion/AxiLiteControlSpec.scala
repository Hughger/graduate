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
}
