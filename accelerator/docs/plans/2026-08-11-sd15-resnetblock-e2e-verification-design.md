# SD1.5 ResNetBlock End-to-End Fixed-Point Verification Design

**Date:** 2026-08-11  
**Status:** Approved design; implementation has not started

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

The directed workload runs in two modes:

- a baseline with immediately available AXI64 responses; and
- a deterministic backpressure mode with bounded, independent AW, W, B, AR,
  and R delays.

Both modes must produce the same final output.  Every wait has a finite cycle
limit and reports the pending phase or channel on failure.  The test fails on
an invalid phase order, missing or duplicate beat, unexpected address, bad
write strobe, non-OKAY AXI response, early `done`, timeout, or any lane
mismatch.

## Evidence and exclusions

Required evidence is the focused end-to-end test, the existing focused AXI64
and arithmetic tests, and generated Verilog from the unchanged accelerator.
Board wrapper work, Vivado implementation, bitstream generation, and FPGA
programming remain out of scope until this verification evidence is complete.

The planned AXKU15 transparent top remains documented separately and is
explicitly deferred by
`2026-08-11-axi64-ddr4-transparent-top-design.md`.
