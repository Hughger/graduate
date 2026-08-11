# AXKU15 DDR4 IP 2024.2 upgrade-copy design

## Objective

Create a project-owned Vivado 2024.2-compatible copy of the official AXKU15
DDR4 IP so the AXI64 DDR4 self-test can be built reproducibly without editing
the vendor demo.

## Scope and ownership

- Copy, never modify, the official `ddr4_core.xci` and only the generated
  artifacts Vivado requires for the project copy.
- Keep the vendor demo directory read-only throughout the workflow.
- Place the owned IP and a manifest under `accelerator/fpga/AXKU15/diffusion`.
- Update the self-test Tcl flow to consume only the owned 2024.2 XCI.
- Do not run implementation, generate a bitstream, or program the board in
  this slice.

## Architecture

The existing `axku15_axi64_ddr4_selftest` wrapper remains the only RTL client.
It exposes the self-test's 64-bit AXI4 master directly to the copied DDR4 IP.
The copied IP preserves the official 64-bit DQ and eight-DQS interface plus
the existing 64-bit AXI4 interface. Vivado 2024.2 upgrades and generates the
project copy; its upgraded XCI becomes the build input. The official 2022.2
XCI and DCP are provenance artifacts only and are not read by the upgraded
build path.

## Validation and failure handling

The build performs RTL elaboration and a synthesis pass only. It fails if the
copied XCI remains locked, if the wrapper/IP interfaces do not elaborate, or
if synthesis reports errors or critical warnings. The build report records the
source and generated tool versions, part, IP configuration, and generated
file hashes so the copy is auditable.

The known physical-interface discrepancy is deliberately not hidden: the
official core has `c0_ddr4_dq[63:0]` and eight DQS pairs, while the currently
available board constraint references 80 DQ bits and ten DQS pairs. Therefore
implementation and programming remain prohibited until the AXKU15 schematic
and DDR4 topology are reconciled.

## Acceptance criteria

1. The official demo directory is unchanged.
2. Vivado 2024.2 reports the project-owned IP as unlocked after upgrade.
3. The AXI64 DDR4 self-test elaborates and synthesizes against the owned IP
   without errors or critical warnings.
4. A checked-in manifest makes the source, version, configuration, and hashes
   of the copied IP explicit.
5. No bitstream is written and no board is programmed.
## Execution update

The project-owned copy was upgraded by Vivado 2024.2 from DDR4 IP revision 17
to revision 24. Its local OOC DCP was generated with `synth_ip`; the generated
files are ignored while the XCI and manifest remain versioned. The official
demo directory was not modified.

Vivado 2024.2 stalled when the non-project self-test flow used `read_ip` to
automatically attach the upgraded DCP. The accepted elaboration-only path now
requires the co-located manifest, DCP, and generated IP XDC, explicitly
attaches the DCP to `u_ddr4_core/inst`, and reads the IP XDC after the board
XDC. It has completed RTL elaboration with zero critical warnings and zero
errors. This does not authorize implementation, bitstream generation, or board
programming, and it does not resolve the physical 64/80-bit mismatch.