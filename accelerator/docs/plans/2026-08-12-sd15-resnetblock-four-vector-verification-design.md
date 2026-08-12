# SD1.5 ResNetBlock Four-Vector AXI64 Verification Design

**Date:** 2026-08-12
**Status:** Approved for implementation

## Goal

Extend the fixed-point AXI64 ResNetBlock simulation boundary to a directed
four-vector transaction.  The proof must preserve all four 512-bit vectors in
order across tensor DMA, Conv1, GN2 activation, Conv2/residual fusion, the
internal result buffer, and AXI64 writeback under independent five-channel
backpressure.

## Scope and workload

The DUT remains `new DiffusionAccelTop(memoryBackend =
DiffusionMemoryBackend.Axi64)`.  One test is added to the existing E2E
specification; there is no production RTL, interface, AXKU15 demo, Vivado, or
FPGA change.

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

## Exclusions

This is a simulation-only transaction-depth increment.  It does not establish
floating-point SD1.5 accuracy, arbitrary shapes, production weights,
throughput/timing closure, AXKU15 DDR4 calibration, Vivado implementation,
bitstream generation, or FPGA programming.
