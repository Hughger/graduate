# AXKU15 DDR4 IP 2024.2 Upgrade-Copy Implementation Plan

> **For agentic workers:** Execute this plan task-by-task with a fresh review gate after each task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a Vivado 2024.2 project-owned copy of the official AXKU15 DDR4 IP and validate the AXI64 DDR4 self-test against that copy without generating a bitstream.

**Architecture:** A batch Tcl command copies the supplied official XCI into the repository-owned `ip/ddr4_core_2024_2` directory, upgrades only that copy, and generates its output products. A small Python manifest writer records the source and upgraded file hashes. The existing self-test build flow rejects locked IP and accepts the owned unlocked XCI for elaboration-only validation.

**Tech Stack:** Vivado 2024.2 Tcl, Chisel-generated Verilog, PowerShell, Python standard library, SBT 1.12.15, Git.

## Global Constraints

- Never modify any file below `D:/work-yanjiusheng/graduate/01_demo_document`.
- Preserve the official 64-bit DQ/eight-DQS DDR4 configuration; do not infer an 80-bit controller.
- Place the copied IP only below `accelerator/fpga/AXKU15/diffusion/ip/ddr4_core_2024_2`.
- The default validation path must stop after RTL elaboration; it must not run implementation, write a bitstream, or program hardware.
- Treat the 64/80-bit DQ/DQS and DRAM-part discrepancies as an explicit board-validation gate.
- Do not add vendor-generated DCP, simulation netlists, or Vivado journal/log files to Git.

---

## File structure

| File | Responsibility |
| --- | --- |
| `accelerator/fpga/AXKU15/diffusion/scripts/upgrade_ddr4_core_2024_2.tcl` | Copy an external official XCI, upgrade only the copied XCI with Vivado 2024.2, generate outputs, and reject a locked result. |
| `accelerator/fpga/AXKU15/diffusion/scripts/write_ddr4_ip_manifest.py` | Record SHA-256, tool version, target part, source path, and upgraded XCI path as deterministic JSON. |
| `accelerator/fpga/AXKU15/diffusion/ip/ddr4_core_2024_2/ddr4_core_2024_2.xci` | Project-owned upgraded IP configuration; copied/rewritten by the upgrade command. |
| `accelerator/fpga/AXKU15/diffusion/ip/ddr4_core_2024_2/manifest.json` | Auditable provenance for the project-owned XCI. |
| `accelerator/fpga/AXKU15/diffusion/scripts/build_axi64_ddr4_selftest.tcl` | Reject locked input IP before reading the self-test wrapper. |
| `accelerator/fpga/AXKU15/diffusion/docs/AXKU15_AXI64_DDR4_SELFTEST_BUILD.md` | Document copy/upgrade and elaboration-only commands. |
| `accelerator/fpga/AXKU15/diffusion/docs/OFFICIAL_DDR4_DEMO_ASSESSMENT.md` | State that 2024.2 validation uses a project-owned upgraded copy, not the official demo. |

## Task 1: Create the owned-IP upgrade and provenance tools

**Files:**
- Create: `accelerator/fpga/AXKU15/diffusion/scripts/upgrade_ddr4_core_2024_2.tcl`
- Create: `accelerator/fpga/AXKU15/diffusion/scripts/write_ddr4_ip_manifest.py`
- Create at runtime, do not stage: `accelerator/fpga/AXKU15/diffusion/ip/ddr4_core_2024_2/ddr4_core_2024_2.xci`
- Create at runtime, stage: `accelerator/fpga/AXKU15/diffusion/ip/ddr4_core_2024_2/manifest.json`

**Consumes:** an external official `ddr4_core.xci`, target part `xcku15p-ffve1517-2-i`, and the installed Vivado 2024.2 executable.

**Produces:** an unlocked project-owned `ddr4_core_2024_2.xci`, generated output products ignored by Git, and a manifest carrying `source_sha256`, `upgraded_sha256`, `vivado_version`, `part`, `source_xci`, and `upgraded_xci`.

