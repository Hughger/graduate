package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec
import org.scalatest.matchers.should.Matchers

class Axi64MemoryModelSpec extends AnyFlatSpec with ChiselScalatestTester with Matchers {
  "Axi64MemoryModel" should "store one 512-bit bridge write as eight ordered 64-bit beats" in {
    test(new MigAppToAxi64Bridge) { dut =>
      val memory = new Axi64MemoryModel(dut.io.axi, Axi64DelayProfile.immediate)
      val word = (0 until 8).map(index => BigInt(index + 1) << (64 * index)).sum

      dut.io.request.bits.write.poke(true.B)
      dut.io.request.bits.address.poke("h400".U)
      dut.io.request.bits.writeData.poke(word.U)
      dut.io.request.bits.writeMask.poke(0.U)
      dut.io.request.valid.poke(true.B)
      dut.io.response.ready.poke(false.B)

      var accepted = false
      var doneSeen = false
      for (_ <- 0 until 64 if !doneSeen) {
        memory.driveBeforeClock()
        val requestFire = !accepted && dut.io.request.valid.peek().litToBoolean &&
          dut.io.request.ready.peek().litToBoolean
        memory.observeBeforeClock()
        doneSeen ||= dut.io.done.peek().litToBoolean
        dut.clock.step()
        if (requestFire) {
          accepted = true
          dut.io.request.valid.poke(false.B)
        }
      }

      accepted shouldBe true
      doneSeen shouldBe true
      memory.read512(0x400) shouldBe word
      memory.assertNoProtocolError()
    }
  }
  it should "return one 512-bit bridge read as eight ordered 64-bit beats" in {
    test(new MigAppToAxi64Bridge) { dut =>
      val memory = new Axi64MemoryModel(dut.io.axi, Axi64DelayProfile.immediate)
      val word = (0 until 8).map(index => BigInt(index + 0x11) << (64 * index)).sum
      memory.load512(0x480, word)

      dut.io.request.bits.write.poke(false.B)
      dut.io.request.bits.address.poke("h480".U)
      dut.io.request.bits.writeData.poke(0.U)
      dut.io.request.bits.writeMask.poke(0.U)
      dut.io.request.valid.poke(true.B)
      dut.io.response.ready.poke(true.B)

      var accepted = false
      var received: Option[BigInt] = None
      for (_ <- 0 until 64 if received.isEmpty) {
        memory.driveBeforeClock()
        val requestFire = !accepted && dut.io.request.valid.peek().litToBoolean &&
          dut.io.request.ready.peek().litToBoolean
        if (dut.io.response.valid.peek().litToBoolean && dut.io.response.ready.peek().litToBoolean) {
          received = Some(dut.io.response.bits.peek().litValue)
        }
        memory.observeBeforeClock()
        dut.clock.step()
        if (requestFire) {
          accepted = true
          dut.io.request.valid.poke(false.B)
        }
      }

      accepted shouldBe true
      received shouldBe Some(word)
      memory.assertNoProtocolError()
    }
  }
}
