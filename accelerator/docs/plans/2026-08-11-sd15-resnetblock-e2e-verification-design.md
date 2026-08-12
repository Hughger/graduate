# SD1.5 ResNetBlock End-to-End Fixed-Point Verification Design

**Date:** 2026-08-11  
**Status:** Implemented and simulation-validated

## Goal

Prove the functional correctness of the existing fixed-point SD1.5 ResNetBlock
prototype before resuming FPGA board integration.  The proof is an end-to-end,
bit-exact Chisel simulation of the real `DiffusionAccelTop` AXI64 backend.  It
is not a claim that full floating-point SD1.5 inference has been reproduced.

## Verification boundary

The DUT is exactly:

```scala
new DiffusionAccelTop(memoryBackend = DiffusionMemoryBackend.Axi64)
```

The test adds Scala test helpers only.  It adds no test-only Chisel hardware
and does not change production RTL behavior.  The AXI64 memory slave is a
Scala behavioural model that observes and drives the DUT's existing AW, W, B,
AR, and R channels.

The model maintains byte-addressable storage and handles the eight ordered
64-bit beats produced when the existing bridge converts one 512-bit tensor
request.  It checks addresses, beat order, write strobes, and response
handshakes.  Memory transactions are accepted only through Decoupled
handshakes.

## Directed ResNetBlock workload

The first workload uses one non-uniform 32-lane INT16 activation vector.  It
is placed in behavioural memory, then drives the existing scheduler through:

1. `LoadResidual`, using the tensor-read DMA;
2. `Gn1Stats`, with the GN1 statistics command and result handshake;
3. `Gn1Conv1`, after deterministic diagonal W8 weights are written;
4. `Gn2Stats`, with the GN2 statistics command and result handshake;
5. `Gn2Conv2Residual`, after identity affine parameters and deterministic
   Conv2 weights are written, using nonzero time embedding and residual
   vectors; and
6. `StoreOutput`, using the tensor-write DMA to write the internal result to
   behavioural memory.

All shifts and affine parameters are explicit.  The directed values exercise
positive and negative values, nonzero variance, requantization, GroupNorm/SiLU,
and residual/time fusion without requiring full production SD1.5 weights.
Saturation boundary behavior remains covered by the existing dedicated
fixed-point and requantization unit tests.

## Bit-exact reference

The test helper calculates expected values with integer arithmetic that mirrors
the RTL's signed width, multiply-accumulate, round-away-from-zero shift,
INT16 saturation, GroupNorm, SiLU, and residual/time-fusion rules.  It also
uses the same 32-lane-to-512-bit byte ordering as the DMA path.

The final 32 output lanes reconstructed from the AXI64 writeback memory must
equal the reference lanes exactly.  Intermediate GN statistics and convolution
outputs are also checked at their existing top-level observation interfaces.

## Backpressure and failure rules

The directed workload has passed in two modes:

- a baseline with immediately available AXI64 responses; and
- a deterministic backpressure mode with bounded, independent AW, W, B, AR,
  and R delays.

Both modes produced the same final output.  Every wait has a finite cycle
limit and reports the pending phase or channel on failure.  The test fails on
an invalid phase order, missing or duplicate beat, unexpected address, bad
write strobe, non-OKAY AXI response, early `done`, timeout, or any lane
mismatch.

## Evidence and exclusions

Recorded evidence on 2026-08-12:

- `sbt 'testOnly FLOOD_Accelerator.diffusion.DiffusionAccelTopResNetBlockE2ESpec FLOOD_Accelerator.diffusion.DiffusionAccelTopAxi64Spec FLOOD_Accelerator.diffusion.MigAppToAxi64BridgeSpec FLOOD_Accelerator.diffusion.ConvToGroupNormStatsPathSpec FLOOD_Accelerator.diffusion.Conv2ResidualPathSpec FLOOD_Accelerator.diffusion.GroupNormActivationPathSpec FLOOD_Accelerator.diffusion.Axi64MemoryModelSpec FLOOD_Accelerator.diffusion.ResNetBlockE2ETestSupportSpec'` passed 17 tests in 8 suites with zero failures.
- The directed 32-lane vector completed through LoadResidual, GN1, Conv1, GN2, Conv2/residual fusion, StoreOutput, and final AXI64 writeback.  Its final 512-bit word matched the integer reference lane-for-lane both with immediate memory responses and with independent staggered AW/W/B/AR/R delays.
- `sbt 'runMain FLOOD_Accelerator.diffusion.GenerateDiffusionAccelAxi64TopVerilog'` completed successfully, regenerating the AXI64-backend accelerator through Chisel elaboration without a new version-controlled artifact.
- The Windows full-suite run (with a 4 GiB SBT heap) passed 76 tests. Its only remaining test, `MacMachineWrapperTest`, intentionally requires the external Verilator backend and therefore cannot run from the Windows PATH. The same test was run in the existing Ubuntu WSL environment with Verilator 5.032 and passed 1/1 (309.206 s). A temporary `/tmp` Verilator copy was used only to disable precompiled headers, avoiding the WSL-mounted-directory build issue; no project source or test was changed. Together these results cover all 77 repository tests.

This evidence validates one directed fixed-point vector and the listed timing modes.  It does not establish floating-point SD1.5 numerical accuracy, arbitrary tensor shapes, full production weights, or performance at a target FPGA clock.  Board wrapper work, Vivado implementation, bitstream generation, and FPGA programming remain out of scope for this verified milestone.

The planned AXKU15 transparent top remains documented separately and is
explicitly deferred by
`2026-08-11-axi64-ddr4-transparent-top-design.md`.
