# AXKU15 board flow

This folder separates two bring-up stages deliberately:

1. `rtl/axku15_diffusion_bringup.v` + `constrs/axku15_bringup.xdc` creates a
   no-DDR smoke bitstream.  It proves the selected XCKU15P part, JTAG download,
   200 MHz system clock (`G12/G11`), reset and four LEDs before a large design
   is introduced.
2. `scripts/extract_ddr4_pins.py` emits the DDR4 package-pin XDC from the
   checked-in AXKU15 manual.  It captures the complete 80-bit memory interface
   without hand-copying pins.  A future Vivado DDR4 MIG must provide the same
   port names and own IOSTANDARD/termination settings.

## Build the smoke bitstream

From this directory, run:

```powershell
vivado -mode batch -source scripts/build_bringup.tcl
```

The bitstream is written below `build/bringup_nonproject/`.  Program it through
Vivado Hardware Manager.  LED2 stays on after configuration; LED1 and LED4
blink, and LED3 reflects release of `KEY1` reset.

## Generate and verify DDR4 pin constraints

```powershell
python scripts/extract_ddr4_pins.py --output constrs/axku15_ddr4_pins.xdc
python -m unittest discover -s tests -v
```

The script requires exactly 80 distinct DQ pins and emits all DQ, DM/DBI,
DQS, address, bank and command pins.  It intentionally does **not** generate a
MIG `.xci`: MIG electrical settings and board timing must be created and
validated with the installed Vivado version before synthesis.  The documented
DDR4 reference clock is `AR32/AT32`; it is emitted as `ddr4_ref_clk_p/n` and is separate from the bring-up logic clock at `G12/G11`.

## Verified implementation evidence

The bring-up flow was run with Vivado 2024.2 on this repository revision. It completed synthesis, implementation and bitstream generation for `xcku15p-ffve1517-2-i` with zero DRC errors. At a 200 MHz constraint, the post-route setup WNS was **4.220 ns** (TNS 0.000 ns); the generated bitstream was 36,343,241 bytes. These numbers apply only to the small clock/LED smoke top, not to the future DDR4/MIG accelerator implementation. See [DDR4 MIG compatibility](docs/ddr4_mig_compatibility.md) before using the 64-bit candidate constraints; an 80-bit AXKU15 MIG remains unclosed.
