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
/**   Thread                                                              */
/**                                                                       */
/**************************************************************************/
/**************************************************************************/


#define CLINT_BASE  0x02000000

    .section .text

/**************************************************************************/
/*                                                                        */
/*  FUNCTION                                               RELEASE        */
/*                                                                        */
/*    _tx_thread_smp_core_preempt                    */
/*                                                           6.2.1        */
/*  AUTHOR                                                                */
/*                                                                        */
/*    Peter Mc Shane, Microchip FPGA Embedded Systems Solutions.           */
/*                                                                        */
/*  DESCRIPTION                                                           */
/*                                                                        */
/*    This function preempts the specified core in situations where the   */
/*    thread corresponding to this core is no longer ready or when the    */
/*    core must be used for a higher-priority thread. If the specified is */
/*    the current core, this processing is skipped since the will give up */
/*    control subsequently on its own.                                    */
/*                                                                        */
/*  INPUT                                                                 */
/*                                                                        */
/*    core                                  The core to preempt           */
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
/*  24-08-2025      Peter Mc Shane            Initial Version 6.2.1         */
/*                                                                        */
/**************************************************************************/
    .globl  _tx_thread_smp_core_preempt
_tx_thread_smp_core_preempt:
// This will raise an inter hart interrupt via the CLINT

#if defined(CONFIG_TARGET_MPFSOC)
// MPFSoC has the e51 as hart 0 and the 4 x U54s as harts 1 to 4
// for SMP we are only operating on the U54s so we need to adjust from
// 0 based core number
    add a0, a0, 1
#endif
    li t0, CLINT_BASE
    slli a0, a0, 2                  # Convert to 32 bit register offset
    add a0, a0, t0                  # Add to base of CLINT
    li t1, 1
    sw t1, (t0)                     # Assert inter hart interrupt
    # Do we clear it here or does the receiver clear?
    ret
