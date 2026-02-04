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

    .section .text

/**************************************************************************/
/*                                                                        */
/*  FUNCTION                                               RELEASE        */
/*                                                                        */
/*    _tx_thread_smp_unprotect                      */
/*                                                           6.2.1        */
/*  AUTHOR                                                                */
/*                                                                        */
/*    Peter Mc Shane, Microchip FPGA Embedded Systems Solutions.           */
/*                                                                        */
/*  DESCRIPTION                                                           */
/*                                                                        */
/*    This function releases previously obtained protection. The supplied */
/*    previous SR is restored. If the value of _tx_thread_system_state    */
/*    and _tx_thread_preempt_disable are both zero, then multithreading   */
/*    is enabled as well.                                                 */
/*                                                                        */
/*  INPUT                                                                 */
/*                                                                        */
/*    Previous Status Register                                            */
/*                                                                        */
/*  OUTPUT                                                                */
/*                                                                        */
/*    None                                                                */
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
    .globl  _tx_thread_smp_unprotect
_tx_thread_smp_unprotect:
    andi a0, a0, 8                  # Only want interrupt enable bit
    csrrci t5, mstatus, 0x08        # Disable ints for safety
    csrr t1, mhartid                # Get current hart id
#if defined(CONFIG_TARGET_MPFSOC)
    add t1, t1, -1                  # Remove e51 from the picture
#endif

#if defined(DBG_ANNO_2H)
    li t5, DBG_UNPROTECT
    sll t5, t5, t1
    la t6, 0x201220a0
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
    la t2, _tx_thread_smp_protection # The protect in force flag is ULONG which is 32 bit
    lw t3, TX_PR_OWN(t2)                    # Fetch protection owner
//    bne t1, t3, _still_protected    # Not us...
    bne t1, t3, _oops5    # Not us... hard fail as looks like an unbalanced protect/unprotect
#if defined(DBG_PROT_LOG)
//debug
    slli t3,t3,8
    lw t6, TX_PR_CNT(t2)
    or t6, t3, t6 # combine owner and count
#endif
    lw t3, TX_PR_CNT(t2)                    # It's ours but is it already 0?

    beqz t3, _did_unpro
//    beqz t3, _still_protected       # Yes so bail out

   addi t3, t3, -1                 # Decrement the count
    sw t3, TX_PR_CNT(t2)
    lw t0, TX_PR_CNT(t2)

    bnez t3, _did_unpro
//    bnez t3, _still_protected       # Bail if count not yet 0

    la t4, _tx_thread_preempt_disable
    lwu t4, (t4)

    bnez t4, _did_unpro
//    bnez t3, _still_protected       # Bail if pre-emption is disabled

    li t3, 0xFFFFFFFF               # Invalidate the owner field
    sw t3, TX_PR_OWN(t2)
    fence

#if defined(DBG_PROT_LOG)
    csrr t4, mhartid
    addi t4, t4, -1
    slli t4, t4, TX_PR_SHIFT
    add t4, t2, t4
    addi t4, t4, TX_PR_FLAG
    sw x0, (t4)
    fence
#endif

#if defined(DBG_ANNO_2H)
    li t5, DBG_PROTECTION
    sll t5, t5, t1
    la t4, 0x201220a0
    sw t5, 4(t4)
#endif

    amoswap.d.rl x0, x0, (t2)           # Clear protection field

_did_unpro:
#if defined(DBG_PROT_LOG)
// Debug logging
    beqz t0, _skip1
    bnez a0, _oops # count is non zero but ints are to be enabled
_skip1: # first dw has count or 0xFFFFFFFF and RA
        # second dw has time, hart id,owner, initial count and previous mstatus ie bit,
    la t5, CLINT_MTIME
    ld t5, (t5)
    slli t3, t3, 32

    li t1, 1
    la t0, pro_out_total
    amoadd.d t2, t1, (t0) # Fetch count and increment memory copy by 1
    fence

    li t1, 2
    la t0, pro_out_count
    amoadd.d t2, t1, (t0) # Fetch count and increment memory copy by 2
    fence

    li t1, 255
    amoand.d t0, t1, (t0) # Mask off memory copy as well
    fence

    andi t2, t2, 255 # Limit range
    slli t2, t2, 3
    la t0, pro_out
    add t0, t0, t2
    or t3, ra, t3
    sd t3, (t0)
    slli t5, t5, 32
    slli t6, t6, 16
    or t5, a0, t5
    or t5, t6, t5
    csrr t6, mhartid
    slli t6, t6, 8
    or t5, t6, t5
    sd t5, 8(t0)
#endif
_still_protected:

#if defined(DBG_ANNO_2H)
    la t4, 0x201220a0
    csrr t1, mhartid
    add t1, t1, -1
    li t5, DBG_UNPROTECT
    sll t5, t5, t1
    sw t5, 4(t4)
#endif

    csrrs x0, mstatus, a0           # Restore previous interrupt state
    ret

_oops:
    nop
    nop
    j _oops

_oops5:
    nop
    nop
    j _oops5