- [ ] **Step 1: Write the failing upgrade precondition check**

Run:

```powershell
& 'C:\Xilinx\Vivado\2024.2\bin\vivado.bat' -mode batch `
  -source accelerator/fpga/AXKU15/diffusion/scripts/upgrade_ddr4_core_2024_2.tcl `
  -tclargs -source-xci DOES_NOT_EXIST -output-dir accelerator/fpga/AXKU15/diffusion/ip/ddr4_core_2024_2
```

Expected: `ERROR: Missing input file` and a nonzero exit code because the Tcl script does not exist yet.

- [ ] **Step 2: Implement the guarded Tcl upgrade command**

Create `upgrade_ddr4_core_2024_2.tcl` with an option parser that accepts exactly `-source-xci` and `-output-dir`, rejects missing files, and performs the following core operations:

```tcl
set copied_xci [file join $output_dir ddr4_core_2024_2.xci]
file mkdir $output_dir
file copy -force $source_xci $copied_xci
create_project -in_memory ddr4_core_2024_2 -part xcku15p-ffve1517-2-i
read_ip $copied_xci
set core [lindex [get_ips] 0]
set_property name ddr4_core_2024_2 $core
upgrade_ip $core
generate_target all $core
if {[get_property IS_LOCKED $core]} { error "Upgraded IP remains locked" }
write_ip_tcl -force [file join $output_dir recreate_ddr4_core_2024_2.tcl] $core
puts "UPGRADED_XCI=[get_property IP_FILE $core]"
exit
```

The implementation must reject an unexpected number of IPs and must not call `synth_design`, `place_design`, `route_design`, or `write_bitstream`.

- [ ] **Step 3: Implement the manifest writer**

Create `write_ddr4_ip_manifest.py` with this program shape:

```python
from argparse import ArgumentParser
from hashlib import sha256
import json
from pathlib import Path

def digest(path: Path) -> str:
    return sha256(path.read_bytes()).hexdigest()

parser = ArgumentParser()
parser.add_argument('--source-xci', type=Path, required=True)
parser.add_argument('--upgraded-xci', type=Path, required=True)
parser.add_argument('--vivado-version', required=True)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
payload = {
    'part': 'xcku15p-ffve1517-2-i',
    'source_sha256': digest(args.source_xci),
    'source_xci': str(args.source_xci),
    'upgraded_sha256': digest(args.upgraded_xci),
    'upgraded_xci': str(args.upgraded_xci),
    'vivado_version': args.vivado_version,
}
args.output.write_text(json.dumps(payload, indent=2, sort_keys=True) + '\\n', encoding='utf-8')
```

- [ ] **Step 4: Run the real copy-and-upgrade command**

Run:

```powershell
$official = 'D:\work-yanjiusheng\graduate\01_demo_document\01_demo_document\demo\ddr_test\ddr_test\ddr_test.srcs\sources_1\ip\ddr4_core\ddr4_core.xci'
$owned = 'accelerator\fpga\AXKU15\diffusion\ip\ddr4_core_2024_2'
& 'C:\Xilinx\Vivado\2024.2\bin\vivado.bat' -mode batch `
  -source accelerator/fpga/AXKU15/diffusion/scripts/upgrade_ddr4_core_2024_2.tcl `
  -tclargs -source-xci $official -output-dir $owned
```

Expected: exit code 0, one upgraded XCI below `$owned`, an `UPGRADED_XCI=` line, and no `write_bitstream` action.

- [ ] **Step 5: Write and verify provenance**

Run:

```powershell
$python = 'C:\Users\98676\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
& $python accelerator/fpga/AXKU15/diffusion/scripts/write_ddr4_ip_manifest.py `
  --source-xci $official `
  --upgraded-xci accelerator/fpga/AXKU15/diffusion/ip/ddr4_core_2024_2/ddr4_core_2024_2.xci `
  --vivado-version 2024.2 `
  --output accelerator/fpga/AXKU15/diffusion/ip/ddr4_core_2024_2/manifest.json
& $python -m json.tool accelerator/fpga/AXKU15/diffusion/ip/ddr4_core_2024_2/manifest.json
```

