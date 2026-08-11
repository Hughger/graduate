# AXKU15 AXI64 DDR4 Transparent Accelerator Top Design

**Date:** 2026-08-11  
**Status:** Approved design; implementation deferred pending accelerator verification

## Goal

Define a project-owned AXKU15 top-level integration that will connect the
`DiffusionAccelTop` AXI64 memory backend to the already validated, project-owned
copy of the official DDR4 controller IP.  This milestone proves that the
accelerator's 64-bit AXI4 memory boundary can be elaborated with the board DDR4
controller without modifying the official demo or its source IP.  The user has
chosen to defer this integration until the accelerator design and verification
work is complete.

## Deferred implementation scope

The integration adds:

- a Chisel generation entry point that instantiates
  `DiffusionAccelTop(memoryBackend = DiffusionMemoryBackend.Axi64)`;
- a transparent Verilog board wrapper that instantiates that generated module
  and `ddr4_core`;
- a Vivado RTL-elaboration Tcl script that attaches the project-owned DDR4 DCP
  and generated DDR4 constraints explicitly; and
- build and design documentation.

The wrapper connects the accelerator AXI4 master channels directly to
`ddr4_core`'s 64-bit AXI4 slave interface:

| Accelerator channel | DDR4 IP channel |
| --- | --- |
| AW | `c0_ddr4_s_axi_aw*` |
| W | `c0_ddr4_s_axi_w*` |
| B | `c0_ddr4_s_axi_b*` |
| AR | `c0_ddr4_s_axi_ar*` |
| R | `c0_ddr4_s_axi_r*` |

All accelerator controls and data-plane interfaces that do not belong to DDR4
remain wrapper top-level ports.  They are deliberately neither tied off nor
replaced by an autonomous controller.

## Clock and reset

`c0_ddr4_ui_clk` clocks the generated accelerator.  The accelerator reset is
asserted while the DDR4 UI reset is asserted or its active-low UI reset output
is inactive.  `c0_init_calib_complete` is exported as an observation signal;
the integration does not claim memory is usable before calibration completes.

The board-facing DDR4 clock, reset, pin signals, and board XDC remain those of
the official AXKU15 DDR4 demo.  The integration uses the repository-owned
upgraded controller copy and its matching DCP/XDC artifacts.

## Deferred validation

The implementation must:

1. pass the focused Scala/Chisel tests for the AXI64 backend;
2. generate the AXI64-backend accelerator Verilog;
3. complete Vivado `synth_design -rtl` with the project-owned controller DCP
   attached explicitly; and
4. leave the official demo and official source IP unmodified.

The existing autonomous DDR4 self-test remains the physical-link baseline.  It
is not replaced by this structural integration test.

## Explicit exclusions

This milestone does not add UART, PCIe, a soft processor, or another host
control plane.  It does not execute a complete SD1.5 workload, run placement or
routing, generate a bitstream, or program the FPGA.

The official demo's 64-bit DDR4 configuration is accepted as the current
project baseline.  The separately observed 64/80-bit board-document mismatch
is deferred to hardware-validation and thesis-limitations work; acceptance of
this baseline is not evidence that 80-bit hardware operation has been proven.

## Prerequisite and follow-on work

Before implementation of this wrapper, the project will complete functional
design and simulation-based verification of one SD1.5 ResNetBlock, including
its scheduler, convolution, GroupNorm, residual path, DMA, and AXI64
behavioural-memory interactions.  The resulting verification evidence becomes
the prerequisite for restoring this board-integration milestone.

Host control, SD1.5 workload submission, and implementation/timing/bitstream
work are separate follow-on milestones.  Keeping them separate preserves this
milestone as a narrow, reproducible accelerator-to-DDR4 integration boundary.
