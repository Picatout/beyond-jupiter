//---------------------------------------------------------------------------
// Copyright Jacques Deschênes 2021 
// This file is part of stm32-tbi 
//
//     stm32-tbi is free software: you can redistribute it and/or modify
//     it under the terms of the GNU General Public License as published by
//     the Free Software Foundation, either version 3 of the License, or
//     (at your option) any later version.
//
//     stm32-tbi is distributed in the hope that it will be useful,
//     but WITHOUT ANY WARRANTY// without even the implied warranty of
//     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//     GNU General Public License for more details.
//
//     You should have received a copy of the GNU General Public License
//     along with stm32-tbi.  If not, see <http://www.gnu.org/licenses/>.
//
//---------------------------------------------------------------------------

/********************
* Version control
*******************/
.equ VER ,	0x01	/*major release version */
.equ EXT ,	0x00	/*minor extension */


	/* registers alias */
    T0		.req	r0 	// temporary register 
    T1		.req	r1  // temporary register 
    T2		.req	r2  // temporary register  
    T3		.req    r3  // temporary register 
    UP		.req	r4  // user variables pointer 
    WP		.req    r5  // working register 
	TOS		.req	r6  // top of data stack 
    DSP		.req	r7 	// data stack pointer 
    RSP		.req	r8	// return stack pointer 
	INX 	.req    r10 // INEXT  address 
//	IP		.req	r12	// VM instruction pointer  


/* beyond Jupiter specific constants */ 
  .equ LED_GPIO, GPIOC_BASE_ADR
  .equ LED_PIN, 13
  .equ UART, USART1_BASE_ADR 

/* Forth specific constants */
	.equ RPP ,	RAM_END-256	/*top of return stack (RP0) */
	.equ TIBB ,	RPP-128	/*terminal input buffer (TIB) */
	.equ SPP ,	RPP-128	/*top of data stack (SP0) */
	.equ VID_BUFF, SPP-256-32000 /* video buffer */
	.equ UPP ,	RAM_ADR	 /* start of user area (UP0) */
	.equ DTOP,  RAM_ADR+0x512 
	.equ DEND , VID_BUFF-4  /*usable RAM end */
    .equ MAPOFFSET, RAM_ADR-0x8000200

	.equ COMPO ,	0x040	/*lexicon compile only */ 
	.equ IMEDD ,	0x080	/*lexicon immediate bit */
	.equ MASKK ,	0x0FFFFFF1F	/*lexicon bit mask, allowed for Chineze character */

	.equ CELLL ,	4	/*size of a cell */
	.equ BASEE ,	10	/*default radix */
	.equ VOCSS ,	8	/*depth of vocabulary stack */

	.equ BKSPP ,	8	/*backspace */
	.equ LF ,	10	  /*line feed */
	.equ CRR ,	13	/*carriage return */
	.equ ERR ,	27	/*error escape */
	.equ TIC ,	39	/*tick */

