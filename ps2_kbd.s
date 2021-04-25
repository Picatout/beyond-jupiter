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

/***************************************

      PS2 KEYBOARD INTERFACE 

***************************************/


  .syntax unified
  .cpu cortex-m4
  .fpu softvfp 
  .thumb

  .include "stm32f411ce.inc"


/**********************************
  keyboard structure 

struct {
    byte bitcntr; received bit counter 
    byte rxshift; shiftin keycode 
    byte flags; flags 
    byte parity; count parity bits 
    }

flags 
   :0 -> parity error flags 
**********************************/
    .equ KBD_PAR_ERR,1
    .equ KBD_FRAME_ERR,2
    .equ KBD_FLAGS,KBD_STRUCT+2 
    .equ KBD_RXSHIFT,KBD_STRUCT+1
    .equ KBD_BITCNTR,KBD_STRUCT 
    .equ KBD_PARITY,KBD_STRUCT+3 

/**********************************
    kbd_isr
    interrupt service routine 
    EXTI0 connected to keyboard 
    clock signal and triggered 
    on falling edge 
**********************************/
    _GBL_FUNC kbd_isr 
    _MOV32 r2,EXTI_BASE_ADR
    mov r0,#(1<<11) 
    str r0,[r2,#EXTI_PR] // reset pending flag 
    _MOV32 r2,GPIOA_BASE_ADR
    ldrh r0,[r2,#GPIO_IDR]
    ldrb r1,[UP,#KBD_BITCNTR]
    cmp r1,#0 
    beq start_bit 
    cmp r1,#9 
    beq parity_bit 
    cmp r1,#10 
    beq stop_bit 
    // data bit 
    ldrb r2,[UP,#KBD_RXSHIFT]
    lsr r2,#1 
    tst r0,#(1<<12) // data bit 
    beq 1f 
    orr r2,#(1<<7)
    ldrb r0,[UP,#KBD_PARITY]
    add r0,#1 
    strb r0,[UP,#KBD_PARITY]
1:  strb r2,[UP,#KBD_RXSHIFT]
    add r1,#1 
    strb r1,[UP,#KBD_BITCNTR]
    b 9f         
start_bit:
    tst r0,#(1<<12) 
    bne 9f // not a start bit 
    add r1,#1 
    strb r1,[UP,#KBD_BITCNTR]
    eor r1,r1 
    strb r1,[UP,#KBD_RXSHIFT]
    strb r1,[UP,#KBD_PARITY]
    b 9f 
parity_bit:
    ldrb r1,[UP,#KBD_PARITY]
    tst r0,#(1<<12)
    beq 1f  
    add r1,#1 
    strb r1,[UP,#KBD_PARITY]  
1:  ldrb r1,[UP,#KBD_BITCNTR]
    add r1,#1
    strb r1,[UP,#KBD_BITCNTR]    
    b 9f      
stop_bit:
    ldrb r1,[UP,#KBD_FLAGS]
    tst r0,#(1<<12)
    beq 2f
    ldrb r1,[UP,#KBD_PARITY]
    tst r1,#1 
    beq 8f // parity error 
// store code in queue 
    ldr r1,[UP,#KBD_QTAIL]
    add r2,UP,#KBD_QUEUE
    ldrb r0,[UP,#KBD_RXSHIFT]
    strb r0,[r2,r1]
    add r1,#1
    and r1,#KBD_QUEUE_SIZE-1
    strb r1,[UP,#KBD_QTAIL]
    b 8f 
2:  // framing error 
    orr r1,#KBD_FRAME_ERR   
    strb r1,[UP,#KBD_FLAGS]
    b 8f 
8:  eor r0,r0 
    strh r0,[UP,#KBD_BITCNTR]
9:  _RET 
    
/**********************************
    kbd_init 
    initialize keyboard 
    PS2 clock on PA11 
    PS2 data on PA12 
**********************************/
    _GBL_FUNC kbd_init 
// interrupt triggered on falling edge 
   _MOV32 r2,EXTI_BASE_ADR
   mov r0,#(1<<11)
   str r0,[r2,#EXTI_IMR] // enable EXTI11 
   str r0,[r2,#EXTI_FTSR] // on falling edge 
// enable interrupt EXTI15_10_IRQ in NVIC 
   mov r0,#EXTI15_10_IRQ
   _CALL nvic_enable_irq 
   _RET 


// KEY-ERR? ( -- 0|1|2)
// report keyboard error 
    _HEADER KEYERRQ,8,"KEY-ERR?"
    _PUSH 
    ldrb TOS,[UP,#KBD_FLAGS]
    and TOS,#3 
    _NEXT     

// KEY-RST-ERR ( -- )
// reset keyboard error flags 
    _HEADER KEY_RST_ERR,11,"KEY-RST-ERR"
    ldrb T0,[UP,#KBD_FLAGS]
    and T0,#0xFC 
    strb T0,[UP,#KBD_FLAGS]
    _NEXT 

// KEYCODE ( -- c )
// extract keyboard scancode from queue.
    _HEADER KEYCODE,7,"KEYCODE"
    _PUSH
    eor TOS,TOS  
    add T3,UP,#KBD_QUEUE
    ldr T0,[UP,#KBD_QHEAD]
    ldr T1,[UP,#KBD_QTAIL]
    cmp T0,T1 
    beq 2f  
    ldrb TOS,[T3,T0]
    add T0,#1 
    and T0,#KBD_QUEUE_SIZE-1
    str T0,[UP,#KBD_QHEAD]
2:  _NEXT 

