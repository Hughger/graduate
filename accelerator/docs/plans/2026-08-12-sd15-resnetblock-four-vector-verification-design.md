# SD1.5 ResNetBlock Four-Vector AXI64 Verification Design

**Date:** 2026-08-12
**Status:** Implemented and simulation-validated

## Goal

Extend the fixed-point AXI64 ResNetBlock simulation boundary to a directed
four-vector transaction.  The proof must preserve all four 512-bit vectors in
order across tensor DMA, Conv1, GN2 activation, Conv2/residual fusion, the
internal result buffer, and AXI64 writeback under independent five-channel
backpressure.

## Scope and workload

The DUT remains `new DiffusionAccelTop(memoryBackend =
DiffusionMemoryBackend.Axi64)`.  One test is added to the existing E2E
specification plus one top-level Decoupled handshake correction.  No public
interface, AXKU15 demo, Vivado, or FPGA change is made.

The transaction has four 32-lane INT16 words:

1. lanes 0--15 `-1`, lanes 16--31 `+1`;
2. lanes 0--15 `+1`, lanes 16--31 `-1`;
3. alternating `-1`, `+1` from lane 0 onward; and
4. alternating `+1`, `-1` from lane 0 onward.

Its combined statistics are `sum = 0`, `sumSquare = 128`, and `count = 128`.
Therefore the existing Q2.30 variance-one rsqrt `759250125`, diagonal unit
Conv1/Conv2 weights, identity GN2 affine parameters, time embedding `+3`, and
residual `-2` remain the bit-exact reference contract.

Tensor read DMA starts at `0x400`, requiring accepted AXI64 burst bases
`0x400`, `0x440`, `0x480`, and `0x4C0`.  Tensor write DMA starts at `0x800`,
requiring bases `0x800`, `0x840`, `0x880`, and `0x8C0`.

## Test behavior

The test drives one four-beat tensor read, GN1 statistics and Conv1 with
`vectors = 4`, GN2 statistics, GN2 activation/Conv2 with `vectors = 4`, then
one four-beat tensor write.  It captures exactly four vectors at Conv1,
activation, and Conv2/fusion, compares each to the integer reference, checks
four writeback words and exactly one `done` pulse, and requires no protocol
error.

It uses `Axi64DelayProfile.staggered`, requires delayed channels
`AW/W/B/AR/R`, and retains named finite waits.  Because activation observation
also forwards into Conv2, the observer keeps accepting valid activation beats
after its fourth recorded vector until the paired Conv2 collection completes;
extra accepted beats are not recorded.  Existing one-, two-, three-vector,
and consecutive-transaction E2E cases remain unchanged and are rerun.

## Recorded evidence

The initial four-vector E2E run exposed a top-level Decoupled contract defect:
`io.gn2Activation.valid` reflected only the GroupNorm/SiLU producer, while an
external activation handshake could occur before the same vector was accepted
by Conv2.  A four-vector workload therefore observed the third activation
word twice at the public port.  The minimal production fix gates the public
activation `valid` with `gn2ConvPath.io.activation.ready`; the output bits and
internal source ready condition remain unchanged.  Consequently, every public
`valid && ready` now corresponds to a real source-to-Conv2 transfer.

On 2026-08-12, the focused command below completed with 28 passing tests in
11 suites and zero failures after that fix:

```powershell
sbt 'testOnly FLOOD_Accelerator.diffusion.TensorTileBufferSpec FLOOD_Accelerator.diffusion.TensorLoadBufferSpec FLOOD_Accelerator.diffusion.ResNetBlockE2ETestSupportSpec FLOOD_Accelerator.diffusion.DiffusionAccelTopResNetBlockE2ESpec FLOOD_Accelerator.diffusion.Axi64MemoryModelSpec FLOOD_Accelerator.diffusion.DiffusionAccelTopAxi64Spec FLOOD_Accelerator.diffusion.MigAppToAxi64BridgeSpec FLOOD_Accelerator.diffusion.ConvToGroupNormStatsPathSpec FLOOD_Accelerator.diffusion.Conv2ResidualPathSpec FLOOD_Accelerator.diffusion.GroupNormActivationPathSpec FLOOD_Accelerator.diffusion.RsqrtUnitReferenceSpec'
```

The ResNetBlock E2E suite completed five tests: one, two, three, and four
vectors plus consecutive transactions.  The four-vector case checked
statistics `(0, 128, 128)`, all four Conv1/activation/Conv2-residual reference
vectors, reads `0x400/0x440/0x480/0x4C0`, writes
`0x800/0x840/0x880/0x8C0`, all delayed AW/W/B/AR/R channels, one completion,
and no AXI behavioural-model protocol error.

`sbt 'runMain FLOOD_Accelerator.diffusion.GenerateDiffusionAccelAxi64TopVerilog'`
completed successfully after the focused regression.  No Vivado implementation,
bitstream generation, or FPGA operation was run.
## Exclusions

This is a simulation-only transaction-depth increment.  It does not establish
floating-point SD1.5 accuracy, arbitrary shapes, production weights,
throughput/timing closure, AXKU15 DDR4 calibration, Vivado implementation,
bitstream generation, or FPGA programming.
