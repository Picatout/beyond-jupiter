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
	.fpu softvfp  
	.thumb

	.include "stm32f411ce.inc"
	
	.section .text, "ax", %progbits

/***********************************
  Start of eForth system 
***********************************/

	.p2align 2 

// hi level word enter
NEST: 
	STMFD	RSP!,{IP}
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

// compile "BX 	INX" 
// this is the only way 
// a colon defintion in RAM 
// can jump to NEST
// INX is initialized to NEST address 
// and must be preserved   
COMPI_NEST:
	add T1,UP,#USER_CTOP 
	ldr T1,[T1]
	mov T2,#0x4700+(10<<3)
	strh T2,[T1],#2
	mov T2,#0xbf00 // NOP.N   
	strh T2,[T1],#2 
	add T2,UP,#USER_CTOP 
	str T1,[T2]
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
	_UNNEST

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
    R>	  ( -- w )
 	Pop the return stack to the data stack.
**********************************************/
	_HEADER RFROM,2,"R>"
	_PUSH
	LDR	TOS,[RSP],#4
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
    >R	  ( w -- )
 	Push the data stack to the return stack.
************************************************/
	_HEADER TOR,2,">R"
	STR	TOS,[RSP,#-4]!
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
    OVER	( w1 w2 -- w1 w2 w1 )
 	Copy second stack item to top.
***********************************/
	_HEADER OVER,4,"OVER"
	_PUSH
	LDR	TOS,[DSP,#4]
	_NEXT 

/***********************************
    0<	  ( n -- t )
 	Return true if n is negative.
***********************************/
	_HEADER ZLESS,2,"0<"
	ASR TOS,#31
	_NEXT 

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
 	arithmetic Right shift # bits.
**********************************/
	_HEADER RSHIFT,6,"RSHIFT"
	LDR	WP,[DSP],#4
	MOV	TOS,WP,ASR TOS
	_NEXT 

/****************************
    LSHIFT	 ( w # -- w )
 	Right shift # bits.
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
    NOT	 ( w -- !w )
 	1"s complement.
*****************************/
	_HEADER INVER,3,"NOT"
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
	_HEADER DAT,2,"D@"
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

/*******************************
  doVAR	( -- a )
  Run time routine for VARIABLE and CREATE.
hidden word used by compiler
********************************/
DOVAR:
	_PUSH
	MOV TOS,IP
	ADD IP,IP,#4 
	B UNNEST 

/**********************************
    doCON	( -- a ) 
 	Run time routine for CONSTANT.
hidden word used by compiler 
***********************************/
DOCON:
	_PUSH
	LDR.W TOS,[IP],#4 
	B UNNEST 

/***********************
  system variables 
***********************/

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
 	Point to top name in RAM 
	vocabulary.
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
	in the name dictionary.
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
    M/MOD	( d n -- r q )
 	Signed floored divide 
	of double by single. 
	Return mod and quotient.
****************************/
	_HEADER MSMOD,5,"M/MOD"
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
//  */MOD	( n1 n2 n3 -- r q )
/* 	Multiply n1 and n2, then 
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
	_NEST
	_ADR	ONEP
	_ADR	CELLS
	_ADR	SPAT
	_ADR	PLUS
	_ADR	AT
	_UNNEST

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
CMOV2:
	_POP
	_NEXT

/***************************
    MOVE	( a1 a2 u -- )
 	Copy u words from a1 to a2.
*******************************/
	_HEADER MOVE,4,"MOVE"
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
  Numeric input, single precision
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

/***********************************
 parse digits 
  d digits count 
  n parsed integer
  a+ updated pointer  
************************************/
PARSE_DIGITS: // ( d n a -- d+ n+ a+ )
    _NEST
    _ADR BASE 
    _ADR AT 
    _ADR TOR  
1:  _ADR COUNT 
    _ADR RAT 
    _ADR DIGTQ
    _QBRAN 2f
    _ADR ROT 
    _ADR RAT 
    _ADR STAR 
    _ADR PLUS
    _ADR SWAP 
    _ADR ROT 
    _ADR ONEP 
    _ADR NROT
    _BRAN 1b 
2:  _ADR DROP 
    _ADR ONEM  // decrement a 
    _ADR RFROM 
    _ADR DROP 
    _UNNEST 

/**************************
 CHAR? 
 check for charcter c 
 move pointer if true 
**************************/
CHARQ: // ( a c -- a+ t | a f )
    ldr T0,[DSP]
    ldrb T1,[T0],#1 
    mov T2,TOS 
    eor TOS,TOS
    cmp T1,T2
    bne 1f 
    str T0,[DSP]
    mvn TOS,TOS  
1:  _NEXT


/**********************************
    INT?	( a -- n T | a F )
 	parse string for at 'a' for 
	integer. Push a flag on TOS.
	integer form:
		[-]hex_digit+  | 
		$[-]hex_digit+ |
		%[-]bin_digit+ | 
		[-]dec_digit+ 
**********************************/
	_HEADER INTQ,4,"INT?"
	_NEST
	_ADR	BASE
	_ADR	AT
	_ADR	TOR
	_DOLIT	0      // a 0 
	_ADR	OVER   // a 0 a 
	_ADR	COUNT  // a 0 a+ cnt 
	_ADR	OVER   // a 0 a+ cnt a+
	_ADR	CAT    // a 0 a+ cnt char 
	_DOLIT '$'     // a 0 a+ cnt char '$'
	_ADR	EQUAL  // a 0 a+ cnt f 
	_QBRAN	0f    
	_ADR	HEX
	_BRAN   1f 
0:  _ADR    OVER  // a 0 a+ cnt a+
	_ADR    CAT   // a 0 a+ cnt char 
	_DOLIT  '%'   // a 0 a+ cnt char '%'
	_ADR	EQUAL  // a 0 a+ cnt f 
	_QBRAN  2f
	_ADR	BIN 
1:	_ADR	SWAP 
	_ADR	ONEP 
	_ADR	SWAP 
	_ADR	ONEM // a 0 a+ cnt-  
2: // check for '-'
	_ADR 	SWAP // a 0 cnt a+ 
	_DOLIT  '-' 
	_ADR	CHARQ
	_ADR	ROT 
	_ADR	OVER 
	_ADR    TOR   // a 0 a+ f cnt R: sign  
	_ADR	SWAP   // a 0 a+ cnt f 
	_QBRAN  2f 
	_ADR	ONEM 
2:	_ADR 	TOR  // a 0 a+  R: sign cnt 
	_DOLIT  0
	_ADR	DUPP 
	_ADR	ROT // a 0 0 0 a+ R: sign cnt 
	_ADR	PARSE_DIGITS  // a 0 d n a+
	_ADR	DROP // a 0 d n 
	_ADR	SWAP  // a 0 n d 
	_ADR	RFROM // a 0 n d cnt  
	_ADR	EQUAL // d == cnt ? 
	_QBRAN  5f // digits left, not an integer 
2:	_ADR	RFROM  // sign 
	_QBRAN  3f   // positive integer 
	_ADR	NEGAT
3:	
	_ADR	NROT  // n a 0 
	_ADR	DDROP // n  
	_DOLIT  -1    // n -1 
	_BRAN   7f  
5:  _ADR	RFROM //  a 0 n sign      	 
    _ADR	DDROP 
7:	_ADR	RFROM
	_ADR	BASE
	_ADR	STORE
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
  do_$	( -- a )
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
	_UNNEST

/******************************************
    $"|	( -- a )
 	Run time routine compiled by _". 
	Return address of a compiled string.
hidden word used by compiler
*****************************************/
STRQP:
	_NEST
	_ADR	DOSTR
	_UNNEST			// force a call to dostr

/*******************************
    .$	( a -- )
 	Run time routine of ." 
	Output a compiled string.
hidden word used by compiler
*******************************/
DOTST:
	_NEST
	_ADR	COUNT // ( -- a+1 c )
	_ADR	TYPEE
	_UNNEST

/**********************
    ."|	( -- )
 	Run time routine of ." 
	Output a compiled string.
hidden word used by compiler
*****************************/
DOTQP:
	_NEST
	_ADR	DOSTR
	_ADR	DOTST
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
	_ADR	STRR
	_ADR	RFROM
	_ADR	OVER
	_ADR	SUBB
	_ADR	SPACS
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
	_ADR	SWAP 
	_ADR 	STOD 
	_ADR	ROT 
	_ADR	TOR
	_ADR	BDIGS
	_ADR	DIGS
	_ADR	EDIGS
	_ADR	RFROM
	_ADR	OVER
	_ADR	SUBB
	_ADR	SPACS
	_ADR	TYPEE
	_UNNEST

/************************
    U.	  ( u -- )
 	Display an unsigned 
	integer in free format.
***************************/
	_HEADER UDOT,2,"U."
	_NEST
	_ADR 	STOD 
	_ADR	BDIGS
	_ADR	DIGS
	_ADR	EDIGS
	_ADR	SPACE
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
	_ADR	BASE
	_ADR	AT
	_DOLIT 10
	_ADR	XORR			// ?decimal
	_QBRAN	DOT1
	_ADR	UDOT
	_UNNEST			// no,display unsigned
DOT1:
    _ADR	STRR
	_ADR	SPACE
	_ADR	TYPEE
	_UNNEST			// yes, display signed

/*************************
   D. ( d -- )
   display double integer 
**************************/
	_HEADER DDOT,2,"D."
	_NEST 
	_ADR DUPP 
	_ADR TOR 
	_ADR DABS 
	_ADR BDIGS
	_ADR DIGS 
	_ADR RFROM
	_ADR SIGN 
	_ADR EDIGS
	_ADR SPACE 
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
	_ADR UDOT 
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
	_HEADER DOTPR,2,".("
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
    NAME>	( na -- ca )
 	Return a code address
	given a name address.
**************************/
	_HEADER NAMET,5,"NAME>"
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
	the "SAME?" and "FIND" 
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
    FIND	( a na -- ca na | a F )
 	Search a vocabulary for a string.
	Return ca and na if succeeded.
hidden word used by NAME?

  Picatout 2020-12-01,  
	 Modified from original. 
   See comment for word "SAME?" 
************************************/
FIND:
	_NEST
	_ADR	SWAP			// na a	
	_ADR	COUNT			// na a+1 count
	_ADR	DUPP 
	_ADR	TEMP
	_ADR	STORE			// na a+1 count 
	_ADR  TOR		// na a+1  R: count  
	_ADR	SWAP			// a+1 na
FIND1:
	_ADR	DUPP			// a+1 na na
	_QBRAN	FIND6	// end of vocabulary
	_ADR	DUPP			// a+1 na na
	_ADR	CAT			// a+1 na name1
	_DOLIT	MASKK
	_ADR	ANDD
	_ADR	RAT			// a+1 na name1 count 
	_ADR	XORR			// a+1 na,  same length?
	_QBRAN	FIND2
	_ADR	CELLM			// a+1 la
	_ADR	AT			// a+1 next_na
	_BRAN	FIND1			// try next word
FIND2:   
	_ADR	ONEP			// a+1 na+1
	_ADR	TEMP
	_ADR	AT			// a+1 na+1 count
	_ADR	SAMEQ		// a+1 na+1 ? 
FIND3:	
	_BRAN	FIND4
FIND6:	
	_ADR	RFROM			// a+1 0 name1 -- , no match
	_ADR	DROP			// a+1 0
	_ADR	SWAP			// 0 a+1
	_ADR	ONEM			// 0 a
	_ADR	SWAP			// a 0 
	_UNNEST			// return without a match
FIND4:	
	_QBRAN	FIND5			// a+1 na+1
	_ADR	ONEM			// a+1 na
	_ADR	CELLM			// a+4 la
	_ADR	AT			// a+1 next_na
	_BRAN	FIND1			// compare next name
FIND5:	
	_ADR	RFROM			// a+1 na+1 count
	_ADR	DROP			// a+1 na+1
	_ADR	SWAP			// na+1 a+1
	_ADR	DROP			// na+1
	_ADR	ONEM			// na
	_ADR	DUPP			// na na
	_ADR	NAMET			// na ca
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
	_ADR	FIND
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
	_ADR MOVE  
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
	_ADR	SPACE
	_ADR	COUNT
	_ADR	TYPEE
	_DOLIT	0X3F
	_ADR	EMIT
	_ADR	CR
	_ADR	PRESE
	_BRAN	QUIT

/*******************************
    _abort"	( f -- )
 	Run time routine of ABORT"
	Abort with a message.
hidden used by compiler 
********************************/
ABORQ:
	_NEST
	_ADR	DOSTR
	_ADR	SWAP 
	_QBRAN	1f	// text flag
	_BRAN	ABORT1
1:
	_ADR	DROP
	_UNNEST			// drop error

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
	_ADR	NUMBER 
	_QBRAN	INTE2
	_UNNEST
INTE2:
	_ADR	ABORT	// error

/******************************
    [	   ( -- )
 	Start the text interpreter.
*******************************/
	_HEADER LBRAC,IMEDD+1,"["
	_NEST
	_DOLIT	INTER
	_ADR	TEVAL
	_ADR	STORE
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

/**********************************
    PRESET	( -- )
 	Reset data stack pointer 
	and the terminal input buffer.
**********************************/
	_HEADER PRESE,6,"PRESET"
	_NEST 
	_DOLIT SPP 
	_ADR SPSTOR 
	_UNNEST 

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
	_ADR ABORT	// no, error

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
	into the code dictionary.
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
	_ADR	WORDD			// move word to code dictionary
	_ADR	COUNT
	_ADR	PLUS
	_ADR	ALGND			// calculate aligned end of string
	_ADR	CPP
	_ADR	STORE
	_UNNEST 			// adjust the code pointer

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
	_UNNEST 

DOPLOOP: // ( n -- R: counter limit )
	ldmfd RSP!,{T0,T1}
	add T0,TOS 
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
	_ADR COMMA
	_UNNEST 

DOLOOP: // ( -- R: counter limit )
	ldr T0,[RSP]
	add T0,#1
	str T0,[RSP]
	ldr T1,[RSP,#4]
	cmp T0,T1 
	bmi 9f
	add RSP,#8  // counter and limit  
	add IP,IP,#4 // skip loop address 
	_NEXT 
9:  ldr IP,[IP]
	_NEXT 


/********************************
	LOOP ( a -- )
	increment counter 
	end loop if >= limit 
*********************************/
	_HEADER LOOP,COMPO+IMEDD+4,"LOOP"
	_NEST 
	_COMPI DOLOOP
	_ADR COMMA 
	_UNNEST 


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

/***********************************
    ABORT"	( -- //  string> )
 	Conditional abort with an 
	error message.
***********************************/
	_HEADER ABRTQ,IMEDD+6,"ABORT\""
	_NEST
	_COMPI	ABORQ
	_ADR	STRCQ
	_UNNEST

/******************************
    $"	( -- //  string> )
 	Compile an inline 
	word literal.
*****************************/
	_HEADER STRQ,IMEDD+COMPO+2,"$\""
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
	_ADR	ABORT

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
	_ADR	NUMBER 
	_QBRAN	SCOM3
	_ADR	LITER
	_UNNEST			// compile number as integer
SCOM3: // compilation abort 
	_ADR COLON_ABORT 
	_ADR	ABORT			// error

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
	_UNNEST

/*********************
    BL.W	( ca -- )
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

	.p2align 2 
/****************************************
 doDOES> ( -- a )
 runtime action of DOES> 
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
	_ADR NAMET 
	_ADR CELLP 
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
	_DOLIT RFROM 
	_ADR	CALLC
	_UNNEST 


/****************************
  DEFER@ ( "name" -- a )
  return value of code field 
  of defered function. 
******************************/
	_HEADER DEFERAT,6,"DEFER@"
	_NEST 
	_ADR TICK
	_ADR CELLP 
	_ADR AT 
	_ADR ONEM 
	_UNNEST 

/*********************************
 DEFER! ( "name1" "name2" -- )
 assign an action to a defered word 
************************************/
	_HEADER DEFERSTO,6,"DEFER!"
	_NEST 
	_ADR TICK 
	_ADR ONEP 
	_ADR TICK 
	_ADR CELLP 
	_ADR STORE 
	_UNNEST

/****************************
  DEFER ( "name" -- )
  create a defered definition
*****************************/
	_HEADER DEFER,5,"DEFER"
	_NEST 
	_ADR CREAT 
	_DOLIT UNNEST 
	_ADR CALLC 
	_DOLIT DEFER_NOP
	_ADR ONEP 
	_ADR LAST 
	_ADR AT 
	_ADR NAMET 
	_ADR CELLP 
	_ADR STORE 
	_UNNEST 
DEFER_NOP:
	_NEST  
	_ADR NOP 
	_UNNEST 

/******************************
    CREATE	( -- //  string> )
 	Compile a new array entry 
	without allocating code space.
***********************************/
	_HEADER CREAT,6,"CREATE"
	_NEST 
	_ADR	TOKEN
	_ADR	SNAME
	_ADR	OVERT
	_ADR	COMPI_NEST 
	_DOLIT	DOVAR
	_ADR	CALLC
	_UNNEST

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
	_DOLIT UNNEST
	_ADR	CALLC  
	_UNNEST

/***********
  Tools
***********/

/*************************
    dm+	 ( a u -- a )
 	Dump u bytes from , 
	leaving a+u on the stack.
hidden word used by DUMP 
****************************/
DMP:
	_NEST
	_ADR	OVER
	_DOLIT	4
	_ADR	UDOTR			// display address
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

/***********************
	TRACE ( -- )
**********************/
	_HEADER TRACE,5,"TRACE"
	_NEST
	_ADR HLD
	_ADR AT 
	_ADR TOR  
	_ADR CR 
	_ADR BASE 
	_ADR AT 
	_ADR TOR
	_ADR DECIM
	_DOLIT '>' 
	_DOLIT 'S'
	_ADR EMIT 
	_ADR EMIT  
	_ADR DOTS
	_ADR CR
	_ADR RFROM 
	_ADR BASE 
	_ADR STORE  
	_ADR RFROM 
	_ADR HLD 
	_ADR STORE  
	_UNNEST 


/**********************
   .S	  ( ... -- ... )
 	Display the contents 
	of the data stack.
*************************/
	_HEADER DOTS,2,".S"
	_NEST
	_ADR	SPACE
	_ADR	DEPTH			// stack depth
	_ADR	TOR			// start count down loop
	_BRAN	DOTS2			// skip first pass
DOTS1:
	_ADR	RAT
	_ADR	PICK
	_ADR	DOT			// index stack, display contents
DOTS2:
	_DONXT	DOTS1	// loop till done
	_ADR	SPACE
	_UNNEST

/*****************************
    >NAME	( ca -- na | F )
 	Convert code address 
	to a name address.
*****************************/
	_HEADER TNAME,5,">NAME"
	_NEST
	_ADR	TOR			//  
	_ADR	CNTXT			//  va
	_ADR	AT			//  na
TNAM1:
	_ADR	DUPP			//  na na
	_QBRAN	TNAM2	//  vocabulary end, no match
	_ADR	DUPP			//  na na
	_ADR	NAMET			//  na ca
	_ADR	RAT			//  na ca code
	_ADR	XORR			//  na f --
	_QBRAN	TNAM2
	_ADR	CELLM			//  la 
	_ADR	AT			//  next_na
	_BRAN	TNAM1
TNAM2:	
	_ADR	RFROM
	_ADR	DROP			//  0|na --
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
	_ADR	TNAME			//  a na/0 --, is it a name?
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

/**********************
	VLIST ( -- )
	WORDS alias 
	+ display words count 
**********************/
	_HEADER VLIST,5,"VLIST"
	_NEST 
	_ADR WORDS
	_ADR CR 
	_ADR WC
	_ADR DOT    
	_UNNEST 

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

/*****************************
	WC ( - n )
	count words in dictionary 
******************************/
	_HEADER WC,2,"WC"
	_NEST 
	_DOLIT 0 
	_ADR LAST
1:	_ADR AT
	_ADR QDUP
	_QBRAN 9f
	_ADR SWAP
	_ADR ONEP
	_ADR SWAP
	_ADR CELLM
	_BRAN 1b
9:	_UNNEST 

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
	_ADR TNAME
	_ADR CELLM
	_ADR AT  
	_ADR LAST 
	_ADR STORE 
	_ADR OVERT
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
	_ADR	MOVE 			// initialize user area
	_ADR	PRESE			// initialize stack and TIB
	_ADR	IF_SENSE
	_ADR	WR_DIS          // disable WEL bit in U3 spi flash  
	_ADR 	PS2_QUERY  
	_ADR    FINIT 
	_ADR	TBOOT
	_ADR	ATEXE			// application boot
	_ADR	OVERT
	_BRAN	QUIT			// start interpretation
COLD2:
	.p2align 2 	
CTOP:
	.word	0XFFFFFFFF		//  keep CTOP even


  .end 

