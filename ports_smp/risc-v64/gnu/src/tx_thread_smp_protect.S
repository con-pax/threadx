/***************************************************************************
 * Copyright (c) 2025 Microchip FPGA Embedded Systems Solutions.
 *
 * This program and the accompanying materials are made available under the
 * terms of the MIT License which is available at
 * https://opensource.org/licenses/MIT.
 *
 * SPDX-License-Identifier: MIT
 **************************************************************************/


/**************************************************************************/
/**************************************************************************/
/**                                                                       */
/** ThreadX Component                                                     */
/**                                                                       */
/**   Thread - Low Level SMP Support                                      */
/**                                                                       */
/**************************************************************************/
/**************************************************************************/
#include "tx_port.h"

#define CLINT_BASE  0x02000000
#define CLINT_MTIME 0x0200BFF8

//    .section .text
    .section .l2_scratchcodetext,"ax",@progbits
//    .section .ram_codetext
/**************************************************************************/
/*                                                                        */
/*  FUNCTION                                               RELEASE        */
/*                                                                        */
/*    _tx_thread_smp_protect                         */
/*                                                           6.2.1        */
/*  AUTHOR                                                                */
/*                                                                        */
/*    Peter Mc Shane, Microchip FPGA Embedded Systems Solutions.           */
/*                                                                        */
/*  DESCRIPTION                                                           */
/*                                                                        */
/*    This function gets protection for running inside the ThreadX        */
/*    source. This is ccomplished by a combination of a test-and-set      */
/*    flag and periodically disabling interrupts.                         */
/*                                                                        */
/*  INPUT                                                                 */
/*                                                                        */
/*    None                                                                */
/*                                                                        */
/*  OUTPUT                                                                */
/*                                                                        */
/*    Previous Status Register                                            */
/*                                                                        */
/*  CALLS                                                                 */
/*                                                                        */
/*    None                                                                */
/*                                                                        */
/*  CALLED BY                                                             */
/*                                                                        */
/*    ThreadX Source                                                      */
/*                                                                        */
/*  RELEASE HISTORY                                                       */
/*                                                                        */
/*    DATE              NAME                      DESCRIPTION             */
/*                                                                        */
/*  24-08-2025      Peter Mc Shane           Initial Version 6.2.1   ?      */
/*                                                                        */
/**************************************************************************/
    .globl  _tx_thread_smp_protect
_tx_thread_smp_protect:
    csrrci a0, mstatus, 0x08        # Save current interrupt enable state and disable ints
    andi a0, a0, 8                  # Only want interrupt enable bit
    csrr t1, mhartid                # Get current hart id
#if defined(CONFIG_TARGET_MPFSOC)
    add t1, t1, -1                  # Remove e51 from the picture
#endif

#if defined(DBG_ANNO_2H)
    la t6, 0x201220a0
    li t5, DBG_PROTECT
    sll t5, t5, t1
    sw t5, (t6)
    la t5, _tx_thread_preempt_disable
    lw t5, (t5)
    beqz t5, _clear
    li t5, DBG_PRE_DIS
    sw t5, 4(t6)
    j _done

_clear:
    li t5, DBG_PRE_DIS
    sw t5, (t6)

_done:
#endif

_restart:
    la t2, _tx_thread_smp_protection # The protect in force flag is ULONG which is 32 bit
    lw t3, TX_PR_OWN(t2)                    # Fetch protection owner
    bne t1, t3, _get_protection

# Fall through if we already own it
//    li t4, 1                      # Flag set value
#if defined(DBG_ANNO_2H)
    li t5, DBG_PROTECTION
    sll t5, t5, t1
    la t6, 0x201220a0
#endif

_got_protection:

#if defined(DBG_ANNO_2H)
    sw t5, (t6)
#endif

#if defined(DBG_PROT_LOG)
    la t5, CLINT_MTIME
    ld t5, (t5)
    fence
    ld t6, TX_PR_LOCK(t2)
#endif
    sw t1, TX_PR_OWN(t2)                    # Mark it as ours

#if defined(DBG_PROT_LOG)
// debug
    csrr t4, mhartid                # Use hart ID 1-4 as marker for debug
    csrr t3, mhartid
    addi t3, t3, -1
    slli t3, t3, TX_PR_SHIFT
    add t3, t2, t3
    addi t3, t3, TX_PR_FLAG
    sw t4, (t3)
    fence

//debug - looking for more than one flag set
    lw t3, TX_PR_FLAG(t2)
    sub t4, t4, t3
    lw t3, TX_PR_FLAG1(t2)
    sub t4, t4, t3
    lw t3, TX_PR_FLAG2(t2)
    sub t4, t4, t3
    lw t3, TX_PR_FLAG3(t2)
    sub t4, t4, t3
    bnez t4, _oops2
#endif
_owned:
    fence
    lw t3, TX_PR_CNT(t2)                    # It's ours so update count
    addi t3, t3, 1
    sw t3, TX_PR_CNT(t2)
    fence
#if defined(DBG_PROT_LOG)
//
// Debug logging
//
    slli t3, t3, 32                 # Copy count to high words
    li t1, 1
    la t0, pro_in_total
    amoadd.d t2, t1, (t0) # Fetch count and increment memory copy by 1
    fence

    li t1, 2
    la t0, pro_in_count
    amoadd.d t2, t1, (t0) # Fetch count and increment memory copy by 2
    fence

    li t1, 255
    amoand.d t0, t1, (t0) # Mask off memory copy as well
    fence

    andi t2, t2, 255 # Limit range

    slli t2, t2, 3
    la t0, pro_in
    add t0, t0, t2

    or t3, ra, t3                   # Record where we were called from as well
    sd t3, (t0)
    slli t5, t5, 32
    csrr t3, mhartid
    or t5, t5, t3
    sd t5, 8(t0)                    # Record time stamp
#endif
#if defined(DBG_ANNO_2H)
    csrr t1, mhartid                # Get current hart id
    add t1, t1, -1                  # Remove e51 from the picture
    la t6, 0x201220a0
    li t5, DBG_PROTECT
    sll t5, t5, t1
    sw t5, 4(t6)
#endif

    ret

_get_protection:
    li t4, 1                      # Flag set value

#if defined(DBG_ANNO_2H)
    li t5, DBG_PROTECTION
    sll t5, t5, t1
    la t6, 0x201220a0
#endif

    fence
    amoswap.d.aq t3, t4, (t2)
    fence
    bnez t3, _retry                 # Out of luck so retry
    j _got_protection        # Got it!

_retry:                             # Circling back for another try
    csrrs x0, mstatus, a0           # Restore interrupt state
    #
    # wfi?
    #

#if defined(DBG_ANNO_2H)
    li t5, DBG_PROTECT
    sll t5, t5, t1
    sw t5, 4(t6)
    sw t5, (t6)
    sw t5, (t6)
    sw t5, 4(t6)
    sw t5, (t6)
#endif

    j _tx_thread_smp_protect
//    j _restart


_oops:
    nop
    nop
    j _oops


_oops2:
#if defined(DBG_ANNO_2H)
    li t4, DBG_TRIGGER
    la t6, 0x201220a0
    sw t4, (t6)
    sw t4, 4(t6)
    sw t4, (t6)
    csrr t1, mhartid                # Get current hart id
    add t1, t1, -1                  # Remove e51 from the picture
    li t5, DBG_TRIG_SRC
    sll t5, t5, t1
    sw t5, (t6)
#endif

_oops_loop:
    nop
    nop
    j _oops_loop

