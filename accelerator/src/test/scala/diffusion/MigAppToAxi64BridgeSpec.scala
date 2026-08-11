package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class MigAppToAxi64BridgeSpec extends AnyFlatSpec with ChiselScalatestTester {
  private val patterned512 = (0 until 8).map(index => BigInt(index + 1) << (64 * index)).sum

  private def idle(dut: MigAppToAxi64Bridge): Unit = {
    dut.io.request.valid.poke(false.B)
    dut.io.response.ready.poke(false.B)
    dut.io.axi.aw.ready.poke(false.B)
    dut.io.axi.w.ready.poke(false.B)
    dut.io.axi.b.valid.poke(false.B)
    dut.io.axi.b.bits.id.poke(0.U)
    dut.io.axi.b.bits.resp.poke(0.U)
    dut.io.axi.ar.ready.poke(false.B)
    dut.io.axi.r.valid.poke(false.B)
    dut.io.axi.r.bits.data.poke(0.U)
    dut.io.axi.r.bits.id.poke(0.U)
    dut.io.axi.r.bits.resp.poke(0.U)
    dut.io.axi.r.bits.last.poke(false.B)
  }

  private def word64(value: BigInt, index: Int): BigInt =
    (value >> (64 * index)) & ((BigInt(1) << 64) - 1)
  private def submitWrite(dut: MigAppToAxi64Bridge, address: BigInt, mask: BigInt = 0): Unit = {
    dut.io.request.bits.write.poke(true.B)
    dut.io.request.bits.address.poke(address.U)
    dut.io.request.bits.writeData.poke(patterned512.U)
    dut.io.request.bits.writeMask.poke(mask.U)
    dut.io.request.valid.poke(true.B)
    dut.io.request.ready.expect(true.B)
    dut.clock.step()
    dut.io.request.valid.poke(false.B)
  }

  private def acceptWriteAddress(dut: MigAppToAxi64Bridge): Unit = {
    dut.io.axi.aw.valid.expect(true.B)
    dut.io.axi.aw.ready.poke(true.B)
    dut.clock.step()
    dut.io.axi.aw.ready.poke(false.B)
  }

  private def acceptWriteData(dut: MigAppToAxi64Bridge): Unit = {
    dut.io.axi.w.valid.expect(true.B)
    dut.io.axi.w.ready.poke(true.B)
    dut.clock.step()
    dut.io.axi.w.ready.poke(false.B)
  }

  "MigAppToAxi64Bridge" should "split a masked 512-bit write into eight ordered AXI beats" in {
    test(new MigAppToAxi64Bridge) { dut =>
      idle(dut)
      dut.io.request.bits.write.poke(true.B)
      dut.io.request.bits.address.poke("h100".U)
      dut.io.request.bits.writeData.poke(patterned512.U)
      dut.io.request.bits.writeMask.poke("hff00000000000000".U)
      dut.io.request.valid.poke(true.B)
      dut.io.request.ready.expect(true.B)
      dut.clock.step()
      dut.io.request.valid.poke(false.B)

      dut.io.axi.aw.valid.expect(true.B)
      dut.io.axi.aw.bits.addr.expect("h100".U)
      dut.io.axi.aw.bits.id.expect(0.U)
      dut.io.axi.aw.bits.len.expect(7.U)
      dut.io.axi.aw.bits.size.expect(3.U)
      dut.io.axi.aw.ready.poke(true.B)
      dut.clock.step()
      dut.io.axi.aw.ready.poke(false.B)

      for (beat <- 0 until 8) {
        dut.io.axi.w.valid.expect(true.B)
        dut.io.axi.w.bits.data.expect(word64(patterned512, beat).U)
        dut.io.axi.w.bits.strb.expect((if (beat == 7) 0 else 255).U)
        dut.io.axi.w.bits.last.expect((beat == 7).B)
        dut.io.axi.w.ready.poke(true.B)
        dut.clock.step()
        dut.io.axi.w.ready.poke(false.B)
      }
    }
  }
  it should "retain write channels through independent backpressure and wait for B completion" in {
    test(new MigAppToAxi64Bridge) { dut =>
      idle(dut)
      submitWrite(dut, 0x180)

      dut.io.axi.aw.valid.expect(true.B)
      dut.io.axi.aw.ready.poke(false.B)
      dut.clock.step(2)
      dut.io.axi.aw.valid.expect(true.B)
      dut.io.axi.aw.bits.addr.expect("h180".U)
      acceptWriteAddress(dut)

      dut.io.axi.w.valid.expect(true.B)
      dut.io.axi.w.ready.poke(false.B)
      dut.clock.step(2)
      dut.io.axi.w.valid.expect(true.B)
      dut.io.axi.w.bits.data.expect(word64(patterned512, 0).U)
      acceptWriteData(dut)
      for (_ <- 1 until 8) {
        acceptWriteData(dut)
      }

      dut.io.request.ready.expect(false.B)
      dut.io.axi.b.ready.expect(true.B)
      dut.io.done.expect(false.B)
      dut.io.axi.b.bits.resp.poke(0.U)
      dut.io.axi.b.valid.poke(true.B)
      dut.clock.step()
      dut.io.axi.b.valid.poke(false.B)
      dut.io.done.expect(true.B)
      dut.io.error.expect(false.B)
      dut.clock.step()
      dut.io.done.expect(false.B)
      dut.io.request.ready.expect(true.B)
    }
  }

  it should "latch an AXI write error without reporting done" in {
    test(new MigAppToAxi64Bridge) { dut =>
      idle(dut)
      submitWrite(dut, 0x1c0)
      acceptWriteAddress(dut)
      for (_ <- 0 until 8) {
        acceptWriteData(dut)
      }

      dut.io.axi.b.ready.expect(true.B)
      dut.io.axi.b.bits.resp.poke(2.U)
      dut.io.axi.b.valid.poke(true.B)
      dut.clock.step()
      dut.io.axi.b.valid.poke(false.B)
      dut.io.done.expect(false.B)
      dut.io.error.expect(true.B)
    }
  }
  private def submitRead(dut: MigAppToAxi64Bridge, address: BigInt): Unit = {
    dut.io.request.bits.write.poke(false.B)
    dut.io.request.bits.address.poke(address.U)
    dut.io.request.bits.writeData.poke(0.U)
    dut.io.request.bits.writeMask.poke(0.U)
    dut.io.request.valid.poke(true.B)
    dut.io.request.ready.expect(true.B)
    dut.clock.step()
    dut.io.request.valid.poke(false.B)
  }

  private def acceptReadAddress(dut: MigAppToAxi64Bridge): Unit = {
    dut.io.axi.ar.valid.expect(true.B)
    dut.io.axi.ar.ready.poke(true.B)
    dut.clock.step()
    dut.io.axi.ar.ready.poke(false.B)
  }

  it should "assemble eight AXI read beats in little-endian beat order and retain the response" in {
    test(new MigAppToAxi64Bridge) { dut =>
      idle(dut)
      submitRead(dut, 0x200)
      dut.io.axi.ar.valid.expect(true.B)
      dut.io.axi.ar.bits.addr.expect("h200".U)
      dut.io.axi.ar.bits.id.expect(0.U)
      dut.io.axi.ar.bits.len.expect(7.U)
      dut.io.axi.ar.bits.size.expect(3.U)
      acceptReadAddress(dut)

      val beats = (0 until 8).map(index => BigInt(index + 1))
      for ((beat, index) <- beats.zipWithIndex) {
        dut.io.axi.r.ready.expect(true.B)
        dut.io.axi.r.bits.data.poke(beat.U)
        dut.io.axi.r.bits.id.poke(0.U)
        dut.io.axi.r.bits.resp.poke(0.U)
        dut.io.axi.r.bits.last.poke((index == 7).B)
        dut.io.axi.r.valid.poke(true.B)
        dut.clock.step()
        dut.io.axi.r.valid.poke(false.B)
      }

      val assembled = beats.zipWithIndex.map { case (value, index) => value << (64 * index) }.sum
      dut.io.response.valid.expect(true.B)
      dut.io.response.bits.expect(assembled.U)
      dut.clock.step(2)
      dut.io.response.valid.expect(true.B)
      dut.io.response.ready.poke(true.B)
      dut.clock.step()
      dut.io.response.ready.poke(false.B)
      dut.io.response.valid.expect(false.B)
      dut.io.request.ready.expect(true.B)
    }
  }

  it should "latch an AXI read error without producing a response" in {
    test(new MigAppToAxi64Bridge) { dut =>
      idle(dut)
      submitRead(dut, 0x240)
      acceptReadAddress(dut)
      dut.io.axi.r.ready.expect(true.B)
      dut.io.axi.r.bits.data.poke(0.U)
      dut.io.axi.r.bits.id.poke(0.U)
      dut.io.axi.r.bits.resp.poke(2.U)
      dut.io.axi.r.bits.last.poke(true.B)
      dut.io.axi.r.valid.poke(true.B)
      dut.clock.step()
      dut.io.axi.r.valid.poke(false.B)
      dut.io.response.valid.expect(false.B)
      dut.io.error.expect(true.B)
      dut.io.request.ready.expect(true.B)
    }
  }
  it should "drain remaining AXI read beats after a non-final read error" in {
    test(new MigAppToAxi64Bridge) { dut =>
      idle(dut)
      submitRead(dut, 0x280)
      acceptReadAddress(dut)

      dut.io.axi.r.ready.expect(true.B)
      dut.io.axi.r.bits.data.poke("hdead".U)
      dut.io.axi.r.bits.id.poke(0.U)
      dut.io.axi.r.bits.resp.poke(2.U)
      dut.io.axi.r.bits.last.poke(false.B)
      dut.io.axi.r.valid.poke(true.B)
      dut.clock.step()
      dut.io.axi.r.valid.poke(false.B)
      dut.io.error.expect(true.B)
      dut.io.request.ready.expect(false.B)
      dut.io.axi.r.ready.expect(true.B)

      dut.io.axi.r.bits.data.poke(0.U)
      dut.io.axi.r.bits.resp.poke(0.U)
      dut.io.axi.r.bits.last.poke(true.B)
      dut.io.axi.r.valid.poke(true.B)
      dut.clock.step()
      dut.io.axi.r.valid.poke(false.B)
      dut.io.response.valid.expect(false.B)
      dut.io.request.ready.expect(true.B)
    }
  }
}
