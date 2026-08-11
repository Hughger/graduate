# AXKU15 AXI64 DDR4 self-test build

## Inputs and ownership

The harness is deliberately outside the official demo directory. Normal
validation requires the project-owned Vivado 2024.2 IP copy:

- `ip/ddr4_core_2024_2/ddr4_core.xci`, its sibling `ddr4_core.dcp`,
  `par/ddr4_core.xdc`, and `manifest.json`;
- the board DDR4 XDC supplied by the official demo as a read-only input;
- generated `Axi64DdrSelfTest.v` from this repository.

The official demo XCI is only an input to the copy-and-upgrade command below;
it is never modified. The self-test Tcl flow rejects an XCI without the
project-owned DCP, IP XDC, and manifest. Generated IP products remain ignored
by Git; only the upgraded XCI and manifest are versioned.
## Generate the self-test RTL

```powershell
Set-Location accelerator
$env:SBT_OPTS='-Dsbt.server.autostart=false'
sbt 'runMain FLOOD_Accelerator.diffusion.GenerateAxi64DdrSelfTestVerilog'
```

The default output is
`target/generated/axi64-ddr4-selftest/Axi64DdrSelfTest.v`.

## Create or refresh the owned IP copy

```powershell
$official = 'D:\work-yanjiusheng\graduate\01_demo_document\01_demo_document\demo\ddr_test\ddr_test\ddr_test.srcs\sources_1\ip\ddr4_core\ddr4_core.xci'
& 'C:\Xilinx\Vivado\2024.2\bin\vivado.bat' -mode batch `
  -source fpga/AXKU15/diffusion/scripts/upgrade_ddr4_core_2024_2.tcl `
  -tclargs -source-xci $official `
  -output-dir fpga/AXKU15/diffusion/ip/ddr4_core_2024_2
Get-Content fpga/AXKU15/diffusion/ip/ddr4_core_2024_2/manifest.json
```

The command copies the XCI, upgrades the copy, generates its OOC DCP with
`synth_ip`, and writes all generated products below the owned IP directory.

## Elaboration-only check

```powershell
vivado -mode batch -source fpga/AXKU15/diffusion/scripts/build_axi64_ddr4_selftest.tcl -tclargs `
  -ddr4-xci fpga/AXKU15/diffusion/ip/ddr4_core_2024_2/ddr4_core.xci `
  -ddr4-xdc <official-demo/ddr4_test.xdc> `
  -selftest-rtl target/generated/axi64-ddr4-selftest/Axi64DdrSelfTest.v
```

Without `-run-impl`, the Tcl flow attaches the owned OOC DCP at
`u_ddr4_core/inst`, reads the generated IP XDC, then stops after
`synth_design -rtl`. This checks the wrapper/interface composition but does not
produce a bitstream. Add `-run-impl` only to request synthesis, placement,
routing, reports, checkpoint, and bitstream generation.
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

On 2026-08-11, Vivado 2024.2 upgraded the project-owned copy from DDR4 IP
revision 17 to revision 24 and generated its OOC DCP with `synth_ip`.
The non-`-run-impl` self-test flow attached that DCP explicitly and completed
`synth_design -rtl` with **0 critical warnings and 0 errors**; no implementation
or bitstream was requested.

The log contains 101 ordinary warnings. The decisive board gate remains: the
XDC has unmatched DQ64--79/DQS8--9 constraints while the core exports only
64 DQ/8 DQS. This result validates tool-version-compatible IP, DCP attachment,
and wrapper composition only. It does not establish DDR4 calibration, timing
closure, or readback on a board.