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
/*    _tx_thread_smp_current_state_get                                    */
/*                                                           6.2.1        */
/*  AUTHOR                                                                */
/*                                                                        */
/*    Peter Mc Shane, Microchip FPGA Embedded Systems Solutions.          */
/*                                                                        */
/*  DESCRIPTION                                                           */
/*                                                                        */
/*    This function is gets the current state of the calling core.        */
/*                                                                        */
/*  INPUT                                                                 */
/*                                                                        */
/*    None                                                                */
/*                                                                        */
/*  OUTPUT                                                                */
/*                                                                        */
/*    The current state for this Hart                                                                */
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

    // TBD, all the other implementations disable interrupts for this but
    // I'm not sure why. It's a single 32 bit fetch so why would it matter
    // if ints are enabled or disabled? A lot of them disable at the start
    // of the function and enable at the end but that just extends the
    // interrupt disable period without adding any additional protection which
    // seems a waste...
    //
    // Actually, the reason ints are disabled for longer is because it is
    // beacause thread code can get switched between cores and the code might
    // start on one core and end on another and so give the wrong result if not
    // fully protected. This also applies to RTOS code being executed in thread
    // context so you need to be very careful...

    .globl  _tx_thread_smp_current_state_get
_tx_thread_smp_current_state_get:
    csrrci t0, mstatus, 0x8         # Save current interrupt enable state and disable ints
    csrr t1, mhartid
#if defined(CONFIG_TARGET_MPFSOC)
// MPFSoC has the e51 as hart 0 and the 4 x U54s as harts 1 to 4
// for SMP we are only operating on the U54s so we need to adjust back to
// 0 based core number
    add t1, t1, -1
#endif
    la t2, _tx_thread_system_state
    slli t1, t1, 2                  # Convert to 32 bit int offset as it is array of ULONG
    add t2, t2, t1                  # Add to base of array
    lw a0, (t2)                     # fetch state - ULONG which is 32 bits
    andi t0, t0, 0x8
    csrs mstatus, t0                # Restore interrupt state
    ret
