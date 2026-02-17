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

    /* place in cacheable memory to ensure atomics work properly */

    .section .l2_scratchcodetext,"ax",@progbits

/**************************************************************************/
/*                                                                        */
/*  FUNCTION                                               RELEASE        */
/*                                                                        */
/*    _tx_thread_smp_protect                                              */
/*                                                           6.2.1        */
/*  AUTHOR                                                                */
/*                                                                        */
/*    Peter Mc Shane, Microchip FPGA Embedded Systems Solutions.          */
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
/*  27-01-2026      Peter Mc Shane           Initial Version 6.2.1   ?    */
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

    la t2, _tx_thread_smp_protection # The protect in force flag is ULONG which is 32 bit
    lw t3, TX_PR_OWN(t2)             # Fetch protection owner
    bne t1, t3, _get_protection

# Fall through if we already own it
_got_protection:
    sw t1, TX_PR_OWN(t2)            # Mark it as ours

    fence
    lw t3, TX_PR_CNT(t2)                    # It's ours so update count
    addi t3, t3, 1
    sw t3, TX_PR_CNT(t2)
    fence
    ret

_get_protection:
    li t4, 1                      # Flag set value
    fence
    amoswap.d.aq t3, t4, (t2)       # Try and grab semaphore
    fence
    bnez t3, _retry                 # Out of luck so retry
    j _got_protection        # Got it!

_retry:                             # Circling back for another try
    csrrs x0, mstatus, a0           # Restore interrupt state
    #
    # wfi?
    #

    j _tx_thread_smp_protect        # Lets give it another try
