# UART Test Makefile for E203 RISC-V
# 编译UART通信测试程序

TARGET = uart_test

# Source files  
SRCS = uart_test.c startup.S

# Custom linker script
LINKER_SCRIPT = link.ld

# Compiler flags for bare metal
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
all: $(TARGET).elf $(TARGET).hex

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

# Generate hex file for FPGA simulation
$(TARGET).hex: $(TARGET).elf
	@echo "Creating $(TARGET).hex for FPGA simulation"
	$(OBJCOPY) -j .text -j .data -O binary --set-start 0x80000000 $< $(TARGET).bin
	@# Convert to 64-bit hex format for e203 ITCM
	@python3 -c "import sys; data=open('$(TARGET).bin','rb').read(); [print('%016x' % int.from_bytes(data[i:i+8],'little')) for i in range(0,len(data),8) if i+8<=len(data)]" > $@
	@echo "Generated $(TARGET).hex for e203 ITCM loading"

# Generate disassembly for debugging
$(TARGET).dump: $(TARGET).elf
	@echo "Creating disassembly $(TARGET).dump"
	$(OBJDUMP) -S -D $< > $@

# Clean build files
clean:
	@echo "Cleaning build files"
	rm -f *.o *.elf *.hex *.bin *.map *.dump

# Debug target
debug: all $(TARGET).dump
	@echo "Debug files generated:"
	@echo "  - $(TARGET).elf (with debug symbols)"
	@echo "  - $(TARGET).dump (disassembly)" 
	@echo "  - $(TARGET).map (memory map)"

# Show memory usage
memmap: $(TARGET).elf
	@echo "Memory usage:"
	@$(SIZE) -A $<

.PHONY: all clean debug memmap 