package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class MigAppTransferSpec extends AnyFlatSpec with ChiselScalatestTester {
  private def idle(dut: MigAppTransfer): Unit = {
    dut.io.request.valid.poke(false.B)
    dut.io.response.ready.poke(false.B)
    dut.io.app.rdy.poke(false.B)
    dut.io.app.wdfRdy.poke(false.B)
    dut.io.app.rdDataValid.poke(false.B)
    dut.io.app.rdData.poke(0.U)
    dut.io.app.rdDataEnd.poke(false.B)
  }

  "MigAppTransfer" should "hold a read command until accepted and retain returned data" in {
    test(new MigAppTransfer) { dut =>
      idle(dut)
      dut.io.request.bits.write.poke(false.B)
      dut.io.request.bits.address.poke("h80".U)
      dut.io.request.bits.writeData.poke(0.U)
      dut.io.request.bits.writeMask.poke(0.U)
      dut.io.request.valid.poke(true.B)
      dut.io.request.ready.expect(true.B)
      dut.clock.step()
      dut.io.request.valid.poke(false.B)

      dut.io.app.en.expect(true.B)
      dut.io.app.cmd.expect(MigAppCommand.Read.U)
      dut.io.app.address.expect("h80".U)
      dut.clock.step(2)
      dut.io.app.en.expect(true.B)
      dut.io.app.rdy.poke(true.B)
      dut.clock.step()
      dut.io.app.rdy.poke(false.B)
      dut.io.app.en.expect(false.B)

      dut.io.app.rdData.poke("h1234".U)
      dut.io.app.rdDataEnd.poke(true.B)
      dut.io.app.rdDataValid.poke(true.B)
      dut.clock.step()
      dut.io.app.rdDataValid.poke(false.B)
      dut.io.response.valid.expect(true.B)
      dut.io.response.bits.expect("h1234".U)
      dut.clock.step(2)
      dut.io.response.valid.expect(true.B)
      dut.io.response.ready.poke(true.B)
      dut.clock.step()
      dut.io.response.valid.expect(false.B)
    }
  }

  it should "complete a write only after both MIG command and data channels accept it" in {
    test(new MigAppTransfer) { dut =>
      idle(dut)
      dut.io.request.bits.write.poke(true.B)
      dut.io.request.bits.address.poke("h100".U)
      dut.io.request.bits.writeData.poke("h5a".U)
      dut.io.request.bits.writeMask.poke(0.U)
      dut.io.request.valid.poke(true.B)
      dut.clock.step()
      dut.io.request.valid.poke(false.B)

      dut.io.app.en.expect(true.B)
      dut.io.app.wdfWren.expect(true.B)
      dut.io.app.cmd.expect(MigAppCommand.Write.U)
      dut.io.app.wdfData.expect("h5a".U)
      dut.io.app.rdy.poke(true.B)
      dut.clock.step()
      dut.io.app.rdy.poke(false.B)
      dut.io.app.en.expect(false.B)
      dut.io.app.wdfWren.expect(true.B)
      dut.io.done.expect(false.B)

      dut.io.app.wdfRdy.poke(true.B)
      dut.clock.step()
      dut.io.app.wdfRdy.poke(false.B)
      dut.io.app.wdfWren.expect(false.B)
      dut.io.done.expect(true.B)
      dut.clock.step()
      dut.io.done.expect(false.B)
      dut.io.request.ready.expect(true.B)
    }
  }
  it should "ignore a non-final read-data beat" in {
    test(new MigAppTransfer) { dut =>
      idle(dut)
      dut.io.request.bits.write.poke(false.B)
      dut.io.request.bits.address.poke(0.U)
      dut.io.request.bits.writeData.poke(0.U)
      dut.io.request.bits.writeMask.poke(0.U)
      dut.io.request.valid.poke(true.B)
      dut.clock.step()
      dut.io.request.valid.poke(false.B)
      dut.io.app.rdy.poke(true.B)
      dut.clock.step()
      dut.io.app.rdy.poke(false.B)

      dut.io.app.rdData.poke("hdead".U)
      dut.io.app.rdDataValid.poke(true.B)
      dut.io.app.rdDataEnd.poke(false.B)
      dut.clock.step()
      dut.io.response.valid.expect(false.B)

      dut.io.app.rdData.poke("hbeef".U)
      dut.io.app.rdDataEnd.poke(true.B)
      dut.clock.step()
      dut.io.response.valid.expect(true.B)
      dut.io.response.bits.expect("hbeef".U)
    }
  }
}