/*************************************
   system variables offset from UPP
*************************************/
  .equ RNDSEED, 4    // prng seed 
  .equ TICKS, RNDSEED+4  // millseconds counter
  .equ CD_TIMER, TICKS+4  // count down timer
  .equ BOOT, CD_TIMER+4  // boot program address
  .equ STDIN, BOOT+4   //character ouput device 
  .equ STDOUT, STDIN+4 // character input device 
  .equ NBASE, STDOUT+4  // numeric conversion base 
  .equ BCHAR, NBASE+4   // display base character flag 
  .equ TMP, BCHAR+4   // temporary variable
  .equ CSPAN, TMP+4  // character count received by expect  
  .equ TOIN, CSPAN+4  // >IN  parse pointer in TIB
  .equ NTIBB, TOIN+4  // #TIB  characters in TIB 
  .equ TIBUF, NTIBB+4   // TIB buffer address 
  .equ EVAL, TIBUF+4  // eval|compile vector 
  .equ VHOLD, EVAL+4   // hold pointer 
  .equ CTXT, VHOLD+4  // context pointer 
  .equ FORTH_CTOP, CTXT+4  // flash free dictionary address 
  .equ USER_CTOP, FORTH_CTOP+4  // ram free dictionary address
  .equ LASTN, USER_CTOP+4     // last word in dictionary link nfa 
  .equ RX_QUEUE_SIZE, 16 // uart_rx queue size 16 characters 
  .equ RX_QUEUE, LASTN+4 // rx queue 
  .equ RX_HEAD, RX_QUEUE+RX_QUEUE_SIZE // queue head indice 
  .equ RX_TAIL, RX_HEAD+4 // queue tail indice 
  .equ VID_CNTR, RX_TAIL+4 // video line counter 
  .equ VID_STATE, VID_CNTR+4 // video field,ODD=0,EVEN=1 
  .equ VID_FIELD, VID_STATE+4 // VSYNC,PRE_VID,VID,POST_VID 
  .equ VID_BUFFER, VID_FIELD+4 // video buffer address 
  .equ KBD_STRUCT, VID_BUFFER+4 // keyboard structure 
  .equ KBD_QUEUE_SIZE, 16 
  .equ KBD_QUEUE, KBD_STRUCT+4 
  .equ KBD_QHEAD,KBD_QUEUE+KBD_QUEUE_SIZE 
  .equ KBD_QTAIL,KBD_QHEAD+4
  .equ ROW,KBD_QTAIL+4 
  .equ COL,ROW+4 
  .equ BK_COLOR,COL+4 
  .equ PEN_COLOR,BK_COLOR+4
  .equ VFPSW, PEN_COLOR+4 
  .equ VFBASE, VFPSW+4 
  .equ TONE_DTMR, VFBASE+4 // tone duration timer 

/***********************************************
* MACROS
*	Assemble inline direct threaded code ending.
***********************************************/
	.macro _CALL fn /* low level routine call */ 
 	PUSH {LR}
	BL \fn  
	POP {LR}
	.endm
	
	.macro _RET /* exit sub-routine */ 
	BX LR 
	.endm 

	// dictionary header  
	.macro _HEADER  label, nlen, name
		.word LINK 
		.equ LINK , . 
	_\label: .byte \nlen    // name field
		.ascii "\name"
		.p2align 2 
	\label:   // code field 
	.endm 
	

// local function header 
	.macro _FUNC label 
	.section .text, "ax", %progbits 
	.p2align 2 
	.type \label, %function  
	\label:
	.endm 

// global function header 
	.macro _GBL_FUNC label 
	.global \label 
	_FUNC \label 
	.endm 


// load large constant to register 
	.macro _MOV32 r, value 
	mov \r,#(\value&0xffff)
	movt \r,#(\value>>16)
	.endm 

	.macro _NEXT /* direct jump INEXT */ 
	B INEXT   
	.endm 

 	.macro	_NEST /*start high level word */
	BX INX  
	NOP.N 
	.endm

	.macro _ADR label 
	.word 1+\label  
	.endm 

 	.macro	_UNNEST	/*end high level word */
	_ADR UNNEST 
	.endm

 	.macro	_DOLIT u /*long literals */
	_ADR	DOLIT
	.word	\u 
	.endm

	.macro _DOTQP len, text 
	_ADR DOTQP 
	.byte \len 
	.ascii "\text" 
	.p2align 2 
	.endm

	.macro _COMPI name 
	_DOLIT \name 
	_ADR CALLC 
	.endm 

	.macro _ABORQ len,name 
	_ADR ABORQ 
	.byte \len 
	.ascii "\name"
	.p2align 2 
	.endm

	.macro _BRAN label 
	_ADR BRAN 
	.word \label 
	.endm 

	.macro _QBRAN label 
	_ADR QBRAN 
	.word \label
	.endm 

	.macro _DONXT label 
	_ADR DONXT
	.word \label 
	.endm 

 	.macro	_PUSH	/*push TOS on data stack*/
	STR	TOS,[DSP,#-4]!
	.endm

 	.macro	_POP /*pop data stack to TOS */
	LDR	TOS,[DSP],#4
	.endm

	// calling a colon word 
	// from a code word   
	.macro _CALL_COLWORD target 
    ldr WP,=\target 
	orr WP,#1
	b \target  
	.endm 
