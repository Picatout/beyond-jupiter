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

  .syntax unified
  .cpu cortex-m4
  .fpu softvfp 
  .thumb

  .include "stm32f411ce.inc"
  .include "tvout.inc"

  .equ FCLK, 96000000
  .equ FHORZ, 15734 
  .equ HPER,(FCLK/FHORZ-1)
  .equ SYNC_LINE,(FCLK/(2*FHORZ)-1)
  .equ HPULSE, (FCLK/1000000*47/10 -1) // 4.7µS
  .equ SERRATION,(FCLK/1000000*23/10-1) // 2.3µS
  .equ VSYNC_PULSE,(FCLK/1000000*271/10-1)  // 27.1µs
  .equ LEFT_MARGIN, (750) 
  .equ VIDEO_FIRST_LINE, 40
  .equ VIDEO_LAST_LINE, (VIDEO_FIRST_LINE+VRES)
  .equ VIDEO_DELAY,(FCLK/1000000*14-1) // 14µSec
  .equ VIDEO_END, (FCLK/1000000*62-1) // 62µSec

// video state 
  .equ ST_VSYNC, 0 
  .equ ST_PREVID,1 
  .equ ST_VIDEO,2 
  .equ ST_POSTVID,3    
// field 
   .equ ODD_FIELD,0 
   .equ EVEN_FIELD,-1

/*******************************************************
NOTES:
 1) Values computed for a 96Mhz sysclock 
 2) Video sync output on PB1 use T3_CH4
 3) video out trigger TIMER3 CH3 
********************************************************/

/**************************************
  initialize TIMER3 CH4 to generate tv_out
  synchronization signal.
**************************************/ 
  _GBL_FUNC tv_init
