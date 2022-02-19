/**************************************************************************
 Copyright Jacques Deschênes 2021,2022 
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

/*****************************************************
*  STM32eForth version 7.20
*  Adapted to blue pill board by Picatout
*  date: 2020-11-22
*  IMPLEMENTATION NOTES:
* 
*	This version use indirect threaded model. This model enable 
*	leaving the core Forth system in FLASH memory while the users 
*	definitions reside in RAM. 

*     Use USART1 for console I/O
*     port config: 115200 8N1 
*     TX on  PA9,  RX on PA10  
*
******************************************************/

/***********************************************************
*	STM32eForth version 7.20
*	Chen-Hanson Ting,  July 2014

*	Subroutine Threaded Forth Model
*	Adapted to STM32F407-Discovery Board
*	Assembled by Keil uVision 5.10

*	Version 4.03
*	Direct Threaded Forth Model
*	Derived from 80386 eForth versin 4.02
*	and Chien-ja Wu's ARM7 eForth version 1.01

*	Version 5.02, 09oct04cht
*	fOR ADuC702x from Analog Devices
*	Version 6.01, 10apr08cht a
*	.p2align 2 to at91sam7x256
*	Tested on Olimax SAM7-EX256 Board with LCD display
*	Running under uVision3 RealView from Keil
*	Version 7.01, 29jun14cht
*	Ported to STM32F407-Discovery Board, under uVision 5.10
*	.p2aligned to eForth 2 Model
*	Assembled to flash memory and executed therefrom.
*	Version 7.10, 30jun14cht
*	Flash memory mapped to Page 0 where codes are executed
*	Version 7.20, 02jul14cht
*	Irreducible Complexity
*	Code copied from flash to RAM, RAM mapped to Page 0.
*	TURNKEY saves current application from RAM to flash.
*********************************************************/

	.syntax unified
	.cpu cortex-m4
	.fpu vfpv4  
	.thumb

	.include "stm32f411ce.inc"
	
	.section .text, "ax", %progbits

/***********************************
  Start of eForth system 
***********************************/

	.p2align 2 

// hi level word enter
NEST: 
	STMFD	RSP!,{IP} // save return address 
	ADD IP,WP,#3
// inner interprer
INEXT: 
	LDR WP,[IP],#4 
	BX WP  
UNNEST: // exit hi level word 
	LDMFD RSP!,{IP}
	LDR WP,[IP],#4 
	BX WP  

	.p2align 2 

// compile "BX INX\nNOP.N " 
// this is the only way 
// a colon defintion in RAM 
// can jump to NEST
// INX register is initialized 
// to NEST address 
// and must be preserved   
COMPI_NEST:
	add T1,UP,#USER_CTOP // pointer HERE 
	ldr T1,[T1]     // address in here   
	mov T2,#0x4700+(10<<3) // binary code for BX INX 
	strh T2,[T1],#2    // store code at HERE, ptr+2   
	mov T2,#0xbf00 // NOP.N   instruction 
	strh T2,[T1],#2  // store code at HERE, ptr+2 
	add T2,UP,#USER_CTOP 
	str T1,[T2]  // save update HERE value 
	_NEXT  

// ' STDIN 
// stdin vector 
TSTDIN:
	_PUSH 
	ADD TOS,UP,#STDIN 
	_NEXT 

// ' STDOUT 
// stdout vector 
TSTDOUT:
	_PUSH 
	ADD TOS,UP,#STDOUT
	_NEXT 

