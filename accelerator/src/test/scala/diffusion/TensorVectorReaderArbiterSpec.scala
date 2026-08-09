package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class TensorVectorReaderArbiterSpec extends AnyFlatSpec with ChiselScalatestTester {
  "TensorVectorReaderArbiter" should "prioritize stats and route its vector and done response exclusively" in {
    test(new TensorVectorReaderArbiter) { dut =>
      dut.io.debugCommand.valid.poke(false.B); dut.io.debugVector.ready.poke(true.B)
      dut.io.statsCommand.valid.poke(false.B); dut.io.statsVector.ready.poke(true.B)
      dut.io.readerCommand.ready.poke(false.B); dut.io.readerVector.valid.poke(false.B); dut.io.readerDone.poke(false.B)
      dut.io.debugCommand.bits.baseAddress.poke(1.U); dut.io.debugCommand.bits.vectors.poke(1.U)
      dut.io.statsCommand.bits.baseAddress.poke(7.U); dut.io.statsCommand.bits.vectors.poke(1.U)
      dut.io.debugCommand.valid.poke(true.B); dut.io.statsCommand.valid.poke(true.B); dut.io.readerCommand.ready.poke(true.B)
      dut.io.readerCommand.bits.baseAddress.expect(7.U); dut.io.statsCommand.ready.expect(true.B); dut.io.debugCommand.ready.expect(false.B)
      dut.clock.step(); dut.io.debugCommand.valid.poke(false.B); dut.io.statsCommand.valid.poke(false.B)
      for (lane <- 0 until 32) { dut.io.readerVector.bits(lane).poke(lane.S) }
      dut.io.readerVector.valid.poke(true.B); dut.io.statsVector.valid.expect(true.B); dut.io.debugVector.valid.expect(false.B)
      dut.clock.step(); dut.io.readerVector.valid.poke(false.B); dut.io.readerDone.poke(true.B)
      dut.io.statsDone.expect(true.B); dut.io.debugDone.expect(false.B); dut.clock.step()
    }
  }
}
