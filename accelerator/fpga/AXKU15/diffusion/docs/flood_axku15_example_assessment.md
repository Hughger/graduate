# FLOOD AXKU15 example: reuse assessment

The repository contains a historical FLOOD board example at
`integrations/chip-test-vivado`. It targets the same FPGA part used by this
project: `xcku15p-ffve1517-2-i`.

## What can be reused

| Item | Evidence in the example | Appropriate use in the SD accelerator |
| --- | --- | --- |
| Board clock | `sys_clk_p/n` at `AR32/AT32`, `DIFF_SSTL12`, 200 MHz | Reference for clock/reset bring-up; separate from the new no-DDR smoke clock at `G12/G11`. |
| Clock plan | 200 MHz input, derived 16 MHz and 50 MHz clocks | A known-good low-frequency peripheral/debug-clock pattern. The compute clock should be defined independently. |
| Reset, LEDs and UART | Top-level ports and constraints | Reuse as a board-observability template for the future SD top. |
| FMC interface | 64-bit bidirectional data bus, control/status pins and complete XDC | Reference only for the original external chip-test board; it is not a DDR4 or diffusion data interface. |
| Memory-initialized controller | `weight_data.mem` / `feature_data.mem` exercised from RTL | Example of deterministic FPGA-side test traffic, not an SD tensor DMA implementation. |

## What must not be copied directly

The checked-in `clk_wiz_0.xci` is locked: it was generated in a 2022.2 context
for an Artix-7 part, while this project targets UltraScale+ KU15P with Vivado
2024.2. It is therefore regenerated locally and never treated as a portable
source artifact. The example also has no DDR4 MIG configuration and does not
solve this board's 80-bit DDR4 interface.

The original `sdc_chip_test.xdc` contains project-file and ILA debug commands.
Those are valid only inside its original GUI project and should not be imported
into a non-project batch flow. The compatibility check intentionally uses the
minimal `flood_example_clock_smoke.xdc` instead.

## Reproducible compatibility check

From `accelerator/fpga/AXKU15/diffusion`, run:

```powershell
& 'C:\Xilinx\Vivado\2024.2\bin\vivado.bat' -mode batch -source scripts/verify_flood_axku15_clock.tcl
```

The script regenerates a KU15P Clocking Wizard (200 MHz in; 16 MHz and 50 MHz
out), then explicitly reads its generated Verilog wrappers together with
`chip_test_cursor_1.v`. Success is indicated by
`FLOOD_AXKU15_CLOCK_REUSE_SYNTHESIS_OK` and produces only ignored files below
`build/flood_clock_reuse_check/`.

The check is deliberately **synthesis-only**. It proves the reusable top and
clock-source compatibility, but it is not timing closure, a legal FMC board
implementation, or a bitstream. The diffusion design should continue to use
the dedicated bring-up top and the separately documented DDR4/MIG work.
