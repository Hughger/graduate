# 512-bit MIG application to 64-bit AXI4 bridge design

## Purpose and scope

This document defines the first integration seam between the diffusion
accelerator's 512-bit `MigAppPort` and the official AXKU15 DDR4 demo's 64-bit
AXI4 slave.  It is a simulation-first bridge: it neither changes the vendor
`ddr4_core.xci` nor asserts that the board's physical DDR4 interface has
already passed calibration.

The bridge accepts one `MigAppRequest` at a time, which matches the existing
`MigAppTransfer` serialization contract.  It expands a 512-bit request into
eight 64-bit AXI beats and returns one 512-bit response for a read.

## Alternatives considered

1. **Directly modify the vendor demo's `mem_test` traffic generator.** This
   would make early hardware experiments quick, but mixes board-specific
   vendor sources with accelerator protocol logic and is difficult to unit
   test.  It is not selected.
2. **Use the vendor IP's 512-bit app interface.** The generated demo exposes a
   64-bit AXI4 slave at its top level; reaching a private/generated app port
   would bind the accelerator to IP internals and prevent use of the known
   wrapper.  It is not selected.
3. **Create a standalone, Chisel-tested 512-to-64 AXI4 master bridge.** This
   isolates protocol conversion, allows deterministic simulation with AXI
   handshakes, and leaves the vendor project intact.  This is the selected
   approach.

## Interface and transfer rules

- The bridge input is `Decoupled[MigAppRequest]`; it is ready only while no
  request is active.
- A write accepts exactly one 512-bit request and issues one AXI write address
  plus eight 64-bit write-data beats.  Byte strobes are the corresponding
  eight slices of `writeMask`; an asserted MIG mask bit disables the matching
  AXI byte strobe.
- A read issues one AXI read address for eight 64-bit beats and collects them
  in increasing beat order: AXI beat 0 becomes response bits `[63:0]`, and
  beat 7 becomes `[511:448]`.
- The accelerator's current 29-bit app address is treated as a byte address;
  the eight AXI beats use `address + 8 * beatIndex`.  The bridge rejects no
  address in the first version, but test vectors will use 64-byte-aligned
  inputs.
- AXI `AW`, `W`, `B`, `AR`, and `R` each obey Decoupled semantics.  Address,
  data, and response state must remain stable while the corresponding ready
  signal is low.
- Exactly one request is outstanding.  This preserves the ordering and
  completion behavior expected by `MigAppRequestArbiter` and avoids assigning
  AXI IDs or reordering rules in the initial milestone.

## Error and reset handling

- The first bridge milestone treats non-OKAY AXI `BRESP`/`RRESP` as a sticky
  error output while still draining the response channel.  It must not report
  a successful `done` for a failed write, nor a valid read response for a
  failed read.
- Reset drops an unfinished transaction and returns the request port to idle.
- Board traffic must remain externally gated by the vendor
  `c0_init_calib_complete` signal; that signal is outside this unit and is
  connected in the later AXKU15 wrapper milestone.

## Tests and acceptance criteria

The implementation is test-first and must demonstrate each of the following:

1. A 512-bit write produces one aligned AXI write address and eight ordered
   64-bit data beats with correctly inverted byte-enable bits.
2. Independent `AWREADY` and `WREADY` backpressure does not duplicate or drop
   an address or data beat.
3. Eight ordered AXI read beats are reassembled into the original 512-bit
   word and presented through a retained response handshake.
4. A response error prevents normal completion and raises the sticky error.
5. The focused Chisel test suite and Verilog generation both pass before the
   bridge is connected to the vendor project.

## Deferred work

- Copying or regenerating the vendor XCI/constraints.
- A board wrapper that connects `c0_init_calib_complete`, clocks, resets, and
  AXI physical pins.
- On-board calibration and read/write validation, which are required before
  treating the 64-bit demo configuration as usable hardware.
- Multiple outstanding transactions and bandwidth optimization.

## Verification record

The standalone bridge was verified in simulation on 2026-08-11 with six
`MigAppToAxi64BridgeSpec` cases: write split/masking, independent write-channel
backpressure, AXI write error, eight-beat read reassembly with a retained
response, AXI read error, and read-error draining through RLAST.  The combined
bridge, `MigAppTransfer`, and `MigAppRequestArbiter` scope passed 10/10 tests.  The real
`GenerateDiffusionAccelTopVerilog` generator also completed successfully.

This evidence covers the Chisel bridge only.  It does not modify the vendor
XCI, establish a board clock/reset wrapper, or prove DDR4 calibration or data
integrity on AXKU15 hardware.