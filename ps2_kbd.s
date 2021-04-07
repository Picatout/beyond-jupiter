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
    byte ones; count bits to 1 
    }

flags 
   :0 -> parity error flags 
**********************************/
    .equ KBD_F_PAR_ERR,1
    .equ KBD_FLAGS,KBD_STRUCT_OFS+2 
    .equ KBD_RXSHIFT,KBD_STRUCT_OFS+1
    .equ KBD_BITCNTR,KBD_STRUCT_OFS 
    .equ KBD_ONES,KBD_STRUCT_OFS+3 

/**********************************
    kbd_isr
    interrupt service routine 
    EXTI0 connected to keyboard 
    clock signal and triggered 
    on falling edge 
**********************************/
    _GBL_FUNC kbd_isr 
    _MOV32 r2,EXTI_BASE_ADR
    mov r0,#1 
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
    ldrb r2,[UP,#KBD_RXSHIFT]
    lsr r2,#1 
    tst r0,#(1<<12) // data bit 
    beq 1f 
    orr r2,#(1<<7)
    ldrb r0,[UP,#KBD_ONES]
    add r0,#1 
    strb r0,[UP,#KBD_ONES]
1:  strb r2,[UP,#KBD_RXSHIFT]
    add r1,#1 
    strb r1,[UP,#KBD_BITCNTR]
    b 9f         
start_bit:
    add r1,#1 
    strb r1,[UP,#KBD_BITCNTR]
    eor r1,r1 
    strb r1,[UP,#KBD_RXSHIFT]
    strb r1,[UP,#KBD_ONES]
    b 9f 
parity_bit:
    ldr r1,[UP,#KBD_ONES]
    tst r0,#(1<<12)
    beq 1f 
    add r1,#1 
1:  tst r1,#1 
    bne 9f      
2: // parity error
    ldrb r1,[UP,#KBD_FLAGS]
    orr r1,#KBD_F_PAR_ERR // parity error flags 
    strb r1,[UP,#KBD_FLAGS]
    b 9f      
stop_bit:
    ldrb r1,[UP,#KBD_FLAGS]
    tst r1,#KBD_F_PAR_ERR 
    bne 9f // drop this code 
// store code in queue 
    ldr r1,[UP,#KBD_QTAIL_OFS]
    add r2,UP,#KBD_QUEUE_OFS
    ldrb r0,[UP,#KBD_RXSHIFT]
    strb r0,[r2,r1]
    add r1,#1
    and r1,#KBD_QUEUE_SIZE-1
    strb r1,[UP,#KBD_QTAIL_OFS]
    eor r0,r0 
    strh r0,[UP,#KBD_BITCNTR]
9:  _RET 
    
/**********************************
    kbd_init 
    initialize keyboard 
    PS2 clock on PA11 
    PS2 data on PA12 
**********************************/
    _GBL_FUNC kbd_init 
// configure EXTI0 on pin PA11 
   _MOV32 r2,SYSCFG_BASE_ADR
   mov r0,#11 
   str r0,[R2,#SYSCFG_EXTICR1]
// interrupt triggered on falling edge 
   _MOV32 r2,EXTI_BASE_ADR
   mov r0,#(1<<0)
   str r0,[r2,#EXTI_IMR] // enable EXTI0 
   str r0,[r2,#EXTI_FTSR] // on falling edge 
// enable interrupt EXIT0 in NVIC 
   mov r0,#(1<<6) // IRQ6
   _MOV32 r2,NVIC_BASE_ADR
   ldr r1,[r2,#NVIC_ISER0]
   orr r1,r0 
   str r1,[r2,#NVIC_ISER0]
   _RET 




