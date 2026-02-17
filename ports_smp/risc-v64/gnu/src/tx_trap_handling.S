/**************************************************************************/
/*                                                                        */
/*       Copyright (c) 2026 Microchip FPGA Embedded Systems Solutions.    */
/*                                                                        */
/*       This software is licensed under the Microsoft Software License   */
/*       Terms for Microsoft Azure RTOS. Full text of the license can be  */
/*       found in the LICENSE file at https://aka.ms/AzureRTOS_EULA       */
/*       and in the root directory of this software.                      */
/*                                                                        */
/**************************************************************************/


/**************************************************************************/
/**************************************************************************/
/**                                                                       */
/** ThreadX Component                                                     */
/**                                                                       */
/**   Initialize                                                          */
/**                                                                       */
/**************************************************************************/
/**************************************************************************/

/**************************************************************************/
#include "common/bits.h"
#include "common/encoding.h"
#include "common/mss_mtrap.h"
#include "tx_port.h"

    .global  trap_entry
    .extern  trap_from_machine_mode     // This is defined in mss_mtrap.c
    .extern  _tx_thread_context_restore

    .section .text
    .balign 4
    trap_entry:
#if defined(__riscv_float_abi_single) || defined(__riscv_float_abi_double)
    addi sp, sp, -65*REGBYTES         // Allocate space for all registers - with floating point enabled
#else
    addi sp, sp, -32*REGBYTES         // Allocate space for all registers - without floating point enabled
#endif

    STORE   x1, 28*REGBYTES(sp)       // Store RA, 28*REGBYTES(because call will override ra [ra is a calle register in riscv])

    call    _tx_thread_context_save

    csrr t0, mcause

    li t1, 0x8000000000000007 // Load the interrupt code for machine timer interrupt into t1
    beq t0, t1, timer

nontimer:
    mv a0, sp
    csrr a1, mtval
    csrr a2, mepc
    call    trap_from_machine_mode
    call _tx_thread_context_restore
    // _tx_thread_context_restore should return to interrupt. Not here.
_err1:
    wfi
    nop
    nop
    j _err1

timer:
    call _tx_timer_interrupt
    call handle_m_timer_interrupt
    call _tx_thread_context_restore

    // _tx_thread_context_restore should return to interrupt. Not here.
_err:
    wfi
    nop
    nop
    j _err