/***************************
  CFSR ( -- u )
  stack CFSR register 
***************************/
    _HEADER CFSR,4,"CFSR"
    _MOV32 T0,SCB_BASE_ADR  
    _PUSH 
    ldr TOS,[T0,#SCB_CFSR]
    eor T1,T1 
    str T1,[T0,#SCB_CFSR]
    _NEXT 

/*****************************
  BFAR ( -- u )
  stack BFAR register
*****************************/
    _HEADER BFAR,4,"BFAR"
    _MOV32 T0,SCB_BASE_ADR  
	_PUSH 
    ldr TOS,[T0,#SCB_BFAR]
    eor T1,T1 
    str T1,[T0,#SCB_BFAR]
    _NEXT 

/********************************************
	KEY? ( -- c T | F )
	check if available character 
********************************************/
	_HEADER QKEY,4,"KEY?" 
	_NEST 
	_ADR TSTDIN // ' STDIN 
	_ADR ATEXE
	_UNNEST 

/********************************************
    KEY	 ( -- c )
 	Wait for and return an input character.
********************************************/
	_HEADER KEY,3,"KEY"
	_NEST
KEY1:
	_ADR CAPS_LED 
	_ADR	QKEY 
	_QBRAN	KEY1
/*  add this code to filter out control characters 	
	_ADR    DUPP 
	_DOLIT  13 
	_ADR    EQUAL 
	_TBRAN  KEY2 
	_ADR    DUPP
	_DOLIT  32 
	_ADR    LESS 
	_QBRAN  KEY2 
	_ADR    DROP 
	_BRAN   KEY1 
*/ 
KEY2: 	
	_UNNEST

/**********************************************
	EMIT ( c -- )
	transmit a character to console 
**********************************************/
	_HEADER EMIT,4,"EMIT"
	_NEST 
	_ADR TSTDOUT 
	_ADR ATEXE 
	_UNNEST 


/************************************************
 GET-IP ( n - c )
 return interrupt priority of IRQn 
************************************************/
/*
	_HEADER GETIP,6,"GET-IP" 
	_NEST 
	_ADR DUPP 
	_ADR ZLESS
	_QBRAN 1f 
	_DOLIT 15
	_ADR ANDD
	_DOLIT 4
	_ADR SUBB  
	_DOLIT 0xE000ED18 
	_BRAN 2f 
1:	_DOLIT 0xE000E400 
2:	_ADR PLUS 
	_ADR CAT
	_DOLIT 4 
	_ADR RSHIFT 
	_UNNEST 
*/

/***********************************************
 RANDOM ( n+ -- {0..n+ - 1} )
 return pseudo random number 
 REF: https://en.wikipedia.org/wiki/Xorshift
************************************************/
	_HEADER RAND,6,"RANDOM"
	_NEST
	_ADR ABSS   
	_ADR SEED 
	_ADR AT 
	_ADR DUPP 
	_DOLIT 13
	_ADR LSHIFT 
	_ADR XORR  
	_ADR DUPP 
	_DOLIT 17 
	_ADR RSHIFT 
	_ADR XORR 
	_ADR DUPP
	_DOLIT 5 
	_ADR LSHIFT 
	_ADR XORR  
	_ADR DUPP 
	_ADR SEED 
	_ADR STORE 
	_DOLIT 0x7FFFFFFF
	_ADR ANDD 
	_ADR SWAP 
	_ADR MODD 
	_UNNEST 


/****************************************
 PAUSE ( u -- ) 
 suspend execution for u milliseconds
****************************************/
	_HEADER PAUSE,5,"PAUSE"
	_NEST 
	_ADR TIMER 
	_ADR STORE 
PAUSE_LOOP:
	_ADR TIMER 
	_ADR AT 
	_QBRAN PAUSE_EXIT 
	_BRAN PAUSE_LOOP 
PAUSE_EXIT: 		
	_UNNEST 

/******************************************
  ULED ( T|F -- )
  control user LED, -1 ON, 0 OFF 
*******************************************/
	_HEADER ULED,4,"ULED"
	mov T0,#(1<<LED_PIN)
	_MOV32 T1,LED_GPIO 
	movs TOS,TOS 
	_POP
	beq ULED_OFF
	lsl T0,#16 
	str T0,[T1,#GPIO_BSRR]
	_NEXT 
ULED_OFF:
	str T0,[T1,#GPIO_BSRR]
	_NEXT    

/**************************
   JOYSTK  ( -- u )
   read joystick port 
**************************/
	_HEADER JOYSTK,6,"JOYSTK"
	_NEST 
	_DOLIT (GPIOA_BASE_ADR+GPIO_IDR)
	_ADR AT 
	_DOLIT 0x100f 
	_ADR ANDD 
	_UNNEST 

/****************************
	BEEP ( msec freq -- )
input:
	freq  frequence hertz 
	msec  durration in msec 
*****************************/
	_HEADER BEEP,4,"BEEP"
	_MOV32 r0,6000000 // Fclk 
	udiv r0,r0,TOS
	_POP  
	_MOV32 r1,TIM4_BASE_ADR
	str r0,[r1,#TIM_ARR]
	lsr r0,#1
	str r0,[r1,#TIM_CCR1]
	mov r0,#1 
	str r0,[r1,#TIM_CCER]
	str r0,[r1,#TIM_CR1]
	ldr r0,[r1,#TIM_DIER]
	str TOS,[UP,#BEEP_DTMR]
	_POP
	_NEXT 


/***************
//  The kernel
***************/

/********************
    NOP	( -- )
 	do nothing.
*********************/
	_HEADER NOP,3,"NOP"
	_NEXT 
 
/********************
    doLIT	( -- w )
 	Push an inline literal.
hidden word used by compiler 
*********************/
DOLIT:
	_PUSH				//  store TOS on data stack
	LDR	TOS,[IP],#4		//  get literal at word boundary
	_NEXT 

/*******************************
    EXECUTE	( ca -- )
 	Execute the word at ca.
*******************************/
	_HEADER EXECU,7,"EXECUTE"
	ORR	WP,TOS,#1 
	_POP
	BX WP 
	_NEXT 

/**********************************************************
    donext	( -- ) counter on R:
 	Run time code for the single index loop.
 	: next ( -- ) \ hilevel model
 	 r> r> dup if 1 - >r @ >r exit then drop cell+ >r // 
hidden word used by compiler 	  
*********************************************************/
DONXT:
	LDR	T2,[RSP]   // ( -- u )  
	CBNZ T2,NEXT1 
	/* loop done */
	ADD	RSP,RSP,#4 // drop counter 
	ADD	IP,IP,#4 // skip after loop address 
	_NEXT
NEXT1:
	/* decrement loop counter */
	SUB	T2,T2,#1
	STR	T2,[RSP]
	LDR	IP,[IP]	// go begining of loop 
	_NEXT 

/**************************************
    ?branch	( f -- )
 	Branch if flag is zero.
hiddend word used by compiler
**************************************/
QBRAN:
	MOVS	TOS,TOS
	_POP
	BNE	QBRAN1
	LDR	IP,[IP]
	_NEXT
QBRAN1:
 	ADD	IP,IP,#4
	_NEXT

/***********************************
	tbranch ( f -- )
    branch if flag is true 
***********************************/
TBRAN:
	MOVS TOS,TOS 
	_POP 
	BEQ 1f 
	LDR IP,[IP]
	_NEXT 
1:  ADD IP,IP,#4
	_NEXT 


/***********************************
    branch	( -- )
 	Branch to an inline address.
hidden word used by compiler 
***********************************/
BRAN:
	LDR	IP,[IP]
	_NEXT

/******************************************
    EXIT	(  -- )
 	Exit the currently executing command.
******************************************/
	_HEADER EXIT,4,"EXIT"
	b UNNEST 


/***********************************
    !	   ( w a -- )
 	Pop the data stack to memory.
************************************/
	_HEADER STORE,1,"!"
	LDR	WP,[DSP],#4
	STR	WP,[TOS]
	_POP
	_NEXT 

/********************************************
    @	   ( a -- w )
 	Push memory location to the data stack.
*********************************************/
	_HEADER AT,1,"@"
	LDR	TOS,[TOS]
	_NEXT 

/*******************************************
    C!	  ( c b -- )
 	Pop the data stack to byte memory.
*******************************************/
	_HEADER CSTOR,2,"C!"
	LDR	WP,[DSP],#4
	STRB WP,[TOS]
	_POP
	_NEXT

/*********************************************
    C@	  ( b -- c )
 	Push byte memory location to the data stack.
**********************************************/
	_HEADER CAT,2,"C@"
	LDRB	TOS,[TOS]
	_NEXT 


/*********************************************
    R>	  ( -- w  R: w -- ) 
 	push from rstack.
**********************************************/
	_HEADER RFROM,2,"R>"
	_PUSH
	LDR	TOS,[RSP],#4
	_NEXT 

/***********************************************
	2R> (  -- D ) R: D --  
    push a double from rstack 
***********************************************/
	_HEADER DRFROM,3,"2R>"
	_PUSH 
	LDR TOS,[RSP],#4 
	_PUSH 
	LDR TOS,[RSP],#4
	_NEXT 

/************************************************
    R@	  ( -- w )
 	Copy top of return stack to the data stack.
************************************************/
	_HEADER RAT,2,"R@"
	_PUSH
	LDR	TOS,[RSP]
	_NEXT 

/***********************************************
    >R	  ( w -- ) R: -- w 
 	pop to rstack.
************************************************/
	_HEADER TOR,2,">R"
	STR	TOS,[RSP,#-4]!
	_POP
	_NEXT

/*********************************************
	2>R ( d -- ) R: -- d 
	pop a double to rstack 
*********************************************/
	_HEADER DTOR,3,"2>R"
	STR TOS,[RSP,#-4]!
    _POP 
	STR TOS,[RSP,#-4]!
	_POP  
	_NEXT 	


/*******************************
//	RP! ( u -- )
// initialize RPP with u 
*******************************/
	_HEADER RPSTOR,3,"RP!"
	MOV RSP,TOS 
	_POP  
	_NEXT 

/********************************
	SP! ( u -- )
 initialize SPP with u 
********************************/
	_HEADER SPSTOR,3,"SP!"
	MOV DSP,TOS 
	EOR TOS,TOS,TOS 
	_NEXT 

/**************************************
    SP@	 ( -- a )
 	Push the current data stack pointer.
***************************************/
	_HEADER SPAT,3,"SP@"
	_PUSH
	MOV	TOS,DSP
	_NEXT

/**************************************
   RP@ ( -- a )
   push current rstack pointer 
**************************************/
	_HEADER RPAT,3,"RP@"
	_PUSH 
	MOV TOS,RSP 
	_NEXT 

/********************************
    DROP	( w -- )
 	Discard top stack item.
********************************/
	_HEADER DROP,4,"DROP"
	_POP
	_NEXT 

/*********************************
    DUP	 ( w -- w w )
 	Duplicate the top stack item.
*********************************/
	_HEADER DUPP,3,"DUP"
	_PUSH
	_NEXT 

/**********************************
    SWAP	( w1 w2 -- w2 w1 )
 	Exchange top two stack items.
**********************************/
	_HEADER SWAP,4,"SWAP"
	LDR	WP,[DSP]
	STR	TOS,[DSP]
	MOV	TOS,WP
	_NEXT 

/***********************************
	2SWAP ( d2 d1 -- d1 d2 )
	swap double integer 
***************************************/
	_HEADER DSWAP,5,"2SWAP"
	mov T0,TOS 
	ldr T1,[DSP]
	ldr TOS,[DSP,#4]
	ldr WP,[DSP,#8]
	str WP,[DSP]
	str T0,[DSP,#4]
	str T1,[DSP,#8]
	_NEXT 


/***********************************
    OVER	( w1 w2 -- w1 w2 w1 )
 	Copy second stack item to top.
***********************************/
	_HEADER OVER,4,"OVER"
	_PUSH
	LDR	TOS,[DSP,#4]
	_NEXT 

/***********************************
	2OVER ( d2 d1 -- d2 d1 d2 )
	copy a double integer to TOS 
**********************************************/
	_HEADER DOVER,5,"2OVER"
	ldr T0,[DSP,#4]
	ldr WP,[DSP,#8]
	_PUSH 
	mov TOS,WP 
	_PUSH
	mov TOS,T0 
	_NEXT 


/***********************************
    0<	  ( n -- t )
 	Return true if n is negative.
***********************************/
	_HEADER ZLESS,2,"0<"
	ASR TOS,#31
	_NEXT 

/**********************************
	0> ( n -- flag )
	true if n > 0 
**********************************/
	_HEADER ZGREAT,2,"0>"
	CBZ TOS, 1f
	ASR TOS,#31 
	MVN TOS,TOS 
1:	_NEXT 


/**********************************
	0<> ( n -- flag )
    true if n <> 0
*********************************/
	_HEADER ZNEQU,3,"0<>"
	CBZ TOS,1f
	MOV TOS,#-1
1:	_NEXT


/*********************************
	<>  ( x1 x2 -- flag )
	true fi x1 <> x2 
********************************/
	_HEADER NEQU,2,"<>"
	LDR T0,[DSP],#CELLL 
	EORS TOS,T0 
	BEQ 1f
	MOV TOS,#-1
1:  _NEXT 


/********************************
    AND	 ( w w -- w )
 	Bitwise AND.
********************************/
	_HEADER ANDD,3,"AND"
	LDR	WP,[DSP],#4
	AND	TOS,TOS,WP
	_NEXT 

/******************************
    OR	  ( w w -- w )
 	Bitwise inclusive OR.
******************************/
	_HEADER ORR,2,"OR"
	LDR	WP,[DSP],#4
	ORR	TOS,TOS,WP
	_NEXT 

/*****************************
    XOR	 ( w w -- w )
 	Bitwise exclusive OR.
*****************************/
	_HEADER XORR,3,"XOR"
	LDR	WP,[DSP],#4
	EOR	TOS,TOS,WP
	_NEXT 

/**************************************************
    UM+	 ( w w -- w cy )
 	Add two numbers, return the sum and carry flag.
***************************************************/
	_HEADER UPLUS,3,"UM+"
	LDR	WP,[DSP]
	ADDS	WP,WP,TOS
	MOV	TOS,#0
	ADC	TOS,TOS,#0
	STR	WP,[DSP]
	_NEXT 

/*********************************
    RSHIFT	 ( w # -- w )
 	logical Right shift # bits.
**********************************/
	_HEADER RSHIFT,6,"RSHIFT"
	LDR	WP,[DSP],#4
	MOV	TOS,WP,LSR TOS
	_NEXT 

/****************************
    LSHIFT	 ( w # -- w )
 	left shift # bits.
****************************/
	_HEADER LSHIFT,6,"LSHIFT"
	LDR	WP,[DSP],#4
	MOV	TOS,WP,LSL TOS
	_NEXT

/*************************
    +	 ( w w -- w )
 	Add.
*************************/
	_HEADER PLUS,1,"+"
	LDR	WP,[DSP],#4
	ADD	TOS,TOS,WP
	_NEXT 

/************************
    -	 ( w w -- w )
 	Subtract.
************************/
	_HEADER SUBB,1,"-"
	LDR	WP,[DSP],#4
	RSB	TOS,TOS,WP
	_NEXT 

/************************
    *	 ( w w -- w )
 	Multiply.
***********************/
	_HEADER STAR,1,"*"
	LDR	WP,[DSP],#4
	MUL	TOS,WP,TOS
	_NEXT 

/***************************
    UM*	 ( w w -- ud )
 	Unsigned multiply.
****************************/
	_HEADER UMSTA,3,"UM*"
	LDR	WP,[DSP]
	UMULL	T2,T3,TOS,WP
	STR	T2,[DSP]
	MOV	TOS,T3
	_NEXT 

/***************************
    M*	 ( w w -- d )
 	signed multiply.
	hold double result
***************************/
	_HEADER MSTAR,2,"M*"
	LDR	WP,[DSP]
	SMULL	T2,T3,TOS,WP
	STR	T2,[DSP]
	MOV	TOS,T3
	_NEXT 

/***************************
    1+	 ( w -- w+1 )
 	Add 1.
***************************/
	_HEADER ONEP,2,"1+"
	ADD	TOS,TOS,#1
	_NEXT 

/***************************
    1-	 ( w -- w-1 )
 	Subtract 1.
***************************/
	_HEADER ONEM,2,"1-"
	SUB	TOS,TOS,#1
	_NEXT 

/***************************
    2+	 ( w -- w+2 )
 	Add 2.
**************************/
	_HEADER TWOP,2,"2+"
	ADD	TOS,TOS,#2
	_NEXT

/**************************
    2-	 ( w -- w-2 )
 	Subtract 2.
**************************/
	_HEADER TWOM,2,"2-"
	SUB	TOS,TOS,#2
	_NEXT

/***************************
    CELL+	( w -- w+4 )
 	Add CELLL.
***************************/
	_HEADER CELLP,5,"CELL+"
	ADD	TOS,TOS,#CELLL
	_NEXT

/***************************
    CELL-	( w -- w-4 )
 	Subtract CELLL.
**************************/
	_HEADER CELLM,5,"CELL-"
	SUB	TOS,TOS,#CELLL
	_NEXT

/**************************** 
    BL	( -- 32 )
 	Blank (ASCII space).
*****************************/
	_HEADER BLANK,2,"BL"
	_PUSH
	MOV	TOS,#32
	_NEXT 

/**************************
    CELLS	( w -- w*4 )
 	Multiply CELLL 
***************************/
	_HEADER CELLS,5,"CELLS"
	LSL TOS,#2
	_NEXT

/***************************
    CELL/	( w -- w/4 )
 	Divide by CELLL.
***************************/
	_HEADER CELLSL,5,"CELL/"
	ASR TOS,#2
	_NEXT

/*************************
    2*	( w -- w*2 )
 	Multiply 2.
*************************/
	_HEADER TWOST,2,"2*"
	MOV	TOS,TOS,LSL#1
	_NEXT

/*************************
    2/	( w -- w/2 )
 	Divide by 2.
***********************/
	_HEADER TWOSL,2,"2/"
	MOV	TOS,TOS,ASR#1
	_NEXT

/****************************
    ?DUP	( w -- w w | 0 )
 	Conditional duplicate.
*****************************/
	_HEADER QDUP,4,"?DUP"
	MOVS	WP,TOS
	IT NE 
    STRNE	TOS,[DSP,#-4]!
	_NEXT

/***********************************
    ROT	( w1 w2 w3 -- w2 w3 w1 )
 	Rotate top 3 items.
*************************************/
	_HEADER ROT,3,"ROT"
	LDR	T0,[DSP]  // w2 
	STR	TOS,[DSP]  // w3 replace w2 
	LDR	TOS,[DSP,#4] // w1 replace w3 
	STR	T0,[DSP,#4] // w2 rpelace w1 
	_NEXT

/*********************************
 -ROT ( w1 w2 w3 -- w3 w1 w2 )
 left rotate top 3 elements 
********************************/
	_HEADER NROT,4,"-ROT"
	LDR T0,[DSP,#4]
	STR TOS,[DSP,#4]	
	LDR TOS,[DSP]
	STR T0,[DSP]
	_NEXT 

/*********************************
    2DROP	( w1 w2 -- )
 	Drop top 2 items.
*********************************/
	_HEADER DDROP,5,"2DROP"
	_POP
	_POP
	_NEXT 

/********************************
	3DROP ( w1 w2 w3 -- )
	drop top 3 items 
********************************/
	_HEADER TDROP,5,"3DROP"
    add DSP,#8 
    _POP 
    _NEXT 

/***********************************
    2DUP	( w1 w2 -- w1 w2 w1 w2 )
 	Duplicate top 2 items.
************************************/
	_HEADER DDUP,4,"2DUP"
	LDR	T0,[DSP] // w1
	STR	TOS,[DSP,#-4]! // push w2  
	STR	T0,[DSP,#-4]! // push w1 
	_NEXT

/******************************
    D+	( d1 d2 -- d3 )
 	Add top 2 double numbers.
******************************/
	_HEADER DPLUS,2,"D+"
	LDR	WP,[DSP],#4
	LDR	T2,[DSP],#4
	LDR	T3,[DSP]
	ADDS	WP,WP,T3
	STR	WP,[DSP]
	ADC	TOS,TOS,T2
	_NEXT

/******************************
	DABS ( d -- ud )
	absolute value double 
*****************************/
	_HEADER DABS,4,"DABS"
	tst TOS,#(1<<31)
	beq 9f 
	mvn TOS,TOS 
	ldr WP,[DSP]
	mvn WP,WP 
	adds WP,#1
	str WP,[DSP]
	bcc 9f 
	add TOS,#1 
9:	_NEXT 

/*****************************
  UD> ( d1 d2 -- f )
  unsigned compare double d1 > d2 
******************************/
	_HEADER UDGREAT,3,"UD>"
	ldr WP,[DSP],#4  // d1 lo 
	ldmfd DSP!,{T0,T1} // d2 hi,lo   
	cmp T0,TOS 
	bhi 1f
	bmi 2f  
	cmp T1,WP 
	bls 2f 
1:	mov TOS,#-1 
	_NEXT 
2:  mov TOS,#0 
	_NEXT 

/******************************
	D0= ( d -- f )
	double 0= 
*****************************/
	_HEADER DZEQUAL,3,"D0="
	mov T0,TOS
	_POP 
	orr TOS,T0 
	beq 9f
	mvn TOS,#0 
9:	_NEXT 

/*****************************
    INVERT	 ( w -- !w )
 	1"s complement.
*****************************/
	_HEADER INVER,6,"INVERT"
	MVN	TOS,TOS
	_NEXT

/*****************************
    NEGATE	( w -- -w )
 	2's complement.
***************************/
	_HEADER NEGAT,6,"NEGATE"
	RSB	TOS,TOS,#0
	_NEXT

/***************************
    ABS	 ( w -- |w| )
 	Absolute.
**************************/
	_HEADER ABSS,3,"ABS"
	TST	TOS,#0x80000000
	IT NE
    RSBNE   TOS,TOS,#0
	_NEXT

/**************************
	CLZ ( n - n )
	count leading zeros 
**************************/
	_HEADER CLZ,3,"CLZ"
	clz TOS,TOS 
	_NEXT 

/*************************
	CTZ ( n -- n )
	count trailing zeros 
************************/
	_HEADER CTZ,3,"CTZ"
	eor T0,T0 
1:  tst TOS,#1 
	bne 2f 
	lsr TOS,#1 
	add T0,#1 
	b 1b 
2:  mov TOS,T0 
	_NEXT 


/*******************
  0= ( w -- f )
 TOS==0?
*******************/
	_HEADER ZEQUAL,2,"0="
	cbnz TOS,1f
	mov TOS,#-1
	_NEXT 
1:  eor TOS,TOS,TOS  
	_NEXT 	

/*********************
    =	 ( w w -- t )
 	Equal?
*********************/
	_HEADER EQUAL,1,"="
	LDR	WP,[DSP],#4
	CMP	TOS,WP
	ITE EQ 
    MVNEQ	TOS,#0
	MOVNE	TOS,#0
	_NEXT

/************************
	<> ( w w -- f )
	different?
************************/
	_HEADER DIFF,2,"<>"
	mov T0,TOS 
	_POP 
	eor TOS,T0
	clz T0,TOS 
	lsl TOS,T0 
	asr TOS,#31 
	_NEXT 

/************************
    U<	 ( w w -- t )
 	Unsigned less?
*************************/
	_HEADER ULESS,2,"U<"
	LDR	WP,[DSP],#4
	CMP	WP,TOS
	ITE CC 
	MVNCC	TOS,#0
	MOVCS	TOS,#0
	_NEXT

/**********************
    <	( w w -- t )
 	Less?
**********************/
	_HEADER LESS,1,"<"
	LDR	WP,[DSP],#4
	CMP	WP,TOS
    ITE LT
	MVNLT	TOS,#0
	MOVGE	TOS,#0
	_NEXT 

/**********************
	U> ( u u -- t|f )
    unsigned greater 
**********************/
	_HEADER UGREAT,2,"U>"
	LDR WP,[DSP],#4 
	CMP TOS,WP 
	ITE CC  
	MVNCC TOS,#0 
	MOVCS TOS,#0
	_NEXT 

/***********************
    >	( w w -- t )
 	greater?
***********************/
	_HEADER GREAT,1,">"
	LDR	WP,[DSP],#4
	CMP	WP,TOS
	ITE GT
    MVNGT	TOS,#0
	MOVLE	TOS,#0
	_NEXT

/***************************
    MAX	 ( w w -- max )
 	Leave maximum.
***************************/
	_HEADER MAX,3,"MAX"
	LDR	WP,[DSP],#4
	CMP	WP,TOS
	IT GT 
	MOVGT	TOS,WP
	_NEXT 

/**************************
    MIN	 ( w w -- min )
 	Leave minimum.
**************************/
	_HEADER MIN,3,"MIN"
	LDR	WP,[DSP],#4
	CMP	WP,TOS
	IT LT
	MOVLT	TOS,WP
	_NEXT

/***********************
    +!	 ( w a -- )
 	Add to memory.
***********************/
	_HEADER PSTOR,2,"+!"
	LDR	WP,[DSP],#4
	LDR	T2,[TOS]
	ADD	T2,T2,WP
	STR	T2,[TOS]
	_POP
	_NEXT

/************************
    2!	 ( d a -- )
 	Store double number.
*************************/
	_HEADER DSTOR,2,"2!"
	LDR	WP,[DSP],#4
	LDR	T2,[DSP],#4
	STR	WP,[TOS],#4
	STR	T2,[TOS]
	_POP
	_NEXT

/************************
    2@	 ( a -- d )
 	Fetch double number.
************************/
	_HEADER DAT,2,"2@"
	LDR	WP,[TOS,#4]
	STR	WP,[DSP,#-4]!
	LDR	TOS,[TOS]
	_NEXT

/***************************
    COUNT	( b -- b+1 c )
 	Fetch length of string.
****************************/
	_HEADER COUNT,5,"COUNT"
	LDRB	WP,[TOS],#1
	_PUSH
	MOV	TOS,WP
	_NEXT

/******************************
    DNEGATE	( d -- -d )
 	Negate double number.
**************************/
	_HEADER DNEGA,7,"DNEGATE"
	LDR	WP,[DSP]
	SUB	T2,T2,T2
	SUBS WP,T2,WP
	SBC	TOS,T2,TOS
	STR	WP,[DSP]
	_NEXT

/******************************
  System and user variables
******************************/

/***********************
  system variables 
***********************/

/***********************
	STATE ( -- a )
	compilation state 
	0 -> interpret
	-1 -> compile 
************************/
	_HEADER STATE,5,"STATE"
	_PUSH 
	ADD TOS,UP,#CSTATE 
	_NEXT 

/**************************
 SEED ( -- a)
 return PRNG seed address 
**************************/
	_HEADER SEED,4,"SEED"
	_PUSH 
	ADD TOS,UP,#RNDSEED
	_NEXT 	

/****************************************
  MSEC ( -- a)
 return address of milliseconds counter
****************************************/
	_HEADER MSEC,4,"MSEC"
    _PUSH
    ADD TOS,UP,#TICKS
    _NEXT 

/*************************
 TIMER ( -- a )
 count down timer 
**********************/
	_HEADER TIMER,5,"TIMER"
	 _PUSH 
    ADD TOS,UP,#CD_TIMER
    _NEXT

/*****************************
    'BOOT	 ( -- a )
 	boot up application vector 
*****************************/
	_HEADER TBOOT,5,"'BOOT"
	_PUSH
	ADD	TOS,UP,#BOOT 
	_NEXT
	
/********************************************	
    BASE	( -- a )
 	Storage of the radix base for numeric I/O.
**********************************************/
	_HEADER BASE,4,"BASE"
	_PUSH
	ADD	TOS,UP,#NBASE
	_NEXT

/***********************************************
	BCHAR ( -- flag )
	boolean variable
	if set base char include in convertion 
	of integer to string.  
************************************************/
		_HEADER BCHR,5,"BCHAR"
		_PUSH 
		ADD TOS,UP,#BCHAR 
		_NEXT 

/*****************************************************
    temp	 ( -- a )
 	A temporary storage location used in parse and find.
hidden word for internal use
********************************************************/
TEMP:
	_PUSH
	ADD	TOS,UP,#TMP
	_NEXT

/*******************************************
    SPAN	( -- a )
 	Hold character count received by EXPECT.
********************************************/
	_HEADER SPAN,4,"SPAN"
	_PUSH
	ADD	TOS,UP,#CSPAN
	_NEXT

/***********************************************************
    >IN	 ( -- a )
 	Hold the character pointer while parsing input stream.
***********************************************************/
	_HEADER INN,3,">IN"
	_PUSH
	ADD	TOS,UP,#TOIN
	_NEXT

/**************************************
    #TIB	( -- a )
 	Hold the current count and address 
	of the terminal input buffer.
**************************************/
	_HEADER NTIB,4,"#TIB"
	_PUSH
	ADD	TOS,UP,#NTIBB
	_NEXT

/******************************
    'EVAL	( -- a )
 	Execution vector of EVAL.
*******************************/
	_HEADER TEVAL,5,"'EVAL"
	_PUSH
	ADD	TOS,UP,#EVAL
	_NEXT

/*********************************
    HLD	 ( -- a )
 	Hold a pointer in building a 
	numeric output string.
*********************************/
	_HEADER HLD,3,"HLD"
	_PUSH
	ADD	TOS,UP,#VHOLD
	_NEXT

/**********************************
    CONTEXT	( -- a )
 	A area to specify vocabulary 
	search order.
**********************************/
	_HEADER CNTXT,7,"CONTEXT"
CRRNT:
	_PUSH
	ADD	TOS,UP,#CTXT
	_NEXT

/******************************
    CP	( -- a )
 	Point to top free area  
	in user RAM. 
******************************/
	_HEADER CPP,2,"CP"
	_PUSH
	ADD	TOS,UP,#USER_CTOP
	_NEXT

/****************************
   FCP ( -- a )
  Point ot top of Forth 
  system dictionary
****************************/
	_HEADER FCP,3,"FCP"
	_PUSH 
	ADD TOS,UP,#FORTH_CTOP 
	_NEXT 

/***************************
    LAST	( -- a )
 	Point to the last name 
	in the dictionary.
***************************/
	_HEADER LAST,4,"LAST"
	_PUSH
	ADD	TOS,UP,#LASTN
	_NEXT


/***********************
	system constants 
***********************/

/********************************
	USER-BEGIN ( -- a )
  where user area begin in RAM
********************************/
	_HEADER USER_BEGIN,10,"USER-BEGIN"
	_PUSH 
	ldr TOS,USR_BGN_ADR 
	_NEXT 
USR_BGN_ADR:
.word  DTOP 

/*********************************
  USER_END ( -- a )
  where user area end in RAM 
******************************/
	_HEADER USER_END,8,"USER-END"
	_PUSH 
	ldr TOS,USER_END_ADR 
	_NEXT 
USER_END_ADR:
	.word DEND 

/********************************
	MAX-INT ( -- n+ )
	maximum integer 
*******************************/
	_HEADER MAXINT,7,"MAX-INT"
	_PUSH 
	_MOV32 TOS, 0x7FFFFFFF
	_NEXT 

/******************************
	MIN-INT ( -- n- )
	minimum integer 
******************************/
	_HEADER MININT,7,"MIN-INT"
	_PUSH 
	_MOV32 TOS, 0x80000000
	_NEXT 

/******************************
	MAX-UINT ( -- u )
	maximum unsigned integer 
******************************/
	_HEADER MAXUINT,8,"MAX-UINT"
	_PUSH
	_MOV32 TOS, 0xFFFFFFFF 
	_NEXT 


/* *********************
  Common functions
***********************/

/********************************
    WITHIN	( u ul uh -- t )
 	Return true if u is within 
	the range of ul and uh.
********************************/
	_HEADER WITHI,6,"WITHIN"
	_NEST
	_ADR	OVER
	_ADR	SUBB
	_ADR	TOR
	_ADR	SUBB
	_ADR	RFROM
	_ADR	ULESS
	_UNNEST

//  Divide

/*************************************
    UM/MOD	( udl udh u -- ur uq )
 	Unsigned divide of a double by a 
	single. Return mod and quotient.
**************************************/
	_HEADER UMMOD,6,"UM/MOD"
	MOV	T3,#1
	LDR	WP,[DSP],#4
	LDR	T2,[DSP]
UMMOD0:
	ADDS	T2,T2,T2
	ADCS	WP,WP,WP
	BCC	UMMOD1
	SUB	WP,WP,TOS
	ADD	T2,T2,#1
	B UMMOD2
UMMOD1:
	SUBS	WP,WP,TOS 
	IT CS 
	ADDCS	T2,T2,#1
	BCS	UMMOD2
	ADD	WP,WP,TOS
UMMOD2:
	ADDS	T3,T3,T3
	BCC	UMMOD0
	MOV	TOS,T2
	STR	WP,[DSP]
	_NEXT

/****************************
    FM/MOD	( d n -- r q )
 	Signed floored divide 
	of double by single. 
	Return mod and quotient.
****************************/
	_HEADER MSMOD,6,"FM/MOD"
	_NEST
	_ADR	DUPP
	_ADR	ZLESS
	_ADR	DUPP
	_ADR	TOR
	_QBRAN MMOD1
	_ADR	NEGAT
	_ADR	TOR
	_ADR	DNEGA
	_ADR	RFROM
MMOD1:
	_ADR	TOR
	_ADR	DUPP
	_ADR	ZLESS
	_QBRAN MMOD2
	_ADR	RAT
	_ADR	PLUS
MMOD2:
	_ADR	RFROM
	_ADR	UMMOD
	_ADR	RFROM
	_QBRAN	MMOD3
	_ADR	SWAP
	_ADR	NEGAT
	_ADR	SWAP
MMOD3:   
	_UNNEST

/****************************
	SM/REM (d n1 -- n2 n3 )
    symetric signed division 
	double by single 
input:
	d   signed double 
	n1  signed single 
output: 
	n2  signed remainder 
	n3  signed quotient 
****************************/
	_HEADER SMSLSHREM,6,"SM/REM"
	_NEST 
	_ADR DUPP 
	_ADR ZLESS 
	_ADR DUPP 
	_ADR TOR   // divisor sign 
	_QBRAN 1f 
	_ADR NEGAT 
1:  _ADR OVER 
	_ADR ZLESS 
	_ADR DUPP 
	_ADR TOR  // divident sign 
	_QBRAN  1f 
	_ADR TOR 
	_ADR DNEGA
	_ADR RFROM 
1:  _ADR UMMOD  // rem quot  
	_ADR RFROM 
	_ADR RAT 
	_ADR XORR
	_QBRAN 1f
	_ADR NEGAT 
1:  _ADR DUPP 
	_ADR ZLESS 
	_ADR RFROM 
	_ADR XORR 
	_QBRAN 1f 
	_ADR SWAP 
	_ADR NEGAT 
    _ADR SWAP 
1:  _UNNEST 


/****************************
	S>D ( n -- d )
	convert single to double 
*****************************/
	_HEADER STOD,3,"S>D"
	_PUSH 
	ASR TOS,#31
	_NEXT 

/****************************
	D2* ( d -- d<<1 )
	double * 2 
***************************/
	_HEADER D2STAR,3,"D2*"
	ldr T0,[DSP]
	lsls T0,#1
	str T0,[DSP]
	lsl TOS,#1
	adc TOS,#0
	_NEXT 

/****************************
	D2/  ( d -- d>>1 )
	double signed divide by 2 
*****************************/
	_HEADER D2SL,3,"D2/"
	ldr T0,[DSP]
	asrs TOS,#1
	rrx T0,T0 
	str T0,[DSP]
	_NEXT 

/***************************
	D/MOD  ( d+ n+ - r+ qd+ )
	unsigned double division
	and modulo 
	output:
		qd+ = d+ / n+
		r+ = qd+ - (d+ * n+ )
***************************/
	_HEADER DSLMOD,5,"D/MOD"
	ldr WP,[DSP]  // d+ high 
	ldr T0,[DSP,#4]   // d+ low, d+ = WP:T0, remainder WP
	mov T2,#32 // shift counter  
	eor T1,T1 // quotient T0:T1  
	cbnz WP,1f    
	eor T2,T2 // nos shifting required 
	mov WP,T0 
	eor T0,T0 
1:  cbz T2,2f   // shift divident for msb at WP:31 
    tst WP,#(1<<31) 
	bne 2f
	adds T1,T1,T1 
	adcs T0,T0,T0 
	adc WP,WP,WP 
	sub T2,#1 
	b 1b 
2:  udiv T3,WP,TOS
	orr T1,T3   // append partial quotient 
	mul T3,TOS
	sub WP,T3 //remainder 
	cbz T2,8f 
	b 1b 
8:	str WP,[DSP,#4] // remainder 
	str T1,[DSP]  // q lo 
	mov TOS,T0  // q hi 		
	_NEXT 


/****************************
	D/  ( ud u -- udq )
	divide unsigned double 
	by unsigned single 
	return double quotient
	rounded to nearest integer 
****************************/
	_HEADER DSLASH,2,"D/"
	_NEST 
	_ADR DUPP 
	_DOLIT 1 
	_ADR RSHIFT 
	_ADR TOR 
	_ADR DSLMOD 
	_ADR ROT 
	_ADR RFROM 
	_ADR GREAT 
	_QBRAN 9f
	_DOLIT 1 
	_ADR STOD 
	_ADR DPLUS 
9:	_UNNEST 


/****************************
	D* ( d s -- d )
    multiply a double 
	by a single 
****************************/
	_HEADER DSTAR,2,"D*"
/*
	_NEST 
	_ADR NROT 
	_ADR DUPP 
	_ADR TOR 
	_ADR DABS
	_ADR SWAP  
	_ADR ROT   
	_ADR DUPP
	_ADR TOR
	_ADR MSTAR
	_ADR ROT
	_ADR RFROM 
	_ADR STAR 
	_ADR PLUS
	_ADR RFROM 
	_ADR ZLESS 
	_QBRAN 9f
	_ADR DNEGA   
9:	_UNNEST 
*/
	ldr T0,[DSP],#4
	ldr T1,[DSP]
	str T0,[DSP] 
	eor T3,T3 
	tst T0,#(1<<31)
	beq 1f 
	// DNEGATE 
	subs T1,T3,T1  
	sbc T0,T3,T0 
1:	smull  T2,T1,T1,TOS // partial product 
	mul TOS,T0,TOS // second partial product 
	add TOS,T1  // TOS:T2 product  
	ldr r0,[DSP]
	tst T0,#(1<<31)
	beq 2f 
	// DNEGATE product 
	subs T2,T3,T2  
	sbc TOS,T3,TOS 
2:  str T2,[DSP]
	_NEXT 


/****************************
   /MOD	( n n -- r q )
	Signed divide. Return
	mod and quotient.
****************************/
	_HEADER SLMOD,4,"/MOD"
	_NEST
	_ADR	OVER
	_ADR	ZLESS
	_ADR	SWAP
	_ADR	MSMOD
	_UNNEST

/**************************
    MOD	 ( n n -- r )
 	Signed divide. Return
	mod only.
**************************/
	_HEADER MODD,3,"MOD"
	_NEST
	_ADR	SLMOD
	_ADR	DROP
	_UNNEST

/*************************
    /	   ( n n -- q )
 	Signed divide. Return
	quotient only.
**************************/
	_HEADER SLASH,1,"/"
	_NEST
	_ADR	SLMOD
	_ADR	SWAP
	_ADR	DROP
	_UNNEST

//******************************
//   */MOD	( n1 n2 n3 -- r q )
/*   Multiply n1 and n2, then 
   divide by n3. Return 
   mod and quotient.
******************************/
	_HEADER SSMOD,5,"*/MOD"
	_NEST
	_ADR	TOR
	_ADR	MSTAR
	_ADR	RFROM
	_ADR	MSMOD
	_UNNEST

//*******************************
//  */ ( n1 n2 n3 -- q )
/* 	Multiply n1 by n2, then 
	divide by n3. Return quotient
	only.
*******************************/
	_HEADER STASL,2,"*/"
	_NEST
	_ADR	SSMOD
	_ADR	SWAP
	_ADR	DROP
	_UNNEST

/*******************
  Miscellaneous
*******************/

/*************************
	CHAR+ ( a -- a+ )
	increment a by one 
	char size unit. 
*************************/
	_HEADER CHARP,5,"CHAR+"
	add TOS,#1
	_NEXT 

/*************************
	CHARS ( n1 -- n1 )
	address size of 
	n1 character
	same on this system 
*************************/
	_HEADER CHARS,5,"CHARS"
	_NEXT 



/*************************
	ALIGN ( -- )
	align data pointer 
	to cell boundary 
************************/
	_HEADER ALIGN,5,"ALIGN"
	ldr T0,[UP,#USER_CTOP]
	add T0,#(CELLL-1)
	and T0,#0xFFFFFFFC 
	str T0,[UP,#USER_CTOP]
	_NEXT 


/*************************
    ALIGNED	( b -- a )
 	Align address to the 
	cell boundary.
**************************/
	_HEADER ALGND,7,"ALIGNED"
	ADD	TOS,TOS,#3
	MVN	WP,#3
	AND	TOS,TOS,WP
	_NEXT

/****************************
    >CHAR	( c -- c )
 	Filter non-printing 
	characters.
****************************/
	_HEADER TCHAR,5,">CHAR"
	_NEST
	_DOLIT  0x7F
	_ADR	ANDD
	_ADR	DUPP	// mask msb
	_ADR	BLANK
	_DOLIT 	127
	_ADR	WITHI	// check for printable
	_ADR	INVER
	_QBRAN	TCHA1
	_ADR	DROP
	_DOLIT 	'_'	// replace non-printables
TCHA1:
	  _UNNEST

/************************
    DEPTH	( -- n )
 	Return the depth of
	the data stack.
***********************/
	_HEADER DEPTH,5,"DEPTH"
	_MOV32 T2,SPP 
	SUB	T2,T2,DSP
	_PUSH
	ASR	TOS,T2,#2
	_NEXT

/*****************************
    PICK	( ... +n -- ... w )
 	Copy the nth stack item 
	to tos.
******************************/
	_HEADER PICK,4,"PICK"
	lsl TOS,#2 
	ldr TOS,[DSP,TOS]
	_NEXT 

/*****************************
	PUT ( xn..x0 w i -- xi...x0 )
	put value w at position 
	xi on stack 
	i in range [0..n] 
*****************************/
	_HEADER PUT,3,"PUT"
	mov WP,TOS 
	_POP 
	lsl WP,#2 
	str TOS,[DSP,WP]
	_POP 
	_NEXT 

/*********************
  Memory access
*********************/

/*************************
    HERE	( -- a )
 	Return the top of
	the code dictionary.
*************************/
	_HEADER HERE,4,"HERE"
	_NEST
	_ADR	CPP
	_ADR	AT
	_UNNEST

/***************************	
    PAD	 ( -- a )
 	Return the address of 
	a temporary buffer.
***************************/
	_HEADER PAD,3,"PAD"
	_NEST
	_ADR	HERE
	_DOLIT 80
	_ADR PLUS 
	_UNNEST

/***********************
    TIB	 ( -- a )
 	Return the address 
	of the terminal 
	input buffer.
************************/
	_HEADER TIB,3,"TIB"
	_PUSH
	ldr TOS,[UP,#TIBUF]
	_NEXT

/*************************
	SOURCE-ID, ( -- 0 | -1 )
output:
	-1 	String (via EVALUATE)	
	0 	User input device
*****************************/
	_HEADER SOURCID,9,"SOURCE-ID"
	_PUSH 
	ldr TOS,[UP,#SRCID]
	_NEXT 


/***********************************
	SOURCE ( -- a u )
output:
	a  address of transaction buffer 
	u  # char in buffer 
***********************************/
	_HEADER SOURCE,6,"SOURCE"
	_NEST 
	_DOLIT  UPP+SRC 
	_ADR   DAT 
	_UNNEST 

/*************************
    @EXECUTE	( a -- )
 	Execute vector stored
	in address a.
*************************/
	_HEADER ATEXE,8,"@EXECUTE"
	MOVS	WP,TOS
	_POP
	LDR	WP,[WP]
	ORR	WP,WP,#1
    IT NE 
	BXNE	WP
	_NEXT

/*******************************
    CMOVE	( b1 b2 u -- )
 	Copy u bytes from b1 to b2.
********************************/
	_HEADER CMOVE,5,"CMOVE"
	CMP TOS,#1 
	BMI CMOV3 
	LDR	T2,[DSP],#4
	LDR	T3,[DSP],#4
	B CMOV1
CMOV0:
	LDRB	WP,[T3],#1
	STRB	WP,[T2],#1
CMOV1:
	MOVS	TOS,TOS
	BEQ	CMOV2
	SUB	TOS,TOS,#1
	B CMOV0
CMOV3: 
	ADD  DSP,#2*CELLL  
CMOV2:
	_POP
	_NEXT

/*********************************
	MOVE ( a1 a2 u -- )
	alias for CMOVE 
*********************************/
	_HEADER MOVE,4,"MOVE"
	B CMOVE 


/***************************
    WMOVE	( a1 a2 u -- )
 	Copy u byte from a1 to a2
	round u to upper modulo 4 
*******************************/
	_HEADER WMOVE,4,"WMOVE"
	MOV T0,#4
	ADD TOS,#3 
	BIC TOS,#3
	LDR	T1,[DSP],#4 // dest
	LDR	T2,[DSP],#4 // src 
	CMP T2,T1 
	BPL MOVE1
	MOV T0,#-4 
	ADD T1,TOS
	ADD T2,TOS 
	B MOVE3
MOVE0:
	LDR	WP,[T2]
	STR	WP,[T1]
MOVE3: 
	ADD T1,T0 
	ADD T2,T0 
MOVE1:
	MOVS TOS,TOS
	BEQ	MOVE2
	SUB	TOS,TOS,#4
	B MOVE0
MOVE2:
	_POP
	_NEXT

/**************************
    FILL	( b u c -- )
 	Fill u bytes of character
	c to area beginning at b.
******************************/
	_HEADER FILL,4,"FILL"
	LDMFD DSP!,{T0,T1} 
	MOVS T0,T0 
	BEQ FILL2
FILL1:
	STRB	TOS,[T1],#1
	SUBS	T0,T0,#1
	BNE FILL1
FILL2:
	_POP
	_NEXT

/*****************************
    PACK$	( b u a -- a )
 	Build a counted word with
	u characters from b. 
	Null fill.
*****************************/
	_HEADER PACKS,5,"PACK$"
	_NEST
	_ADR	ALGND
	_ADR	DUPP
	_ADR	TOR		// strings only on cell boundary
	_ADR	OVER
	_ADR	PLUS
	_ADR	ONEP 
	_DOLIT 	0xFFFFFFFC
	_ADR	ANDD			// count mod cell
	_DOLIT 	0
	_ADR	SWAP
	_ADR	STORE			// null fill cell
	_ADR	RAT
	_ADR	DDUP
	_ADR	CSTOR
	_ADR	ONEP			// save count
	_ADR	SWAP
	_ADR	CMOVE
	_ADR	RFROM
	_UNNEST   			// move string

/***********************************
  Numeric output, single precision
***********************************/

/**************************
    DIGIT	( u -- c )
 	Convert digit u to 
	a character.
***************************/
	_HEADER DIGIT,5,"DIGIT"
	_NEST
	_DOLIT 9
	_ADR	OVER
	_ADR	LESS
	_DOLIT	7
	_ADR	ANDD
	_ADR	PLUS
	_DOLIT	'0'
	_ADR	PLUS 
	_UNNEST

/*********************************
    EXTRACT	( ud base -- ud c )
 	Extract the least significant
	digit from positive double.
**********************************/
	_HEADER EXTRC,7,"EXTRACT"
	_NEST
	_ADR	DSLMOD
	_ADR	ROT
	_ADR	DIGIT
	_UNNEST

/***************************
    <#	  ( -- )
 	Initiate the numeric
	output process.
****************************/
	_HEADER BDIGS,2,"<#"
	_NEST
	_ADR	PAD
	_ADR	HLD
	_ADR	STORE
	_UNNEST

/*********************************
    HOLD	( c -- )
 	Insert a character into the 
	numeric output string.
**********************************/
	_HEADER HOLD,4,"HOLD"
	_NEST
	_ADR	HLD
	_ADR	AT
	_ADR	ONEM
	_ADR	DUPP
	_ADR	HLD
	_ADR	STORE
	_ADR	CSTOR
	_UNNEST

/***********************
    #	   ( ud -- ud )
 	Extract one digit 
	from ud and append 
	the digit to output 
	string.
*************************/
	_HEADER DIG,1,"#"
	_NEST
	_ADR	BASE
	_ADR	AT
	_ADR	EXTRC
	_ADR	HOLD
	_UNNEST

/***************************
    #S	  ( ud -- 0 )
 	Convert ud until all 
	digits are added to 
	the output string.
***************************/
	_HEADER DIGS,2,"#S"
	_NEST
DIGS1:
    _ADR	DIG
	_ADR	DDUP
	_ADR    ORR 
	_QBRAN 	DIGS2
	_BRAN	DIGS1
DIGS2:
	 _ADR DROP 
	 _UNNEST

/*********************
    SIGN	( n -- )
 	Add a minus sign
	to the numeric
	output string.
*********************/
	_HEADER SIGN,4,"SIGN"
	_NEST
	_ADR	ZLESS
	_QBRAN	SIGN1
	_DOLIT '-'
	_ADR	HOLD
SIGN1:
	  _UNNEST

/*************************
    #>  ( w -- b u )
 	Prepare the output 
	word to be TYPE'd.
************************/
	_HEADER EDIGS,2,"#>"
	_NEST
	_ADR	DROP
	_ADR	HLD
	_ADR	AT
	_ADR	PAD
	_ADR	OVER
	_ADR	SUBB
	_UNNEST

/**************************
    str	 ( n -- b u )
 	Convert a signed 
	integer to a numeric 
	string.
hidden word used by compiler
***************************/
STRR:
	_NEST
	_ADR 	STOD 
	_ADR	DUPP
	_ADR	TOR
	_ADR	DABS
	_ADR	BDIGS
	_ADR	DIGS
	_ADR	RFROM
	_ADR	SIGN
	_ADR	EDIGS
	_UNNEST

/*************************
    HEX	 ( -- )
 	Use radix 16 as 
	base for numeric 
	conversions.
*************************/
	_HEADER HEX,3,"HEX"
	_NEST
	_DOLIT 16
	_ADR	BASE
	_ADR	STORE
	_UNNEST

/**************************
	BIN ( -- )
	Use radix 2 as 
	base for numeric 
	conversion 
**************************/
	_HEADER BIN,3,"BIN"
	_NEST 
	_DOLIT 2 
	_ADR BASE 
	_ADR STORE
	_UNNEST 

/************************
    DECIMAL	( -- )
 	Use radix 10 as base
	for numeric conversions.
*************************/
	_HEADER DECIM,7,"DECIMAL"
	_NEST
	_DOLIT 10
	_ADR	BASE
	_ADR	STORE
	_UNNEST

/************************************
  Numeric input
***********************************/

/***********************************
    DIGIT?	( c base -- u t )
 	Convert a character to its 
	numeric value. A flag 
	indicates success.
**********************************/
	_HEADER DIGTQ,6,"DIGIT?"
	_NEST
	_ADR	TOR
	_DOLIT 	'0'
	_ADR	SUBB
	_DOLIT 9
	_ADR	OVER
	_ADR	LESS
	_QBRAN	DGTQ1
	_DOLIT 7
	_ADR	SUBB
	_ADR	DUPP
	_DOLIT	10
	_ADR	LESS
	_ADR	ORR
DGTQ1:
	_ADR	DUPP
	_ADR	RFROM
	_ADR	ULESS
	_UNNEST


/*****************************************
	>NUMBER ( ud1 adr1 u1 -- ud2 adr2 u2 )
  convert unsigned double string 
  to double integer adding to ud1 
input:
	ud1  unsiged double 
	adr1  string address 
	u1    string length 
outpout:
	ud2   modifield ud1 
	adr2  point to char not converted 
	u2    char left in string 
**************************************/
	_HEADER TONBR,7,">NUMBER"
	_NEST 
	_ADR DUPP 
	_QBRAN 9f 
1: 	_ADR OVER  // d a u a 
	_ADR CAT   // d  a u c 
	_ADR BASE   
	_ADR AT      // d a u c base
	_ADR DIGTQ   // d a u n flag 
	_QBRAN 8f
	_ADR TOR   	 
	_ADR ONEM 
	_ADR DSWAP // a u d 
	_ADR BASE 
	_ADR AT 
	_ADR DSTAR 
	_ADR RFROM 
	_DOLIT 0    
	_ADR DPLUS 
	_ADR DSWAP 
	_ADR SWAP 
	_ADR ONEP
	_ADR SWAP  
	_BRAN 1b 
8:  _ADR DROP
9:	_UNNEST 


/**************************
 CHAR? ( a cnt c -- a+ cnt- t | a cnt f )
 check for charcter c 
 move pointer if *a==c  
**************************/
CHARQ:
    ldr T0,[DSP,#4]
    ldrb T1,[T0],#1 
    mov T2,TOS 
    eor TOS,TOS
    cmp T1,T2
    bne 1f 
    str T0,[DSP,#4]
	ldr T0,[DSP]
	sub T0,#1 
	str T0,[DSP]
    mvn TOS,TOS  
1:  _NEXT


/*********************************
   NEG? ( a cnt -- a cnt f |a+ cnt- t )
   skip '-'|'+' return -1 if '-' 
   else return 0 
*********************************/
NEGQ: 
	_PUSH 
	eor TOS,TOS // false flag 
	ldr T0,[DSP,#4]
	ldrb T1,[T0],#1
	cmp T1,#'-' 
	beq 1f
	cmp T1,#'+'
	bne 3f 
	b 2f 
1:  mvn TOS,TOS  // true flag 
2:	str T0,[DSP,#4]
	ldr T0,[DSP]
	sub T0,#1 
	str T0,[DSP]
3:	_NEXT 



/**********************************
    INT?	( a -- n T | a F )
 	parse string  at 'a' for 
	integer. Push a flag on TOS.
	integer form:
		[-]hex_digit+  | 
		$[-]hex_digit+ |
		%[-]bin_digit+ | 
		[-]dec_digit+ 
**********************************/
	_HEADER INTQ,4,"INT?"
	_NEST
// save BASE 	
	_ADR	BASE
	_ADR	AT
	_ADR	TOR
	_DOLIT	0      // a 0 
	_ADR	OVER   // a 0 a 
	_ADR	COUNT  // a 0 a+ cnt 
	_DOLIT  '$' 
	_ADR    CHARQ 
	_QBRAN  0f 
// hexadecimal number 
	_ADR    HEX
	_BRAN   2f 
0:  _DOLIT  '%'   // -- a 0 a cnt '%'
	_ADR	CHARQ  // -- a 0 a cnt f 
	_QBRAN  2f
	_ADR	BIN 
2: // check if negative number 
	_ADR    NEGQ 
	_ADR	TOR  // -- a 0 a+ cnt- R: sign 
	_DOLIT  0
	_ADR	DUPP 
	_ADR	DSWAP // a 0 0 0 a+ cnt- R: sign 
	_ADR    TONBR // a 0 d a+ cnt 
	_QBRAN  2f
    // not an integer 
	_ADR RFROM // a 0 d a sign  
	_ADR DDROP 
	_ADR DDROP 
	_BRAN 7f 
2: // valid integer 
	_ADR	DROP // a 0 d
	_ADR    DSWAP 
	_ADR    DDROP 
	_ADR    DROP  // d>s 
	_ADR    RFROM // n sign 
	_QBRAN  2f
	_ADR    NEGAT   
2:	_DOLIT  -1 
7: // restore BASE 
	_ADR	RFROM
	_ADR	BASE
	_ADR	STORE
	_UNNEST


/********************************
    NUMBER? ( a -- int -1 | float -2 | a 0 )
    parse number, integer or float 
    if not a number return ( a 0 ) 
    if integer return ( int -1 ) 
    if float return ( float -2 )
**********************************/
    _HEADER NUMBERQ,7,"NUMBER?"
    _NEST 
    _ADR INTQ
    _ADR QDUP 
    _QBRAN 2f 
    _UNNEST 
2:  _ADR FLOATQ
    _UNNEST 


/********************
  console I/O
********************/

/**********************
    SPACE	( -- )
 	Send the blank 
	character to 
	the output device.
************************/
	_HEADER SPACE,5,"SPACE"
	_NEST
	_ADR	BLANK
	_ADR	EMIT
	_UNNEST

/***************************
    SPACES	( +n -- )
 	Send n spaces to the 
	output device.
****************************/
	_HEADER SPACS,6,"SPACES"
	_NEST
	_DOLIT	0
	_ADR	MAX
	_ADR	TOR
	_BRAN	CHAR2
CHAR1:
	_ADR	SPACE
CHAR2:
	_DONXT	CHAR1
	_UNNEST

/***********************
    TYPE	( b u -- )
 	Output u characters 
	from b.
************************/
	_HEADER TYPEE,4,"TYPE"
	_NEST
	_ADR  TOR   // ( a+1 -- R: u )
	_BRAN	TYPE2
TYPE1:  
	_ADR  COUNT
	_ADR TCHAR
	_ADR EMIT
TYPE2:  
	_DONXT	TYPE1
	_ADR	DROP
	_UNNEST

/***************************
    CR	  ( -- )
 	Output a carriage return
	and a line feed.
****************************/
	_HEADER CR,2,"CR"
	_NEST
	_DOLIT	CRR
	_ADR	EMIT
	_DOLIT	LF
	_ADR	EMIT
	_UNNEST

/******************************************
  do_$	( -- a u )
  Return the address of a compiled string.
  adjust return address to skip over it.
hidden word used by compiler. 
******************************************/
DOSTR:
	_NEST     
/* compiled string address is 2 levels deep */
	_ADR	RFROM	// { -- a1 }
	_ADR	RFROM	//  {a1 -- a1 a2 } 
	_ADR	DUPP	// {a1 a2 -- a1 a2 a2 }
	_ADR	COUNT	//  get addr+1 count  { a1 a2 -- a1 a2 a2+1 c }
	_ADR	PLUS	// { -- a1 a2 a2+1+c }
	_ADR	ALGND	//  end of string
//	_ADR	ONEP	//  restore b0, this result in return address 2 level deep.
	_ADR	TOR		//  address after string { -- a1 a2 }
	_ADR	SWAP	//  count tugged
	_ADR	TOR     //  ( -- a2) is string address
	_ADR    COUNT  //   ( a2 -- a2+1 cnt )
	_UNNEST

/******************************************
    $"|	( -- a u )
 	Run time routine compiled by _". 
	Return address of a compiled string.
hidden word used by compiler
*****************************************/
STRQP:
	_NEST
	_ADR	DOSTR
	_UNNEST			// force a call to dostr


/**********************
    ."|	( -- )
 	Run time routine of ." 
	Output a compiled string.
hidden word used by compiler
*****************************/
DOTQP:
	_NEST
	_ADR	DOSTR
	_ADR	TYPEE 
	_UNNEST

/*************************
	LPAD  ( n+ -- )
	emit n spaceS + 
	base character  
	16 -> $
	 2 -> %
	 other -> none 
*************************/
LPAD:
	_NEST 
	_ADR BCHR 
	_ADR  AT 
	_QBRAN 3f 
	_ADR BASE 
	_ADR AT 
	_ADR DUPP 
	_DOLIT 16
	_ADR EQUAL 
	_QBRAN 1f
	_ADR DROP 
	_DOLIT '$'
0:	_ADR  SWAP 
	_ADR  ONEM 
	_ADR  SPACS 
	_ADR  EMIT 
	_UNNEST 
1:  _DOLIT 2 
	_ADR EQUAL 
	_QBRAN 3f
	_DOLIT '%'
	_BRAN 0b   	
3:	_ADR  SPACS 
	_UNNEST 


/******************************
    .R	  ( n +n -- )
 	Display an integer in a 
	field of n columns, 
	right justified.
*******************************/
	_HEADER DOTR,2,".R"
	_NEST
	_ADR	TOR
	_ADR    STOD 
	_ADR	DTOA 
	_ADR	RFROM
	_ADR	OVER
	_ADR	SUBB
	_ADR    LPAD  
	_ADR	TYPEE
	_UNNEST


/*************************
    U.R	 ( u +n -- )
 	Display an unsigned 
	integer in n column, 
	right justified.
***************************/
	_HEADER UDOTR,3,"U.R"
	_NEST
	_ADR    TOR 
	_DOLIT  0
	_ADR    DTOA 
	_ADR	RFROM
	_ADR	OVER
	_ADR	SUBB
	_ADR    LPAD  
	_ADR	TYPEE
	_UNNEST


/************************
    U.	  ( u -- )
 	Display an unsigned 
	integer in free format.
***************************/
	_HEADER UDOT,2,"U."
	_NEST
	_DOLIT  0 
	_ADR	BDIGS
	_ADR	DIGS
	_ADR	EDIGS
	_DOLIT  1 
	_ADR	LPAD  
	_ADR	TYPEE
	_UNNEST


/************************
    .	   ( w -- )
 	Display an integer 
	in free format, 
	preceeded by a space.
**************************/
	_HEADER DOT,1,"."
	_NEST
	_ADR    SPACE 
	_ADR	BASE
	_ADR	AT
1:	_DOLIT  10
	_ADR	XORR	// decimal base?
	_QBRAN	DOT1
	_ADR	UDOT    // no,display unsigned
	_UNNEST			
DOT1:
	_ADR    STOD 
    _ADR	DTOA
	_DOLIT  1 
	_ADR	LPAD  
1:	_ADR	TYPEE
	_UNNEST			// yes, display signed


/*************************
  D>A ( d -- p u )
  convert double integer to 
  ASCII string in pad  
input:
	d    int64 to convert 
output:
	p     pointer to string  
	u     string length 
**************************/
	_HEADER DTOA,3,"D>A" 
	_NEST
    _ADR DUPP 
	_ADR TOR 
	_ADR DABS 
	_ADR BDIGS
	_ADR DIGS 
	_ADR RFROM 
	_ADR SIGN  
	_ADR EDIGS 
	_UNNEST 


/*************************
   D. ( d -- )
   display double integer 
**************************/
	_HEADER DDOT,2,"D."
	_NEST
	_ADR SPACE 
	_ADR DTOA 
	_DOLIT 1
	_ADR LPAD 
	_ADR TYPEE
	_UNNEST 

/**************************
	UD. ( d -- )
	display unsigned double
**************************/
	_HEADER UDDOT,3,"UD."
	_NEST
	_ADR SPACE 
	_ADR BDIGS
	_ADR DIGS 
	_ADR EDIGS 
	_DOLIT 1
	_ADR LPAD 
	_ADR TYPEE
	_UNNEST 



/***********************
	H. ( w -- )
	display integer 
	in hexadecimal 
*********************/
	_HEADER HDOT,2,"H."
	_NEST 
	_ADR BASE
	_ADR AT 
	_ADR SWAP
	_ADR HEX
	_DOLIT 0 
	_ADR BDIGS
	_ADR DIGS
	_ADR EDIGS
	_ADR SPACE
	_DOLIT '$'
	_ADR EMIT 
	_ADR TYPEE
	_ADR BASE
	_ADR STORE  
	_UNNEST 


/***********************
    ?	   ( a -- )
 	Display the contents
	in a memory cell.
*************************/
	_HEADER QUEST,1,"?"
	_NEST
	_ADR	AT
	_ADR	DOT
	_UNNEST

/**************
  Parsing
***************/

/*********************************************
    parse	( b u c -- b u delta //  string> )
 	Scan word delimited by c. 
	Return found string and its offset.
hidden word used by PARSE
**********************************************/
PARS:
	_NEST
	_ADR	TEMP
	_ADR	STORE
	_ADR	OVER
	_ADR	TOR
	_ADR	DUPP
	_QBRAN	PARS8
	_ADR	ONEM
	_ADR	TEMP
	_ADR	AT
	_ADR	BLANK
	_ADR	EQUAL
	_QBRAN	PARS3
	_ADR	TOR
PARS1:
	_ADR	BLANK
	_ADR	OVER
	_ADR	CAT	 // skip leading blanks 
	_ADR	SUBB
	_ADR	ZLESS
	_ADR	INVER
	_QBRAN	PARS2
	_ADR	ONEP
	_DONXT	PARS1
	_ADR	RFROM
	_ADR	DROP
	_DOLIT	0
	_ADR	DUPP
	_UNNEST
PARS2:
	_ADR	RFROM
PARS3:
	_ADR	OVER
	_ADR	SWAP
	_ADR	TOR
PARS4:
	_ADR	TEMP
	_ADR	AT
	_ADR	OVER
	_ADR	CAT
	_ADR	SUBB // scan for delimiter
	_ADR	TEMP
	_ADR	AT
	_ADR	BLANK
	_ADR	EQUAL
	_QBRAN	PARS5
	_ADR	ZLESS
PARS5:
	_QBRAN	PARS6
	_ADR	ONEP
	_DONXT	PARS4
	_ADR	DUPP
	_ADR	TOR
	_BRAN	PARS7
PARS6:
	_ADR	RFROM
	_ADR	DROP
	_ADR	DUPP
	_ADR	ONEP
	_ADR	TOR
PARS7:
	_ADR	OVER
	_ADR	SUBB
	_ADR	RFROM
	_ADR	RFROM
	_ADR	SUBB
	_UNNEST
PARS8:
	_ADR	OVER
	_ADR	RFROM
	_ADR	SUBB
	_UNNEST

/************************************
    PARSE	( c -- b u //  string> )
 	Scan input stream and return 
	counted string delimited by c.
************************************/
	_HEADER PARSE,5,"PARSE"
	_NEST
	_ADR	TOR
	_ADR	TIB
	_ADR	INN
	_ADR	AT
	_ADR	PLUS			// current input buffer pointer
	_ADR	NTIB
	_ADR	AT
	_ADR	INN
	_ADR	AT
	_ADR	SUBB			// remaining count
	_ADR	RFROM
	_ADR	PARS
	_ADR	INN
	_ADR	PSTOR
	_UNNEST

/*******************************
    .(	  ( -- )
 	Output following string 
	up to next ) .
******************************/
	_HEADER DOTPR,IMEDD+2,".("
	_NEST
	_DOLIT	')'
	_ADR	PARSE
	_ADR	TYPEE
	_UNNEST

/************************
    (	   ( -- )
 	Ignore following 
	string up to next )
	A comment.
************************/
	_HEADER PAREN,IMEDD+1,"("
	_NEST
	_DOLIT	')'
	_ADR	PARSE
	_ADR	DDROP
	_UNNEST

/*******************
    \	   ( -- )
 	Ignore following 
	text till the 
	end of line.
********************/
	_HEADER BKSLA,IMEDD+1,"\\"
	_NEST
	_ADR	NTIB
	_ADR	AT
	_ADR	INN
	_ADR	STORE
	_UNNEST

/******************************
    CHAR	( -- c )
 	Parse next word and
	return its first character.
*******************************/
	_HEADER CHAR,4,"CHAR"
	_NEST
	_ADR	BLANK
	_ADR	PARSE
	_ADR	DROP
	_ADR	CAT
	_UNNEST

/**********************************
	[CHAR] ( -- c )
	immediate version of CHAR 
**********************************/
	_HEADER IMCHAR,COMPO+IMEDD+6,"[CHAR]"
	_NEST 
	_ADR CHAR
	_ADR LITER 
	_UNNEST 

/**********************************
    WORD	( c -- a //  string> )
 	Parse a word from input stream
	and copy it to code dictionary.
***********************************/
	_HEADER WORDD,4,"WORD"
	_NEST
	_ADR	PARSE
	_ADR	HERE
	_ADR	CELLP
	_ADR	PACKS
	_UNNEST

/********************************
    TOKEN	( -- a //  string> )
 	Parse a word from input 
	stream and copy it to 
	name dictionary.
*********************************/
	_HEADER TOKEN,5,"TOKEN"
	_NEST
	_ADR	BLANK
	_ADR	WORDD
	_ADR	UPPER 
	_UNNEST

/**********************
  Dictionary search
***********************/

/*************************
    >CFA	( nfa -- cfa )
 	Return a code field address
	given a name field address.
**************************/
	_HEADER TOCFA,4,">CFA"
	_NEST
	_ADR	COUNT
	_DOLIT	0x1F
	_ADR	ANDD
	_ADR	PLUS
	_ADR	ALGND
	_UNNEST

/***************************************
    SAME?	( a1 a2 u -- a1 a2 f | -0+ )
 	Compare u bytes in two strings. 
	Return 0 if identical.

  Picatout 2020-12-01, 
    Because of problem with .align 
	directive that doesn't fill 
	with zero's I had to change 
	the "SAME?" and "SEARCH" 
 	words  to do a byte by byte comparison. 
****************************************/
	_HEADER SAMEQ,5,"SAME?"
	_NEST
	_ADR	TOR
	_BRAN	SAME2
SAME1:
	_ADR	OVER  // ( a1 a2 -- a1 a2 a1 )
	_ADR	RAT   // a1 a2 a1 u 
	_ADR	PLUS  // a1 a2 a1+u 
	_ADR	CAT	   // a1 a2 c1    		
	_ADR	OVER  // a1 a2 c1 a2 
	_ADR	RAT    
	_ADR	PLUS    
	_ADR	CAT	  // a1 a2 c1 c2
	_ADR	SUBB  
	_ADR	QDUP
	_QBRAN	SAME2
	_ADR	RFROM
	_ADR	DROP
	_UNNEST	// strings not equal
SAME2:
	_DONXT	SAME1
	_DOLIT	0
	_UNNEST	// strings equal

/***********************************
    SEARCH	( a na -- ca na | a F )
 	Search a vocabulary for a string.
	Return ca and na if succeeded.
hidden word used by NAME?

  Picatout 2020-12-01,  
	 Modified from original. 
   See comment for word "SAME?" 
************************************/
SEARCH:
	_NEST
	_ADR	SWAP			// na a	
	_ADR	COUNT			// na a+1 count
	_ADR	DUPP 
	_ADR	TEMP
	_ADR	STORE			// na a+1 count 
	_ADR  TOR		// na a+1  R: count  
	_ADR	SWAP			// a+1 na
SEARCH1:
	_ADR	DUPP			// a+1 na na
	_QBRAN	SEARCH6	// end of vocabulary
	_ADR	DUPP			// a+1 na na
	_ADR	CAT			// a+1 na name1
	_DOLIT	MASKK
	_ADR	ANDD
	_ADR	RAT			// a+1 na name1 count 
	_ADR	XORR			// a+1 na,  same length?
	_QBRAN	SEARCH2
	_ADR	CELLM			// a+1 la
	_ADR	AT			// a+1 next_na
	_BRAN	SEARCH1			// try next word
SEARCH2:   
	_ADR	ONEP			// a+1 na+1
	_ADR	TEMP
	_ADR	AT			// a+1 na+1 count
	_ADR	SAMEQ		// a+1 na+1 ? 
SEARCH3:	
	_BRAN	SEARCH4
SEARCH6:	
	_ADR	RFROM			// a+1 0 name1 -- , no match
	_ADR	DROP			// a+1 0
	_ADR	SWAP			// 0 a+1
	_ADR	ONEM			// 0 a
	_ADR	SWAP			// a 0 
	_UNNEST			// return without a match
SEARCH4:	
	_QBRAN	SEARCH5			// a+1 na+1
	_ADR	ONEM			// a+1 na
	_ADR	CELLM			// a+4 la
	_ADR	AT			// a+1 next_na
	_BRAN	SEARCH1			// compare next name
SEARCH5:	
	_ADR	RFROM			// a+1 na+1 count
	_ADR	DROP			// a+1 na+1
	_ADR	SWAP			// na+1 a+1
	_ADR	DROP			// na+1
	_ADR	ONEM			// na
	_ADR	DUPP			// na na
	_ADR	TOCFA			// na ca
	_ADR	SWAP			// ca na
	_UNNEST			//  return with a match

/********************************
    NAME?	( a -- ca na | a F )
 	Search all context vocabularies 
	for a string.
***********************************/
	_HEADER NAMEQ,5,"NAME?"
	_NEST
	_ADR	CNTXT
	_ADR	AT
	_ADR	SEARCH
	_UNNEST

/********************
  console input
********************/

/****************************
	ASCIZ ( a -- a+ )
	convert counted string to 
	null terminated string 
	in pad.
*****************************/
	_HEADER ASCIZ,5,"ASCIZ" 
	_NEST 
	_ADR COUNT
	_ADR DUPP
	_ADR TOR 
	_ADR PAD 
	_ADR SWAP
	_ADR WMOVE  
	_ADR PAD 
	_ADR RFROM
	_ADR PLUS 
	_DOLIT 0 
	_ADR SWAP  
	_ADR CSTOR
	_ADR PAD   
	_UNNEST 

/***********************
	UPPER (cstring -- cstring )
	convert to upper case in situ
*******************************/
	_HEADER UPPER,5,"UPPER"
	_NEST 
	_ADR DUPP 
	_ADR TOR 
	_ADR COUNT
	_DOLIT 0x1f
	_ADR ANDD
	_ADR TOR 
	_BRAN 3f
1:  _ADR DUPP 
	_ADR COUNT 
	_ADR DUPP 
	_DOLIT 'a'-1
	_ADR GREAT
	_QBRAN 2f 
	_ADR DUPP 
	_DOLIT 'z'+1 
	_ADR LESS 
	_QBRAN 2f 
	_DOLIT 0x5f  
	_ADR ANDD
2:	_ADR ROT
	_ADR CSTOR
3:  _DONXT 1b
	_ADR DROP 
	_ADR RFROM
	_UNNEST 

/**************************************
   BKSP  ( bot eot cur -- bot eot cur )
   Move cursor left by one character.
hidden word used by KTAP
***************************************/
BKSP:
	_NEST
	_ADR	TOR
	_ADR	OVER
	_ADR	RFROM
	_ADR	SWAP
	_ADR	OVER
	_ADR	XORR
	_QBRAN	BACK1
	_DOLIT	BKSPP
	_ADR	EMIT
	_ADR	ONEM
	_ADR	BLANK
	_ADR	EMIT
	_DOLIT	BKSPP
	_ADR	EMIT
BACK1:
	  _UNNEST

/****************************************
   TAP	 ( bot eot cur c -- bot eot cur )
   Accept and echo the key stroke 
   and bump the cursor.
hidden word used by KTAP 
****************************************/
TAP:
	_NEST
	_ADR	DUPP
	_ADR	EMIT
	_ADR	OVER
	_ADR	CSTOR
	_ADR	ONEP
	_UNNEST


/*******************************************
    kTAP	( bot eot cur c -- bot eot cur )
 	Process a key stroke, CR or backspace.
hidden word used by ACCEPT 
*******************************************/
KTAP:
TTAP:
	_NEST
	_ADR	DUPP
	_DOLIT	CRR
	_ADR	XORR
	_QBRAN  KTAP2
	_DOLIT	BKSPP
	_ADR	XORR
	_QBRAN	KTAP1
	_ADR	BLANK
	_ADR	TAP
	_UNNEST
//	.word	0			// patch
KTAP1:
	_ADR	BKSP
	_UNNEST
KTAP2:
	_ADR	DROP
	_ADR	SWAP
	_ADR	DROP
	_ADR	DUPP
	_UNNEST

/************************************
    ACCEPT	( b u -- b u )
 	Accept characters to input 
	buffer. Return with actual count.
*************************************/
	_HEADER ACCEP,6,"ACCEPT"
	_NEST
	_ADR	OVER
	_ADR	PLUS
	_ADR	OVER
ACCP1:
	_ADR	DDUP
	_ADR	XORR
	_QBRAN	ACCP4
	_ADR	KEY
	_ADR	DUPP
	_ADR	BLANK
	_DOLIT 127
	_ADR	WITHI
	_QBRAN	ACCP2
	_ADR	TAP
	_BRAN	ACCP3
ACCP2:
	_ADR	KTAP
ACCP3:	  
	_BRAN	ACCP1
ACCP4:
	_ADR	DROP
	_ADR	OVER
	_ADR	SUBB
	_UNNEST

/*****************************
    QUERY	( -- )
 	Accept input stream 
	to terminal input buffer.
******************************/
	_HEADER QUERY,5,"QUERY"
	_NEST
	_ADR	TIB
	_DOLIT 80
	_ADR	ACCEP
	_ADR	NTIB
	_ADR	STORE
	_ADR	DROP
	_DOLIT	0
	_ADR	INN
	_ADR	STORE
	_UNNEST

/********************
  Error handling
********************/

/*********************
    ABORT	( a -- )
 	Reset data stack 
	and jump to QUIT.
**********************/
	_HEADER ABORT,5,"ABORT"
	_NEST
ABORT1: 
	_ADR    LBRAC  
	_ADR	PRESE
	_DOLIT  0 
	_ADR    DUPP 
	_DOLIT  UPP+TOIN 
	_ADR    DSTOR 
	_DOLIT  TIBB 
	_DOLIT  UPP+TIBUF  
	_ADR    STORE 
	_ADR    CR 
	_BRAN	QUIT


/*******************************
	PRT_ABORT ( a -- )
    print message and abort 
input:
	a   address of counted string 	

hidden word 
*******************************/
PRT_ABORT:
	_NEST 
	_ADR SPACE 
	_ADR COUNT 
	_ADR TYPEE 
	_ADR  SPACE 
	_DOLIT '?'
	_ADR    EMIT 
	_ADR    CR 
	_BRAN   ABORT1 




/*******************************
    _abort"	( f -- )
 	Run time routine of ABORT"
	Abort with a message.
hidden used by compiler 
********************************/
ABORQ:
	_NEST
	_ADR	DOSTR
	_ADR	ROT  
	_QBRAN	1f	// error flag
	_ADR    SPACE 
	_ADR    TYPEE
	_ADR    CR  
	_BRAN   ABORT1
1:
	_ADR	DDROP
	_UNNEST			// drop message


/************************
  The text interpreter
************************/

/***************************
    $INTERPRET  ( a -- )
 	Interpret a word. 
	If failed, try to 
	convert it to an integer.
******************************/
	_HEADER INTER,10,"$INTERPRET"
	_NEST
	_ADR	NAMEQ
	_ADR	QDUP	// ?defined
	_QBRAN	INTE1
	_ADR	AT
	_DOLIT	COMPO
	_ADR	ANDD	// ?compile only lexicon bits
	_ABORQ	13," compile only"
	_ADR	EXECU
	_UNNEST			// execute defined word
INTE1:
	_ADR	NUMBERQ
	_QBRAN	INTE2
	_UNNEST
INTE2:
	_ADR	PRT_ABORT	// error

/******************************
    [	   ( -- )
 	Start the text interpreter.
*******************************/
	_HEADER LBRAC,IMEDD+1,"["
	_NEST
	_DOLIT	INTER
	_ADR	TEVAL
	_ADR	STORE
	_DOLIT  0 
	_ADR    STATE 
	_ADR    STORE 
	_UNNEST

/**********************
    .OK	 ( -- )
 	Display "ok" only 
	while interpreting.
************************/
	_HEADER DOTOK,3,".OK"
	_NEST
	_DOLIT	INTER
	_ADR	TEVAL
	_ADR	AT
	_ADR	EQUAL
	_QBRAN	DOTO1
	_DOTQP	3," ok"
DOTO1:
	_ADR	CR
	_UNNEST

/*************************
    ?STACK	( -- )
 	Abort if the data 
	stack underflows.
************************/
	_HEADER QSTAC,6,"?STACK"
	_NEST
	_ADR	DEPTH
	_ADR	ZLESS	// check only for underflow
	_ABORQ	9,"underflow"
	_UNNEST

/*******************
    EVAL	( -- )
 	Interpret the 
	input stream.
*******************/
	_HEADER EVAL,4,"EVAL"
	_NEST
EVAL1:
    _ADR	TOKEN
	_ADR	DUPP
	_ADR	CAT	// ?input stream empty
	_QBRAN	EVAL2
	_ADR	TEVAL
	_ADR	ATEXE
	_ADR	QSTAC	// evaluate input, check stack
	_BRAN	EVAL1
EVAL2:
	_ADR	DROP
	_ADR	DOTOK
	_UNNEST	// prompt


/******************************
	EVALUATE ( ix* a u -- jx* )
    interpret string 
input:
    ix*  argument required 
	a   address string to interpret 
	u   str length 
output:
	jx*  evalution results 
***********************************/
	_HEADER EVALUATE,8,"EVALUATE"
	_NEST 
	// save original source specs
	_DOLIT UPP+TOIN 
	_ADR   DUPP 
	_ADR  AT 
	_ADR   TOR 
	_DOLIT  0
	_ADR  SWAP
	_ADR   STORE 
	_DOLIT UPP+SRC 
	_ADR   DAT 
	_ADR   DTOR 
	_DOLIT -1
	_DOLIT UPP+SRCID 
	_ADR   STORE 
	_DOLIT UPP+SRC 
	_ADR   DSTOR
	_ADR   EVAL 
    // restore original source specs 
	_ADR   DRFROM 
	_DOLIT UPP+SRC 
	_ADR   DSTOR 
	_ADR   RFROM 
	_DOLIT UPP+TOIN 
	_ADR   STORE 
	_DOLIT 0 
	_DOLIT UPP+SRCID 
	_ADR   STORE 
	_UNNEST 


/**********************************
    PRESET	( -- )
 	Reset data stack pointer 
	and the terminal input buffer.
**********************************/
	_HEADER PRESE,6,"PRESET"
	_MOV32 DSP,SPP 
	_NEXT 


/*********************
    QUIT	( -- )
 	Reset return stack 
	pointer and start 
	text interpreter.
***********************/
	_HEADER QUIT,4,"QUIT"
	_DOLIT RPP 
	_ADR RPSTOR 
QUIT1:
	_ADR	LBRAC			// start interpretation
QUIT2:
	_ADR	QUERY			// get input
	_ADR	EVAL
	_BRAN	QUIT2	// continue till error

/***************************
	FORGET ( <string> -- )
	forget all definition 
	starting at <string>
****************************/
	_HEADER FORGET,6,"FORGET"
	_NEST 
	_ADR TOKEN 
	_ADR DUPP 
	_QBRAN 9f 
	_ADR NAMEQ // ( a -- ca na | a 0 )
	_ADR QDUP 
	_QBRAN 8f
	_ADR CELLM // ( ca la )
	_ADR DUPP 
	_ADR CPP   
	_ADR STORE
	_ADR AT 
	_ADR LAST 
	_ADR STORE
	_ADR OVERT 
8:  _ADR DROP 
9:	_UNNEST 

	.p2align 2 

/*****************
  The compiler
******************/

/**************************************
	POSTPONE <name> ( -- )
	use to compile immediate word 
**************************************/
	_HEADER POSTPONE,COMPO+IMEDD+8,"POSTPONE"
	_NEST 
	_ADR ITICK
	_ADR CALLC  
	_UNNEST 


/**************************************
    '	   ( -- ca )
 	Search context vocabularies 
	for the next word in input stream.
***************************************/
	_HEADER TICK,1,"'"
	_NEST
	_ADR	TOKEN
	_ADR	NAMEQ	// ?defined
	_QBRAN	TICK1
	_UNNEST	// yes, push code address
TICK1:
	_ADR PRT_ABORT	// error

/*****************************************
	['] ( -- ca )
	immediate version of ' 
****************************************/
	_HEADER ITICK,COMPO+IMEDD+3,"[']"
	_NEST 
	_ADR TICK  
	_UNNEST 


/***********************************
	FIND ( c-adr -- c-adr 0 | xt 1 | xt -1 )
	search all context for name at 
	c-adr 
input:
	c-adr   name 
output:
	c-adr  0   not found 
	xt 1   found word immediate 
	xt -1  found normal word 
***********************************/
	_HEADER FIND,4,"FIND"
	_NEST 
	_ADR NAMEQ 
	_ADR DUPP 
	_QBRAN 9f
	_ADR CAT 
	_DOLIT IMEDD
	_ADR ANDD 
	_DOLIT 7 
	_ADR RSHIFT  
	_ADR DUPP 
	_TBRAN 9f 
	_ADR INVER 
9:	_UNNEST 



/***********************
    ALLOT	( n -- )
 	Allocate n bytes to 
	the ram area.
************************/
	_HEADER ALLOT,5,"ALLOT"
	_NEST
	_ADR	CPP
	_ADR	PSTOR
	_UNNEST			// adjust code pointer

/******************************
    ,	   ( w -- )
 	Compile an integer 
	into dataspace.
******************************/
	_HEADER COMMA,1,","
	_NEST
	_ADR	HERE
	_ADR	DUPP
	_ADR	CELLP	// cell boundary
	_ADR	CPP
	_ADR	STORE
	_ADR	STORE
	_UNNEST	// adjust code pointer, compile
	.p2align 2 

/***********************************
	C, ( c -- )
	compile 1 character into 
	dataspace 
************************************/
	_HEADER CCOMMA,2,"C,"
	_NEST 
	_ADR 	HERE 
	_ADR	DUPP 
	_ADR    ONEP 
	_ADR    CPP 
	_ADR    STORE 
	_ADR    CSTOR 
	_UNNEST 

/************************************
    [COMPILE]   ( -- //  string> )
 	Compile the next immediate word 
	into code dictionary.
*************************************/
	_HEADER BCOMP,IMEDD+9,"[COMPILE]"
	_NEST
	_ADR	TICK
	_ADR	COMMA
	_UNNEST

/****************************
    COMPILE	( -- )
 	Compile the next address 
	in colon list to code 
	dictionary.
*******************************/
	_HEADER COMPI,COMPO+7,"COMPILE"
	_NEST
	_ADR	RFROM
	_ADR	DUPP 
	_ADR	AT
	_DOLIT 1 
	_ADR	ORR 
	_ADR	COMMA 
	_ADR	CELLP 
	_ADR	TOR 
	_UNNEST	// adjust return address

/*************************
    LITERAL	( w -- )
 	Compile tos to code 
	dictionary as an 
	integer literal.
***************************/
	_HEADER LITER,IMEDD+7,"LITERAL"
	_NEST
	_COMPI	DOLIT
	_ADR	COMMA
	_UNNEST

/********************
    $,"	( -- )
 	Compile a literal 
	string up to next " .
hidden word 
************************/
STRCQ:
	_NEST
	_DOLIT -4
	_ADR	CPP
	_ADR	PSTOR
	_DOLIT	'\"'
	_ADR	WORDD	// move word to code dictionary
	_ADR	COUNT
	_ADR	PLUS
	_ADR	ALGND	// calculate aligned end of string
	_ADR	CPP
	_ADR	STORE   // adjust the code pointer
	_UNNEST 			

/*******************
   Structures
*******************/

/*************************
    FOR	 ( -- a )
 	Start a FOR-NEXT loop 
	structure in a colon 
	definition.
**************************/
	_HEADER FOR,COMPO+IMEDD+3,"FOR"
	_NEST
	_COMPI	TOR
	_ADR	HERE
	_UNNEST

/********************************
	DO ( limit start -- )
	initialise a DO...LOOP 
	or DO...+LOOP 
********************************/
	_HEADER DO,COMPO+IMEDD+2,"DO"
	_NEST
	_COMPI SWAP
	_COMPI TOR 
	_COMPI TOR 
	_ADR HERE 
	_DOLIT 0  // end marker used by resolve_leave 
	_UNNEST 

DOPLOOP: // ( n -- R: limit counter )
	mov T2,TOS 
	_POP 
	ldmfd RSP!,{T0,T1}
	add T0,T2 
	stmfd RSP!,{T0,T1}
	cmp T0,T1 
	bmi 9f 
	add RSP,#8
	add IP,#4
	_NEXT 
9:  ldr IP,[IP]
	_NEXT 
	
/***************************
	+LOOP ( a -- )
	increment counter 
	end loop if countr>limit
****************************/
	_HEADER PLOOP,COMPO+IMEDD+5,"+LOOP"
	_NEST 
	_COMPI DOPLOOP 
	_ADR resolve_leave 
	_ADR COMMA
	_UNNEST 

DOLOOP: // ( -- R: limit counter )
	ldr T0,[RSP]
	add T0,#1
	str T0,[RSP]
	ldr T1,[RSP,#4]
	cmp T0,T1 
	bmi 9f
	add RSP,#8  // drop counter and limit  
	add IP,IP,#4 // skip loop address 
	_NEXT 
9:  ldr IP,[IP]
	_NEXT 


resolve_leave:
	_NEST
1:	_ADR QDUP 
	_QBRAN 2f 
	_ADR HERE 
	_ADR CELLP 
	_ADR SWAP 
	_ADR STORE 
	_BRAN 1b 
2:
	_UNNEST 

/********************************
	LOOP ( a -- )
	increment counter 
	end loop if >= limit 
*********************************/
	_HEADER LOOP,COMPO+IMEDD+4,"LOOP"
	_NEST 
	_COMPI DOLOOP
	_ADR resolve_leave 
	_ADR COMMA  // resolve loop branch 
	_UNNEST 

/************************************
	UNLOOP ( -- ) ( R: limit count -- )
	remove loop parameters from rstack 
****************************************/
	_HEADER UNLOOP,6,"UNLOOP"
	add RSP,#2*CELLL 
	_NEXT 


/*********************************
	LEAVE ( -- ) ( R: loop-sys -- ) 
	exit inner DO...LOOP 
**********************************/
	_HEADER LEAVE,COMPO+IMEDD+5,"LEAVE"
	_NEST 
	_COMPI DOLEAVE
	_ADR HERE
	_ADR OVER 
	_QBRAN 1f
	_ADR SWAP 
1:	_DOLIT 0 
	_ADR COMMA   
	_UNNEST 

// LEAVE runtime
// remove limit and counter from rstack  
DOLEAVE:
	add RSP,#2*CELLL
	ldr IP,[IP] 
	_NEXT 


/**********************
    BEGIN	( -- a )
 	Start an infinite 
	or indefinite 
	loop structure.
************************/
	_HEADER BEGIN,COMPO+IMEDD+5,"BEGIN"
	_NEST
	_ADR	HERE
	_UNNEST
	.p2align 2 

/********************
    NEXT	( a -- )
 	Terminate a FOR-NEXT
	loop structure.
**************************/
	_HEADER FNEXT,COMPO+IMEDD+4,"NEXT"	
	_NEST
	_COMPI	DONXT
	_ADR	COMMA
	_UNNEST

/***************************
	I ( -- n )
	stack for loop counter 
***************************/
	_HEADER I,1+COMPO,"I"
	_PUSH 
	ldr TOS,[RSP]
	_NEXT 

/****************************
	J ( -- n )
	stack outer loop counter 
****************************/
	_HEADER J,1,"J"
	_PUSH 
	ldr TOS,[RSP,#4]
	_NEXT 

/**********************
    UNTIL	( a -- )
 	Terminate a BEGIN-UNTIL
	indefinite loop structure.
******************************/
	_HEADER UNTIL,COMPO+IMEDD+5,"UNTIL"
	_NEST
	_COMPI	QBRAN
	_ADR	COMMA
	_UNNEST

/**********************
    AGAIN	( a -- )
 	Terminate a BEGIN-AGAIN
	infinite loop structure.
*****************************/
	_HEADER AGAIN,COMPO+IMEDD+5,"AGAIN"
	_NEST
	_COMPI	BRAN
	_ADR	COMMA
	_UNNEST

/************************
    IF	  ( -- A )
 	Begin a conditional
	branch structure.
**************************/
	_HEADER IFF,COMPO+IMEDD+2,"IF"
	_NEST
	_COMPI	QBRAN
	_ADR	HERE
	_DOLIT	4
	_ADR	CPP
	_ADR	PSTOR
	_UNNEST

/*************************
    AHEAD	( -- A )
 	Compile a forward 
	branch instruction.
*************************/
	_HEADER AHEAD,COMPO+IMEDD+5,"AHEAD"
	_NEST
	_COMPI	BRAN
	_ADR	HERE
	_DOLIT	4
	_ADR	CPP
	_ADR	PSTOR
	_UNNEST

/**************************
    REPEAT	( A a -- )
 	Terminate a BEGIN-WHILE-REPEAT
	indefinite loop.
**********************************/
	_HEADER REPEA,COMPO+IMEDD+6,"REPEAT"
	_NEST
	_ADR	AGAIN
	_ADR	HERE
	_ADR	SWAP
	_ADR	STORE
	_UNNEST

/*********************
    THEN	( A -- )
 	Terminate a conditional
	branch structure.
*****************************/
	_HEADER THENN,COMPO+IMEDD+4,"THEN"
	_NEST
	_ADR	HERE
	_ADR	SWAP
	_ADR	STORE
	_UNNEST

/***************************
    AFT	 ( a -- a A )
 	Jump to THEN in a 
	FOR-AFT-THEN-NEXT loop 
	the first time through.
*****************************/
	_HEADER AFT,COMPO+IMEDD+3,"AFT"
	_NEST
	_ADR	DROP
	_ADR	AHEAD
	_ADR	BEGIN
	_ADR	SWAP
	_UNNEST

/**********************
    ELSE	( A -- A )
 	Start the false 
	clause in an 
	IF-ELSE-THEN structure.
****************************/
	_HEADER ELSEE,COMPO+IMEDD+4,"ELSE"
	_NEST
	_ADR	AHEAD
	_ADR	SWAP
	_ADR	THENN
	_UNNEST

/**************************
    WHILE	( a -- A a )
 	Conditional branch out 
	of a BEGIN-WHILE-REPEAT loop.
*********************************/
	_HEADER WHILE,COMPO+IMEDD+5,"WHILE"
	_NEST
	_ADR	IFF
	_ADR	SWAP
	_UNNEST

/**********************************
	RECURSE ( -- )
	compile recursive call to 
	actual defined word 
***********************************/
	_HEADER RECURSE,COMPO+IMEDD+7,"RECURSE"
	_NEST 
	_ADR LAST
	_ADR AT  
	_ADR TOCFA 
	_ADR CALLC  
	_UNNEST 


/***********************************
    ABORT"	( -- //  string> )
 	Conditional abort with an 
	error message.
***********************************/
	_HEADER ABRTQ,IMEDD+COMPO+6,"ABORT\""
	_NEST
	_COMPI	ABORQ
	_ADR	STRCQ
	_UNNEST

/******************************
    S"	( -- //  string> )
 	Compile an inline 
	word literal.
*****************************/
	_HEADER STRQ,IMEDD+COMPO+2,"S\""
	_NEST
	_COMPI	STRQP
	_ADR	STRCQ
	_UNNEST

/******************************
    ."	( -- //  string> )
 	Compile an inline word
	literal to be typed out 
	at run time.
*******************************/
	_HEADER DOTQ,IMEDD+COMPO+2,".\""
	_NEST
	_COMPI	DOTQP
	_ADR	STRCQ
	_UNNEST

/*********************
  Name compiler
***********************/

/**************************
    ?UNIQUE	( a -- a )
 	Display a warning 
	message if the word 
	already exists.
**************************/
	_HEADER UNIQU,7,"?UNIQUE"
	_NEST
	_ADR	DUPP
	_ADR	NAMEQ			// ?name exists
	_QBRAN	UNIQ1	// redefinitions are OK
	_DOTQP	7," reDef "		// but warn the user
	_ADR	OVER
	_ADR	COUNT
	_ADR	TYPEE			// just in case its not planned
UNIQ1:
	_ADR	DROP
	_UNNEST

/***********************
    $,n	 ( na -- )
 	Build a new dictionary 
	name using the data at na.
hidden word 
*******************************/
SNAME:
	_NEST
	_ADR	DUPP			//  na na
	_ADR	CAT			//  ?null input
	_QBRAN	SNAM1
	_ADR	UNIQU			//  na
	_ADR	LAST			//  na last
	_ADR	AT			//  na la
	_ADR	COMMA			//  na
	_ADR	DUPP			//  na na
	_ADR	LAST			//  na na last
	_ADR	STORE			//  na , save na for vocabulary link
	_ADR	COUNT			//  na+1 count
	_ADR	PLUS			//  na+1+count
	_ADR	ALGND			//  word boundary
	_ADR	CPP
	_ADR	STORE			//  top of dictionary now
	_UNNEST
SNAM1:
	_ADR	STRQP
	.byte	7
	.ascii " name? "
	_ADR	PRT_ABORT

/************************
    $COMPILE	( a -- )
 	Compile next word to 
	code dictionary as 
	a token or literal.
**************************/
	_HEADER SCOMP,8,"$COMPILE"
	_NEST
	_ADR	NAMEQ
	_ADR	QDUP	// defined?
	_QBRAN	SCOM2
	_ADR	AT
	_DOLIT	IMEDD
	_ADR	ANDD	// immediate?
	_QBRAN	SCOM1
	_ADR	EXECU
	_UNNEST			// it's immediate, execute
SCOM1:
	_ADR	CALLC			// it's not immediate, compile
	_UNNEST	
SCOM2:
	_ADR	NUMBERQ 
	_QBRAN	SCOM3
	_ADR	LITER
	_UNNEST			// compile number as integer
SCOM3: // compilation abort 
	_ADR COLON_ABORT 
	_ADR	PRT_ABORT			// error

/********************************
 before aborting a compilation 
 reset HERE and LAST
 to previous values. 
*******************************/
COLON_ABORT:
	_NEST 
	_ADR LAST 
	_ADR AT 
	_ADR CELLM 
	_ADR DUPP 
	_ADR CPP  
	_ADR STORE 
	_ADR AT 
	_ADR LAST 
	_ADR STORE 
	_ADR OVERT 
	_UNNEST 

/*********************
    OVERT	( -- )
 	Link a new word 
	into the current 
	vocabulary.
**********************/
	_HEADER OVERT,5,"OVERT"
	_NEST
	_ADR	LAST
	_ADR	AT
	_ADR	CNTXT
	_ADR	STORE
	_UNNEST

/**********************
    ;  ( -- )
 	Terminate a colon
	definition.
***********************/
	_HEADER SEMIS,IMEDD+COMPO+1,";"
	_NEST
	_DOLIT	UNNEST
	_ADR	CALLC
	_ADR    ALIGN 
	_ADR	LBRAC
	_ADR	OVERT
	_UNNEST

/******************
    ]	   ( -- )
 	Start compiling 
	the words in 
	the input stream.
*********************/
	_HEADER RBRAC,1,"]"
	_NEST
	_DOLIT	SCOMP
	_ADR	TEVAL
	_ADR	STORE
	_DOLIT  -1
	_ADR    STATE 
	_ADR    STORE 
	_UNNEST

/****************************
    CALLC	( ca -- )
 	compile ca.
hidden word used by compiler
*****************************/
CALLC:
	_NEST
	_DOLIT 1 
	_ADR ORR 
	_ADR COMMA  
	_UNNEST 


/*************************
 	:	( -- //  string> )
 	Start a new colon 
	definition using 
	next word as its name.
**************************/
	_HEADER COLON,1,":"
	_NEST
	_ADR    ALIGN 
	_ADR	TOKEN
	_ADR	SNAME
	_ADR	COMPI_NEST 
	_ADR	RBRAC
	_UNNEST

/*************************
    IMMEDIATE   ( -- )
 	Make the last compiled 
	word an immediate word.
***************************/
	_HEADER IMMED,9,"IMMEDIATE"
	_NEST
	_DOLIT	IMEDD
	_ADR	LAST
	_ADR	AT
	_ADR	AT
	_ADR	ORR
	_ADR	LAST
	_ADR	AT
	_ADR	STORE
	_UNNEST

/******************
  Defining words
******************/

	.p2align 2 
/****************************************
 doDOES> ( -- a )
 runtime action of 		 
 leave parameter field address on stack 
hidden word used by compiler 
***************************************/
DODOES:
	_NEST 
	_ADR	RFROM
	_ADR	CELLP 
	_ADR	ONEP  
	_ADR LAST 
	_ADR AT
	_ADR TOCFA 
	_ADR TOVECTOR  
	_ADR STORE  
	_UNNEST 

	.p2align 2
/**********************
  DOES> ( -- )
  compile time action
*************************/
	_HEADER DOES,IMEDD+COMPO+5,"DOES>"
	_NEST 
	_DOLIT DODOES 
	_ADR CALLC 
	_DOLIT	UNNEST
	_ADR	CALLC 
	_ADR COMPI_NEST
//	_DOLIT RFROM 
//	_ADR   CALLC
 	_UNNEST 


/****************************
  DEFER@ ( cfa1 -- cfa2 )

******************************/
	_HEADER DEFERAT,6,"DEFER@"
	_NEST 
	_ADR TOBODY
	_ADR AT 
	_UNNEST 


/*********************************
 DEFER! ( cfa1 cfa2 -- )
 assign an action to a defered word 
************************************/
	_HEADER DEFERSTO,6,"DEFER!"
	_NEST 
	_ADR TOBODY 
	_ADR STORE 
	_UNNEST

/****************************
  DEFER ( "name" -- )
  create a defered definition
*****************************/
	_HEADER DEFER,5,"DEFER"
	_NEST 
	_ADR CREAT
	_DOLIT NOP  
	_ADR  CALLC 
	_DOLIT  AT 
	_ADR   CALLC 
	_DOLIT  EXECU
	_ADR   CALLC   
	_DOLIT UNNEST 
	_ADR  CALLC 
	_UNNEST 



/*********************************
	:NONAME  ( -- xt )
	create a colon word without 
	name. 
output:
	xt  exécution token of 
	new definition
*********************************/
	_HEADER NONAME,7,":NONAME"
	_NEST 
	_ADR 	HERE 
	_ADR	COMPI_NEST 
	_ADR 	RBRAC
	_UNNEST 

/*******************************
	IS cccc ( xt -- )
input:
   cccc  defered word name 
   xt    execution token 
   to be affected to the 
   defered word.
********************************/
	_HEADER IS,IMEDD+2,"IS"
	_NEST
	_ADR STATE 
	_ADR AT 
	_QBRAN 1f 
	_DOLIT ITICK
	_ADR CALLC  
	_DOLIT DEFERSTO
	_ADR CALLC
	_BRAN 2f    
1:  _ADR TICK 
	_ADR DEFERSTO 
2:	_UNNEST 


/******************************
    CREATE	( -- //  string> )
 	Compile a new array entry 
	without allocating code space.
***********************************/
	_HEADER CREAT,6,"CREATE"
	_NEST 
	_ADR	ALIGN 
	_ADR	TOKEN
	_ADR	SNAME
	_ADR	OVERT
	_ADR	COMPI_NEST 
	_DOLIT	DOVAR
	_ADR	CALLC
	_DOLIT  NOP     // reserved slot    
	_ADR    CALLC   // for DOES> vector 
	_DOLIT  UNNEST 
	_ADR    CALLC 
	_UNNEST

/*******************************
  doVAR	( -- a )
  Run time routine for VARIABLE and CREATE.
hidden word used by compiler
********************************/
DOVAR:
	_PUSH
	MOV TOS,IP
	ADD TOS,#2*CELLL // >BODY 
	_NEXT  


/*******************************
    VARIABLE	( -- //  string> )
 	Compile a new variable 
	initialized to 0.
***********************************/
	_HEADER VARIA,8,"VARIABLE"
	_NEST
	_ADR	CREAT
	_DOLIT	0
	_ADR	COMMA
	_UNNEST

/**********************************
    doCON	( -- a ) 
 	Run time routine for CONSTANT.
hidden word used by compiler 
***********************************/
DOCON:
	_PUSH
	LDR.W TOS,[IP],#4 
	B UNNEST 


/***********************************
    CONSTANT	( u -- //  string> )
 	Compile a new constant.
************************************/
	_HEADER CONST,8,"CONSTANT"
	_NEST 
	_ADR	TOKEN
	_ADR	SNAME
	_ADR	OVERT
	_ADR	COMPI_NEST
	_DOLIT	DOCON
	_ADR	CALLC
	_ADR	COMMA
	_DOLIT	UNNEST 
	_ADR	CALLC  
	_UNNEST


/***********
  Tools
***********/

/*************************
    dm+	 ( a u -- a )
 	Dump u bytes from a , 
	leaving a+u on the stack.
	hidden word used by DUMP 
****************************/
DMP:
	_NEST
	_ADR	OVER
	_DOLIT	4
	_ADR	UDOTR			// display address
	_DOLIT  0         // don't show base char 
	_ADR    BCHR
	_ADR    DUPP
	_ADR    AT 
	_ADR    TOR      // save original value of BCHAR 
	_ADR    STORE 
	_ADR	SPACE
	_ADR	TOR			// start count down loop
	_BRAN	PDUM2			// skip first pass
PDUM1:
    _ADR	DUPP
	_ADR	CAT
	_DOLIT	3
	_ADR	UDOTR			// display numeric data
	_ADR	ONEP			// increment address
PDUM2:
    _ADR	DONXT
	.word	PDUM1	// loop till done
	_ADR    RFROM   // restore BCHAR value 
	_ADR    BCHR 
	_ADR    STORE 
	_UNNEST
	.p2align 2 
//    DUMP	( a u -- )
// 	Dump u bytes from a, in a formatted manner.

/**********************
	DUMP ( a n -- )
	hex dump memory 
*********************/
	_HEADER DUMP,4,"DUMP"
	_NEST
	_DOLIT  15 
	_ADR    PLUS 
	_DOLIT  0xFFFFFFF0 
	_ADR    ANDD 
	_ADR    SWAP 
	_DOLIT  0xFFFFFFFC
	_ADR    ANDD 
	_ADR    SWAP 
	_ADR	BASE
	_ADR	AT
	_ADR	TOR
	_ADR	HEX			// save radix,set hex
	_DOLIT	16
	_ADR	SLASH			// change count to lines
	_ADR	TOR
	_BRAN	DUMP4			// start count down loop
DUMP1:
    _ADR	CR
	_DOLIT	16
	_ADR	DDUP
	_ADR	DMP			// display numeric
	_ADR	ROT
	_ADR	ROT
	_ADR	SPACE
	_ADR	SPACE
	_ADR	TYPEE			// display printable characters
DUMP4:
  _DONXT	DUMP1	// loop till done
DUMP3:
	_ADR	DROP
	_ADR	RFROM
	_ADR	BASE
	_ADR	STORE			// restore radix
	_UNNEST

/*******************************
   TRACE. display in hexadecimal
   TRACE. use a different buffer 
   than DOT  to avoid current 
   display overwrite.
*******************************/ 
TDOT: // ( u -- )
	_NEST 
	_ADR BASE 
	_ADR AT 
	_ADR TOR
	_ADR HEX  
	_ADR HLD 
	_ADR AT 
	_ADR TOR   // R: base *hold 
	_ADR HERE 
	_DOLIT 160 
	_ADR PLUS
	_ADR DUPP 
	_ADR TOR  
	_ADR HLD 
	_ADR STORE
	_DOLIT 0  
	_ADR DIGS  
	_ADR DROP
	_DOLIT '$'
	_ADR HOLD 
	_ADR HLD 
	_ADR AT
	_ADR RFROM   
	_ADR OVER 
	_ADR SUBB 
	_ADR SPACE 
	_ADR TYPEE 
	_ADR RFROM 
	_ADR HLD 
	_ADR STORE 
	_ADR RFROM 
	_ADR BASE 
	_ADR STORE 
	_UNNEST 

/**********************
   .S	  ( ... -- ... )
 	Display the contents 
	of the data stack.
*************************/
	_HEADER DOTS,2,".S"
	_NEST
	_ADR	DEPTH	// stack depth
	_ADR	TOR		// start count down loop
	_BRAN	DOTS2  // skip first pass
DOTS1:
	_ADR	RAT
	_ADR	PICK
	_ADR	TDOT // index stack, display contents
DOTS2:
	_DONXT	DOTS1 // loop till done
	_ADR	CR 
	_UNNEST

RBASE: 
	_PUSH 
	_MOV32 TOS,RPP 
	_NEXT 


/**************************
  R.  display return stack 
**************************/
RDOT: 
	_NEST 
	_ADR RBASE
	_ADR RPAT 
	_ADR SUBB
	_ADR CELLSL   
	_DOLIT 2
	_ADR SUBB 
	_ADR TOR
	_ADR RBASE 
1:	_ADR CELLM 
	_ADR DUPP 
	_ADR AT 
	_ADR TDOT 
	_ADR RFROM   
	_ADR ONEM 
	_ADR DUPP
	_ADR TOR 
	_ADR ZEQUAL   
	_QBRAN 1b
	_ADR RFROM  
	_ADR DDROP
	_ADR CR   
	_UNNEST 

/**************************
	TRACE ( -- )
	display stacks content 
**************************/
	_HEADER TRACE,5,"TRACE"
	_NEST
	_ADR CR 
	_DOLIT '>' 
	_DOLIT 'S'
	_ADR EMIT 
	_ADR EMIT  
	_ADR DOTS
	_DOLIT '>'
	_DOLIT 'R'
	_ADR EMIT 
	_ADR EMIT 
	_ADR RDOT 
	_UNNEST 


/****************************
  >BODY  ( xt -- adr )
  get parameter field address
  from code field address 
****************************/
	_HEADER TOBODY,5,">BODY"
	add TOS,#4*CELLL   
	_NEXT 		

/*****************************
	>VECTOR ( xt -- adr )
	for words defined by 
	CREATE  return 
	address vector slot 
	for DOES> 
hidden word.	
*****************************/
TOVECTOR:
	add TOS,#2*CELLL
	_NEXT 

/*****************************
    >NFA	( cfa -- nfa | F )
 	Convert code address 
	to a name address.
*****************************/
	_HEADER TONFA,4,">NFA"
	_NEST
	_ADR	TOR			//  
	_ADR	CNTXT			//  va
	_ADR	AT			//  nfa
TNAM1:
	_ADR	DUPP			//  nfa nfa
	_QBRAN	TNAM2	//  vocabulary end, no match
	_ADR	DUPP			//  nfa nfa
	_ADR	TOCFA			//  nfa ca
	_ADR	RAT			//  nfa cfa code
	_ADR	XORR			//  nfa f --
	_QBRAN	TNAM2
	_ADR	CELLM			//  la 
	_ADR	AT			//  next_nfa
	_BRAN	TNAM1
TNAM2:	
	_ADR	RFROM
	_ADR	DROP			//  0|nfa --
	_UNNEST			// 0

/********************************
    .ID	 ( na -- )
 	Display the name at address.
********************************/
	_HEADER DOTID,3,".ID"
	_NEST
	_ADR	QDUP			// if zero no name
	_QBRAN	DOTI1
	_ADR	COUNT
	_DOLIT	0x1F
	_ADR	ANDD			// mask lexicon bits
	_ADR	TYPEE
	_UNNEST			// display name string
DOTI1:
	_DOTQP	9," {noName}"
	_UNNEST

	.equ WANT_SEE, 0  // set to 1 if you want SEE 
.if WANT_SEE 
/*******************************
    SEE	 ( -- //  string> )
 	A simple decompiler.
*******************************/
	_HEADER SEE,3,"SEE"
	_NEST
	_ADR	TICK	//  ca --, starting address
	_ADR	CR	
	_DOLIT	20
	_ADR	TOR
SEE1:
	_ADR	CELLP			//  a
	_ADR	DUPP			//  a a
	_ADR	DECOMP		//  a
	_DONXT	SEE1
	_ADR	DROP
	_UNNEST

/*************************
 	DECOMPILE ( a -- )
 	Convert code in a.  
	Display name of command or as data.
*************************************/
	_HEADER DECOMP,9,"DECOMPILE"
	_NEST
	_ADR	DUPP			//  a a
// 	_ADR	TOR			//  a
	_ADR	AT			//  a code
	_ADR	DUPP			//  a code code
	_DOLIT	0xF800D000 //0xF800F800
	_ADR	ANDD
	_DOLIT	0xF000D000 //0xF800F000
	_ADR	EQUAL			//  a code ?
	_ADR	INVER 
	_QBRAN	DECOM2	//  not a command
	//  a valid_code --, extract address and display name
	MOVW	IP,#0xFFE
	MOV	WP,TOS
	LSL	TOS,TOS,#21		//  get bits 22-12
	ASR	TOS,TOS,#9		//  with sign extension
	LSR	WP,WP,#15		//  get bits 11-1
	AND	WP,WP,IP		//  retain only bits 11-1
	ORR	TOS,TOS,WP		//  get bits 22-1
	NOP
	_ADR	OVER			//  a offset a
	_ADR	PLUS			//  a target-4
	_ADR	CELLP			//  a target
	_ADR	TONFA			//  a na/0 --, is it a name?
	_ADR	QDUP			//  name address or zero
	_QBRAN	DECOM1
	_ADR	SPACE			//  a na
	_ADR	DOTID			//  a --, display name
// 	_ADR	RFROM			//  a
	_ADR	DROP
	_UNNEST
DECOM1:	// _ADR	RFROM		//  a
	_ADR	AT			//  data
	_ADR	UDOT			//  display data
	_UNNEST
DECOM2:
	_ADR	UDOT
// 	_ADR	RFROM
	_ADR	DROP
	_UNNEST
.endif 


/*********************
    WORDS	( -- )
 	Display the names 
	in the context vocabulary.
*******************************/
	_HEADER WORDS,5,"WORDS"
	_NEST
	_ADR	CR
	_ADR	CNTXT
	_ADR	AT			// only in context
WORS1:
	_ADR	QDUP			// ?at end of list
	_QBRAN	WORS2
	_ADR	DUPP
	_ADR	SPACE
	_ADR	DOTID			// display a name
	_ADR	CELLM
	_ADR	AT
	_BRAN	WORS1
WORS2:
	_UNNEST


/*************************
	MARK <string> ( -- )
    create forget point 
	in dictionary 
*************************/	
	_HEADER MARK,4,"MARK"
	_NEST
	_ADR CREAT 
	_ADR DODOES 
	_UNNEST
	_NEST  
	_ADR RFROM 
	_DOLIT 8
	_ADR SUBB
	_ADR TONFA
	_ADR CELLM
	_ADR AT  
	_ADR LAST 
	_ADR STORE 
	_ADR OVERT
	_UNNEST 

/*********************************
	ARRAY "name" ( n -- )
    create an array of n elements 
*********************************/
	_HEADER ARRAY,5,"ARRAY"
	_NEST 
	_ADR	TOKEN
	_ADR	SNAME
	_ADR	OVERT
	_ADR	COMPI_NEST
	_DOLIT	DO_ARRAY
	_ADR	CALLC
	_DOLIT	UNNEST 
	_ADR	CALLC  
	_DOLIT  4 
	_ADR    STAR 
	_ADR    ALLOT 
	_UNNEST 	

// does> du array
DO_ARRAY:
	_NEST  
	_DOLIT 4 
	_ADR STAR  
	_ADR RAT  
	_ADR CELLP 
	_ADR PLUS  
	_UNNEST 


/****************
  cold start
*****************/

/**********************************
    VER	 ( -- n )
 	Return the version 
	number of this implementation.
hidden word used by COLD
**********************************/
VERSN:
	_NEST
	_DOLIT	VER*256+EXT
	_UNNEST

/*********************
    hi	  ( -- )
 	Display the sign-on 
	message.
***********************/
	_HEADER HI,2,"HI"
	_NEST
	_ADR	CR	// initialize I/O
	_DOTQP	17, "beyond Jupiter, v" 
	_ADR	BASE
	_ADR	AT
	_ADR	HEX	// save radix
	_ADR	VERSN
	_ADR	BDIGS
	_DOLIT  0 
	_ADR	DIG
	_ADR	DIG
	_DOLIT	'.'
	_ADR	HOLD
	_ADR	DIGS
	_ADR	EDIGS
	_ADR	TYPEE	// format version number
	_ADR	BASE
	_ADR	STORE
	_ADR	CR
	_UNNEST			// restore radix

/***********************
   HI_BOTH ( -- )
   display sign-on 
   on both CONSOLE
***********************/
HI_BOTH:
    _NEST 
	_ADR LOCAL 
	_ADR CONSOLE 
	_ADR HI 
	_ADR SERIAL 
	_ADR CONSOLE 
	_ADR HI
	_UNNEST 

/**********************
 check if PS2 keyboard 
 present.
**********************/
PS2_QUERY: 
	_NEST 
	_DOLIT 400 
	_ADR PAUSE
	_ADR PS2_QKEY
	_QBRAN 1f
	_DOLIT BAT_OK 
	_ADR XORR 
	_QBRAN 9f 
1:	_ADR KBD_RST
	_DOLIT BAT_OK 
	_ADR XORR  
	_QBRAN 9f  
// no ps2 keyboard 
// swith to serial console
	_ADR CR 
	_DOTQP 25,"no PS2 keyboard detected."
	_ADR SERIAL 
	_ADR CONSOLE 
9:	_UNNEST 

/*************************
   check PA8 to 
   select console 
   PA8 -> low  LOCAL 
   PA8 -> high SERIAL 
*************************/
IF_SENSE:
	_NEST 
	_ADR LOCAL 
	_DOLIT (GPIOA_BASE_ADR+GPIO_IDR) 
	_ADR AT 
	_DOLIT (1<<8)
	_ADR ANDD 
	_QBRAN 9f 
	_ADR ONEP 
9:  _ADR CONSOLE 
	_UNNEST 

/****************************
   display READY on active
   console
***************************/
READY:
    _NEST 
	_DOTQP 5,"READY"
	_ADR  CR 
    _UNNEST 

/********************
    COLD	( -- )
 	The high level cold 
	start sequence.
**************************/
	.word	LINK 
	LINK = . 
_LASTN:	.byte  4
	.ascii "COLD"
	.p2align 2	
COLD:
	_CALL forth_init 
	ldr IP,=COLD1 
	_NEXT
	.p2align 2 
COLD1:
	_DOLIT  0 
	_ADR ULED // turn off user LED 
	_DOLIT	UZERO
	_DOLIT	UPP
	_DOLIT	ULAST-UZERO
	_ADR	WMOVE 			// initialize user area
	_ADR	PRESE			// initialize stack and TIB
	_ADR	WR_DIS          // disable WEL bit in U3 spi flash  
	_ADR 	PS2_QUERY  
	_ADR	TBOOT
	_ADR	ATEXE			// application boot
	_ADR	OVERT
	_ADR	IF_SENSE
	_ADR    READY 
	_BRAN	QUIT			// start interpretation
COLD2:
	.p2align 2 	
CTOP:
	.word	0XFFFFFFFF		//  keep CTOP even


  .end 

