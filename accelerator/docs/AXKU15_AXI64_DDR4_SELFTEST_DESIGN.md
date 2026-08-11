# AXKU15 AXI64 DDR4 self-test harness design

## Objective

Create a board-oriented harness that tests the newly integrated 512-bit to
64-bit AXI bridge through the official DDR4 core without modifying the vendor
demo.  The harness runs autonomously after DDR4 calibration: it writes one
known 512-bit word, reads the same address back, and exposes calibration,
active, pass, and fail status for LEDs or external observation.

This is a DDR4 transport-validation increment, not a Stable Diffusion inference
demo.  It deliberately avoids pretending that the official demo has a host
control plane for the full accelerator.

## Architecture

1. `Axi64DdrSelfTest` is a small Chisel module.  It instantiates the existing
   `MigAppToAxi64Bridge`, waits for `calibrated`, issues one 512-bit write,
   waits for an OKAY B response, issues the matching 512-bit read, and compares
   all 512 bits.
2. It has no external request input.  The fixed address is 64-byte aligned and
   the fixed data contains eight distinct 64-bit words, so both AXI burst order
   and bridge read reassembly are exercised.
3. `GenerateAxi64DdrSelfTestVerilog` emits that module independently of
   `DiffusionAccelTop`.
4. `axku15_axi64_ddr4_selftest.v` is a thin SystemVerilog wrapper.  It
   instantiates the unmodified vendor `ddr4_core` and the generated self-test,
   maps the complete AXI channels, and maps statuses to the existing four LED
   pins: `led[0]=calibrated`, `led[1]=active`, `led[2]=passed`,
   `led[3]=failed`.
5. A parameterized non-project Vivado Tcl flow reads the user-selected vendor
   XCI and its matching XDC by path; it writes outputs only under this
   repository's `build/` directory.

## Reset and calibration rules

- The harness clock is `c0_ddr4_ui_clk`; reset is asserted by
  `c0_ddr4_ui_clk_sync_rst` or deasserted `c0_ddr4_aresetn`.
- `c0_init_calib_complete` is an input to the harness state machine.  No AXI
  request is issued until it is high.
- A non-OKAY B/R response or a 512-bit read mismatch sets sticky `failed`.
- `passed` and `failed` are mutually exclusive and remain asserted until reset.
- The vendor core's `c0_alert_n` is exposed by the wrapper but is not treated as
  a substitute for an AXI data-integrity result.

## Source ownership and constraints

The wrapper never edits, copies into place, or regenerates the official demo's
XCI/RTL/XDC.  The build command takes absolute or relative paths to those
artifacts.  The existing 64/80-bit and DRAM-part mismatch remains a physical
validation risk; a successful tool build alone is not a calibration or memory
test result.

## Acceptance tests

1. Unit simulation demonstrates no request before `calibrated`, eight ordered
   write beats, eight ordered read beats, and sticky pass after a matching read.
2. Separate simulations demonstrate sticky fail for a read mismatch and an
   AXI error response.
3. The self-test Verilog generator exits successfully and its output contains
   all AXI64 channel groups plus status outputs.
4. The wrapper is linted/elaborated only when the user supplies a matching
   vendor XCI/XDC.  A successful bitstream is documented as implementation
   evidence, while physical programming/calibration is a separately authorized
   lab action.
