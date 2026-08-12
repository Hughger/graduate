# SD1.5 ResNetBlock Two-Vector AXI64 DMA Verification Design

**Date:** 2026-08-12  
**Status:** Implemented and simulation-validated

## Goal

Extend the existing single-vector fixed-point ResNetBlock proof with one
directed two-vector transaction.  The test proves that the real AXI64-backed
`DiffusionAccelTop` preserves 512-bit vector order across a two-beat tensor
read, two-vector compute pipeline, and two-beat tensor writeback.

This is a simulation-only verification increment.  It neither changes
production RTL nor starts Vivado implementation, bitstream generation, or
FPGA programming.

## DUT and test boundary

The DUT remains exactly:

```scala
new DiffusionAccelTop(memoryBackend = DiffusionMemoryBackend.Axi64)
```

The test reuses the existing test-side `Axi64MemoryModel`, deterministic
independent AXI64 backpressure profile, and integer fixed-point reference.
It adds no test-only Chisel hardware.  The behavioural slave remains the
sole driver of AW, W, B, AR, and R responses.

## Directed data layout

One tensor vector is one 512-bit word containing 32 little-endian INT16
lanes.  The read command starts at `0x400` and uses `beats = 2`:

| Beat | Address | INT16 lanes 0--15 | INT16 lanes 16--31 |
| --- | --- | --- | --- |
| 0 | `0x400` | `-1` | `+1` |
| 1 | `0x440` | `+1` | `-1` |

The two vectors are intentionally different in lane order while having equal
per-vector and aggregate statistics.  Thus an address or vector-order error
cannot be hidden by the expected final memory words.

The existing deterministic parameterization is retained: diagonal Conv1 and
Conv2 W8 weights are one, shifts are zero, GN2 gamma is 256, beta is zero,
time embedding is `+3`, residual is `-2`, and residual addition is enabled.

## Transaction and result checks

The test starts the existing scheduler and drives this sequence:

1. Submit one tensor-read command at `0x400` for two 512-bit beats.
2. Wait for DMA completion, then issue GN1 statistics and Conv1 commands with
   `vectors = 2`.
3. Require GN1 aggregate statistics of `sum = 0`, `sumSquare = 64`, and
   `count = 64`; accept and compare both Conv1 output vectors in input order.
4. Issue GN2 statistics, activation, and Conv2 commands with `vectors = 2`.
   Require the same aggregate GN2 statistics, then compare both activation
   and fused Conv2/residual output vectors in order against the integer
   reference.
5. Submit one tensor-write command at `0x800` for two beats and require the
   behavioural memory words at `0x800` and `0x840` to match the corresponding
   expected vectors exactly.

The model must observe two ordered AXI64 read bursts at `0x400` and `0x440`,
and two ordered write bursts at `0x800` and `0x840`.  Each bridge burst is
still eight 64-bit AXI beats (`len = 7`, `size = 3`); the test checks existing
bridge protocol assertions, byte strobes, response codes, and no duplicate or
missing beat.

## Timing and failure rules

The directed two-vector test uses the existing staggered delay profile:
independent AW, W, B, AR, and R delays.  It must record that each delayed
channel was exercised.  Every polling loop has a named finite limit.

The test fails for phase-order errors; read or write address/order errors;
invalid AXI metadata or response; early scheduler completion; missing,
duplicate, or reordered compute outputs; timeout; or any final 16-bit lane
mismatch.

## Acceptance evidence

Required evidence is:

- the new focused two-vector end-to-end test passes under staggered AXI64
  backpressure;
- the existing single-vector ResNetBlock E2E test and focused AXI64/compute
  regression suites still pass; and
- generated AXI64-backend accelerator Verilog still elaborates without a
  production RTL change.

## Recorded evidence

Recorded on 2026-08-12:

- `sbt 'testOnly FLOOD_Accelerator.diffusion.DiffusionAccelTopResNetBlockE2ESpec FLOOD_Accelerator.diffusion.Axi64MemoryModelSpec FLOOD_Accelerator.diffusion.DiffusionAccelTopAxi64Spec FLOOD_Accelerator.diffusion.MigAppToAxi64BridgeSpec FLOOD_Accelerator.diffusion.ConvToGroupNormStatsPathSpec FLOOD_Accelerator.diffusion.Conv2ResidualPathSpec FLOOD_Accelerator.diffusion.GroupNormActivationPathSpec'` passed 16 tests in 7 suites with zero failures.
- The two-vector E2E transaction issued one two-beat read at `0x400`, observed AXI64 read burst bases `0x400`, `0x440`, then issued one two-beat write at `0x800` and observed write burst bases `0x800`, `0x840`. Both final 512-bit words matched the integer reference exactly. The test also checked two ordered Conv1, activation, and Conv2/residual outputs, GN1/GN2 aggregate statistics `(0, 64, 64)`, and exercised staggered AW, W, B, AR, and R backpressure.
- `sbt 'runMain FLOOD_Accelerator.diffusion.GenerateDiffusionAccelAxi64TopVerilog'` completed successfully. It elaborated the unchanged production AXI64-backend top and introduced no new version-controlled generated artifact.
## Exclusions

This verifies exactly one two-vector fixed-point workload.  It does not prove
floating-point SD1.5 equivalence, arbitrary tensor sizes or shapes, production
model weights, throughput at a target frequency, AXKU15 timing closure, DDR4
hardware calibration, bitstream generation, or FPGA programming.
