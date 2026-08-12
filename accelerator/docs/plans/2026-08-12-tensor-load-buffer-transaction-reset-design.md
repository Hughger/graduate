# Tensor Load Buffer Transaction Reset Design

**Date:** 2026-08-12  
**Status:** Implemented and simulation-validated

## Problem

`TensorLoadBuffer` resets its write address when a new DMA load begins, but
does not clear the underlying `TensorTileBuffer` occupancy counter.  Tensor
reads also do not decrement that counter.  Consequently, a completed
ResNetBlock transaction can leave a nonzero `tensorBufferOccupancy`, which
makes its transaction boundary ambiguous and eventually risks artificial
buffer-full backpressure across repeated runs.

## Goal

Give every accepted tensor-DMA transaction a fresh logical tile-buffer state.
When `TensorLoadBuffer.io.start` begins a new load, the tile buffer's write
address and occupancy must be reset before the first incoming lane is stored.
The first transaction's data need not be physically erased because the next
load overwrites the addressed range; only its logical visibility and capacity
must reset.

## Design

Add a synchronous `clear` input to `TensorTileBuffer`.  On `clear`, it resets
its write address and occupancy to zero; it must not issue a read or write
handshake in that cycle.  Connect `TensorLoadBuffer.io.start` directly to this
new `clear` input.

`TensorLoadBuffer` already resets `address` to zero on `start` and does not
accept DMA data until its following active cycle.  Thus the clear cycle cannot
drop an accepted input lane.  The existing buffer RAM contents remain intact
and become inaccessible until rewritten by the new transaction.

No external port on `DiffusionAccelTop` changes.  The visible effect is that
`tensorBufferOccupancy` becomes zero in the clear cycle induced by an accepted
new tensor-DMA transaction, before its first DMA beat is stored, then begins
counting only that transaction's lanes.

## Verification

1. Extend `TensorTileBufferSpec` with a failing test that writes data, asserts
   nonzero occupancy, pulses `clear`, then requires zero occupancy and no
   data handshake during clear.
2. Extend `TensorLoadBufferSpec` with a failing test that completes one load,
   starts a second load, and requires occupancy to return to zero before the
   second DMA beat is accepted.
3. Complete the consecutive AXI64 ResNetBlock E2E test.  It must require zero
   `tensorBufferOccupancy` between the two runs, verify transaction B's
   distinct statistics/output/writeback, preserve transaction A writeback,
   and observe all four read and write burst bases in order.
4. Run focused buffer, E2E, AXI64, compute, and rsqrt regressions, then
   elaborate the unchanged AXI64 top through Chisel.

## Recorded evidence

On 2026-08-12, the focused command below completed with 26 passing tests in
11 suites and no failures:

```powershell
sbt 'testOnly FLOOD_Accelerator.diffusion.TensorTileBufferSpec FLOOD_Accelerator.diffusion.TensorLoadBufferSpec FLOOD_Accelerator.diffusion.ResNetBlockE2ETestSupportSpec FLOOD_Accelerator.diffusion.DiffusionAccelTopResNetBlockE2ESpec FLOOD_Accelerator.diffusion.Axi64MemoryModelSpec FLOOD_Accelerator.diffusion.DiffusionAccelTopAxi64Spec FLOOD_Accelerator.diffusion.MigAppToAxi64BridgeSpec FLOOD_Accelerator.diffusion.ConvToGroupNormStatsPathSpec FLOOD_Accelerator.diffusion.Conv2ResidualPathSpec FLOOD_Accelerator.diffusion.GroupNormActivationPathSpec FLOOD_Accelerator.diffusion.RsqrtUnitReferenceSpec'
```

The direct tile-buffer test confirms that `clear` accepts neither a read nor a
write, clears logical valid/occupancy/high-water/pending state, and lets the
same address be written again as the first lane of a new transaction.  The
load-buffer test confirms that the `start`/clear cycle holds DMA input
`ready` low, exposes zero occupancy, and then accepts the second load; its
32 lanes become the new logical contents.

The consecutive top-level test checks the same boundary after the second
transaction's tensor-read command is accepted and before its first payload is
accepted.  At that point `tensorBufferOccupancy` is zero.  It does not claim
that occupancy is zero during the idle interval before the new command.

`sbt 'runMain FLOOD_Accelerator.diffusion.GenerateDiffusionAccelAxi64TopVerilog'`
also completed successfully.  The elaboration generated no tracked source
change.
## Constraints and exclusions

- The change is restricted to `TensorTileBuffer`, its direct
  `TensorLoadBuffer` connection, and tests/evidence.
- It must not alter AXI64 protocol, fixed-point arithmetic, compute phase
  ordering, vendor AXKU15 demo/IP, Vivado flow, bitstream generation, or FPGA
  programming.
- This establishes a resettable logical tensor-buffer boundary, not RAM data
  sanitization, floating-point SD1.5 equivalence, arbitrary-shape support, or
  hardware performance/timing closure.
