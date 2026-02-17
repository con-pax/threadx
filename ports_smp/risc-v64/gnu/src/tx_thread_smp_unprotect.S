/***************************************************************************
 * Copyright (c) 2026 Microchip FPGA Embedded Systems Solutions.
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
/*    _tx_thread_smp_unprotect                                            */
/*                                                           6.2.1        */
/*  AUTHOR                                                                */
/*                                                                        */
/*    Peter Mc Shane, Microchip FPGA Embedded Systems Solutions.          */
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
/*  27-01-2026      Peter Mc Shane           Initial Version 6.2.1   ?    */
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

    la t2, _tx_thread_smp_protection    # The protect in force flag is ULONG which is 32 bit
    lw t3, TX_PR_OWN(t2)                # Fetch protection owner
    bne t1, t3, _did_unpro              # Not us...

    lw t3, TX_PR_CNT(t2)                # It's ours but is it already 0?
    beqz t3, _did_unpro                 # Yes so bail out

    addi t3, t3, -1                     # Decrement the count
    sw t3, TX_PR_CNT(t2)

    bnez t3, _did_unpro                 # Bail if count not yet 0

    la t4, _tx_thread_preempt_disable
    lwu t4, (t4)
    bnez t4, _did_unpro                 # Bail if pre-emption is disabled

    li t3, 0xFFFFFFFF                   # Invalidate the owner field
    sw t3, TX_PR_OWN(t2)
    fence

    amoswap.d.rl x0, x0, (t2)           # Clear protection field

_did_unpro:
    csrrs x0, mstatus, a0           # Restore previous interrupt state
    ret
