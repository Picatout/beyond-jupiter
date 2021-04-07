/*****************************************************
*  STM32eForth version 7.20
*  Adapted to beyond Jupiter board by Picatout
*  date: 2020-11-22
*  IMPLEMENTATION NOTES:

*     Use USART1 for console I/O
*     port config: 115200 8N1 
*     TX on  PA9,  RX on PA10  
*
*     eForth is executed from flash, not copied to RAM
*     eForth use main stack R13 as return stack (thread stack not used) 
*
*     Forth return stack is at end of RAM (addr=0x200005000) and reserve 512 bytes
*     a 128 bytes flwr_buffer is reserved below rstack for flash row writing
*     a 128 bytes tib is reserved below flwr_buffer 
*     Forth dstack is below tib and reserve 512 bytes 
*   
******************************************************/

/**************************
    Forth system 
**************************/
/*
*	indirect thread model
*	  Register assignments
*	T0	 	R0 	working register 
*	T1	 	R1  working register 
*	T2	 	R2  working register  
*	UP	 	R3  variables pointer 
*	IP	 	R4	instruction pointer  
*	TOS	 	R5  top of data stack 
*	DSP	 	R6 	data stack pointer 
*	RSP	 	R7	return stack pointer 
*   T3      R8  working register 
*   T4      R9  working register 
*/

  .syntax unified
  .cpu cortex-m4
  .fpu softvfp
  .thumb

  .include "stm32f411ce.inc"
//  .include "macros.inc"


/**************************
    inner interpreter 
**************************/
NEXT:
    ldr T2,[IP],#4
    bx [T2]