Expected: valid JSON with two distinct 64-character SHA-256 values and the exact target part.

- [ ] **Step 6: Commit Task 1**

```powershell
git add accelerator/fpga/AXKU15/diffusion/scripts/upgrade_ddr4_core_2024_2.tcl `
  accelerator/fpga/AXKU15/diffusion/scripts/write_ddr4_ip_manifest.py `
  accelerator/fpga/AXKU15/diffusion/ip/ddr4_core_2024_2/ddr4_core_2024_2.xci `
  accelerator/fpga/AXKU15/diffusion/ip/ddr4_core_2024_2/manifest.json
git commit -m "feat: add upgraded AXKU15 DDR4 IP copy"
```

## Task 2: Guard self-test composition against locked IP

**Files:**
- Modify: `accelerator/fpga/AXKU15/diffusion/scripts/build_axi64_ddr4_selftest.tcl:44-49`
- Test: `accelerator/fpga/AXKU15/diffusion/scripts/build_axi64_ddr4_selftest.tcl` invoked once with the official XCI and once with the owned XCI

**Consumes:** `ddr4_core_2024_2.xci` from Task 1 and generated `Axi64DdrSelfTest.v`.

**Produces:** a deterministic error for a locked XCI and an elaboration-only build path for the unlocked owned XCI.

- [ ] **Step 1: Capture the failing locked-IP behavior**

Run the existing self-test build with the official 2022.2 XCI. Expected: it currently succeeds despite a locked-IP warning; this demonstrates why the guard is necessary.

```powershell
& 'C:\Xilinx\Vivado\2024.2\bin\vivado.bat' -mode batch `
  -source accelerator/fpga/AXKU15/diffusion/scripts/build_axi64_ddr4_selftest.tcl `
  -tclargs -ddr4-xci $official -ddr4-xdc $xdc -selftest-rtl $selftest
```

- [ ] **Step 2: Add the lock guard immediately after `read_ip`**

Replace the existing input comment and add this exact validation:

```tcl
read_ip $ddr4_xci
set loaded_ips [get_ips]
if {[llength $loaded_ips] != 1} { error "Expected exactly one DDR4 IP, got [llength $loaded_ips]" }
set ddr4_ip [lindex $loaded_ips 0]
if {[get_property IS_LOCKED $ddr4_ip]} {
  error "DDR4 IP is locked in this Vivado version: $ddr4_xci"
}
```

Do not add `upgrade_ip`, `generate_target`, or any implementation command to the build script.

- [ ] **Step 3: Verify the locked official XCI is rejected**

Repeat Step 1. Expected: nonzero exit and `DDR4 IP is locked in this Vivado version` before `read_verilog` runs.

- [ ] **Step 4: Generate current self-test RTL and validate the owned XCI**

Run:

```powershell
Set-Location accelerator
$env:SBT_OPTS='-Dsbt.server.autostart=false'
sbt 'runMain FLOOD_Accelerator.diffusion.GenerateAxi64DdrSelfTestVerilog'
Set-Location ..
& 'C:\Xilinx\Vivado\2024.2\bin\vivado.bat' -mode batch `
  -source accelerator/fpga/AXKU15/diffusion/scripts/build_axi64_ddr4_selftest.tcl `
  -tclargs -ddr4-xci accelerator/fpga/AXKU15/diffusion/ip/ddr4_core_2024_2/ddr4_core_2024_2.xci `
  -ddr4-xdc $xdc `
  -selftest-rtl accelerator/target/generated/axi64-ddr4-selftest/Axi64DdrSelfTest.v
