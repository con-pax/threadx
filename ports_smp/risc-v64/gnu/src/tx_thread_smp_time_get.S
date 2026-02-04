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

#define CLINT_BASE  0x02000000
#define CLINT_MTIME 0x0200BFF8

    .section .text

/**************************************************************************/
/*                                                                        */
/*  FUNCTION                                               RELEASE        */
/*                                                                        */
/*    _tx_thread_smp_time_get                       */
/*                                                           6.2.1        */
/*  AUTHOR                                                                */
/*                                                                        */
/*    Peter Mc Shane, Microchip FPGA Embedded Systems Solutions.           */
/*                                                                        */
/*  DESCRIPTION                                                           */
/*                                                                        */
/*    This function gets the global time value that is used for debug     */
/*    information and event tracing.                                      */
/*                                                                        */
/*  INPUT                                                                 */
/*                                                                        */
/*    None                                                                */
/*                                                                        */
/*  OUTPUT                                                                */
/*                                                                        */
/*    32-bit time stamp                                                   */
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
    .globl  _tx_thread_smp_time_get
_tx_thread_smp_time_get:
    la a0, CLINT_MTIME
    lwu a0,(a0)
    ret


    .globl  _tx_thread_smp_time_get_upper
_tx_thread_smp_time_get_upper:
    la a0, CLINT_MTIME + 4
    lwu a0,(a0)
    ret
