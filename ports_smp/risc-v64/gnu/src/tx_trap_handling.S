/**************************************************************************/
/*                                                                        */
/*       Copyright (c) Microsoft Corporation. All rights reserved.        */
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
    .extern  trap_from_machine_mode     //This is defined in mss_mtrap.c
    .extern  _tx_thread_context_restore

    .section .text
    .balign 4
    trap_entry:
    blez sp, bad_addr
#if defined(__riscv_float_abi_single) || defined(__riscv_float_abi_double)
    addi sp, sp, -65*REGBYTES         // Allocate space for all registers - with floating point enabled
#else
    addi sp, sp, -32*REGBYTES         // Allocate space for all registers - without floating point enabled
#endif

    STORE   x1, 28*REGBYTES(sp)       // Store RA, 28*REGBYTES(because call will override ra [ra is a calle register in riscv])

//    csrw    mscratch, x1 // Debug save of ra and tp
//    csrw    sscratch, s0

    call    _tx_thread_context_save

    csrr t0, mcause

    li t1, 0x8000000000000007 // Load the interrupt code for machine timer interrupt into t1

//    lui t1, 0x80000    // Load upper 20 bits
//    addi t1, t1, 0x7   // Add lower 12 bits

    beq t0, t1, timer


nontimer:
    mv a0, sp
    csrr a1, mtval
    csrr a2, mepc
    call    trap_from_machine_mode
    call _tx_thread_context_restore
    // _tx_thread_context_restore will return to interrupt. Not here.
_err1:
    wfi
    nop
    nop
    j _err1

timer:
#if defined(DBG_ANNO_2H) || defined(DBG_ANNO_4H)
    la t6, 0x201220a0
    li t5, DBG_TIMER
    sw t5, (t6)
#endif

    call _tx_timer_interrupt
    call handle_m_timer_interrupt

#if defined(DBG_ANNO_2H) || defined(DBG_ANNO_4H)
    la t6, 0x201220a0
    li t5, DBG_TIMER
    sw t5, 4(t6)
#endif

    call _tx_thread_context_restore
_err:
    wfi
    nop
    nop
    j _err

bad_addr:
    nop
    nop
    j bad_addr
