/*
 * Startup Assembly for E203 RISC-V Processor
 * Entry point at 0x80000000
 */

.section .text.init, "ax", @progbits
.global _start
.type _start, @function

_start:
    /* Disable interrupts */
    csrw mstatus, zero
    csrw mie, zero
    
    /* Setup stack pointer to top of DTCM */
    la sp, __stack_top
    
    /* Clear BSS section */
    la t0, __bss_start
    la t1, __bss_end
clear_bss:
    beq t0, t1, copy_data
    sw zero, 0(t0)
    addi t0, t0, 4
    j clear_bss
    
copy_data:
    /* Copy .data section from ROM to RAM */
    la t0, __data_lma      /* Load address in ITCM */
    la t1, __data_start    /* Runtime address in DTCM */
    la t2, __data_end      /* End of data section */
    
copy_data_loop:
    beq t1, t2, call_main
    lw t3, 0(t0)
    sw t3, 0(t1)
    addi t0, t0, 4
    addi t1, t1, 4
    j copy_data_loop
    
call_main:
    /* Set up global pointer (optional for this simple case) */
    .option push
    .option norelax
1:  auipc gp, %pcrel_hi(__global_pointer$)
    addi  gp, gp, %pcrel_lo(1b)
    .option pop
    
    /* Call main function */
    jal ra, main
    
    /* If main returns, loop forever */
end_loop:
    j end_loop

.size _start, . - _start 