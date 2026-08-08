/*
 * Custom Linker Script for E203 RISC-V Processor
 * ITCM Code: 0x80000000 (256KB)
 * DTCM Data: 0x90000000 (256KB)
 */

ENTRY(_start)

MEMORY
{
    /* ITCM: Instruction Tightly Coupled Memory */
    itcm (rxai) : ORIGIN = 0x80000000, LENGTH = 256K
    
    /* DTCM: Data Tightly Coupled Memory */
    dtcm (wxa)  : ORIGIN = 0x90000000, LENGTH = 256K
}

/* Stack grows down from top of DTCM */
PROVIDE(__stack_top = ORIGIN(dtcm) + LENGTH(dtcm));

SECTIONS
{
    /* Program entry point must be at 0x80000000 */
    .text : ALIGN(4)
    {
        KEEP(*(.text.init))     /* Boot code first */
        *(.text)                /* Program code */
        *(.text.*)
        *(.rodata)              /* Read-only data */
        *(.rodata.*)
        . = ALIGN(4);
        __text_end = .;
    } > itcm

    /* Data sections in DTCM */
    .data : ALIGN(4)
    {
        __data_start = .;
        *(.data)
        *(.data.*)
        *(.sdata)
        *(.sdata.*)
        . = ALIGN(4);
        __data_end = .;
    } > dtcm AT > itcm

    /* BSS section for zero-initialized data */
    .bss : ALIGN(4)
    {
        __bss_start = .;
        *(.bss)
        *(.bss.*)
        *(.sbss)
        *(.sbss.*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end = .;
    } > dtcm

    /* Stack section */
    .stack : ALIGN(4)
    {
        __stack_bottom = .;
        . = . + 4096;  /* 4KB stack */
        __stack_top = .;
    } > dtcm

    /* Store LMA (Load Memory Address) of .data section */
    __data_lma = LOADADDR(.data);
    
    /* Global pointer for relaxation optimization */
    PROVIDE(__global_pointer$ = __data_start + 0x800);
    
    /* Memory size checks */
    ASSERT(__text_end <= ORIGIN(itcm) + LENGTH(itcm), "Code size exceeds ITCM limit (256KB)")
    ASSERT(__stack_top <= ORIGIN(dtcm) + LENGTH(dtcm), "Data size exceeds DTCM limit (256KB)")
} 