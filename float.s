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

/*==========================================================
    THE 'FLOATING POINT ARITHMETIC' ROUTINES
==========================================================*/

/******************************************************
    Parsing float32 to IEEE-754 format is quite Complex
    so the original Jupiter ACE Z80 code 
    is adapted to this ARM-7M architecture.
    REF: docs/Jupiter-Ace-ROM.asm 

    based on BCD  (binary Coded Decimal)
Format:
    bit 23:0  6 BCD digits mantissa
        mantissa range 0...999999 
    bit 30:24 exponent offset by 127 for exponent (decimal value)
        exponent range:  -127...127   128 value indicate out of range 
    bit 31    mantissa sign 

    ** Floating point words: 
    REF: docs/JA-Ace4000-Manual-First-US-Edition.pdf, chapter 15
    F+, F-, F*, F/, 
    FNEGATE, INT, UFLOAT, F. 
*******************************************************/    


/*****************************************************************************
    PREP_FP  
    prepare floating point
    work space 

; ( f1, f2 -- m1, m2 )
; -> from add/mult/div
; Entered with two floating point numbers on the stack.
; The exponents are stored in the first two bytes of FP_WS and the third byte
; is loaded with the manipulated result sign.
; the two exponent locations on the Data Stack are blanked leaving just the
; binary coded mantissas.
*******************************************************************************/
PREP_FP:
    ldr T0,[UP,#FP_WS] // float work space pointer 
// clear first 16 bytes of 19 bytes array 
    mov T1,#4 
    eor T2,T2 
1:  str T2,[T0],#4
    subs T1,#1
    bne 1b 
    str T2,[UP,#TMP] // clear tmp variable (SPARE)

    _RET 

/***********************
  digit_add  
 add 2 BCD digits 
 input:
    T0  first digit
    T1  second digit 
    T2  carry 
 output:
    T0  sump
    T2  carry 
***********************/ 
    .type add_digit, %function
digit_add:
    add T0,T2 
    add T0,T1 
    cmp T0,#10
    bmi 1f 
    add T0,#6 
1:  lsr T2,T0,#4 
    and T0,#15
    _RET 

/*********************************
    digit_sub 
    substract T0-BORROW-T1 
  input:
        T0  first digit 
        T1  second digit 
        T2  borrow 
  output:
        T0  substraction 
        T2  borrow 
*********************************/
digit_sub:
    cbz T2,1f
    subs T0,T2 
    eor T2,T2 
    bpl 1f 
    add T0,#10  
    mov T2,#1 
1:  subs T0,T1 
    bpl 3f
    add T0,#10
    and T0,#15 
    mov T2,#1
3:  _RET 

/**********************************
    digit_prod 
    multiply 2 BCD digits 
    input:
        T0 first digit 
        T1 second digit 
    output:
        T0  prod low digit 
        T1  prod high digit 
***********************************/
digit_prod:
    mul T0,T1 
    mov T1,#10 
    udiv T2,T0,T1 
    mul T1,T1,T2 
    sub T0,T1
    mov T1,T2  
    _RET 

/****************************************
    BCD+  ( bcd1 bcd2 carry -- sum carry )
    sum=bcd1+bcd2+carry 
    bcd are 8 digits packed in 32 bits   
*****************************************/
    _HEADER BCD_ADD,4,"BCD+"
    eor T3,T3 // bit shift  
    eor WP,WP // sum   
    mov T2,TOS
    _POP   
1:  ldr T0,[DSP]
    lsr T0,T3 
    and T0,#15
    lsr T1,TOS,T3 
    and T1,#15
    bl digit_add 
    lsl T0,T3 
    orr WP,T0 
    add T3,#4 
    cmp T3,#32 
    bmi 1b 
    str WP,[DSP]
    mov TOS,T2 
    _NEXT 


/********************************************
    BCD- ( bcd1 bcd2 borrow -- diff borrow )
    diff=bcd1-borrow-bcd2 
********************************************/
    _HEADER BCD_SUB,4,"BCD-"
    eor T3,T3 // bit shift 
    eor WP,WP
    mov T2,TOS 
    _POP 
1:  ldr T0,[DSP]
    lsr T0,T3 
    and T0,#15 
    lsr T1,TOS,T3
    and T1,#15 
    bl digit_sub
    lsl T0,T3 
    orr WP,T0 
    add T3,#4 
    cmp T3,#32 
    bmi 1b 
    str WP,[DSP]
    mov TOS,T2 
    _NEXT 


/*********************************
    BCD1+ ( bcd -- bcd+1 carry )
    increment bcd integer 
*********************************/
    _HEADER BCD_1P,5,"BCD1+"
    eor T3,T3 
    mov WP,TOS 
    mov T0,#15 
1:  lsl T1,T0,T3 
    mvn T1,T1 
    and WP,T1 
    lsr T1,TOS,T3
    and T1,#15 
    add T1,#1 
    cmp T1,#10 
    bmi 2f 
    add T1,#6 
2:  lsr T2,T1,#4 
    and T1,#15 
    lsl T1,T3 
    orr WP,T1
    cbz T2,3f 
    add T3,#4 
    cmp T3,#32 
    bmi 1b 
3:  str WP,[DSP,#-4]! 
    mov TOS,T2 
    _NEXT     

/*******************************
    BCD-NEG ( bcd -- - bcd carry )
    BCD ten's complement 
*******************************/
    _HEADER BCD_NEG,7,"BCD-NEG"
    _MOV32 WP,0x99999999
1:  rsb TOS,WP  
    b BCD_1P 


/*******************************
    F+ ( f1 f2 -- f1+f2 )
    add 2 float 
*******************************/
    _HEADER FPLUS,2,"F+"
    _NEST 

    _UNNEST 

/*******************************
    F- ( f1 f2 -- f1-f2 )
    substract 2 float 
*******************************/
    _HEADER FMINUS,2,"F-"
    _NEST 

    _UNNEST 

/*******************************
    F* ( f1 f2 -- f1*f2 )
    multiply 2 float 
******************************/

/*******************************
    F/ ( f1 f2 -- f1/f2 )
    divide f1 by f2 
*******************************/
    _HEADER FSLH,2,"F/"
    _NEST 

    _UNNEST 


/********************************
    FNEGATE ( f -- -f )
    negate floating point 
********************************/
    _HEADER FNEG,7,"FNEGATE"
    _NEST 

    _UNNEST 

/*******************************
    INT ( f -- n )
    convert float to integer 
*******************************/
    _HEADER INT,3,"INT"
    _NEST 

    _UNNEST 

/*******************************
    UFLOAT ( n -- f )
    convert integer to float 
*******************************/
    _HEADER UFLOAT,6,"UFLOAT"
    _NEST 

    _UNNEST 

/*******************************
    F. ( f -- )
    print float
*******************************/
    _HEADER FDOT,2,"F."
    _NEST

    _UNNEST 

/*******************************
    IS_BASE10 ( c -- n t | c f )
    check if character is base 10
    digit. 
*******************************/ 
IS_BASE10:
    push {T0}
    mov T0,TOS 
    _PUSH 
    eor TOS,TOS 
    subs T0,#'0' 
    bmi 2f 
    cmp T0,#10 
    bpl 2f 
    str T0,[DSP] 
2:  pop {T0}
    _RET 


/*****************************
    PARSE_PREDECIM ( a -- a+ n t | a f )
    parse integer part of float32 
*****************************/
PARSE_PREDCIM:


/*****************************
   parse decimal part of float32 
*****************************/
PARSE_DECIM:
    eor T0,T0 // sign 
    eor T1,T1 // u
    mov T3,#10 // numeric base  
    ldrb T2,[TOS],#1
    stmfd RSP!,{T2} //count >R 
    ldrb T2,[TOS]
    cmp T2,'-'
    bne 1f 
    mvn T0,T0 // negative 
    b 2f
1:  subs T2,#'0'
    bmi 3f 
    cmp T2,#10
    bpl 3f 
    mul T1,T3 
    add T1,T2 
// NEXT 
2:  add TOS,#1 
    ldr T2,[RSP]
    subs T2,#1 
    bne 0b 
3:  add RSP,#4 
    stmfd DSP!,{T0,T1}
    _NEXT 


/*******************************
    FLOAT? ( a -- f -1 | a 0 )
    parse floating point 
*******************************/
    _HEADER FLOATQ,6,"FLOAT?"
    _NEST
_DOLIT 0 
_UNNEST     
    _ADR DUPP 
    _ADR TOR  // a >R 
    _ADR PARSE_DECIM // get mantissa 
    _ADR ROT 
    _ADR DUPP 
    _ADR CAT 
    _ADR DUPP 
    _DOLIT '.'
    _ADR XORR   
    _QBRAN fraction   
try_e:
    _DOLIT 'E'
    _ADR XORR 
    _QBRAN exponent 
not_float:
    _ADR TDROP // drop 3 elements
    _ADR RFROM   
    _DOLIT 0 
    _UNNEST 
fraction:
    _ADR DROP
1:  _ADR ONEP // m s a+ --
    _ADR PARSE_DECIM // get fraction
    
    _UNNEST 
exponent: // get exponent 

    _UNNEST 

/********************************
    NUMBER ( a -- n -1 | f -2 | a 0 )
    parse number, integer or float 
    if not a number return 0 
    if integer return n -1 
    if float return f -2 
**********************************/
    _HEADER NUMBER,6,"NUMBER"
    _NEST 
    _ADR NUMBQ
    _ADR QDUP 
    _QBRAN 2f 
    _UNNEST 
2:  _ADR FLOATQ
    _UNNEST 

