# SD1.5 ResNetBlock Three-Vector AXI64 Verification Design

**Date:** 2026-08-12
**Status:** Approved for implementation

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

## Exclusions

This is a simulation-only transaction-length extension.  It does not prove
floating-point SD1.5 accuracy, arbitrary tensor shapes or production weights,
throughput/timing closure, AXKU15 DDR4 calibration, Vivado implementation,
bitstream generation, or FPGA programming.
