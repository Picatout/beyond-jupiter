/**************************************************************************
 Copyright Jacques Deschênes 2021 
 This file is part of beyond-Jupiter 

     beyond-Jupiter is free software: you can redistribute it and/or modify
     it under the terms of the GNU General Public License as published by
     the Free Software Foundation, either version 3 of the License, or
     (at your option) any later version.

     beyond-Jupiter is distributed in the hope that it will be useful,
     but WITHOUT ANY WARRANTY without even the implied warranty of
     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
     GNU General Public License for more details.

     You should have received a copy of the GNU General Public License
     along with beyond-Jupiter.  If not, see <http://www.gnu.org/licenses/>.

***************************************************************************/

/**********************************
   Hardware initialization
**********************************/

  .syntax unified
  .cpu cortex-m4
  .fpu vfpv4
  .thumb

  .include "stm32f411ce.inc"
  .include "macros.inc"

/*************************************
*   interrupt service vectors table 
**************************************/
   .section  .isr_vector,"a",%progbits
  .type  isr_vectors, %object

isr_vectors:
  .word   _mstack          /* main return stack address */
  .word   reset_handler    /* startup address */
/* core interrupts || exceptions */
  .word   nmi_handler  /*  -14 NMI */
  .word   hardfault_handler  /*  -13 HardFault */
  .word   memfault_handler  /*  -12 Memory Management */
  .word   busfault_handler  /* -11 Bus fault */
  .word   usagefault_handler  /* -10 Usage fault */
  .word   0 /* -9 */
  .word   0 /* -8 */ 
  .word   0 /* -7 */
  .word   0	/* -6 */
  .word   default_handler  /* -5 SWI instruction */
  .word   default_handler  /* -4 Debug monitor */
  .word   0 /* -3 */
  .word   default_handler  /* -2 PendSV */
  .word   systick_handler  /* -1 Systick */
 irq0:  
  /* External Interrupts */
  .word      default_handler /* IRQ0, Window WatchDog  */                                        
  .word      default_handler /* IRQ1, PVD_VDM */                        
  .word      default_handler /* IRQ2, TAMPER */            
  .word      default_handler /* IRQ3, RTC  */                      
  .word      default_handler /* IRQ4, FLASH */                                          
  .word      default_handler /* IRQ5, RCC */                                            
  .word      default_handler /* IRQ6, EXTI Line0 */                        
  .word      default_handler /* IRQ7, EXTI Line1  */                          
  .word      default_handler /* IRQ8, EXTI Line2 */                          
  .word      default_handler /* IRQ9, EXTI Line3 */                          
  .word      default_handler /* IRQ10, EXTI Line4 */                          
  .word      default_handler /* IRQ11, DMA1 CH1 */                  
  .word      default_handler /* IRQ12, DMA1 CH2 */                   
  .word      default_handler /* IRQ13, DMA1 CH3 */                   
  .word      default_handler /* IRQ14, DMA1 CH4  */                   
  .word      default_handler /* IRQ15, DMA1 CH5 */                   
  .word      default_handler /* IRQ16, DMA1 CH6 */                   
  .word      default_handler /* IRQ17, DMA1 CH7 */                   
  .word      default_handler /* IRQ18, ADC1, ADC2 global interrupt */                   
  .word      0 /* IRQ19 not used */                         
  .word      0 /* IRQ20 not used */                          
  .word      0 /* IRQ21 not used */                          
  .word      0 /* IRQ22 not used */                          
  .word      default_handler /* IRQ23, External Line[9:5]s */                          
  .word      default_handler /* IRQ24, TIM1 Break and TIM9 global */         
  .word      default_handler /* IRQ25, TIM1 Update and TIM10 global */         
  .word      default_handler /* IRQ26, TIM1 Trigger and Commutation and TIM11 */
  .word      default_handler /* IRQ27, TIM1 Capture Compare */                          
  .word      default_handler /* IRQ28, TIM2 */                   
  .word      tv_out_isr /* IRQ29, TIM3 */                   
  .word      timer4_handler /* IRQ30, TIM4 */                   
  .word      default_handler /* IRQ31, I2C1 Event */                          
  .word      default_handler /* IRQ32, I2C1 Error */                          
  .word      default_handler /* IRQ33, I2C2 Event */                          
  .word      default_handler /* IRQ34, I2C2 Error */                            
  .word      default_handler /* IRQ35, SPI1 */                   
  .word      default_handler /* IRQ36, SPI2 */                   
  .word      uart_rx_handler /* IRQ37, USART1 */                   
  .word      default_handler /* IRQ38, USART2 */                   
  .word      0 /* IRQ39, not used */                   
  .word      kbd_isr /* IRQ40, External Line[15:10]s */                          
  .word      default_handler /* IRQ41, RTC Alarm , EXTI17 */                 
  .word      default_handler /* IRQ42, USB Wakeup, EXTI18 */                       
  .word      0 /* IRQ43, not used  */         
  .word      0 /* IRQ44, not used */         
  .word      0 /* IRQ45, not used  */
  .word      0 /* IRQ46, not used */                          
  .word      default_handler /* IRQ47, DMA1 CH8 */                          
  .word      0 /* IRQ48, not used  */                   
  .word      default_handler /* IRQ49, SDIO */                   
  .word      default_handler /* IRQ50, TIM5 */                   
  .word      default_handler /* IRQ51, SPI3 */                   
  .word      0 /* IRQ52, not used  */                   
  .word      0 /* IRQ53, not used */                   
  .word      0 /* IRQ54, not used */                   
  .word      0 /* IRQ55, not used  */
  .word      default_handler /* IRQ56, DMA2 CH1 */                   
  .word      default_handler /* IRQ57, DMA2 CH2 */                   
  .word      default_handler /* IRQ58, DMA2 CH3 */                   
  .word      default_handler /* IRQ59, DMA2 CH4 */ 
  .word		 default_handler /* IRQ60, DMA2 CH5 */
  .word		 0 /* IRQ61, not used */
  .word		 0 /* IRQ62, not used */
  .word		 0 /* IRQ63, not used */
  .word		 0 /* IRQ64, not used */
  .word		 0 /* IRQ65, not used */
  .word		 0 /* IRQ66, not used */
  .word		 default_handler /* IRQ67, OTG_FS */
  .word		 default_handler /* IRQ68, DMA2 CH6 */
  .word		 default_handler /* IRQ69, DMA2 CH7 */
  .word		 default_handler /* IRQ70, DMA2 CH8 */
  .word		 default_handler /* IRQ71, USART 6 */
  .word		 default_handler /* IRQ72, I2C3_EV */
  .word		 default_handler /* IRQ73, I2C3_ER */
  .word		 0 /* IRQ74, not used */
  .word		 0 /* IRQ75, not used */
  .word		 0 /* IRQ76, not used */
  .word		 0 /* IRQ77, not used */
  .word		 0 /* IRQ78, not used */
  .word		 0 /* IRQ79, not used */
  .word		 0 /* IRQ80, not used */
  .word		 fpu_exception /* IRQ81, FPU */
  .word		 0 /* IRQ82, not used */
  .word		 0 /* IRQ83, not used */
  .word		 default_handler /* IRQ84, SPI4 */
  .word		 default_handler /* IRQ85, SPI5 */
