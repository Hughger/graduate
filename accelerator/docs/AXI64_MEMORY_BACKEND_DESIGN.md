# AXI64 memory-backend integration design

## Goal

Allow the existing diffusion top to use either its current 512-bit MIG
application-port backend or the new 64-bit AXI4 bridge.  The default generated
top must preserve the current MIG seam and behavior.  A second generated top
must expose AXI64 so it can be connected to the official AXKU15 DDR4 demo in a
later Verilog wrapper.

## Confirmed interface boundary

`DiffusionAccelTop` currently connects `MigAppRequestArbiter` to a single
`MigAppTransfer`, then exposes the transfer's raw `MigAppPort`.  In contrast,
`MigAppToAxi64Bridge` consumes the request/response/done side of that
connection.  Therefore the bridge must replace `MigAppTransfer` *inside* the
diffusion top; placing it after `io.mig` would mismatch protocols and duplicate
serialization.

The official demo supplies a 64-bit AXI4 slave with `AW`, `W`, `B`, `AR`, and
`R`, a UI clock/reset pair (`c0_ddr4_ui_clk`, `c0_ddr4_aresetn`), and
`c0_init_calib_complete`.

## Alternatives

1. Add a raw `MigAppPort` to AXI converter outside the top.  It would retain
   the current serializer, but duplicates the already tested request-level
   bridge and creates two incompatible conversion boundaries.  Not selected.
2. Fork the complete diffusion top for the AXI path.  This gives a direct
   interface but would duplicate a large evolving data path.  Not selected.
3. Select the backend at `DiffusionAccelTop` construction.  Both backend
   choices share one `MigAppRequestArbiter`; the original is the default and
   the alternate instantiates `MigAppToAxi64Bridge`.  This is selected.

## Selected architecture

`DiffusionAccelTop` receives a constructor parameter:

```scala
class DiffusionAccelTop(
    resultDepth: Int = 128,
    memoryBackend: DiffusionMemoryBackend = DiffusionMemoryBackend.MigApp
) extends Module
```

`DiffusionMemoryBackend` has exactly `MigApp` and `Axi64` values.  The IO keeps
both named seams (`mig` and `axi64`) so either generated RTL variant has stable
port names.  Only the selected backend is live:

- `MigApp`: preserve the current `MigAppTransfer` connections and tie AXI64
  master outputs inactive; AXI64 return channels are ignored.
- `Axi64`: connect the arbiter's request/response/done interface directly to
  `MigAppToAxi64Bridge`; tie MIG command outputs inactive and ignore its return
  inputs.

The performance monitor's memory-stall term is selected with the backend:
MIG uses app ready signals; AXI64 uses any active AXI channel with its ready
low, including B/R response waiting.  The existing one-cycle-per-cycle stall
definition remains unchanged.

`GenerateDiffusionAccelTopVerilog` continues to emit the default MIG variant.
`GenerateDiffusionAccelAxi64TopVerilog` emits the alternate variant to
`target/generated/diffusion-accel-axi64-top`.

## Board-wrapper boundary

The follow-on SystemVerilog wrapper will instantiate the vendor `ddr4_core`
unchanged and an AXI64 generated top.  It uses the MIG UI clock as the
accelerator clock and asserts accelerator reset until both `c0_ddr4_aresetn`
and `c0_init_calib_complete` are high.  The wrapper maps only the complete
official AXI4 channel fields, adding fixed AXI fields (`burst=INCR`, cache/prot/
qos/user zero) that are not modelled by the Chisel bridge.

This design does not copy vendor files, regenerate an XCI, connect physical
DDR pins, or claim DDR4 calibration.  Those activities occur only after the
alternate top passes its simulation and generation tests.

## Acceptance tests

1. Existing `DiffusionAccelTop` tests and default Verilog generation preserve
   MIG behavior.
2. An AXI64-backend top test submits a request through the existing external
   memory port and observes the eight-beat bridge transaction.
3. AXI64-backend tests prove that MIG outputs remain inactive and that an AXI
   response drives the existing memory response/done path.
4. The AXI64 generated RTL contains the `axi64_aw`, `axi64_w`, `axi64_b`,
   `axi64_ar`, and `axi64_r` signals.
5. No test, source file, XCI, or constraint is written under the user-provided
   official demo directory.

## Verification record

On 2026-08-11, `DiffusionAccelTopAxi64Spec` verified that the default top still
uses MIG with AXI64 idle and that the AXI64 variant keeps MIG commands inactive
while reassembling an eight-beat read into the existing memory response.  The
selected default-top, AXI64-top, and bridge test scope passed 10/10 cases.

Both `GenerateDiffusionAccelTopVerilog` and
`GenerateDiffusionAccelAxi64TopVerilog` completed successfully.  The latter
emits all five AXI64 channel groups (`axi64_aw`, `axi64_w`, `axi64_b`,
`axi64_ar`, and `axi64_r`).  No vendor source, XCI, constraint, physical pin,
or board-calibration claim is included in this result.