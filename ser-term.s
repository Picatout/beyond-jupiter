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
    basic serial I/O 
**********************************/

  .syntax unified
  .cpu cortex-m4
  .fpu softvfp 
  .thumb


/**************************
	UART RX handler
**************************/
	.p2align 2
	.type uart_rx_handler, %function
uart_rx_handler:
	_MOV32 r3,UART 
	ldr r0,[r3,#USART_SR]
	ldr r1,[r3,#USART_DR]
	tst r0,#(1<<5) // RXNE 
	beq 2f // no char received 
	cmp r1,#VK_CTRL_C 
	beq user_reboot // received CTRL-C then reboot MCU 
	add r0,UP,#RX_QUEUE
	ldr r2,[UP,#RX_TAIL]
	strb r1,[r0,r2]
	add r2,#1 
	and r2,#(RX_QUEUE_SIZE-1)
	str r2,[UP,#RX_TAIL]
2:	
	bx lr 

/*******************************
  initialize UART peripheral 
********************************/
	.type ser_init, %function
ser_init:
/* set GPIOA PIN 9, uart TX  */
  _MOV32 r0,GPIOA_BASE_ADR
  ldr r1,[r0,#GPIO_MODER]
  mvn r2,#0xf<<(2*9)
  and r1,r1,r2
  mov r2,#0xa<<(2*9) // alternate function mode for PA9 and PA10
  orr r1,r1,r2 
  str r1,[r0,#GPIO_MODER]
/* select alternate functions USART1==AF07 */ 
  mov r1,#0x77<<4 
  str r1,[r0,#GPIO_AFRH]
/* configure USART1 registers */
  _MOV32 r0,UART 
/* BAUD rate */
  mov r1,#(52<<4)+1  /* (96Mhz/16)/115200=52,0833333 quotient=52, reste=0,083333*16=1 */
  str r1,[r0,#USART_BRR]
  mov r1,#(3<<2)+(1<<13)+(1<<5) // TE+RE+UE+RXNEIE
  str r1,[r0,#USART_CR1] /*enable usart*/
/* set interrupt priority */
  mov r0,#USART1_IRQ 
  mov r1,#7
  _CALL nvic_set_priority
/* enable interrupt in NVIC */
  mov r0,#USART1_IRQ 
  _CALL nvic_enable_irq  
  _RET  



/***********************************************************
    SER-KEY?  ( -- c T | F )
 	Return input character and true, or a false if no input.
************************************************************/
    _HEADER SER_QKEY,8,"SER-KEY?"
	_PUSH
	ldr T0,[UP,#RX_TAIL] 
	ldr T1,[UP,#RX_HEAD]
	eors TOS,T0,T1 
	beq 1f
	add T0,UP,#RX_QUEUE 
	add T0,T1 
	ldrb TOS,[T0]
	add T1,#1 
	and T1,#(RX_QUEUE_SIZE-1)
	str T1,[UP,#RX_HEAD]
	_PUSH 
	mov TOS,#-1
1:	_NEXT 

/*******************************************
    SER-EMIT	 ( c -- )
    Send character c to the serial device.
*******************************************/
    _HEADER SER_EMIT,8,"SER-EMIT"
	_MOV32 WP,UART 
1:  ldr T0,[WP,#USART_SR]
    tst T0,#0x80 // TXE flag 
	beq 1b 
	strb TOS,[WP,#USART_DR]	 
	_POP
	_NEXT 


/****************************************
    LOCAL ( -- 0 )
    constant: local console id 
****************************************/
        _HEADER LOCAL,5,"LOCAL"
        _PUSH 
        mov TOS,#0
        _NEXT 

/****************************************
    SERIAL ( -- 1 )
    constant: serial console id 
****************************************/
        _HEADER SERIAL,6,"SERIAL"
        _PUSH 
        mov TOS,#1
        _NEXT 

/****************************************
    CONSOLE ( id -- )
    select active user interface 
****************************************/
        _HEADER CONSOLE,7,"CONSOLE"
        mov T0,TOS
        _POP 
        cbz T0, 4f 
// serial console 
        ldr T0,=SER_QKEY 
        str T0,[UP,#STDIN]
        ldr T0,=SER_EMIT
        str T0,[UP,#STDOUT]
        _CALL_COLWORD READY 
        _NEXT 
4: // local console 
        ldr T0,=PS2_QKEY
        str T0,[UP,#STDIN]
        ldr T0,=TV_EMIT
        str T0,[UP,#STDOUT]
        _CALL_COLWORD READY 
        _NEXT 

/*******************************
    ANSI-PARAM ( n -- )
    convert and transmit 
    ANSI ESC[  parameter 
*******************************/
      _HEADER ANSI_PARAM,10,"ANSI-PARAM"
      _NEST 
      _DOLIT -1 // c 
1:    _ADR ONEP  // c+1
      _ADR TOR   
      _DOLIT 10 
      _ADR SLMOD // r q  
      _ADR QDUP  // r q q | r 0  
      _QBRAN 2f  // r 0 
      _ADR RFROM // r q c 
      _BRAN 1b
2:    _DOLIT '0'  
      _ADR PLUS 
      _ADR EMIT 
      _ADR RFROM 
      _ADR QDUP 
      _QBRAN 3f
      _ADR ONEM 
      _ADR TOR 
      _BRAN 2b 
3:    
      _UNNEST 

/******************************
    ESC[ 
    send ANSI escape sequence
*******************************/
      _HEADER ANSI_ESC,4,"ESC["
      _NEST 
      _DOLIT 27 
      _ADR EMIT 
      _DOLIT '['
      _ADR EMIT 
      _UNNEST 

/*************************************
    SER-AT ( line col -- )
    move cursor on serial console
*************************************/
      _HEADER SER_AT,6,"SER-AT"
      _NEST
      _ADR ANSI_ESC
      _ADR SWAP 
      _ADR ANSI_PARAM 
      _DOLIT ';'
      _ADR EMIT
      _ADR ANSI_PARAM
      _DOLIT 'H'
      _ADR EMIT 
      _UNNEST 

/****************************
    SER-CLS ( -- )
    serial clear screeen 
****************************/
    _HEADER SER_CLS,7,"SER-CLS"
    _NEST
    _DOLIT 1 
    _ADR DUPP 
    _ADR SER_AT  
    _ADR ANSI_ESC
    _DOLIT 'J'
    _ADR EMIT 
    _UNNEST 

