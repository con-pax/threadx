/***************************************************************************
 * Copyright 2026 Microchip FPGA Embedded Systems Solutions.
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
/**   Initialize                                                          */
/**                                                                       */
/**************************************************************************/
/**************************************************************************/

    .section .data
    .global  __tx_free_memory_start
__tx_free_memory_start:


    .section .text
/**************************************************************************/
/*                                                                        */
/*  FUNCTION                                               RELEASE        */
/*                                                                        */
/*    _tx_initialize_low_level                           RISC-V64/GNU     */
/*                                                           6.2.1        */
/*  AUTHOR                                                                */
/*                                                                        */
/*    Peter Mc Shane Microchip FPGA Embedded Systems Solutions.           */
/*                                                                        */
/*  DESCRIPTION                                                           */
/*                                                                        */
/*    This function is responsible for any low-level processor            */
/*    initialization, including setting up interrupt vectors, setting     */
/*    up a periodic timer interrupt source, saving the system stack       */
/*    pointer for use in ISR processing later, and finding the first      */
/*    available RAM memory address for tx_application_define.             */
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
/*    None                                                                */
/*                                                                        */
/*  CALLED BY                                                             */
/*                                                                        */
/*    _tx_initialize_kernel_enter           ThreadX entry function        */
/*                                                                        */
/*  RELEASE HISTORY                                                       */
/*                                                                        */
/*    DATE              NAME                      DESCRIPTION             */
/*                                                                        */
/*  27-01-2026      Peter Mc Shane          Initial Version 6.2.1         */
/*                                                                        */
/**************************************************************************/
/* VOID   _tx_initialize_low_level(VOID)
{  */
    .global  _tx_initialize_low_level
_tx_initialize_low_level:
    csrr t1, mhartid                // Get current hart id
#if defined(CONFIG_TARGET_MPFSOC)
    add t1, t1, -1                  // Remove e51 from the picture
#endif

    slli t1, t1, 3                  // Convert to 64 bit int offset as it is array of pointers
    la      t0, _tx_thread_system_stack_ptr
    add     t0, t0, t1
    sd      sp, (t0)                // Save system stack pointer

    la      t0, __l2_scratchpad_vma_end
    la      t1, _tx_initialize_unused_memory
    sd      t0, 0(t1)    // Save unused memory address

#ifdef __riscv_flen
    fscsr x0
#endif

    ret
