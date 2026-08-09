package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class TensorVectorReaderThreeWayArbiterSpec extends AnyFlatSpec with ChiselScalatestTester {
  "TensorVectorReaderThreeWayArbiter" should "prioritize stats over compute over debug and preserve compute response ownership" in {
    test(new TensorVectorReaderThreeWayArbiter) { dut =>
      dut.io.debugCommand.valid.poke(false.B); dut.io.debugVector.ready.poke(true.B)
      dut.io.computeCommand.valid.poke(false.B); dut.io.computeVector.ready.poke(true.B)
      dut.io.statsCommand.valid.poke(false.B); dut.io.statsVector.ready.poke(true.B)
      dut.io.readerCommand.ready.poke(true.B); dut.io.readerVector.valid.poke(false.B); dut.io.readerDone.poke(false.B)
      dut.io.debugCommand.bits.baseAddress.poke(1.U); dut.io.debugCommand.bits.vectors.poke(1.U)
      dut.io.computeCommand.bits.baseAddress.poke(5.U); dut.io.computeCommand.bits.vectors.poke(1.U)
      dut.io.statsCommand.bits.baseAddress.poke(9.U); dut.io.statsCommand.bits.vectors.poke(1.U)

      dut.io.debugCommand.valid.poke(true.B); dut.io.computeCommand.valid.poke(true.B); dut.io.statsCommand.valid.poke(true.B)
      dut.io.readerCommand.bits.baseAddress.expect(9.U)
      dut.io.statsCommand.ready.expect(true.B); dut.io.computeCommand.ready.expect(false.B); dut.io.debugCommand.ready.expect(false.B)
      dut.clock.step()
      dut.io.statsCommand.valid.poke(false.B)
      dut.io.readerDone.poke(true.B); dut.clock.step(); dut.io.readerDone.poke(false.B)

      dut.io.readerCommand.bits.baseAddress.expect(5.U)
      dut.io.computeCommand.ready.expect(true.B); dut.io.debugCommand.ready.expect(false.B)
      dut.clock.step()
      dut.io.computeCommand.valid.poke(false.B); dut.io.debugCommand.valid.poke(false.B)
      for (lane <- 0 until 32) { dut.io.readerVector.bits(lane).poke((lane - 16).S) }
      dut.io.readerVector.valid.poke(true.B)
      dut.io.computeVector.valid.expect(true.B); dut.io.debugVector.valid.expect(false.B); dut.io.statsVector.valid.expect(false.B)
      dut.io.computeVector.bits(0).expect((-16).S)
      dut.clock.step()
      dut.io.readerVector.valid.poke(false.B); dut.io.readerDone.poke(true.B)
      dut.io.computeDone.expect(true.B); dut.io.statsDone.expect(false.B); dut.io.debugDone.expect(false.B)
    }
  }
}
