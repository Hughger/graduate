# AXKU15 AXI64 DDR4 self-test build

## Inputs and ownership

The harness is deliberately outside the official demo directory.  It requires
three read-only inputs supplied at invocation time:

- `ddr4_core.xci` from the official AXKU15 demo;
- the matching DDR4 XDC from that same demo;
- generated `Axi64DdrSelfTest.v` from this repository.

The Tcl flow writes reports and optional implementation products only under
`fpga/AXKU15/diffusion/build/axi64_ddr4_selftest`.  It never changes the XCI,
generated vendor sources, or XDC input.

## Generate the self-test RTL

```powershell
Set-Location accelerator
$env:SBT_OPTS='-Dsbt.server.autostart=false'
sbt 'runMain FLOOD_Accelerator.diffusion.GenerateAxi64DdrSelfTestVerilog'
```

The default output is
`target/generated/axi64-ddr4-selftest/Axi64DdrSelfTest.v`.

## Elaboration-only check

```powershell
vivado -mode batch -source fpga/AXKU15/diffusion/scripts/build_axi64_ddr4_selftest.tcl -tclargs `
  -ddr4-xci <official-demo/ddr4_core.xci> `
  -ddr4-xdc <official-demo/ddr4_test.xdc> `
  -selftest-rtl target/generated/axi64-ddr4-selftest/Axi64DdrSelfTest.v
```

Without `-run-impl`, the Tcl flow stops after `synth_design -rtl`; this checks
the wrapper/interface composition but does not produce a bitstream.  Add
`-run-impl` only to request synthesis, placement, routing, reports, checkpoint,
and bitstream generation.

## Interpretation and LED status

| LED | Meaning |
| --- | --- |
| 0 | `c0_init_calib_complete` is high |
| 1 | self-test has started and is waiting for AXI completion |
| 2 | matching 512-bit readback passed |
| 3 | AXI response error or readback mismatch |

An elaboration or implementation result is only tool-flow evidence.  A board
must still be explicitly programmed and observed: LED0 alone indicates
calibration, while LED2 is the write/read transport result.  The existing
64-bit demo versus documented 80-bit/DRAM-part discrepancy remains an
unresolved physical validation condition.

## Verified elaboration evidence

On 2026-08-11, Vivado 2024.2 ran the default (non-`-run-impl`) flow against
the official demo's existing `ddr4_core.xci`, its XDC, and the generated
self-test RTL.  `synth_design -rtl` completed with **0 critical warnings and
0 errors**; no implementation or bitstream was requested.

The same log contains 90 ordinary warnings.  Two are decisive gates rather
than cleanup work: the 2022.2 `ddr4_core` is locked in Vivado 2024.2, and the
XDC has unmatched DQ64--79/DQS8--9 constraints while the core exports only
64 DQ/8 DQS.  The elaboration result validates wrapper composition only.  It
does not clear the tool-version/IP-lock or physical 64/80-bit mismatch, and it
does not establish DDR4 calibration or readback on a board.