# SD1.5 ResNetBlock Nonzero-Mean Variance-Four AXI64 Verification Design

**Date:** 2026-08-12
**Status:** Implemented and simulation-validated

## Goal

Add a directed two-vector fixed-point ResNetBlock E2E simulation that covers
an asymmetric, nonzero-mean input distribution with integer variance four.
The proof exercises GroupNorm mean subtraction, integer variance, Q2.30
rsqrt, affine quantization, SiLU, Conv2/residual fusion, and AXI64 DMA under
staggered five-channel backpressure.

## Workload and fixed-point contract

The two 32-lane INT16 words contain 16 lanes of `1`, 16 lanes of `2`, and 32
lanes of `5`: word 0 is 16 `1` lanes followed by 16 `2` lanes; word 1 is 32
`5` lanes.  The aggregate fixed-point statistics are:

```text
sum       = 16*1 + 16*2 + 32*5 = 208
sumSquare = 16*1 + 16*4 + 32*25 = 880
count     = 64
mean      = trunc(208 / 64) = 3
variance  = trunc(880 / 64) - 3*3 = 4
rsqrtQ30  = 480191942
```

Each reference lane follows the RTL sequence:

```text
centered   = input - 3
normalized = roundAwayFromZero(centered * 480191942, 30)
affine     = roundAwayFromZero(normalized * 256, 8)
activation = SiLU_PWL(saturateInt16(affine))
final      = saturateInt16(activation + temb + residual)
```

The workload uses diagonal unit Conv1/Conv2 weights, identity GN2 affine
parameters, `temb = +5`, `residual = -3`, DMA reads `0x400`/`0x440`, and DMA
writes `0x800`/`0x840`.

## Scope and acceptance checks

The DUT remains `new DiffusionAccelTop(memoryBackend =
DiffusionMemoryBackend.Axi64)`.  Production RTL remains unchanged.  Test-only
reference code gains an explicit mean-aware final-lane helper, and the E2E
suite gains one workload.

The test checks GN1/GN2 statistics `(208, 880, 64)`, Conv1 preservation,
two mean-aware activations, two final vectors, ordered AXI64 read/write
histories, all delayed `AW/W/B/AR/R` channels, one `done` pulse, and no AXI
behavioural-model protocol error.  Existing vector-depth and consecutive
transaction cases are rerun unchanged.

## Simulation evidence

- The reference-model RED failed as intended: the new contract initially could not
  resolve `finalLanesWithMeanAndRsqrt`; the minimal helper then made all 5/5
  support tests pass.
- The AXI64 ResNetBlock E2E suite passed 6/6 cases (0 failures, 0 errors),
  including `preserve nonzero-mean variance-four vectors through AXI64
  ResNetBlock`.
- The directed workload observed GN1 and GN2 statistics `(208, 880, 64)`,
  integer mean `3`, variance `4`, and Q2.30 reciprocal square root
  `480191942`.  It verified Conv1 preservation, mean-aware GN2 activation,
  Conv2 plus `temb=+5` and `residual=-3`, writeback at `0x800`/`0x840`, read
  history `0x400`/`0x440`, all delayed AXI64 channels, `done`, and no
  behavioural-memory protocol error.
- The focused cross-module regression passed 30/30 tests across 11 suites
  (0 failures, 0 errors). `GenerateDiffusionAccelAxi64TopVerilog` also
  completed successfully in 19 seconds.
## Exclusions

This proves one directed integer-mean, variance-four workload.  It does not
establish floating-point SD1.5 accuracy, arbitrary distributions or shapes,
production weights, performance/timing closure, Vivado implementation,
bitstream generation, or FPGA programming.