```

Expected: `synth_design -rtl` completes with zero errors and zero critical warnings; no implementation products are produced.

- [ ] **Step 5: Commit Task 2**

```powershell
git add accelerator/fpga/AXKU15/diffusion/scripts/build_axi64_ddr4_selftest.tcl
git commit -m "fix: reject locked DDR4 self-test IP"
```

## Task 3: Document the owned IP flow and run regression gates

**Files:**
- Modify: `accelerator/fpga/AXKU15/diffusion/docs/AXKU15_AXI64_DDR4_SELFTEST_BUILD.md:3-39,56-68`
- Modify: `accelerator/fpga/AXKU15/diffusion/docs/OFFICIAL_DDR4_DEMO_ASSESSMENT.md:81-89`
- Test: nine existing Scala suites and the owned-XCI Vivado elaboration command from Task 2

**Consumes:** the unlocked owned XCI and manifest from Task 1 plus the guard from Task 2.

**Produces:** a reproducible documented command path and verified RTL/Chisel regression evidence without claiming board closure.

- [ ] **Step 1: Update the build guide**

Replace the statement that all XCI inputs are external with a section that names the project-owned XCI, shows the Task 1 upgrade command, requires inspection of `manifest.json`, and uses the owned-XCI path in the elaboration command. State exactly: “This command does not run implementation, write a bitstream, or program the board.” Keep the 64/80-bit and DRAM-part discrepancy as an explicit blocker.

- [ ] **Step 2: Update the official-demo assessment**

Append a dated upgrade-copy status paragraph stating that the original 2022.2 demo remains unchanged; only the project-owned 2024.2 XCI is used for the new validation flow; and successful elaboration is not calibration, timing closure, or board data-integrity evidence.

- [ ] **Step 3: Run Chisel regression**

Run:

```powershell
Set-Location accelerator
$env:SBT_OPTS='-Dsbt.server.autostart=false'
sbt 'testOnly FLOOD_Accelerator.diffusion.Axi64DdrSelfTestSpec FLOOD_Accelerator.diffusion.MigAppToAxi64BridgeSpec FLOOD_Accelerator.diffusion.DiffusionAccelTopMemorySpec FLOOD_Accelerator.diffusion.DiffusionAccelTopAxi64Spec FLOOD_Accelerator.diffusion.DiffusionAccelTopTensorDmaSpec FLOOD_Accelerator.diffusion.DiffusionAccelTopInternalStoreSpec FLOOD_Accelerator.diffusion.DiffusionAccelTopPerfSpec FLOOD_Accelerator.diffusion.MigAppTransferSpec FLOOD_Accelerator.diffusion.MigAppRequestArbiterSpec'
```

Expected: all nine suites pass.

- [ ] **Step 4: Verify provenance and non-implementation behavior**

Run the owned-XCI elaboration command from Task 2 and inspect its log for `RTL Elaboration Complete`, `0 Critical Warnings`, `0 Errors`, and no occurrences of `write_bitstream`, `place_design`, or `route_design`.

- [ ] **Step 5: Commit and push Task 3**

```powershell
git add accelerator/fpga/AXKU15/diffusion/docs/AXKU15_AXI64_DDR4_SELFTEST_BUILD.md `
  accelerator/fpga/AXKU15/diffusion/docs/OFFICIAL_DDR4_DEMO_ASSESSMENT.md
git diff --check
git commit -m "docs: document upgraded DDR4 IP validation"
git push origin sd15-resnetblock
```

## Plan self-review

- Spec coverage: Task 1 implements the owned copy and provenance; Task 2 prevents accidental use of locked IP; Task 3 documents the workflow and runs RTL/Vivado regression. The official demo preservation, 64-bit configuration, and no-bitstream boundary are global constraints and are checked by each task.
- Placeholder scan: no incomplete work markers or unspecified error handling remain.
- Interface consistency: the owned XCI path, part number, manifest fields, Tcl option names, and build invocation are identical across all tasks.