isr_end:
  .size  isr_vectors, .-isr_vectors
  .p2align 9

/*****************************************************
* default isr handler called on unexpected interrupt
*****************************************************/
   .section  .text, "ax", %progbits 
   
  .type default_handler, %function
  .p2align 2 
  .global default_handler
default_handler:
  _CALL forth_init 
  ldr IP,=dh
  b INEXT  
dh:
  _ADR PRESE
  _DOTQP 23, "exeption reboot, CFSR: "     
  _ADR CFSR 
  _ADR DUPP
  _ADR TOR 
  _DOLIT 16 
  _ADR BASE 
  _ADR STORE 
  _ADR UDOT 
  _DOTQP 8 , ", BFAR: "
  _ADR RFROM
  _DOLIT (1<<15)
  _ADR ANDD
  _QBRAN 1f
  _ADR BFAR
  _DOLIT ','
  _ADR EMIT 
  _ADR SPACE 
  _ADR UDOT 
// display fpu
1:
  _DOTQP 9 , ", FPSCR: "
  _ADR FPSCR
  _ADR UDOT 
1:
  _ADR reset_mcu 


/*********************************
   fpu exception 
*********************************/
  .type fpu_exception, %function 
  .global fpu_exception 
  .p2align 2 
fpu_exception:
  push {lr}
  mov r0,#FPU_IRQ 
  bl nvic_disable_irq 
  _PUSH 
  mov TOS,IP 
  ldr IP,=fpu_except
  b INEXT 
