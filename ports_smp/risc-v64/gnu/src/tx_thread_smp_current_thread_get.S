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
/**   Thread                                                              */
/**                                                                       */
/**************************************************************************/
/**************************************************************************/

    .section .text

/**************************************************************************/
/*                                                                        */
/*  FUNCTION                                               RELEASE        */
/*                                                                        */
/*    _tx_thread_smp_current_thread_get                                   */
/*                                                           6.2.1        */
/*  AUTHOR                                                                */
/*                                                                        */
/*    Peter Mc Shane, Microchip FPGA Embedded Systems Solutions.          */
/*                                                                        */
/*  DESCRIPTION                                                           */
/*                                                                        */
/*    This function is gets the current thread of the calling core.       */
/*                                                                        */
/*  INPUT                                                                 */
/*                                                                        */
/*    None                                                                */
/*                                                                        */
/*  OUTPUT                                                                */
/*                                                                        */
/*    _tx_thread_current_ptr for the current Hart                                                                */
/*                                                                        */
/*  CALLS                                                                 */
/*                                                                        */
/*    None                                                                */
/*                                                                        */
/*  CALLED BY                                                             */
/*                                                                        */
/*    ThreadX Components                                                  */
/*                                                                        */
/*  RELEASE HISTORY                                                       */
/*                                                                        */
/*    DATE              NAME                      DESCRIPTION             */
/*                                                                        */
/*  27-01-2026      Peter Mc Shane           Initial Version 6.2.1   ?    */
/*                                                                        */
/**************************************************************************/
    .globl  _tx_thread_smp_current_thread_get
_tx_thread_smp_current_thread_get:
    csrrci t0, mstatus, 0x8         # Save current interrupt enable state and disable ints
    csrr t1, mhartid
#if defined(CONFIG_TARGET_MPFSOC)
// MPFSoC has the e51 as hart 0 and the 4 x U54s as harts 1 to 4
// for SMP we are only operating on the U54s so we need to adjust back to
// 0 based core number
    add t1, t1, -1
#endif
    la t2, _tx_thread_current_ptr
    slli t1, t1, 3                  # Convert to 64 bit int offset as its array of addresses
    add t2, t2, t1                  # Add to base of array
    ld a0, (t2)                     # fetch address
    andi t0, t0, 0x8
    csrs mstatus, t0                # Restore interrupt state
    ret