// configure PA0:3 as OUTPUT_OD 
  _MOV32 r0,GPIOA_BASE_ADR 
  ldr r1,[r0,#GPIO_MODER]
  mov r2,#0x55
  orr r1,r2
  str r1,[r0,#GPIO_MODER]
  eor r1,r1 
  str r1,[r0,#GPIO_ODR]  
// configure PB1 as OUTPUT_AFPP 
// this is TIM3_CC4 output compare 
  add r0,#0x400 // GPIOB_BASE_ADR
  mov r1,#1 // pin 1 
  mov r2,#OUTPUT_AFPP // mode+type  
  _CALL gpio_config 
  mov r1,#1 
  mov r2,#2
  _CALL gpio_speed 
//  mov r2,#(2<<4) // alternate function 2 on BP1==TIM3_CH4 
  ldr r1,[r0,#GPIO_AFRL]
  orr r1,#(2<<4) // r2 
  str r1,[r0,#GPIO_AFRL]
// enable peripheral clock 
  _MOV32 r2,RCC_BASE_ADR 
  mov r0,#2 
  ldr r1,[r2,#RCC_APB1ENR]
  orr r1,r0 
  str r1,[r2,#RCC_APB1ENR]
// configure TIMER3   
  _MOV32 r2,TIM3_BASE_ADR
  mov r0,#HPER
  str r0,[r2,#TIM_ARR]
  mov r0,#VIDEO_DELAY 
  str r0,[r2,#TIM_CCR3]
  mov r0,#HPULSE 
  str r0,[r2,#TIM_CCR4]  
  mov r0,#(7<<12)+(7<<4)
  str r0,[r2,#TIM_CCMR2]
  mov r0,#(1<<12)+(1<<8)
  str r0,[r2,#TIM_CCER]
  mov r0,#1 
  str r0,[r2,#TIM_DIER]
  str r0,[r2,#TIM_CR1] //CEN 
// enable interrupt in NVIC controller 
  mov r0,#TIM3_IRQ 
  mov r1,#2
  _CALL nvic_set_priority
  mov r0,#TIM3_IRQ 
  _CALL nvic_enable_irq
  _RET

/*************************************
  TIMER3 interrupt for tv_out
  T1 line # 
  T0 TIM3_BASE_ADR 
*************************************/
  _GBL_FUNC tv_out_isr
  _MOV32 T0,TIM3_BASE_ADR
  eor T1,T1
  str T1,[T0,#TIM_SR]
  ldr T1,[UP,#VID_CNTR]
  add T1,#1 
  str T1,[UP,#VID_CNTR]
/** machine state cases **/
  ldr T2,[UP,#VID_STATE]
  cmp T2,#ST_VSYNC 
  beq state_vsync
  cmp T2,#ST_PREVID 
  beq state_pre_video 
  cmp T2,#ST_VIDEO 
  beq state_video_out 
  cmp T2,#ST_POSTVID 
  beq state_post_video
  b default_handler // invalid state 
/*** vertical sync state **/
state_vsync:
  cmp T1,#1
  bne 1f 
/****** set vertical pre-sync  *****/
  mov T1,#SERRATION
  str T1,[T0,#TIM_CCR4]
  mov T1,#SYNC_LINE 
  str T1,[T0,#TIM_ARR]
  b tv_isr_exit 
1: cmp T1,#7
  bne 2f 
// vertical sync pulse   
  mov T1,#VSYNC_PULSE
  str T1,[T0,#TIM_CCR4]
  b tv_isr_exit
2: cmp T1,#13
   bne 3f  
// set vertical post-sync    
   mov T1,#SERRATION 
   str T1,[T0,#TIM_CCR4]
   b tv_isr_exit   
3: cmp T1,#18
   bne 4f 
// if even field full line  
   ldr T1,[UP,#VID_FIELD]
   cmp T1,#ODD_FIELD  
   beq tv_isr_exit 
   b sync_end 
4: cmp T1,#19 
   bne tv_isr_exit
sync_end: 
   mov T1,#9
   str T1,[UP,#VID_CNTR]
   mov T1,#HPULSE 
   str T1,[T0,#TIM_CCR4] 
   mov T1,#HPER 
   str T1,[T0,#TIM_ARR] 
   mov T1,#ST_PREVID 
   str T1,[UP,#VID_STATE]
   b tv_isr_exit 
/*****************************/
state_pre_video:
   cmp T1,#VIDEO_FIRST_LINE
   bmi tv_isr_exit 
   mov T1,#ST_VIDEO 
   str T1,[UP,#VID_STATE]
   mov T1,#(1<<3) // CC3IE 
   str T1,[T0,#TIM_DIER]
   b tv_isr_exit 
/**************************
    VIDEO OUTPUT 
**************************/   
state_video_out:
   cmp T1,#VIDEO_LAST_LINE 
   bls 1f 
   mov T1,#ST_POSTVID 
   str T1,[UP,#VID_STATE]
   mov T1,#1 
   str T1,[T0,#TIM_DIER]
   b tv_isr_exit 
1: // video output
   ldr T0,[UP,#VID_BUFFER]
   sub T1,#(VIDEO_FIRST_LINE+1) 
   mov T3,#160
   mul T1,T3 
   add T0,T1  
   _MOV32 T1,GPIOA_BASE_ADR 
2: ldrb T2,[T0]
   lsr T2,#4 
   str T2,[T1,#GPIO_ODR]
   nop.w
   nop.w 
   ldrb T2,[T0],#1
   and T2,#15 
   str T2,[T1,#GPIO_ODR]
   nop.w
   nop.w  
   subs T3,#1
   bne 2b  
   mov T2,#(15<<16) 
   str T2,[T1,#GPIO_BSRR]
   b tv_isr_exit 
state_post_video:
   mov T2,#262
   cmp T1,T2
   bmi tv_isr_exit     
// odd field line 262 half line 
   ldr T1,[UP,VID_FIELD]
   cbnz T1, frame_end 
   mov T1,#SYNC_LINE
   str T1,[T0,#TIM_ARR]      
frame_end: 
   mov T1,#ST_VSYNC 
   str T1,[UP,#VID_STATE]
   eor T1,T1 
   str T1,[UP,#VID_CNTR]
   ldr T1,[UP,#VID_FIELD]
   mvn T1,T1  
   str T1,[UP,#VID_FIELD]
tv_isr_exit: 
   _RET   


/***************************
    FORTH WORDS 
***************************/
    .equ LINK, 0 

// BACK-COLOR ( -- a )
//   back color variable 
   _HEADER BACKCOLOR,10,"BACK-COLOR" 
	_PUSH 
	ADD TOS,UP,#BK_COLOR
	_NEXT

// PEN-COLOR ( -- a )
// pen color variable 
  _HEADER PENCOLOR,9,"PEN-COLOR"
	_PUSH 
	ADD TOS,UP,#PEN_COLOR
	_NEXT 

// COLUMN ( -- a )
// cursor column variable 
  _HEADER COLUMN,6,"COLUMN"
  _PUSH 
  ADD TOS,UP,#COL 
  _NEXT 

// ROW ( -- a )
// cursor row 
  _HEADER CURSOR_ROW,3,"ROW"
  _PUSH 
  ADD TOS,UP,#ROW 
  _NEXT 

// ROW>Y ( n1 - n2 )
// convert cursor row to y coord 
  _HEADER ROWY,5,"ROW>Y"
  mov T0,#CHAR_HEIGHT
  mul TOS,T0 
  _NEXT 

// COL>X ( n1 -- n2 )
// convert cursor column to x coord 
  _HEADER COLX,5,"COL>X" 
  mov T0,#CHAR_WIDTH 
  mul TOS,T0 
  _NEXT 

// FONT ( -- a )
// return address of font table
  _HEADER FONT,4,"FONT" 
  _PUSH 
  ldr TOS,=font_6x8 
  _NEXT 

// VIDBUFF ( -- a )
// address of video buffer 
  _HEADER VIDBUFF,7,"VIDBUFF"
  _PUSH 
  LDR TOS,[UP,#VID_BUFFER]
  _NEXT 


// PLOT ( x y op -- )
// draw a pixel 
//    0 back color 
//    1 pen color 
//    2 invert (invert color pixels )
//    3 xor pen color  
    _HEADER PLOT,4,"PLOT"
// compute video buffer byte address from coords
    ldmfd DSP!,{T0,T1} // T0=y,T1=x 
    mov T2,#BPR // bytes per row  
    mul T0,T2 
    lsr T2,T1,#1 // 2 pixels per byte  
    add T0,T2 
    ldr T3,[UP,#VID_BUFFER] 
    add T3,T0 // T3 -> byte address 
    ldrb WP,[T3] // byte in buffer, 2 pixels 
    mov T2,#15 // AND mask 
    tst T1,#1 
    beq 1f 
    lsl T2,#4 // mask out low nibble for odd pixel  
1:  ldr T0,=plot_op 
    tbb [T0,TOS]
op_back:
    and WP,T2 // mask out nibble 
    ldrb T0,[UP,#BK_COLOR]
    tst T1,#1 
    bne 1f 
    lsl T0,#4 // high nibble  
1:  orr WP,T0  
    strb WP,[T3]
    b 9f 
op_pen: 
    and WP,T2 
    ldrb T0,[UP,#PEN_COLOR]
    tst T1,#1
    bne 1f 
    lsl T0,#4 // even pixel high nibble 
1:	orr WP,T0 
    strb WP,[T3]
    b 9f 
op_invert:
    eor WP,T2 
    strb WP,[T3]
    b 9f 
op_xor:
    ldr T0,[UP,#PEN_COLOR]
    tst T1,#1 
    bne 1f 
    lsl T0,#4 
1:  eor WP,T0 
    strb WP,[T3]
9:  _POP 
    _NEXT 

plot_op: .byte 0, (op_pen-op_back)/2,(op_invert-op_back)/2,(op_xor-op_back)/2


// VSYNC ( -- )
// wait vertical sync phase 
    _HEADER VSYNC,5,"VSYNC"
1:  ldr T0,[UP,#VID_CNTR]
    cmp T0,#0
    bne 1b
    _NEXT 

// CLS ( -- )
// clear TV screen 
    _HEADER CLS,3,"CLS"
    eor T0,T0 
    ldrb T1,[UP,#BK_COLOR]
    orr T0,T1 
    lsl T1,#4 
    orr T0,T1 
    lsl T1,T0,#8 
    orr T0,T1 
    lsl T1,T0,#16
    orr T0,T1 
    mov T1,#VIDEO_BUFFER_SIZE-4   
    ldr T2,[UP,#VID_BUFFER]
1:	str T0,[T2,T1]
    subs T1,#4
    bne 1b
    str T0,[T2]
    eor T0,T0 
    str T0,[UP,#ROW]
    str T0,[UP,#COL]
    _NEXT 


// CLRLINE ( n -- )
// clear text line 
  _HEADER CLRLINE,7,"CLRLINE"
  _NEST
  _DOLIT (BPR*CHAR_HEIGHT)
  _ADR DUPP  
  _ADR TOR 
  _ADR STAR
  _ADR VIDBUFF
  _ADR PLUS
  _ADR RFROM   
  _DOLIT 0 
  _ADR FILL 
  _UNNEST 

// SCROLLUP ( -- )
// scroll up tv screen 1 char height 
  _HEADER SCROLLUP,8,"SCROLLUP"
  _NEST 
  _ADR VIDBUFF 
  _ADR DUPP 
  _DOLIT BPR*CHAR_HEIGHT 
  _ADR DUPP 
  _ADR TOR 
  _ADR PLUS 
  _ADR SWAP 
  _DOLIT VIDEO_BUFFER_SIZE 
  _ADR RFROM  
  _ADR SUBB 
  _ADR MOVE
  _DOLIT 24 
  _ADR CLRLINE 
  _UNNEST 

//  RIGHT ( -- )
// move cursor 1 char. right 
  _HEADER RIGHT,5,"RIGHT"
  ldr T0,[UP,#COL]
  add T0,#1
  cmp T0,#53
  bpl TVCR  
  str T0,[UP,#COL]
  _NEXT 


// TV-CR 
// carriage return line feed 
  _HEADER TVCR,5,"TV-CR"
  eor T0,T0 
  str T0,[UP,#COL]
  ldr T0,[UP,#ROW]
  cmp T0,#24
  beq 2f 
  add T0,#1 
  str T0,[UP,#ROW]
  _NEXT 
2:_CALL_COLWORD 3f 
3: 
  _ADR SCROLLUP 
  _UNNEST  


// extract font pixel 
FONT_PIXEL: // ( r -- 0|1 )
    mov T0,#128 
    and TOS,T0 
    lsr TOS,#7
    _NEXT 

// increment x coord 
INCR_X: // ( x y -- x' y )
  ldr T0,[DSP]
  add T0,#1 
  str T0,[DSP]
  _NEXT 

// shift font row data
NEXT_PIXEL:
    lsl TOS,#1
    _NEXT 


// CHAR_ROW 
// plot character row 
// {x y r -- }
//  _HEADER CHAR_ROW,7,"CHARROW"
CHAR_ROW:  
    _NEST 
    _DOLIT 5 
    _ADR TOR 
1:  _ADR TOR 
    _ADR DDUP 
    _ADR RAT
    _ADR FONT_PIXEL  // {x y x y 0|1 }
    _ADR PLOT 
    _ADR INCR_X 
    _ADR RFROM 
    _ADR NEXT_PIXEL
    //_DOLIT 1 
    //_ADR LSHIFT 
    _DONXT 1b
    _ADR TDROP 
    _UNNEST 


CHAR_FONT: // ( c -- c-adr )
   sub TOS,#32
   mov T0,#8 
   mul TOS,T0 
   ldr T0,=font_6x8
   add TOS,T0 
   _NEXT 

/**********************************
   TV-PUTC ( c -- )
   draw character in video buffer
**********************************/
    _HEADER TVPUTC,7,"TV-PUTC"
    _NEST 
    _ADR CHAR_FONT 
    _ADR COLUMN 
    _ADR AT
    _ADR COLX  // x coord 
    _ADR CURSOR_ROW 
    _ADR AT    
    _ADR ROWY  // {c-adr x y -- } 
    _ADR ROT  // TEST 
    _DOLIT 7   
    _ADR TOR  
1:  _ADR TOR  // { x y }
    _ADR DDUP  // { x y x y }
    _ADR RAT 
    _ADR CAT   // { x y x y r }
    _ADR CHAR_ROW 
    _ADR ONEP // {x y' }
    _ADR RFROM 
    _ADR ONEP // {x y' c-adr' }
    _DONXT 1b
    _ADR TDROP  
    _ADR RIGHT
    _UNNEST  

// PRINT ( cstr -- )
// print counted string 
    _HEADER PRINT,5,"PRINT"
    _NEST 
    _ADR COUNT 
    _ADR ONEM 
    _ADR TOR 
1:  _ADR DUPP 
    _ADR CAT 
    _ADR TVPUTC 
    _ADR ONEP 
    _DONXT 1b 
    _ADR DROP 
    _UNNEST 

// CURPOS ( line col -- )
// set text cursor position 
    _HEADER CURPOS,6,"CURPOS"
    cmp TOS,#53
    bmi 1f 
    mov TOS,#52
1:  str TOS,[UP,#COL]
    _POP
    cmp TOS,#25
    bmi 1f 
    mov TOS,#24 
1:  str TOS,[UP,#ROW]
    _POP 
    _NEXT 

// INPUT ( -- c-adr )
// input a string in pad 
    _HEADER INPUT,5,"INPUT"
    _NEST 
    _ADR PAD 
    _ADR DUPP 
    _ADR ONEP 
    _DOLIT 53
    _ADR ACCEP
    _ADR SWAP 
    _ADR DROP 
    _ADR OVER 
    _ADR CSTOR  
    _UNNEST 


	.section .rodata 
	.p2align 2
/********************************************
    TV font  ASCII 6 pixels x 8 pixels 
********************************************/
font_6x8:
.byte 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 // espace
.byte 0x20,0x20,0x20,0x20,0x20,0x00,0x20,0x00 // !
.byte 0x50,0x50,0x50,0x00,0x00,0x00,0x00,0x00 // "
.byte 0x50,0x50,0xF8,0x50,0xF8,0x50,0x50,0x00 // #
.byte 0x20,0x78,0xA0,0x70,0x28,0xF0,0x20,0x00 // $
.byte 0xC0,0xC8,0x10,0x20,0x40,0x98,0x18,0x00 // %
.byte 0x60,0x90,0xA0,0x40,0xA8,0x90,0x68,0x00 // &
.byte 0x60,0x20,0x40,0x00,0x00,0x00,0x00,0x00 // '
.byte 0x10,0x20,0x40,0x40,0x40,0x20,0x10,0x00 // (
.byte 0x40,0x20,0x10,0x10,0x10,0x20,0x40,0x00 // )
.byte 0x00,0x20,0xA8,0x70,0xA8,0x20,0x00,0x00 // *
.byte 0x00,0x20,0x20,0xF8,0x20,0x20,0x00,0x00 // +
.byte 0x00,0x00,0x00,0x00,0x60,0x20,0x40,0x00 // ,
.byte 0x00,0x00,0x00,0xF0,0x00,0x00,0x00,0x00 // -
.byte 0x00,0x00,0x00,0x00,0x00,0x60,0x60,0x00 // .
.byte 0x00,0x08,0x10,0x20,0x40,0x80,0x00,0x00 // /
.byte 0x70,0x88,0x98,0xA8,0xC8,0x88,0x70,0x00 // 0
.byte 0x20,0x60,0x20,0x20,0x20,0x20,0xF8,0x00 // 1
.byte 0x70,0x88,0x10,0x20,0x40,0x80,0xF8,0x00 // 2
.byte 0xF0,0x08,0x08,0xF0,0x08,0x08,0xF0,0x00 // 3
.byte 0x10,0x30,0x50,0x90,0xF8,0x10,0x10,0x00 // 4
.byte 0xF8,0x80,0x80,0xF0,0x08,0x08,0xF0,0x00 // 5
.byte 0x30,0x40,0x80,0xF0,0x88,0x88,0x70,0x00 // 6
.byte 0xF8,0x08,0x10,0x20,0x40,0x40,0x40,0x00 // 7
.byte 0x70,0x88,0x88,0x70,0x88,0x88,0x70,0x00 // 8
.byte 0x70,0x88,0x88,0x70,0x08,0x08,0x70,0x00 // 9
.byte 0x00,0x60,0x60,0x00,0x60,0x60,0x00,0x00 // :
.byte 0x00,0x60,0x60,0x00,0x60,0x20,0x40,0x00 // ;
.byte 0x10,0x20,0x40,0x80,0x40,0x20,0x10,0x00 // <
.byte 0x00,0x00,0xF8,0x00,0xF8,0x00,0x00,0x00 // =
.byte 0x40,0x20,0x10,0x08,0x10,0x20,0x40,0x00 // >
.byte 0x70,0x88,0x08,0x10,0x20,0x00,0x20,0x00 // ?
.byte 0x70,0x88,0x08,0x68,0xA8,0xA8,0x70,0x00 // @
.byte 0x70,0x88,0x88,0xF8,0x88,0x88,0x88,0x00 // A
.byte 0xF0,0x88,0x88,0xF0,0x88,0x88,0xF0,0x00 // B
.byte 0x78,0x80,0x80,0x80,0x80,0x80,0x78,0x00 // C
.byte 0xF0,0x88,0x88,0x88,0x88,0x88,0xF0,0x00 // D
.byte 0xF8,0x80,0x80,0xF8,0x80,0x80,0xF8,0x00 // E
.byte 0xF8,0x80,0x80,0xF8,0x80,0x80,0x80,0x00 // F
.byte 0x78,0x80,0x80,0xB0,0x88,0x88,0x70,0x00 // G
.byte 0x88,0x88,0x88,0xF8,0x88,0x88,0x88,0x00 // H
.byte 0x70,0x20,0x20,0x20,0x20,0x20,0x70,0x00 // I
.byte 0x78,0x08,0x08,0x08,0x08,0x90,0x60,0x00 // J
.byte 0x88,0x90,0xA0,0xC0,0xA0,0x90,0x88,0x00 // K
.byte 0x80,0x80,0x80,0x80,0x80,0x80,0xF8,0x00 // L
.byte 0x88,0xD8,0xA8,0x88,0x88,0x88,0x88,0x00 // M
.byte 0x88,0x88,0xC8,0xA8,0x98,0x88,0x88,0x00 // N
.byte 0x70,0x88,0x88,0x88,0x88,0x88,0x70,0x00 // O
.byte 0xF0,0x88,0x88,0xF0,0x80,0x80,0x80,0x00 // P
.byte 0x70,0x88,0x88,0x88,0xA8,0x98,0x78,0x00 // Q
.byte 0xF0,0x88,0x88,0xF0,0xA0,0x90,0x88,0x00 // R
.byte 0x78,0x80,0x80,0x70,0x08,0x08,0xF0,0x00 // S
.byte 0xF8,0x20,0x20,0x20,0x20,0x20,0x20,0x00 // T
.byte 0x88,0x88,0x88,0x88,0x88,0x88,0x70,0x00 // U
.byte 0x88,0x88,0x88,0x88,0x88,0x50,0x20,0x00 // V
.byte 0x88,0x88,0x88,0xA8,0xA8,0xD8,0x88,0x00 // W
.byte 0x88,0x88,0x50,0x20,0x50,0x88,0x88,0x00 // X
.byte 0x88,0x88,0x88,0x50,0x20,0x20,0x20,0x00 // Y
.byte 0xF8,0x10,0x20,0x40,0x80,0x80,0xF8,0x00 // Z
.byte 0x60,0x40,0x40,0x40,0x40,0x40,0x60,0x00 // [
.byte 0x00,0x80,0x40,0x20,0x10,0x08,0x00,0x00 // '\'
.byte 0x18,0x08,0x08,0x08,0x08,0x08,0x18,0x00 // ]
.byte 0x20,0x50,0x88,0x00,0x00,0x00,0x00,0x00 // ^
.byte 0x00,0x00,0x00,0x00,0x00,0x00,0xF8,0x00 // _
.byte 0x40,0x20,0x10,0x00,0x00,0x00,0x00,0x00 // `
.byte 0x00,0x00,0x70,0x08,0x78,0x88,0x78,0x00 // a
.byte 0x80,0x80,0x80,0xB0,0xC8,0x88,0xF0,0x00 // b
.byte 0x00,0x00,0x70,0x80,0x80,0x88,0x70,0x00 // c
.byte 0x08,0x08,0x08,0x68,0x98,0x88,0x78,0x00 // d
.byte 0x00,0x00,0x70,0x88,0xF8,0x80,0x70,0x00 // e
.byte 0x30,0x48,0x40,0xE0,0x40,0x40,0x40,0x00 // f
.byte 0x00,0x00,0x78,0x88,0x88,0x78,0x08,0x70 // g
.byte 0x80,0x80,0xB0,0xC8,0x88,0x88,0x88,0x00 // h
.byte 0x00,0x20,0x00,0x20,0x20,0x20,0x20,0x00 // i
.byte 0x10,0x00,0x30,0x10,0x10,0x90,0x60,0x00 // j
.byte 0x80,0x80,0x90,0xA0,0xC0,0xA0,0x90,0x00 // k
.byte 0x60,0x20,0x20,0x20,0x20,0x20,0x70,0x00 // l
.byte 0x00,0x00,0xD0,0xA8,0xA8,0x88,0x88,0x00 // m
.byte 0x00,0x00,0xB0,0xC8,0x88,0x88,0x88,0x00 // n
.byte 0x00,0x00,0x70,0x88,0x88,0x88,0x70,0x00 // o
.byte 0x00,0x00,0xF0,0x88,0x88,0xF0,0x80,0x80 // p
.byte 0x00,0x00,0x68,0x90,0x90,0xB0,0x50,0x18 // q
.byte 0x00,0x00,0xB0,0xC8,0x80,0x80,0x80,0x00 // r
.byte 0x00,0x00,0x70,0x80,0x70,0x08,0xF0,0x00 // s
.byte 0x40,0x40,0xE0,0x40,0x40,0x48,0x30,0x00 // t
.byte 0x00,0x00,0x88,0x88,0x88,0x98,0x68,0x00 // u
.byte 0x00,0x00,0x88,0x88,0x88,0x50,0x20,0x00 // v
.byte 0x00,0x00,0x88,0x88,0xA8,0xA8,0x50,0x00 // w
.byte 0x00,0x00,0x88,0x50,0x20,0x50,0x88,0x00 // x
.byte 0x00,0x00,0x88,0x88,0x88,0x78,0x08,0x70 // y
.byte 0x00,0x00,0xF8,0x10,0x20,0x40,0xF8,0x00 // z
.byte 0x20,0x40,0x40,0x80,0x40,0x40,0x20,0x00 // {
.byte 0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x00 // |
.byte 0x40,0x20,0x20,0x10,0x20,0x20,0x40,0x00 // }
.byte 0x00,0x00,0x40,0xA8,0x10,0x00,0x00,0x00 // ~
.byte 0xFC,0xFC,0xFC,0xFC,0xFC,0xFC,0xFC,0xFC // 95 rectangle
.byte 0x40,0x20,0x10,0xF8,0x10,0x20,0x40,0x00 // 96 right arrow
.byte 0x10,0x20,0x40,0xF8,0x40,0x20,0x10,0x00 // 97 left arrow
.byte 0x20,0x70,0xA8,0x20,0x20,0x20,0x00,0x00 // 98 up arrrow
.byte 0x00,0x20,0x20,0x20,0xA8,0x70,0x20,0x00 // 99 down arrow
.byte 0x00,0x70,0xF8,0xF8,0xF8,0x70,0x00,0x00 // 100 circle 
