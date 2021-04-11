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
    indirect threaded model
    Register assignments
    T0	 	R0 	working register 
    T1	 	R1  working register 
    T2	 	R2  working register  
    T3      R3  working register 
    UP	 	R4  variables pointer 
    TOS	 	R5  top of data stack 
    DSP	 	R6 	data stack pointer 
    RSP	 	R7	return stack pointer 
    T4      R8  working register 
    T5      R9  working register 
    IP	 	R12	VM instruction pointer  
*/

/********************************************************
* RAM memory mapping
* 	0x20000000	RAM base address
*	0x20000000  system variables	
* 	0x20000200	user space 
* 	0x2000????	top of dictionary, HERE
* 	0x2000????	WORD buffer, HERE+16
*   0x200180FC  end of user space
*   0x20018100  video buffer 32000 bytes 
* 	0x2001FF00	top of data stack  R2
* 	0x2001FF80	TIB terminal input buffer
* 	0x2001FF80	top of return stack  R1
* 	0x20020000	top of hardware stack for interrupts R14
********************************************************/


  .syntax unified
  .cpu cortex-m4
  .fpu softvfp
  .thumb

  .include "stm32f411ce.inc"
//  .include "macros.inc"

    .section  .text, "ax", %progbits 

