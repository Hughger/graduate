package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class TensorReadDmaSpec extends AnyFlatSpec with ChiselScalatestTester {
  private def idle(dut: TensorReadDma): Unit = {
    dut.io.command.valid.poke(false.B)
    dut.io.data.ready.poke(false.B)
    dut.io.memoryRequest.ready.poke(false.B)
    dut.io.memoryResponse.valid.poke(false.B)
    dut.io.memoryResponse.bits.poke(0.U)
  }

  "TensorReadDma" should "issue sequential 64-byte reads and retain each response under backpressure" in {
    test(new TensorReadDma) { dut =>
      idle(dut)
      dut.io.command.bits.address.poke("hfc0".U)
      dut.io.command.bits.beats.poke(2.U)
      dut.io.command.valid.poke(true.B)
      dut.io.command.ready.expect(true.B)
      dut.clock.step()
      dut.io.command.valid.poke(false.B)

      dut.io.memoryRequest.valid.expect(true.B)
      dut.io.memoryRequest.bits.write.expect(false.B)
      dut.io.memoryRequest.bits.address.expect("hfc0".U)
      dut.io.memoryRequest.ready.poke(true.B)
      dut.clock.step()
      dut.io.memoryRequest.ready.poke(false.B)

      dut.io.memoryResponse.bits.poke("haaaa".U)
      dut.io.memoryResponse.valid.poke(true.B)
      dut.clock.step()
      dut.io.memoryResponse.valid.poke(false.B)
      dut.io.data.valid.expect(true.B)
      dut.io.data.bits.expect("haaaa".U)
      dut.clock.step(2)
      dut.io.data.valid.expect(true.B)
      dut.io.memoryRequest.valid.expect(false.B)

      dut.io.data.ready.poke(true.B)
      dut.clock.step()
      dut.io.data.ready.poke(false.B)
      dut.io.memoryRequest.valid.expect(true.B)
      dut.io.memoryRequest.bits.address.expect("h1000".U)
      dut.io.memoryRequest.ready.poke(true.B)
      dut.clock.step()
      dut.io.memoryRequest.ready.poke(false.B)

      dut.io.memoryResponse.bits.poke("hbbbb".U)
      dut.io.memoryResponse.valid.poke(true.B)
      dut.clock.step()
      dut.io.memoryResponse.valid.poke(false.B)
      dut.io.data.valid.expect(true.B)
      dut.io.data.bits.expect("hbbbb".U)
      dut.io.data.ready.poke(true.B)
      dut.clock.step()
      dut.io.done.expect(true.B)
      dut.clock.step()
      dut.io.done.expect(false.B)
      dut.io.busy.expect(false.B)
    }
  }

  it should "complete a zero-beat command without issuing a memory request" in {
    test(new TensorReadDma) { dut =>
      idle(dut)
      dut.io.command.bits.address.poke(0.U)
      dut.io.command.bits.beats.poke(0.U)
      dut.io.command.valid.poke(true.B)
      dut.clock.step()
      dut.io.command.valid.poke(false.B)
      dut.io.memoryRequest.valid.expect(false.B)
      dut.io.done.expect(true.B)
      dut.io.busy.expect(false.B)
    }
  }
}
