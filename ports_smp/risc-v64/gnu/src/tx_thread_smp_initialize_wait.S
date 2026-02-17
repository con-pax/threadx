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

//    .section .text
    .section .l2_scratchcodetext,"ax",@progbits

/**************************************************************************/
/*                                                                        */
/*  FUNCTION                                               RELEASE        */
/*                                                                        */
/*    _tx_thread_smp_initialize_wait                                      */
/*                                                           6.2.1        */
/*  AUTHOR                                                                */
/*                                                                        */
/*    Peter Mc Shane, Microchip FPGA Embedded Systems Solutions.          */
/*                                                                        */
/*  DESCRIPTION                                                           */
/*                                                                        */
/*    This function is the place where additional cores wait until        */
/*    initialization is complete before they enter the thread scheduling  */
/*    loop.                                                               */
/*                                                                        */
/*  INPUT                                                                 */
/*                                                                        */
/*    None                                                                */
/*                                                                        */
/*  OUTPUT                                                                */
/*                                                                        */
/*    None                                                                */
/*                                                                        */
/*  CALLS                                                                 */
/*                                                                        */
/*    _tx_thread_schedule                   Thread scheduling loop        */
/*                                                                        */
/*  CALLED BY                                                             */
/*                                                                        */
/*    Hardware                                                            */
/*                                                                        */
/*  RELEASE HISTORY                                                       */
/*                                                                        */
/*    DATE              NAME                      DESCRIPTION             */
/*                                                                        */
/*  27-01-2026      Peter Mc Shane           Initial Version 6.2.1   ?    */
/*                                                                        */
/**************************************************************************/
    .globl  _tx_thread_smp_initialize_wait
_tx_thread_smp_initialize_wait:
    csrci mstatus, 0xF              # Disable interrupts until we get up and running properly

    csrr t1, mhartid                # Get current hart id
#if defined(CONFIG_TARGET_MPFSOC)
    add t1, t1, -1                  # Remove e51 from the picture
#endif

    slli t1, t1, 2                  # Convert to 32 bit int offset as it is array of ULONG
    la t2, _tx_thread_system_state
    add t2, t2, t1                  # address of _tx_thread_system_state[core]
    li t4, 0xF0F0F0F0               # This is the initialize in progress value

wait_for_initialize:
    lwu t3, (t2)
    nop                             # Empty loops may make debug difficult so pad a bit
    nop
    bne t3, t4, wait_for_initialize # Wait until we get to init stage
    la t4, _tx_thread_smp_release_cores_flag

wait_for_release:
    lwu t3, (t4)
    nop
    nop
    beqz t3, wait_for_release

    slli t1, t1, 1                  # Now convert to 64 bit int offset for array of addresses
    la t4, _tx_thread_system_stack_ptr
    add t4, t4, t1                  # Address of _tx_thread_system_stack_ptr[core]
    sd sp, (t4)                     # Save current system stack pointer

    sw x0, (t2)                     # Clear cores current state
    la t2, _tx_thread_system_state  # Reload address of _tx_thread_system_state[0]

core_0_wait:
    lwu t3, (t2)
    nop
    nop
    bnez t3, core_0_wait            # Loop until core 0 is finished init

    J _tx_thread_schedule           # Head to the scheduler

    ret                             # Should never get here...
