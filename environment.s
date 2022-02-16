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

/*******************************
    ENVIRONMENT? 
    constants 
    vocabulary separate from 
    main dictionary  
*******************************/


/*******************************
    ENVIRONMENT? 
    ( c-addr u -- false | i * x true ) 
********************************/
    _HEADER ENVQ,12,"ENVIRONMENT?"
    _NEST 
    // save normal context 
    _ADR CNTXT 
    _ADR AT 
    _ADR TOR 
    // set environment context 
    _DOLIT _ENVLASTN  
    _ADR   CNTXT 
    _ADR   STORE 
    // search string 
    _ADR   DROP 
    _ADR   ONEM 
    _ADR   NAMEQ
    _ADR   DUPP 
    _QBRAN  1f
    _ADR   DROP 
    _ADR   EXECU 
    _BRAN  2f
1:  _ADR  SWAP 
    _ADR  DROP 
2:  // restore normal context 
    _ADR RFROM
    _ADR CNTXT 
    _ADR STORE 
    _UNNEST 


    .equ ENVLNK , 0 

	// dictionary header  
	.macro _ENV_HEADER  label, nlen, name
		.word ENVLNK 
		.equ ENVLNK , . 
	_\label: .byte \nlen    // name field
		.ascii "\name"
		.p2align 2 
	\label:   // code field 
	.endm 
	

/***********************************
    envronment constants 
***********************************/

/**********************************
    /COUNTED-STRING ( -- 255 t )
constant:
    255 maximum counted string length
*************************************/
    _ENV_HEADER CNTDSTR,15,"/COUNTED-STRING"
    _PUSH 
    MOV  TOS,#255
    B flag_true


/******************************************
    /HOLD  ( -- 80 t )
    size of the pictured numeric 
    output string buffer, in characters
constant:
    80 bytes   
*******************************************/
    _ENV_HEADER SLHOLD,5,"/HOLD"
    _PUSH
    MOV TOS,#80
    B flag_true

/***************************************
    /PAD ( -- 80 t )	
    size of the scratch area 
    pointed to by PAD, in characters
constant: 
    80 bytes 
***************************************/
    _ENV_HEADER SLPAD,4,"/PAD"
    _PUSH 
    MOV TOS,#80
    B flag_true

/**************************************
    ADDRESS-UNIT-BITS ( -- 32 t )
    size of one address unit, in bits
constant:
    32 bits
**************************************/
    _ENV_HEADER ADRBITS,17,"ADDRESS-UNIT-BITS"
    _PUSH 
    MOV TOS,#32
    B flag_true

/***************************************
    FLOORED	( -- t ) 
    flag true if floored division 
    is the default
constant:
    true 
***************************************/
    _ENV_HEADER FLOORED,7,"FLOORED"
    b flag_true

/*************************************
    MAX-CHAR  ( -- 127 -1 t )
    maximum value of any character in 
    the implementation-defined 
    character set.
constant:
    127 
*************************************/
    _ENV_HEADER MAXCHAR,8,"MAX-CHAR"
    _PUSH 
    MOV TOS,#127 
    b flag_true 

/************************************
    MAX-D	(-- 0xffffffff 0x7fffffff t )
    largest usable signed double number
constant:
    0x7FFF_FFFF_FFFF_FFFF 
************************************/
    _ENV_HEADER MAXD,5,"MAX-D"
    _PUSH 
    _MOV32 TOS,0xFFFFFFFF 
    _PUSH
    _MOV32 TOS,0x7FFFFFFF 
    B flag_true

/************************************
    MAX-N ( -- 0x7FFFFFFF t ) 
    largest usable signed integer
constant:
    0x7FFFFFFF
*************************************/
    _ENV_HEADER MAXN,5,"MAX-N"
    _PUSH 
    _MOV32 TOS,0x7FFFFFFF 
    B flag_true 

/************************************
    MAX-U ( -- 0xFFFFFFFF t ) 
    largest usable unsigned integer
constant:
    0xFFFFFFFF 
************************************/
    _ENV_HEADER MAXU,5,"MAX-U"
    _PUSH 
    MOV TOS,#-1 
    B flag_true 

/**********************************
    MAX-UD ( -- 0xFFFFFFFF 0xFFFFFFFFF t )
    largest usable unsigned double number
constant:
    0xFFFF_FFFF_FFFF_FFFF 
*************************************/
    _ENV_HEADER MAXUD,6,"MAX-UD"
    _PUSH 
    MOV  TOS,#-1 
    _PUSH 
    MOV TOS,#-1 
    B flag_true

/*************************************
    RETURN-STACK-CELLS ( -- 32 t )
    maximum size of the return stack, 
    in cells
constant:
    32 cells 
************************************/
    _ENV_HEADER RSTKCELLS,18,"RETURN-STACK-CELLS"
    _PUSH 
    MOV TOS,#32 
    B flag_true

/*************************************
    STACK-CELLS ( -- 32 t ) 
    maximum size of the data stack, 
    in cells
constant:
    32 cells 
*************************************/
	.word	ENVLNK 
	ENVLINK = . 
_ENVLASTN:	.byte 11
	.ascii "STACK-CELLS"
	.p2align 2	
STKCELLS: 
    _PUSH 
    MOV TOS,#32 
//    B flag_true 

flag_true:
    _PUSH 
    MOV TOS,#-1 
    _NEXT 