fpu_except:  
  _ADR CR 
  _ADR BASE 
  _ADR AT 
  _ADR TOR  
  _DOLIT 16 
  _ADR BASE 
  _ADR STORE
  _DOLIT 4 
  _ADR SUBB  
  _DOTQP 4, "IP= "
  _ADR DOT 
  _DOTQP 23 , " ,fpu exception FPSCR: "
  _ADR FPSCR 
  _ADR DUPP 
  _ADR DOT
  _ADR QDUP 
  _QBRAN 2f 
  _DOLIT ',' 
  _ADR EMIT 
  _DOLIT ' ' 
  _ADR EMIT
  _ADR DUPP 
  _DOLIT 0x10 
  _ADR ANDD
  _ADR QDUP  
  _QBRAN 1f 
  _DOLIT fpu_exceptions
  _ADR PLUS 
  _ADR AT 
  _ADR COUNT 
  _ADR TYPEE
1: _DOLIT 15 
  _ADR ANDD
  _ADR CLZ 
  _DOLIT 31 
  _ADR SWAP 
  _ADR SUBB 
  _DOLIT 2 
  _ADR LSHIFT 
  _DOLIT fpu_exceptions 
  _ADR PLUS 
  _ADR AT 
  _ADR COUNT 
  _ADR TYPEE 
2: _ADR CR 
  _DOLIT 0
  _ADR CLR_FPSCR 
  _ADR RFROM  
  _ADR BASE 
  _ADR STORE 
  _ADR exit_fpu_isr // reset_mcu 

