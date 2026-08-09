package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class TensorWriteDmaSpec extends AnyFlatSpec with ChiselScalatestTester {
  private def idle(dut: TensorWriteDma): Unit = {
    dut.io.command.valid.poke(false.B)
    dut.io.data.valid.poke(false.B)
    dut.io.memoryRequest.ready.poke(false.B)
    dut.io.memoryDone.poke(false.B)
  }

  "TensorWriteDma" should "write ordered 64-byte beats and wait for each completion" in {
    test(new TensorWriteDma) { dut =>
      idle(dut)
      dut.io.command.bits.address.poke("h380".U)
      dut.io.command.bits.beats.poke(2.U)
      dut.io.command.valid.poke(true.B)
      dut.clock.step()
      dut.io.command.valid.poke(false.B)
      dut.io.data.ready.expect(true.B)

      dut.io.data.bits.poke("h1111".U)
      dut.io.data.valid.poke(true.B)
      dut.clock.step()
      dut.io.data.valid.poke(false.B)
      dut.io.memoryRequest.valid.expect(true.B)
      dut.io.memoryRequest.bits.write.expect(true.B)
      dut.io.memoryRequest.bits.address.expect("h380".U)
      dut.io.memoryRequest.bits.writeData.expect("h1111".U)
      dut.io.memoryRequest.bits.writeMask.expect(0.U)
      dut.io.memoryRequest.ready.poke(true.B)
      dut.clock.step()
      dut.io.memoryRequest.ready.poke(false.B)
      dut.io.data.ready.expect(false.B)

      dut.io.memoryDone.poke(true.B)
      dut.clock.step()
      dut.io.memoryDone.poke(false.B)
      dut.io.data.ready.expect(true.B)

      dut.io.data.bits.poke("h2222".U)
      dut.io.data.valid.poke(true.B)
      dut.clock.step()
      dut.io.data.valid.poke(false.B)
      dut.io.memoryRequest.valid.expect(true.B)
      dut.io.memoryRequest.bits.address.expect("h3c0".U)
      dut.io.memoryRequest.ready.poke(true.B)
      dut.clock.step()
      dut.io.memoryRequest.ready.poke(false.B)
      dut.io.memoryDone.poke(true.B)
      dut.clock.step()
      dut.io.memoryDone.poke(false.B)
      dut.io.done.expect(true.B)
      dut.io.busy.expect(false.B)
    }
  }

  it should "complete a zero-beat command without waiting for data" in {
    test(new TensorWriteDma) { dut =>
      idle(dut)
      dut.io.command.bits.address.poke(0.U)
      dut.io.command.bits.beats.poke(0.U)
      dut.io.command.valid.poke(true.B)
      dut.clock.step()
      dut.io.command.valid.poke(false.B)
      dut.io.data.ready.expect(false.B)
      dut.io.memoryRequest.valid.expect(false.B)
      dut.io.done.expect(true.B)
    }
  }
}
