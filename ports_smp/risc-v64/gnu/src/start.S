/*******************************************************************************
 * Copyright 2019-2025 Microchip FPGA Embedded Systems Solutions.
 *
 * SPDX-License-Identifier: MIT
 *
 * MPFS HAL Embedded Software
 *
 */

#define PRIM_HART			2
#include "tx_port.h"

  .globl reset_vector
  .globl _start
  .globl _secondary

reset_vector:
_start:

	// Park secondary harts
	csrr a0, mhartid
	li   a1, PRIM_HART
	bne  a0, a1, _secondary
    /*
     * clear the Return Address Stack
     */
    //call .clear_ras
_here1:
    /* Setup trap handler */
    la a4, trap_vector
    csrw mtvec, a4          # initalise machine trap vector address
    /* Make sure that mtvec is updated before continuing */
    1:
    csrr    a5, mtvec
    bne a4, a5, 1b
    /* Disable and clear all interrupts */
    li a2,  0x00000008
    csrc mstatus, a2        # clear interrupt enable bit
    csrw mie, zero
    csrw mip, zero
_here:
    # Init delegation registers, mideleg, medeleg, if a U54
    # These are not initialised by the hardware and come up in a random state
    csrr a0, mhartid
    beqz a0, .skip_e51
    csrw mideleg, 0
    csrw medeleg, 0

.skip_e51:
    # mscratch must be init to zero- we are not using scratch memory
    csrw mscratch, zero
    csrw mcause, zero
    csrw mepc, zero
    /*
     * clear PMP enables
     */
    csrw pmpcfg0, zero
    csrw pmpcfg2, zero
    /*
     * clear regs
     */
    li  x1, 0
    li  x2, 0
    li  x3, 0
    li  x4, 0
    li  x5, 0
    li  x6, 0
    li  x7, 0
    li  x8, 0
    li  x9, 0
    li  x10,0
    li  x11,0
    li  x12,0
    li  x13,0
    li  x14,0
    li  x15,0
    li  x16,0
    li  x17,0
    li  x18,0
    li  x19,0
    li  x20,0
    li  x21,0
    li  x22,0
    li  x23,0
    li  x24,0
    li  x25,0
    li  x26,0
    li  x27,0
    li  x28,0
    li  x29,0
    li  x30,0
    li  x31,0

    # enable FPU and accelerator if present, setting ignored on E51
    li t0, 0x00006000 | 0x00018000
    csrs mstatus, t0

    # Init floating point control register to zero
    # skip if e51
    csrr a0, mhartid
    beqz a0, .no_float
#ifdef __riscv_flen
    fscsr x0
#endif
.no_float:

     # make sure XLEN agrees with compilation choice, if not will loop here
.LxlenCheck:
    csrr t0, misa
#if __riscv_xlen == 64
    bltz t0, .LxlenPass
#else
    bgez t0, .LxlenPass
#endif
    j .LxlenCheck
.LxlenPass:

    # initialize global pointer, global data
    # The __global_pointer is allocated in the linker script. It points to a
    # location 2k after sdata start as the offsets used in the gp are +/- 2k
    # See https://www.sifive.com/blog/2017/08/28/all-aboard-part-3-linker-relaxation-in-riscv-toolchain/
    # see: http://www.rowleydownload.co.uk/arm/documentation/gnu/as/RISC_002dV_002dDirectives.html
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop

	// Park secondary harts
	csrr a0, mhartid
	li   a1, PRIM_HART
	bne  a0, a1, secondary

	//Init stack
	la sp, _stack_top

	// enable interrupts
	li a2, 0x1 << 3 //Soft
	csrw mie, a2

	// Load data section
	la a0, _data_lma
	la a1, _data
	la a2, _edata
	bgeu a1, a2, 2f
1:
	LOAD t0, (a0)
	STORE t0, (a1)
	addi a0, a0, REGBYTES
	addi a1, a1, REGBYTES
	bltu a1, a2, 1b
2:

	// Clear bss section
	la a0, _bss
	la a1, _ebss
	bgeu a0, a1, 2f
1:
	// reduce branch time, be sure about bss alignment in linker script
	STORE zero, 0x00 (a0)
	STORE zero, 0x08 (a0)
	STORE zero, 0x10 (a0)
	STORE zero, 0x18 (a0)
	STORE zero, 0x20 (a0)
	STORE zero, 0x28 (a0)
	STORE zero, 0x30 (a0)
	STORE zero, 0x38 (a0)
	addi a0, a0, REGBYTES * 8
	bltu a0, a1, 1b
2:

	// argc, argv, envp is 0
	li  a0, 0
	li  a1, 0
	li  a2, 0
	jal main

_secondary:
	wfi
	j _secondary

trap_vector:
    addi    sp, sp, -REGBYTES /* Save t0 for now */
    STORE   t0, 0x0(sp)
    csrr  t0, mcause
    bge   t0,x0,.Le51_other  /* Not an interrupt... */
    slli  t0,t0,1
    srli  t0,t0,1
    addi  t0,t0,-7
    bne   t0,x0,.Le51_other /* Not Timer interrupt... */
    /* Interrupt is timer interrupt so let FreeRTOS handle it */
    LOAD    t0, 0x0(sp)     # Restore t0 for proper context save by FreeRTOS
    addi    sp, sp, REGBYTES

    #if defined(__riscv_float_abi_single) || defined(__riscv_float_abi_double)
        addi    sp, sp, -520                            // Allocate space for all registers - with floating point enabled
    #else
        addi    sp, sp, -256                            // Allocate space for all registers - without floating point enabled
    #endif
    sd      x1, 224(sp)                             // Store RA
    call    _tx_thread_context_save                 // Call ThreadX context save

    call    _tx_timer_interrupt
    call    handle_m_timer_interrupt
    call    _tx_thread_context_restore              // Jump to ThreadX context restore function. Note: this does not return!
    mret    //this should never get called.

	/*
 * clear_ras , clear_ras_2_deep
 * Two deep function calls.
 * Used to clear the interal processor Return Address Stack
 * This is belt and braces, may not be required
 */
.clear_ras:
    mv a5, x1
    nop
    call .clear_ras_2_deep
    nop
    nop
    nop
    nop
    nop
    nop
    mv  x1, a5
    ret

.clear_ras_2_deep:
    nop
    nop
    nop
    nop
    nop
    nop
    ret