exit_fpu_isr:
   ldr IP,=QUIT  
   _MOV32 r0,SCB_BASE_ADR
   eor r1,r1 
   str r1,[r0,#SCB_ICSR]
   mov r0,#FPU_IRQ 
   bl nvic_enable_irq 
   pop {lr}
   bx lr 


  .p2align 2 
// fpu exception 
fpu_exceptions:  .word fpu_except_invalid_op, fpu_except_div0, fpu_except_overflow, fpu_except_underflow, fpu_except_inexact

  .p2align 2 
fpu_except_invalid_op: // bit 0  
  .byte 18
  .ascii " invalid operation" 
                      
  .p2align 2 
fpu_except_div0: // bit 1 
  .byte 14 
  .ascii " division by 0" 

  .p2align 2 
fpu_except_overflow: // bit 2
  .byte 9 
  .ascii " overflow"

  .p2align 2 
fpu_except_underflow:  // bit 3 
  .byte 10
  .ascii " underflow"

  .p2align 2 
fpu_except_inexact: // bit 4 
  .byte 10 
  .ascii " inexact, "


/*********************************
  non maskable interrupt handler
  irq -14 
*********************************/
  .type nmi_handler, %function
  .p2align 2
  .global nmi_handler 
nmi_handler:
  ldr IP,=nmi_hl 
  b  INEXT
nmi_hl:
  _ADR PRESE 
  _ADR CR 
  _DOTQP  25 , "not managed nmi exception"
  _ADR CR 
  _ADR ABORT 
   

/***********************************
   hard fault handler
   irq -13
***********************************/
  .type hardfault_handler, %function
  .p2align 2
  .global hardfault_handler 
hardfault_handler:
  _MOV32 r0,RAM_END 
  mov sp,r0 
  ldr IP,=hardfault_hl 
  b INEXT
hardfault_hl:
  _ADR PRESE
  _ADR CR  
  _DOTQP  20 , "hard fault exception"
  _ADR CR 
  _ADR reset_mcu

/***********************************
   memory manager fault 
   irq -12 
************************************/
  .type memfault_handler, %function
  .p2align 2
  .global memfault_handler 
memfault_handler:
  _MOV32 r0,RAM_END 
  mov sp,r0 
  ldr IP,=memfault_hl 
  b INEXT 
memfault_hl: 
  _ADR PRESE
  _ADR CR  
  _DOTQP  33 , "memory manager exception, MMFSR: "
  _DOLIT 16 
  _ADR BASE 
  _ADR STORE   
  _ADR CFSR
  _DOLIT 255 
  _ADR ANDD 
  _ADR UDOT 
  _ADR CR 
  _ADR reset_mcu 


/************************************
   bus fault 
   irq -11 
***********************************/
  .type busfault_handler, %function
  .p2align 2
  .global busfault_handler 
busfault_handler:
  _MOV32 r0,RAM_END 
  mov sp,r0 
  ldr IP,=busfault_hl 
  b INEXT 
busfault_hl:
  _ADR PRESE
  _DOLIT 1 
  _ADR ULED 
  _DOLIT  100 
  _ADR MSEC 
  _ADR BFAR 
  _ADR CFSR 
  _ADR CR  
  _DOTQP  27 , "bus fault exception, BFSR: "
  _DOLIT 16 
  _ADR BASE 
  _ADR STORE   
  _DOLIT 0XFF00 
  _ADR ANDD   
  _ADR UDOT 
  _DOTQP 7 , " BFAR: "
  _ADR UDOT 
  _ADR CR 
  _ADR reset_mcu  

/************************************
    usage fault
    irq -10 
************************************/
  .type usagefault_handler, %function
  .p2align 2
  .global usagefault_handler 
usagefault_handler:
  _MOV32 r0,RAM_END 
  mov sp,r0 
  ldr IP,=usagefault_hl
  b INEXT 
usagefault_hl:
  _ADR PRESE
  _ADR CR  
  _DOTQP  23 , "usage exception, UFSR: "
  _DOLIT 16 
  _ADR BASE 
  _ADR STORE   
  _ADR CFSR
  _DOLIT 16 
  _ADR RSHIFT 
  _ADR UDOT 
  _ADR CR 
  _ADR reset_mcu  


/********************************
    timer interrupt handler
********************************/
  .type timer4_handler, %function
  .p2align 2
  .global timer4_handler
timer4_handler:
    _MOV32 r3,UPP 
    ldr r0,[r3,#BEEP_DTMR]
    cbnz r0, 1f 
    // disable tone generator
    _MOV32 r3,TIM4_BASE_ADR
    ldr r0,[r3,#TIM_CR1]
    and r0,#-2 
    str r0,[r3,#TIM_CR1]
//    ldr r0,[r3,#TIM_DIER]
//    and r0,#-4
//    str r0,[r3,#TIM_DIER]
1:  // reset interrupt flags
    _MOV32 r3,TIM4_BASE_ADR
    ldr r0,[r3,#TIM_SR]
    and r0,#-4
    str r0,[r3,#TIM_SR]
    bx lr 


/*********************************
	system milliseconds counter
*********************************/	
  .type systick_handler, %function
  .p2align 2 
  .global systick_handler
systick_handler:
  _MOV32 r3,UPP
  ldr r0,[r3,#TICKS]  
  add r0,#1
  str r0,[r3,#TICKS]
  // tone timer 
  ldr r0,[r3,#BEEP_DTMR]
  cbz r0,1f
  sub r0,#1 
  str r0,[r3,#BEEP_DTMR]
1: // countdown timer 
  ldr r0,[r3,#CD_TIMER]
  cbz r0, systick_exit
  sub r0,#1
  str r0,[r3,#CD_TIMER]
systick_exit:
  bx lr

user_reboot:
   _CALL forth_init 
  ldr IP,=ur
  b INEXT  
ur:
  _ADR PRESE
  _ADR CR   
	_DOLIT user_reboot_msg
	_ADR COUNT 
  _ADR TYPEE 
  _ADR reset_mcu 

	.p2align 2 
user_reboot_msg:
	.byte 12
	.ascii "user reboot!"
	.p2align 2 

reset_mcu:
  _MOV32 r0,UART 
1: ldr r1,[r0,#USART_SR]
  tst r1,#(1<<6)
  beq 1b
  _MOV32 r0,SCB_BASE_ADR  
	ldr r1,[r0,#SCB_AIRCR]
	orr r1,#(1<<2)
	movt r1,#SCB_VECTKEY
	str r1,[r0,#SCB_AIRCR]
	b . 

/**************************************
  reset_handler execute at MCU reset
***************************************/
  .type  reset_handler, %function
  .p2align 2 
  .global reset_handler
reset_handler:
	_MOV32 r0,RAM_END
	mov sp,r0 
// enable memory, bus and usage exceptions  
  _MOV32 r0,SCB_BASE_ADR
  eor r1,r1 
  movt r1,#7 
  str r1,[r0,#SCB_SHCSR]
	bl	remap 
	bl	init_devices	 	/* RCC, GPIOs, USART */
  bl  fpu_init 
	bl  ser_init
 	bl	tv_init
  bl  kbd_init
  bl  flash_spi_init   
	b COLD 



	.type forth_init, %function 
  .p2align 2 
forth_init:
	_MOV32 UP,UPP 
	_MOV32 DSP,SPP
	_MOV32 RSP,RPP
  ldr INX,=NEST
  orr INX,#1 
	EOR TOS,TOS  
	_RET 



  .type init_devices, %function
  .p2align 2 
init_devices:
/* init clock to HSE 96 Mhz */
/* set 3 wait states in FLASH_ACR_LATENCY */
  _MOV32 R0,FLASH_BASE_ADR 
  mov r1,#3 
  str r1,[r0,#FLASH_ACR]
/* configure clock for HSE, 25 Mhz crystal */
/* enable HSE in RCC_CR */
  _MOV32 R0,RCC_BASE_ADR 
  ldr r1,[r0,#RCC_CR]
  orr r1,r1,#(1<<16) /* HSEON bit */
  str r1,[r0,#RCC_CR] /* enable HSE */
/* wait HSERDY loop */
wait_hserdy:
  ldr r1,[r0,#RCC_CR]
  tst r1,#(1<<17)
  beq wait_hserdy

/************************************************* 
   configure PLL  and source 
   SYSCLOCK=96 Mhz
   select HSE as  PLL source clock
   PLLM=50, PLLN=384, PLLP=0, PLLQ=4  
   APB1 clock is limited to 50 Mhz so divide Fsysclk by 2 
****************************************************/
  /* set RCC_PLLCFGR */
  _MOV32 r0, RCC_BASE_ADR
  _MOV32 r1, (50+(384<<6)+(1<<22)+(4<<24))
  str r1,[r0,#RCC_PLLCFGR]
  /* enable PLL */
  ldr r1,[r0,#RCC_CR]
  orr r1, #(1<<24)
  str r1,[r0,#RCC_CR]
/* wait for PLLRDY */
wait_pllrdy:
  ldr r1,[r0,#RCC_CR]
  tst r1,#(1<<25)
  bne wait_pllrdy 
/* RCC_CFGR RTCPRE=25, PPRE1=4 */
  _MOV32 r1,((25<<16)+(4<<10))
  str r1,[r0,#RCC_CFGR]
/* select PLL as sysclock SW=PLL (i.e. 2 ) */
  ldr r1,[r0,#RCC_CFGR]
  orr r1,#2
  str r1,[r0,#RCC_CFGR] /* PLL selected as sysclock */
/* wait for SWS==2 */
wait_sws:
  ldr r1,[r0,#RCC_CFGR]
  tst r1,#(2<<2)
  beq wait_sws
/* now sysclock is 96 Mhz */


/* enable peripheral clock for GPIOA, GPIOB, GPIOC and USART1 */
  mov	r1, #0x9F		/* all GPIO clock */
  str	r1, [r0, #RCC_AHB1ENR]
  mov	r1, #(1<<4)+(1<<14)  /* USART1 + SYSCFG clock enable */
  str	r1,[r0,#RCC_APB2ENR]	
/* configure GPIOC:13 as output for user LED */
  _MOV32 r0,LED_GPIO 
  mov r1,#LED_PIN
  mov r2,#OUTPUT_OD 
  _CALL gpio_config 
  mov r2,#1
  _CALL gpio_out 
/* enable compensation CELL for fast I/O */
	_MOV32 r1,SYSCFG_BASE_ADR
	mov r0,#1 
	str r0,[R1,#SYSCFG_CMPCR]
/* wait for ready bit */ 
1:  ldr r0,[R1,#SYSCFG_CMPCR]
    tst r0,#(1<<8)
	beq 1b 	

/* configure audio output 
   PB6 Aout 
   T4-CH1  PWM mode
   Fck = 96Mhz/16  
*/
  _MOV32 r0,GPIOB_BASE_ADR // port 
  // select AF02 on PB6 // T4-CH1 
  ldr r1,[r0,#GPIO_AFRL]
  orr r1,#(2<<24)
  str r1,[r0,#GPIO_AFRL] 
  mov r1,#6 // pin 
  mov r2,#OUTPUT_AFPP  // mode 
  _CALL gpio_config 
// enable timer4 clock 
  _MOV32 r2,RCC_BASE_ADR 
  mov r0,#4
  ldr r1,[r2,#RCC_APB1ENR]
  orr r1,r0 
  str r1,[r2,#RCC_APB1ENR]
// configure TIMER4 CH1  pwm mode   
  _MOV32 r2,TIM4_BASE_ADR
// préscale / 16 
  _MOV32 r0,TIM4_BASE_ADR
  mov r1,#15 
  str r1,[r0,#TIM_PSC] // div Fck/16
// pwm mode 
  mov r1,#7<<4 
  str r1,[r0,#TIM_CCMR1]
  ldr r1,[r0,TIM_CCER]
  orr r1,#1
  str r1,[r0,#TIM_CCER]
  // enable interrupt 
  ldr r1,[r0,#TIM_DIER]
  orr r1,#1 
  str r1,[r0,#TIM_DIER]
  mov r0,#TIM4_IRQ 
  _CALL  nvic_enable_irq


/* configure systicks for 1msec ticks */
// set priority to 15 (lowest)
  mov r0,#STCK_IRQ
  mov r1,#15 
  _CALL nvic_set_priority
  _MOV32 r0,STK_BASE_ADR 
  _MOV32 r1,95999 
  str r1,[r0,#STK_LOAD]
  mov r1,#7
  str r1,[r0,STK_CTL]
  _RET  

  
/* copy system variables to RAM */ 
	.type remap, %function 
    .global remap 
remap:
// copy system to RAM 	
	_MOV32 r0,RAM_ADR 
	ldr r1,=UZERO 
	mov r2,#ULAST-UZERO 
	add r2,r2,#3
	and r2,r2,#~3 
1:	ldr r3,[r1],#4 
	str r3,[r0],#4 
	subs R2,#4 
	bne 1b
// zero end of RAM 
	_MOV32 r2,RAM_END 
	eor r3,r3,r3 
2:  str r3,[r0],#4
	cmp r0,r2 
	blt 2b 
	_MOV32 UP,RAM_ADR  
	_RET 

// set irq priority 
// 0 highest 
// 15 lowest
// input: r0 IRQn  
//        r1  ipr 
nvic_set_priority:
    push {r3}
    cmp r0,#0 
    bmi negative_irq 
    _mov32 r3,NVIC_IPR_BASE
    lsl r1,#4 
    strb r1,[r3,r0]
    pop {r3}
    _RET 
negative_irq:
    _MOV32 r3,(SCB_BASE_ADR+SCB_SHPR1)
    and r0,#0XF 
    sub r0,#4 
    lsl r1,#4 
    strb r1,[r3,r0]
    pop {r3}
    _RET 


// enable interrupt in nvic 
// input: r0 = IRQn 
nvic_enable_irq: 
    push {r1,r2,r3}
    _MOV32 r3,(NVIC_BASE_ADR+NVIC_ISER0)
    mov r1,r0 
    lsr r1,#5  
    lsl r1,#2  // ISERn  
    and r0,#31 // bit#
    mov r2,#1 
    lsl r2,r0
    cpsid I
    str r2,[r3,r1]
    cpsie I 
    pop {r1,r2,r3}
    _RET 

// disable interrupt in nvic
// input: r0 = IRQn
nvic_disable_irq:
    push {r1,r2,r3}
    _MOV32 r3,(NVIC_BASE_ADR+NVIC_ICER0)
    mov r1,r0 
    lsr r1,#5  
    lsl r1,#2  // ISERn
    and r0,#31 // bit#
    mov r2,#1 
    lsl r2,r0
    str r2,[r3,r1]
    dsb 
    isb 
    pop {r1,r2,r3}
    _RET 

// clear interrupt pending flag 
// input: r0 = IRQn
nvic_clear_irq_pending:
    _MOV32 r3,(NVIC_BASE_ADR+NVIC_ICPR0)
    push {r1,r2,r3}
    mov r1,r0 
    lsr r1,#5 
    lsl r1,#2  // IABRn
    and r0,#31 // bit#
    mov r2,#1 
    lsl r2,r0
    str r2,[r3,r1]
    dsb 
    isb 
    pop {r1,r2,r3}
    _RET 


/**********************************
  gpio_config 
  Configure gpio mode 
  input:
    r0   GPIOx 
    r1   pin 
    r2   mode 
  output:
    none 
  use:
    r3,r5,r11  
**********************************/
gpio_config:
    push {r3,r5,r11}
//  clear registers field 
    mov r5,#1
    lsl r5,r1
    mvn r5,r5 // 1 bit field mask 
    ldr r3,[r0,#GPIO_OTYPER]
    and r3,r5 
    str r3,[r0,#GPIO_OTYPER]
    mov r5,#3 
    mov r11,#2 
    mul r11,r1 
    lsl r5,r11 
    mvn r5,r5 // 2 bits field mask 
    ldr r3,[r0,#GPIO_MODER]
    and r3,r5 
    str r3,[r0,#GPIO_MODER]
    ldr r3,[r0,#GPIO_PUPDR]
    and r3,r5 
    str r3,[r0,#GPIO_PUPDR]
// set mode register, r2 low nibble  
    and r5,r2,#3    
    lsl r5,r11 // mode 
    ldr r3,[r0,#GPIO_MODER]
    orr r3,r5 
    str r3,[r0,#GPIO_MODER]
    cmp r2,#3
    beq 9f // analog input 
    ands r5,r2,#3 
    beq input_pull 
output_type:
    lsr r2,#4 
    lsl r2,r1 // 1 bit field 
    ldr r3,[r0,#GPIO_OTYPER]
    orr r3,r2 
    str r3,[r0,#GPIO_OTYPER]
    b 9f 
input_pull:
    ldr r3,[r0,#GPIO_PUPDR]
    lsr r2,#4 
    lsl r2,r11 // 2 bits field 
    orr r3,r2 
    str r3,[r0,#GPIO_PUPDR]
9:  pop {r3,r5,r11}
    _RET 

// configure gpio speed 
// input:
//    r0   GPIO_BASE_ADR 
//    r1   pin 
//    r2   speed
// use:
//  r3,r5,r11 
gpio_speed:
    push {r3,r5,r11}
    ldr r3,[r0,#GPIO_OSPEEDR]
    mov r5,#3
    mov r11,#2 
    mul r11,r1 
    lsl r5,r11
    mvn r5,r5 
    and r3,r5   
    lsl r2,r11  
    orr r3,r2 
    str r3,[r0,#GPIO_OSPEEDR]
    pop {r3,r5,r11}
    _RET

/**************************** 
  gpio_out port,pin,0|1
  input:
    r0   gpio_base_adr 
    r1   pin 
    r2   data 0|1 
**************************/
gpio_out:
    push {r3}
    mov r3,#1 
    lsl r3,r1 
    cbnz r2, 1f 
    lsl r3,#16 
1:  str r3,[r0,#GPIO_BSRR]    
    pop {r3}
    _RET 

/******************************************************
*  COLD start moves the following to USER variables.
*  MUST BE IN SAME ORDER AS USER VARIABLES.
******************************************************/
	.p2align 2
UZERO:
	.word 0  			/*Reserved */
	.word 0xaa55aa55 /* SEED  */ 
	.word 0      /* TICKS */
    .word 0     /* CD_TIMER */
	.word HI_BOTH  /*'BOOT */
	.word PS2_QKEY /* query for character */
  .word TV_EMIT  /* char output device */
  .word BASEE 	/*BASE */
  .word -1      /*BCHAR*/ 
	.word 0			/*tmp */
	.word 0			/*SPAN */
	.word 0			/*>IN */
	.word 0			/*#TIB */
	.word TIBB	/*TIBU */
	.word INTER	/*'EVAL */
	.word 0			/*HLD */
	.word _LASTN	/*CONTEXT */
	.word CTOP  	/* FCP end of system dictionnary */
	.word RAM_ADR+(CTOP-UZERO)	/* CP end of RAM dictionary RAM */
	.word _LASTN	/*LAST word in dictionary */
	.space  RX_QUEUE_SIZE /* space reserved for rx_queue,head and tail pointer. */
	.word 0  /* RX_HEAD */
	.word 0  /* RX_TAIL */ 
	.word 0  /* VID_CNTR, video_line counter */ 
	.word 0  /* VID_STATE, video state */  
    .word 0  /* VID_FIELD, field */
	.word VID_BUFF /* video_buffer address */ 
    .word 0 /* kbd struct */
	.space KBD_QUEUE_SIZE,0  
	.word 0  /* kbd queue head */
	.word 0 /* kbd queue tail */ 
    .word 0 /* tv cursor row */
    .word 0 /* tv cursor column */ 
    .word 0 /* tv back color */
    .word 7 /* tv font color */
    .word 0 /* FPSW */
    .word 0 /* FBASE */ 
    .word 0 /* BEEP_DTMR */
    .word 0 /* CSTATE */ 
    .word 0,0 
ULAST:

// used by _HEADER macro 
// to link names field
// in dictionary  
    .equ LINK, 0 
