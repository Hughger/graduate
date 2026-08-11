# Official AXKU15 DDR4 demo assessment

## Evidence inspected

The vendor demo is located in the workspace at
`01_demo_document/01_demo_document/demo/ddr_test/ddr_test`.  It includes a
Vivado 2022.2 project, `ddr4_core.xci`, generated DDR4 IP RTL, board
constraints, a `ddr4_top` memory-test design, and a historical
`ddr4_top.bit`.

Its historical implementation log records successful route and bitstream
generation on `xcku15p-ffve1517-2-i`: 0 critical warnings and 0 errors at
bitstream generation.  This is valuable evidence that the vendor flow is a
better starting point than a newly created generic MIG configuration.

## Interface facts

The XCI and generated stub agree on the following configuration:

| Item | Official demo |
| --- | --- |
| Vivado/IP version | Vivado 2022.2, `ddr4_v2_2_17` |
| DDR4 component setting | `MT40A512M16HA-075E` |
| Physical DQ / DQS | 64 DQ bits / 8 DQS pairs |
| External memory interface | 64-bit AXI4, 32-bit address, 4-bit ID, 8-bit burst length |
| Generated internal app width | 512 bits |
| User clock/reset/status | `c0_ddr4_ui_clk`, `c0_ddr4_ui_clk_sync_rst`, `c0_init_calib_complete` |

`ddr4_top.v` instantiates the core through its 64-bit AXI4 slave and uses a
traffic generator (`mem_test`) through `aq_axi_master`.

## Important limitation

The AXKU15 board material in this repository describes five x16 DDR4 devices
(80 DQ bits), while the official demo top and IP expose only
`c0_ddr4_dq[63:0]` / eight DQS pairs.  The demo constraint file also contains
references up to DQ79 and DQS9.  Therefore its historical bitstream proves
that the project can be implemented; it does **not** by itself prove that all
five fitted memory components calibrate and pass data traffic on this board.

There is also a component-string difference between the demo's `HA-075E` and
the board documentation's `LY-062E`.  It must be resolved with the vendor or
with a real board calibration/read-write test before treating this IP as a
production DDR4 controller.

## Accelerator integration path

`DiffusionAccelTop` uses 512-bit internal memory beats through its `MigAppPort`
seam.  The official controller exposes 64-bit AXI4 externally.  The safe
integration path is therefore:

1. Preserve the vendor `ddr4_core.xci` and physical constraints unchanged in a
   dedicated baseline project.
2. Replace only `mem_test`/`aq_axi_master` with a verified bridge that expands
   each 512-bit accelerator beat into eight 64-bit AXI beats and repacks eight
   AXI read beats into one accelerator response.
3. Gate accelerator reset and traffic on `c0_init_calib_complete`.
4. Program the baseline on the physical board and verify calibration plus
   read/write patterns before attaching the diffusion top.
5. Only then run synthesis and implementation for the combined design.

The bridge is feasible RTL work.  The physical 64/80-bit and memory-part
differences remain board-validation gates, not assumptions to hide in code.

## Bridge verification status

A standalone Chisel `MigAppToAxi64Bridge` now converts one accelerator 512-bit
request into an eight-beat 64-bit AXI4 burst and repacks eight AXI read beats.
Its focused bridge/transfer/arbiter simulation passed 10/10 tests on 2026-08-11,
and real `DiffusionAccelTop` Verilog generation still completes.  The bridge is
not yet connected to the vendor project, so this does not alter the 64/80-bit
or memory-part validation gate above.
## AXI64 selectable-top status

The accelerator now has a generated AXI64-top variant that selects the tested
512-to-64 bridge internally while retaining the existing MIG-top as its
default.  Focused default-MIG, AXI64-top, and bridge simulation passed 10/10
cases on 2026-08-11, and both generated-top commands completed.  It is ready
for a future wrapper-level connection to the official core's AXI slave, but no
vendor project has been changed and no calibration/data test has been run.