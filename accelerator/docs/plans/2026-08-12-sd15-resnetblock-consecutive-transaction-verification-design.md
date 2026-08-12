# SD1.5 ResNetBlock Consecutive Transaction Verification Design

**Date:** 2026-08-12  
**Status:** Approved design; implementation has not started

## Goal

Prove that the AXI64-backed fixed-point ResNetBlock prototype can complete
two distinct transactions consecutively.  The second transaction must read,
compute, and write its own data without retaining tensor, result-buffer,
DMA-address, scheduler, or response state from the first transaction.

This is a simulation-only increment.  It does not change production RTL and
does not start Vivado implementation, bitstream generation, or FPGA work.

## DUT and boundary

The DUT remains exactly:

```scala
new DiffusionAccelTop(memoryBackend = DiffusionMemoryBackend.Axi64)
```

The test reuses the current AXI64 behavioural memory, its accepted AR/AW
burst-address history, and the existing fixed-point ResNetBlock controls.  It
adds no test-only Chisel hardware and changes no file under
`accelerator/src/main`.

## Directed transactions

Each transaction processes two 512-bit vectors.  Transaction A uses the
already validated opposite-lane-order inputs at `0x400` and `0x440`, then
writes to `0x800` and `0x840`.

Transaction B uses a different pair of symmetric variance-four vectors at `0x1000` and
`0x1040`: lane 0--15 are `-2` and lane 16--31 are `+2` in the first word; the
second word reverses that order.  Its GroupNorm statistics are
`sum = 0`, `sumSquare = 256`, and `count = 64`.  It uses a different residual
vector and time embedding than transaction A, and writes to `0x1800` and
`0x1840`.

For transaction B, the reference helper is extended only as needed to support
the selected symmetric non-unit variance and its matching fixed-point rsqrt
calculation.  It must not weaken the existing variance-one reference checks.

## Required sequence and checks

1. Start transaction A, issue one two-beat read, execute GN1, Conv1, GN2,
   activation, Conv2/residual, and one two-beat write; wait for exactly one
   top-level `done` pulse.
2. Before starting transaction B, require `busy == false`, phase `Idle`, and
   zero tensor-buffer occupancy.
3. Start transaction B using a second AXI-Lite start write.  Execute the same
   phases with B's addresses, vector count, parameters, and reference values.
4. Require exactly one additional `done` pulse, then compare both transaction
   B writeback words with B's integer reference.
5. Require accepted read burst history to be
   `[0x400, 0x440, 0x1000, 0x1040]` and accepted write burst history to be
   `[0x800, 0x840, 0x1800, 0x1840]`.  Transaction A writeback words must remain
   unchanged after B completes.

Each phase output is collected only on a Decoupled handshake and compared in
vector order.  Both transactions use the staggered AW/W/B/AR/R delay profile;
all five channels must be recorded as delayed.

## Failure rules

The test fails on an absent or extra `done` pulse; non-idle state between
transactions; stale output or address history; incorrect B statistics;
misordered/missing/duplicate result; AXI protocol error; timeout; or a lane
mismatch in either transaction's writeback.

## Acceptance evidence

Required evidence is a passing focused consecutive-transaction E2E test,
passing existing single- and two-vector ResNetBlock E2E tests plus focused
AXI64/compute regressions, and successful Chisel elaboration of the unchanged
AXI64-backend top.

## Exclusions

This proves two directed fixed-point transactions only.  It does not establish
floating-point SD1.5 accuracy, arbitrary tensor shapes, production weights,
throughput, AXKU15 timing closure, DDR4 calibration, bitstream generation, or
FPGA programming.
