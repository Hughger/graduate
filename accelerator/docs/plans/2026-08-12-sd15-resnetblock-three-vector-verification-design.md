# SD1.5 ResNetBlock Three-Vector AXI64 Verification Design

**Date:** 2026-08-12
**Status:** Implemented and simulation-validated

## Goal

Extend the existing fixed-point, AXI64-backed ResNetBlock simulation boundary
from one and two contiguous 512-bit vectors to one directed three-vector
transaction.  The proof must demonstrate preserved vector order through DMA,
both compute paths, and writeback while the behavioural AXI64 memory applies
independent backpressure on all five channels.

## Scope and workload

The DUT remains `new DiffusionAccelTop(memoryBackend =
DiffusionMemoryBackend.Axi64)`.  The change adds one test case to the existing
E2E specification only; it does not modify production RTL or public hardware
interfaces.

The input comprises three 32-lane INT16 words:

1. lanes 0--15 `-1`, lanes 16--31 `+1`;
2. lanes 0--15 `+1`, lanes 16--31 `-1`; and
3. alternating `-1`, `+1` from lane 0 onward.

The combined GroupNorm statistics are `sum = 0`, `sumSquare = 96`, and
`count = 96`; the Q2.30 rsqrt remains `759250125`.  Diagonal unit Conv1/Conv2
weights, identity GN2 affine parameters, time embedding `+3`, and residual
`-2` retain the validated fixed-point reference boundary.

Read DMA begins at `0x400` and must issue accepted AXI64 bursts at
`0x400`, `0x440`, and `0x480`.  Write DMA begins at `0x800` and must issue
accepted bursts at `0x800`, `0x840`, and `0x880`.

## Test behavior

The new case will drive one three-beat read command, GN1 statistics and Conv1
with `vectors = 3`, GN2 statistics, GN2 activation/Conv2 with `vectors = 3`,
and one three-beat write command.  It will collect exactly three handshaken
vectors at Conv1, activation, and Conv2/fusion interfaces; compare each to the
integer reference; require exactly one completion; and verify all three memory
writeback words.

It will use `Axi64DelayProfile.staggered`, require the five delayed channel
names `AW`, `W`, `B`, `AR`, and `R`, and require no behavioural-model protocol
error.  Every wait remains bounded.  Existing one-vector, two-vector, and
consecutive-transaction tests remain unchanged and are rerun in the focused
regression.

## Recorded evidence

On 2026-08-12, the focused command below completed with 27 passing tests in
11 suites and zero failures:

```powershell
sbt 'testOnly FLOOD_Accelerator.diffusion.TensorTileBufferSpec FLOOD_Accelerator.diffusion.TensorLoadBufferSpec FLOOD_Accelerator.diffusion.ResNetBlockE2ETestSupportSpec FLOOD_Accelerator.diffusion.DiffusionAccelTopResNetBlockE2ESpec FLOOD_Accelerator.diffusion.Axi64MemoryModelSpec FLOOD_Accelerator.diffusion.DiffusionAccelTopAxi64Spec FLOOD_Accelerator.diffusion.MigAppToAxi64BridgeSpec FLOOD_Accelerator.diffusion.ConvToGroupNormStatsPathSpec FLOOD_Accelerator.diffusion.Conv2ResidualPathSpec FLOOD_Accelerator.diffusion.GroupNormActivationPathSpec FLOOD_Accelerator.diffusion.RsqrtUnitReferenceSpec'
```

The ResNetBlock E2E suite completed four tests: the existing one-vector,
two-vector, and consecutive-transaction cases plus the new three-vector case.
The latter used the three directed words defined above, observed GroupNorm
statistics `(0, 96, 96)`, and matched every Conv1, GN2 activation, and
Conv2/residual vector to the integer reference.  It verified three read bursts
at `0x400`, `0x440`, and `0x480`, three writes at `0x800`, `0x840`, and
`0x880`, all five delayed AW/W/B/AR/R channels, and no AXI behavioural-model
protocol error.

The external activation observation is part of the live path into Conv2, so
the test continues to handshake that Decoupled channel after recording its
three expected vectors.  This prevents the observer from introducing
backpressure that would block the internal computation; only the first three
vectors are retained for comparison.

`sbt 'runMain FLOOD_Accelerator.diffusion.GenerateDiffusionAccelAxi64TopVerilog'`
completed successfully after the focused regression.  No production RTL,
Vivado implementation, bitstream generation, or FPGA operation was run.
## Exclusions

This is a simulation-only transaction-length extension.  It does not prove
floating-point SD1.5 accuracy, arbitrary tensor shapes or production weights,
throughput/timing closure, AXKU15 DDR4 calibration, Vivado implementation,
bitstream generation, or FPGA programming.
