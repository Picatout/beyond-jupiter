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

  .section  .text, "ax", %progbits 

  .include "mcSaite.inc"

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
    // keyboard state flags 
    .equ KBD_PAR_ERR,(1<<0)     // parity error 
    .equ KBD_FRAME_ERR,(1<<1)   // frame error 
    .equ KBD_CAPSLK,(1<<2) // capslock 
    .equ KBD_SHIFT,(1<<3)  // shift down
    .equ KBD_CTRL,(1<<4)   // ctrl down 
    .equ KBD_ALT,(1<<5)    // alt down
    .equ KBD_ALTCHAR,(1<<6) // altchar down 
    .equ KBD_REL,(1<<7) // key released flag 
    // structure members offset 
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


// ASYNC-KEY ( -- n )
// return async key flags 
    _HEADER ASYNC_KEY,9,"ASYNC-KEY"
    _PUSH 
    ldrb TOS,[UP,#KBD_FLAGS]
    and TOS,#0xFC  
    _NEXT 

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

// KEYCODE 
// extract keyboard scancode from queue.
// output:
//        T0  keycode | 0 
keycode: 
    push {T1,T2,T3}
    eor T0,T0  
    add T3,UP,#KBD_QUEUE
    ldr T1,[UP,#KBD_QHEAD]
    ldr T2,[UP,#KBD_QTAIL]
    cmp T1,T2 
    beq 2f  
    ldrb T0,[T3,T1]
    add T1,#1 
    and T1,#KBD_QUEUE_SIZE-1
    str T1,[UP,#KBD_QHEAD]
2:  pop {T1,T2,T3}
    _RET 

wait_code:
    _CALL keycode 
    movs T0,T0
    beq wait_code  
    _RET 

// translation table scan 
// input:
//      T0   target code 
//      T1   table pointer 
// output: 
//        T0   0 | code 
table_scan:
    push {T2}
1:  ldrb T2,[T1],#1
    cbz T2,2f 
    cmp T2,T0
    beq 2f 
    add T1,#1 
    b 1b 
2:  ldrb T0,[T1] 
9:  pop {T2}
    _RET 

// INKEY ( -- 0|key )
// get a character from keyboard
// don't wait for it.
    _HEADER INKEY,5,"INKEY"
    _PUSH 
    eor TOS,TOS 
    ldr T1,=sc_ascii // translation table
    _CALL keycode
    cbz T0,inkey_exit  
    cmp T0,#XT_KEY // extended keycode 
    beq xcode
    cmp T0,#XT2_KEY // pause 
    beq pause_key 
    cmp T0,#KEY_REL // key released
    beq released 
7:  _CALL table_scan 
    cmp T0,#VK_CLOCK
    beq inkey_exit 
    mov TOS,T0
8:  _CALL do_async_key 
    cmp T0,#255
    bne inkey_exit 
    _CALL do_modifiers
inkey_exit:     
    ldrb T0,[UP,#KBD_FLAGS]
    mvn T1,#KBD_REL 
    and T0,T1 
    strb T0,[UP,#KBD_FLAGS]
    _NEXT
pause_key: // discard next 7 codes 
    mov T1,#7 
1:  _CALL wait_code 
    subs T1,#1
    bne 1b 
    _NEXT 
xcode: // extended scancode 
    ldr T1,=extended // extended code translation table 
    _CALL wait_code
    cmp T0,#KEY_REL
    bne 7b 
released: // key released
    ldrb T0,[UP,#KBD_FLAGS]
    orr T0,#KBD_REL 
    strb T0,[UP,#KBD_FLAGS]
    _CALL wait_code 
    _CALL table_scan
    cmp T0,#VK_CLOCK
    beq toggle_capslock 
    _CALL do_async_key 
    b inkey_exit  
toggle_capslock:
// when capslock is released toggle its flag
    ldrb T0,[UP,#KBD_FLAGS]
    mov T1,#KBD_CAPSLK 
    eor T0,T1 
    strb T0,[UP,#KBD_FLAGS]
    b inkey_exit 

// check if async key 
// and process it
do_async_key:
    _CALL is_async_key  
    cmp T0,#255
    beq 9f 
// asynchornous key, set/reset flag 
set_async_key: 
    eor TOS,TOS // no key to return 
    ldrb T2,[UP,#KBD_FLAGS] 
    ldr T1,=async_jump 
    tbb [T1,T0]
shift_key:
    mov T0,#KBD_SHIFT 
    b set_reset
ctrl_key:
    mov T0,#KBD_CTRL
    b set_reset 
alt_key:
    mov T0,#KBD_ALT 
    b set_reset 
altchar_key:
    mov T0,#KBD_ALTCHAR 
set_reset:
    tst T2,#KBD_REL 
    beq 1f 
    mvn T0,T0
    and T2,T0
    b 2f
1:  orr T2,T0 
2:  strb T2,[UP,#KBD_FLAGS]
9:  _RET 

// check for modifiers flags 
// and process it.
do_modifiers:
    ldrb T0,[UP,#KBD_FLAGS]
    tst T0,#KBD_SHIFT 
    bne shift_down 
    tst T0,#KBD_ALTCHAR 
    bne altchar_down 
    tst T0,#KBD_CTRL
    b 9f 
shift_down:
    mov T0,TOS 
    ldr T1,=shifted 
    b 8f 
altchar_down:
    mov T0,TOS 
    ldr T1,=altchar
    b 8f
ctrl_down:
    mov T0,TOS 
    ldr T1,=controls 
8:  _CALL table_scan
    mov TOS,T0
9:  _CALL do_capslock 
    _RET 

do_capslock:
    ldrb T0,[UP,#KBD_FLAGS]
    tst T0,#KBD_CAPSLK 
    beq 9f 
    cmp TOS,#'A'
    bmi 9f 
    cmp TOS,#'Z'+1 
    bmi 3f 
    cmp TOS,#'a'
    bmi 9f 
    cmp TOS,#'z'+1
    bpl 9f 
3:  mov T0,#(1<<5)
    eor TOS,T0 
9:  _RET 

// check if it is an asynchronous key 
// input:
//        T0  virtual code
// output:
//        T0 code order | -1 
is_async_key:
    ldr T1,=async_keys
    b table_scan

// asynchronous key table 
async_keys:
    .byte VK_LSHIFT,0 // left shift 
    .byte VK_RSHIFT,0 // right shift 
    .byte VK_LCTRL,1  // left control 
    .byte VK_RCTRL,1  // right control 
    .byte VK_LALT,2  // left alt 
    .byte VK_RALT,3   // right alt (alt char)
    .byte 0,255 

async_jump: // tbb table for async keys 
    .byte 0 // shift  key 
    .byte (ctrl_key-shift_key)/2
    .byte (alt_key-shift_key)/2
    .byte (altchar_key-shift_key)/2

