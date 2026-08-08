# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the Hummingbirdv2 E203 RISC-V SoC subsystem, an open-source RISC-V processor implementation by Nuclei System Technology. The current directory (`rtl/e203/subsys/`) contains the subsystem-level Verilog modules that integrate the E203 CPU core with peripherals, memory controllers, and bus infrastructure.

## Architecture Overview

The subsystem is organized into several key components:

### Core Modules
- **e203_subsys_top.v**: Top-level subsystem module that integrates CPU and closely coupled devices
- **e203_subsys_main.v**: Main subsystem implementation with CPU core integration
- **e203_subsys_*.v**: Various subsystem components (clocks, peripherals, memory, etc.)

### Custom Accelerators
- **mac_unit/**: Matrix multiplication accelerator unit
  - **MacMachine_top.v**: Top-level MAC unit with APB interface and SRAM controllers
  - **MacMachineWrapper.v**: Wrapper for MAC unit integration
  - Supports 256-bit wide SRAM interfaces for input, weight, and output data

### DMA Controller
- **dma/**: Direct Memory Access controller
  - **dma_top.v**: Top-level DMA module with APB and AXI interfaces
  - Supports burst transfers, incremental and jump modes
  - 32-bit and 64-bit data width support

### Memory Controllers
- **axi2bram_*.v**: AXI to BRAM interface controllers
- **e203_bram_*.v**: BRAM memory modules (8K, 128K, 1MB variants)
- **MacMachine_RamCtrlSimple.v**: Simplified RAM controller for MAC unit
- **RamCtrlSwitch.v**: RAM controller switching logic

### Bus Infrastructure
- **bus/**: AXI bus matrix and interconnect
  - **axi_matrix/**: Synopsys DW AXI interconnect IP
  - **axi_x2x/**: AXI protocol converters and bridges
  - **top/bus_top.v**: Top-level bus integration

### APB Peripherals
- **design_apb_*.v**: APB interconnect and multiplexer modules

## Key Features

1. **RISC-V E203 Integration**: Subsystem built around the E203 RISC-V core
2. **Custom MAC Unit**: Hardware accelerator for matrix operations with dedicated SRAM interfaces
3. **DMA Controller**: High-performance data movement with AXI4 interface
4. **Flexible Memory System**: Multiple BRAM sizes and AXI-based memory controllers
5. **APB Peripheral Bus**: Standard ARM APB for peripheral integration
6. **AXI Interconnect**: Industry-standard AXI4 bus infrastructure

## Interface Standards

- **APB (Advanced Peripheral Bus)**: Used for control and status registers
- **AXI4**: Used for high-bandwidth data transfers
- **ICB (Internal Chip Bus)**: Nuclei's internal bus protocol used in E203 core

## Development Notes

### Memory Map
The system uses a structured memory map with different regions for:
- SRAM blocks (input, weight, output for MAC unit)
- APB peripheral space
- AXI memory regions

### Clock Domains
- Main system clock for APB and AXI interfaces
- Separate SRAM clocks for memory controllers
- Clock gating and power management through subsystem clock controllers

### Reset Strategy
- Unified reset strategy with `rst_n` (active low reset)
- Separate reset controls for different subsystem components

## File Naming Conventions

- `e203_subsys_*.v`: Core subsystem modules
- `*_top.v`: Top-level integration modules
- `axi2bram*.v`: AXI to BRAM bridge modules
- `design_*.v`: System integration and interconnect modules

This subsystem represents a complete SoC implementation with the E203 RISC-V core, custom accelerators, and standard bus interfaces suitable for FPGA implementation and ASIC prototyping.