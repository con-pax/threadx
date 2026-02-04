/***************************************************************************
 * Copyright (c) 2024 Microsoft Corporation
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

#include "tx_port.h"

    .section .text
/**************************************************************************/
/*                                                                        */
/*  FUNCTION                                               RELEASE        */
/*                                                                        */
/*    _tx_thread_system_return                           RISC-V64/GNU     */
/*                                                           6.2.1        */
/*  AUTHOR                                                                */
/*                                                                        */
/*    Scott Larson, Microsoft Corporation                                 */
/*                                                                        */
/*  DESCRIPTION                                                           */
/*                                                                        */
/*    This function is target processor specific.  It is used to transfer */
/*    control from a thread back to the system.  Only a minimal context   */
/*    is saved since the compiler assumes temp registers are going to get */
/*    slicked by a function call anyway.                                  */
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
/*    ThreadX components                                                  */
/*                                                                        */
/*  RELEASE HISTORY                                                       */
/*                                                                        */
/*    DATE              NAME                      DESCRIPTION             */
/*                                                                        */
/*  03-08-2023      Scott Larson            Initial Version 6.2.1         */
/*                                                                        */
/**************************************************************************/
/* VOID   _tx_thread_system_return(VOID)
{  */
    .global  _tx_thread_system_return
_tx_thread_system_return:
    /* Save minimal context on the stack.  */

    csrrci t0, mstatus, 0x08        # Save current interrupt enable state and disable ints

#if defined(DBG_ANNO_2H)
    la t6, 0x201220a0
    csrr t4, mhartid                                    // Get current hart id
    add t4, t4, -1                                      // Remove e51 from the picture
    li t5, DBG_SYSRET
    sll t5, t5, t4
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

// debug
    ori t0, t0, 8
#if defined(__riscv_float_abi_single) || defined(__riscv_float_abi_double)
    addi    sp, sp, -29*REGBYTES                        // Allocate space on the stack - with floating point enabled
#else
    addi    sp, sp, -16*REGBYTES                        // Allocate space on the stack - without floating point enabled
#endif
    STORE   t0, 14*REGBYTES(sp)                         // Save mstatus
//debug
//    ld t0, 432(sp)
//    csrw    sscratch, t0

    /* Store floating point preserved registers.  */
#if defined(__riscv_float_abi_single)
    fsw     f8,  15*REGBYTES(sp)                        // Store fs0
    fsw     f9,  16*REGBYTES(sp)                        // Store fs1
    fsw     f18, 17*REGBYTES(sp)                        // Store fs2
    fsw     f19, 18*REGBYTES(sp)                        // Store fs3
    fsw     f20, 19*REGBYTES(sp)                        // Store fs4
    fsw     f21, 20*REGBYTES(sp)                        // Store fs5
    fsw     f22, 21*REGBYTES(sp)                        // Store fs6
    fsw     f23, 22*REGBYTES(sp)                        // Store fs7
    fsw     f24, 23*REGBYTES(sp)                        // Store fs8
    fsw     f25, 24*REGBYTES(sp)                        // Store fs9
    fsw     f26, 25*REGBYTES(sp)                        // Store fs10
    fsw     f27, 26*REGBYTES(sp)                        // Store fs11
    csrr    t0, fcsr
    STORE   t0, 27*REGBYTES(sp)                         // Store fcsr
#elif defined(__riscv_float_abi_double)
    fsd     f8,  15*REGBYTES(sp)                        // Store fs0
    fsd     f9,  16*REGBYTES(sp)                        // Store fs1
    fsd     f18, 17*REGBYTES(sp)                        // Store fs2
    fsd     f19, 18*REGBYTES(sp)                        // Store fs3
    fsd     f20, 19*REGBYTES(sp)                        // Store fs4
    fsd     f21, 20*REGBYTES(sp)                        // Store fs5
    fsd     f22, 21*REGBYTES(sp)                        // Store fs6
    fsd     f23, 22*REGBYTES(sp)                        // Store fs7
    fsd     f24, 23*REGBYTES(sp)                        // Store fs8
    fsd     f25, 24*REGBYTES(sp)                        // Store fs9
    fsd     f26, 25*REGBYTES(sp)                        // Store fs10
    fsd     f27, 26*REGBYTES(sp)                        // Store fs11
    csrr    t0, fcsr
    STORE   t0, 27*REGBYTES(sp)                         // Store fcsr
#endif

    STORE   x0,  0(sp)                                  // Solicited stack type
    STORE   x1,  13*REGBYTES(sp)                        // Save RA
    STORE   x8,  12*REGBYTES(sp)                        // Save s0
    STORE   x9,  11*REGBYTES(sp)                        // Save s1
    STORE   x18, 10*REGBYTES(sp)                        // Save s2
    STORE   x19,  9*REGBYTES(sp)                        // Save s3
    STORE   x20,  8*REGBYTES(sp)                        // Save s4
    STORE   x21,  7*REGBYTES(sp)                        // Save s5
    STORE   x22,  6*REGBYTES(sp)                        // Save s6
    STORE   x23,  5*REGBYTES(sp)                        // Save s7
    STORE   x24,  4*REGBYTES(sp)                        // Save s8
    STORE   x25,  3*REGBYTES(sp)                        // Save s9
    STORE   x26,  2*REGBYTES(sp)                        // Save s10
    STORE   x27,  1*REGBYTES(sp)                        // Save s11
