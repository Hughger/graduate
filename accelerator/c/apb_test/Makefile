# Custom Makefile for AXI Test Project
# E203 RISC-V Bare Metal Application

TARGET = apb_test

# Include HummingBird SDK
HBIRD_SDK_ROOT = ../../..

# Source files
SRCS = main.c startup.S

# Custom linker script
LINKER_SCRIPT = link.ld

# Compiler flags for bare metal, no standard library
COMMON_FLAGS = -march=rv32imac -mabi=ilp32 -mcmodel=medany
COMMON_FLAGS += -ffunction-sections -fdata-sections -fno-common
COMMON_FLAGS += -nostdlib -nostartfiles -fno-builtin
COMMON_FLAGS += -Os -g

# C specific flags
CFLAGS = $(COMMON_FLAGS) -std=c99 -Wall -Wextra

# Assembly flags
ASMFLAGS = $(COMMON_FLAGS)

# Linker flags
LDFLAGS = -T $(LINKER_SCRIPT) -Wl,--gc-sections -Wl,-Map,$(TARGET).map
LDFLAGS += -nostdlib -nostartfiles -Wl,--no-relax
LDFLAGS += -march=rv32imac -mabi=ilp32 -mcmodel=medany

# Tools
CROSS_COMPILE = riscv64-unknown-elf-
CC = $(CROSS_COMPILE)gcc
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump
SIZE = $(CROSS_COMPILE)size

# Object files
OBJS = $(SRCS:.c=.o)
OBJS := $(OBJS:.S=.o)

# Default target
all: $(TARGET).elf $(TARGET).hex $(TARGET).bin

# Compile C files
%.o: %.c
	@echo "Compiling $<"
	$(CC) $(CFLAGS) -c $< -o $@

# Compile assembly files
%.o: %.S
	@echo "Assembling $<"
	$(CC) $(ASMFLAGS) -c $< -o $@

# Link ELF file
$(TARGET).elf: $(OBJS) $(LINKER_SCRIPT)
	@echo "Linking $(TARGET).elf"
	$(CC) $(OBJS) $(LDFLAGS) -o $@
	$(SIZE) $@

# Generate hex file for simulation (pure hex format for $readmemh)
$(TARGET).hex: $(TARGET).elf
	@echo "Creating $(TARGET).hex (pure hex format for Verilog)"
	$(OBJCOPY) -j .text -j .data -O binary --set-start 0x80000000 $< $(TARGET).bin
	@# Convert binary to hex format that $readmemh can understand
	@python -c "import sys; data=open('$(TARGET).bin','rb').read(); [print('%016x' % int.from_bytes(data[i:i+8],'little')) for i in range(0,len(data),8) if i+8<=len(data)]" > $@
	@echo "Generated pure hex format (64-bit words) for Verilog \$$readmemh"

# Generate Verilog memory file
$(TARGET).verilog: $(TARGET).elf
	@echo "Creating $(TARGET).verilog"
	$(OBJCOPY) -O verilog $< $@

# Generate binary file
$(TARGET).bin: $(TARGET).elf
	@echo "Creating $(TARGET).bin"
	$(OBJCOPY) -O binary $< $@

# Generate disassembly
$(TARGET).dump: $(TARGET).elf
	@echo "Creating disassembly $(TARGET).dump"
	$(OBJDUMP) -S -D $< > $@

# Memory map analysis
memmap: $(TARGET).elf
	@echo "Memory Map:"
	@echo "=========================================="
	@$(SIZE) -A $<
	@echo "=========================================="
	@echo "Entry point: 0x80000000 (ITCM)"
	@echo "Stack top:   0x90010000 (DTCM)"
	@echo "AXI target:  0x40000000"

# Clean build files
clean:
	@echo "Cleaning build files"
	rm -f *.o *.elf *.hex *.bin *.map *.dump *.verilog

# Debug info
debug: all $(TARGET).dump
	@echo "Debug files generated:"
	@echo "  - $(TARGET).elf (with debug symbols)"
	@echo "  - $(TARGET).dump (disassembly)"
	@echo "  - $(TARGET).map (memory map)"

# Simulation target - generates hex file for $readmemh
sim: $(TARGET).hex $(TARGET).verilog
	@echo "Simulation files ready:"
	@echo "  - $(TARGET).hex (Intel HEX format)"
	@echo "  - $(TARGET).verilog (Verilog memory format)"
	@echo "Use in testbench:"
	@echo "  $$readmemh(\"$(TARGET).hex\", memory);"

.PHONY: all clean debug memmap sim 