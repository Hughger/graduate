package FLOOD_Accelerator.diffusion

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class BlockSchedulerSpec extends AnyFlatSpec with ChiselScalatestTester {
  "BlockScheduler" should "follow the fused equal-channel phase sequence" in {
    test(new BlockScheduler) { dut =>
      dut.io.start.poke(false.B)
      dut.io.phaseDone.poke(false.B)
      dut.clock.step()
      dut.io.busy.expect(false.B)

      dut.io.start.poke(true.B)
      dut.clock.step()
      dut.io.start.poke(false.B)
      dut.io.busy.expect(true.B)
      dut.io.phase.expect(BlockPhase.LoadResidual.U)

      Seq(
        BlockPhase.Gn1Stats,
        BlockPhase.Gn1Conv1,
        BlockPhase.Gn2Stats,
        BlockPhase.Gn2Conv2Residual,
        BlockPhase.StoreOutput
      ).foreach { expected =>
        dut.io.phaseDone.poke(true.B)
        dut.clock.step()
        dut.io.phaseDone.poke(false.B)
        dut.io.phase.expect(expected.U)
      }
      dut.io.phaseDone.poke(true.B)
      dut.clock.step()
      dut.io.busy.expect(false.B)
      dut.io.done.expect(true.B)
    }
  }
}