//    csrr    t0, mstatus                                 // Pickup mstatus
//    STORE   t0, 14*REGBYTES(sp)                         // Save mstatus


   /* Lockout interrupts. - will be enabled in _tx_thread_schedule  */

//    csrci   mstatus, 0xF

#ifdef TX_ENABLE_EXECUTION_CHANGE_NOTIFY

    call    _tx_execution_thread_exit                   // Call the thread execution exit function
#endif
    csrr t4, mhartid                                    // Get current hart id
#if defined(CONFIG_TARGET_MPFSOC)
    add t4, t4, -1                                      // Remove e51 from the picture
#endif
    slli t4, t4, 3                                      // Convert to 64 bit address offset
    li      t0, 0x0a000000 // Debug test, are we being called on a system stack?
    ble     sp, t0, bad_addr
    la      t0, _tx_thread_current_ptr                  // Pickup address of pointer
    add     t0, t4, t0
    LOAD    t1, 0(t0)                                   // Pickup current thread pointer
    la      t2,_tx_thread_system_stack_ptr              // Pickup stack pointer address
    add     t2, t4, t2


    /* Save current stack and switch to system stack.  */
    /* _tx_thread_current_ptr -> tx_thread_stack_ptr =  SP;
    SP = _tx_thread_system_stack_ptr;  */

    sd      sp, 8(t1)                                   // Save stack pointer
    ld      sp, 0(t2)                                   // Switch to system stack
    blez sp, bad_addr
    beqz sp, bad_addr

    /* Determine if the time-slice is active.  */
    /* if (_tx_timer_time_slice[core])
    {  */

    srli    t4, t4, 1                                   // Adjust to 32 bit offset
    la      t5, _tx_timer_time_slice                    // Pickup time slice variable addr
    add     t5, t4, t4
    lw      t3, 0(t5)                                   // Pickup time slice value
    beqz    t3, _tx_thread_dont_save_ts                 // If no time-slice, don't save it

        /* Save time-slice for the thread and clear the current time-slice.  */
        /* _tx_thread_current_ptr -> tx_thread_time_slice =  _tx_timer_time_slice;
        _tx_timer_time_slice =  0;  */

    sw   t3, 36(t1)                                     // Save current time-slice for thread
    sw   x0, 0(t5)                                      // Clear time-slice variable

    /* }  */
_tx_thread_dont_save_ts:

    /* Clear the current thread pointer.  */
    /* _tx_thread_current_ptr =  TX_NULL;  */

    sd      x0, 0(t0)                                   // Clear current thread pointer

    fence
    li     t5, 1
    sw      t5, 252(t1)                                     // Set Ready flag
    fence

    /* Now clear protection. It is assumed that protection is in force whenever this routine is called.  */

    la      t1, _tx_thread_smp_protection
    la      t2, _tx_thread_preempt_disable
    sw      x0, TX_PR_CNT(t1)                           // Clear protection count
    li      t0, 0xFFFFFFFF                      // Build invalid value
//    addi    t1, t1, 8
//
//    addi    t1, t1, -8
    sw      t0,TX_PR_OWN(t1)                           // Set core to an invalid value
//    fence                                       // Ensure that accesses to shared resource have completed

//debug
    sw      x0, TX_PR_FLAG(t1)
    sw      x0, TX_PR_FLAG1(t1)
    sw      x0, TX_PR_FLAG2(t1)
    sw      x0, TX_PR_FLAG3(t1)

#if defined(DBG_ANNO_2H)
    csrr t4, mhartid
    addi t4,t4,-1
    li t5, DBG_SYSRET
    sll t5, t5, t4
    la t6, 0x201220a0
    sw t5, 4(t6)
    sw t5, (t6)
    sw t5, 4(t6)
    li t5, DBG_PROTECTION
    sll t5, t5, t4
    sw t5, 4(t6)
#endif

    amoswap.d.rl x0, x0, (t1)
    //    sd      x0, (t1)                            // Clear protection
    sw      x0, (t2)                            // Clear preempt disable flag
    fence

#if defined(DBG_ANNO_2H)
    li t5, DBG_PRE_DIS
    sw t5, (t6)
#endif

// arm does this...
//    SEV                                         // Send event to other CPUs, wakes anyone waiting on a mutex (using WFE)

//    csrw    mscratch, x1 // Debug save of ra and tp
//    csrw    sscratch, s0

    call      _tx_thread_schedule                                          // Return to thread scheduler

/* }  */


bad_addr:
    nop
    nop
    j bad_addr
