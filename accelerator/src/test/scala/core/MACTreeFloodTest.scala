import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec
import FLOOD_Accelerator.core.MACTreeFlood

class MACTreeFloodSpec extends AnyFlatSpec with ChiselScalatestTester {
  behavior of "MACTreeFlood"

  it should "retain a pipeline-1 result while its output FIFO is full" in {
    test(new MACTreeFlood(paral = 2, dataWidth = 8, outputWidth = 16, pipeline = 1, tLatency = 2)) { dut =>
      dut.io.out.ready.poke(false.B)
      dut.io.inB.valid.poke(false.B)
      dut.io.inA(0).poke(1.S)
      dut.io.inA(1).poke(1.S)

      def waitFor(condition: => Boolean, maxCycles: Int, description: String): Unit = {
        var waitCycles = 0
        while (!condition && waitCycles < maxCycles) {
          dut.clock.step(1)
          waitCycles += 1
        }
        assert(condition, s"timed out waiting for $description after $maxCycles cycles")
      }

      def sendVector(): Unit = {
        waitFor(dut.io.inB.ready.peek().litToBoolean, 12, "input ready")
        dut.io.inB.bits(0).poke(1.S)
        dut.io.inB.bits(1).poke(1.S)
        dut.io.inB.valid.poke(true.B)
        assert(dut.io.inB.ready.peek().litToBoolean, "vector must be accepted when valid is asserted")
        dut.clock.step(1)
        dut.io.inB.valid.poke(false.B)
      }

      var acceptedVectors = 0
      for (vectorIndex <- 0 until 4) {
        sendVector()
        acceptedVectors += 1
        assert(acceptedVectors == vectorIndex + 1, s"vector ${vectorIndex + 1} must be accepted before the next vector")
        waitFor(dut.io.inB.ready.peek().litToBoolean, 12, s"vector ${vectorIndex + 1} completion")
      }
      assert(acceptedVectors == 4, "the first four vectors must be accepted before presenting the fifth")
      sendVector()
      dut.clock.step(3)
      dut.io.inB.ready.expect(false.B)

      for (resultIndex <- 0 until 5) {
        waitFor(dut.io.out.valid.peek().litToBoolean, 8, s"result ${resultIndex + 1} of 5")
        dut.io.out.bits.expect(1.S)
        dut.io.out.ready.poke(true.B)
        dut.clock.step(1)
        dut.io.out.ready.poke(false.B)
      }
    }
  }
}
