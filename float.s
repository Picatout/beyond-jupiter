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
    so I rather adapted  Forth dimensions Volume IV, #1
    library proposed by Michael Jesch 
    is adapted to this ARM-7M architecture.
    REF: docs/FD-V04N1.pdf 

Format:
    bit 23:0  6 digits signed mantissa
    bit 31:24 signed exponent 

*******************************************************/    

    MANTISSA_MASK = 0xffffff // biggest mantissa 


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


/*****************************************
    BCD* ( bcd1 bcd2 -- prod_low prod_hi )
    multiply 2 bcd numbers 
    return 16 digits products 
*****************************************/
    _HEADER BCD_STAR,4,"BCD*"

    _NEXT 

/**********************************
    BCD>BIN ( bcd sign -- binary )
    convert bcd number to binary 
**********************************/
    _HEADER BCD_BIN,7,"BCD>BIN"
    push {TOS}
    _POP 
    eor WP,WP 
    mov T1,#10 
    mov T3,#28 
1:  mul WP,T1 
    lsr T2,TOS,T3 
    and T2,#15 
    add WP,T2 
    subs T3,#4 
    bpl 1b
    mov TOS,WP
    pop {T0}
    cbz T0,4f
    rsb TOS,#0 
4:  _NEXT 

/**********************************
    BIN>BCD ( int -- bcd sign )
    convert bcd number to binary 
**********************************/
    _HEADER BIN_BCD,7,"BIN>BCD"
    mov T0,TOS 
    _PUSH
    eor TOS,TOS // sign  
    tst T0,#(1<<31)
    beq 1f 
    mvn TOS,TOS // negative 
    rsb T0,#0 // 2's complement 
1:  mov T1,#10
    eor WP,WP 
    eor T3,T3 
2:  cbz T0,3f 
    udiv T2,T0,T1    
    push {T2}
    mul T2,T1 
    rsb T2,T0 
    pop {T0}
    lsl T2,T3 
    orr WP,T2 
    add T3,#4 
    cmp T3,#32 
    bne 2b 
3:  str WP,[DSP]
    _NEXT 

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


// accumulate digits 
// ( n a+ c -- n+ a+ c- )
ACCUM_DIGITS:
    _NEST 
    _ADR TOR 
    _BRAN 4f 
1:  _ADR COUNT 
    _DOLIT 10  // n a+ char 10 
    _ADR DIGTQ
    _QBRAN 6f
    _ADR ROT 
    _DOLIT 10 
    _ADR STAR 
    _ADR PLUS 
    _ADR SWAP // n a+  
4:  _ADR RFROM  
    _ADR DUPP 
    _QBRAN 9f 
    _ADR ONEM 
    _ADR TOR
    _BRAN 1b 
6:  _ADR DROP 
    _ADR ONEM
    _ADR RFROM
    _ADR DUPP  
    _QBRAN 9f 
    _ADR ONEP      
9:  _UNNEST 

// parse mantissa
//  ( a c -- dcnt m a+ c- ) 
MANTISSA:
    _NEST
    _ADR OVER 
    _ADR TOR  
    _DOLIT 0 
    _ADR NROT 
    _ADR ACCUM_DIGITS
    _ADR SWAP  // m c- a+ 
    _ADR DUPP  
    _ADR RFROM // m c- a+ a+ a 
    _ADR  SUBB // m c- a+ dcnt 
    _ADR NROT // m dcnt c- a+ 
    _ADR SWAP // m dcnt a+ c-
    _ADR TOR  // m dcnt a+ R: c- 
    _ADR SWAP // m a+ dcnt 
    _ADR NROT // dcnt m a+ 
    _ADR RFROM // dcnt m a+ c-  
    _UNNEST 

//parse exponent
// ( a c -- e esign a+ c- ) 
EXPONENT:
    _NEST 
    _ADR DASHQ 
    _ADR TOR  // a c R: esign 
    _DOLIT 0 
    _ADR NROT 
    _ADR ACCUM_DIGITS 
    _ADR RFROM 
    _ADR NROT // e esign a+ c- 
    _UNNEST 

// build float
//  ( dcnt m e esign msign -- float ) 
FORMAT_FLOAT:
    _NEST 
    _DOLIT (1<<31)
    _ADR ANDD 
    _ADR SWAP 
    _DOLIT (1<<30)
    _ADR XORR  
    _ADR ORR  // dcnt m e sign 
    _ADR ROT  // dcnt e sign m 
    _ADR DUPP 
    _QBRAN 2f // mantissa = 0 
    _ADR TOR // dcnt e sign R:  mantissa 
    _ADR NROT 
    _ADR PLUS // sign e R: mantissa  
    _DOLIT 64 
    _ADR PLUS 
    _DOLIT 24 
    _ADR LSHIFT 
    _ADR RFROM 
    _ADR BOUND_MANTISSA
    _ADR ORR 
    _BRAN 9f
2:  _ADR TOR // 
    _ADR DDROP 
    _ADR DROP 
    _ADR RFROM 
9:  _UNNEST 


// bound mantissa
//  0xfffff < m <= MANTISSA_MASK
//  ( e m1 -- e m2 )
BOUND_MANTISSA:
    _NEST
    _ADR DUPP 
    _DOLIT MANTISSA_MASK
    _ADR UGREAT  
    _QBRAN SCALE_UP
// to much digits 
// scale down  
1:  _ADR DUPP 
    _DOLIT MANTISSA_MASK 
    _ADR UGREAT 
    _QBRAN 2f 
    _DOLIT 10 
    _ADR SLASH 
    _BRAN 1b
2:  _UNNEST 
SCALE_UP:
    _ADR DUPP 
    _DOLIT 0xff0000
    _ADR ANDD 
    _ADR INVER
    _QBRAN 9f
    _DOLIT 10 
    _ADR STAR 
    _ADR SWAP 
    _ADR ONEM
    _BRAN 1b 
9:  _UNNEST 


/*******************************
    FLOAT? ( a -- f -1 | a 0 )
    parse floating point 
*******************************/
    _HEADER FLOATQ,6,"FLOAT?"
    _NEST
    _ADR BASE 
    _ADR AT 
    _ADR TOR
    _ADR DECIM 
    _DOLIT 0
    _ADR OVER   // a 0 a  
    _ADR COUNT  // a 0 a+ c 
    _ADR DASHQ  // negative sign? 
    _ADR TOR   // a 0 a+ c- R: base msign   
    _ADR MANTISSA // a 0 dcnt m a+ c- 
    _ADR OVER 
    _ADR CAT
    _ADR DUPP  
    _DOLIT '.' 
    _ADR XORR 
    _QBRAN 1f 
    _DOLIT 'E' 
    _ADR XORR 
    _QBRAN 2f
// format error 
0:  _ADR _DDROP // -- a 0 dcnt m 
    _ADR _DDROP // -- a 0
    _ADR RFROM 
    _ADR DROP 
    _BRAN 9f  
1:  _ADR DROP
    _ADR ONEM
    _ADR SWAP 
    _ADR ONEP 
    _ADR SWAP
_ADR TRACE 
    _ADR ACCUM_DIGITS // a 0 dcnt m a+ c-
_ADR TRACE 
    _ADR OVER 
    _ADR CAT 
    _ADR DUPP 
    _DOLIT '.' 
    _ADR EQUAL 
    _QBRAN 2f
    _ADR DROP 
    _DOLIT 0 
    _BRAN 3f 
2:  _DOLIT 'E'
    _ADR XORR 
    _QBRAN 2f
    _ADR DUPP 
    _ADR ZEQUAL 
    _QBRAN 0b 
    _DOLIT 0
    _ADR ROT 
    _BRAN 3f  
2:  _ADR EXPONENT // a 0 dcnt m e esign a+ c- 
    _QBRAN 3f   // if not char left ok 
    _ADR DDROP 
    _BRAN 0b
3: _ADR TRACE   
    _ADR DROP // a 0 dcnt m e esign 
    _ADR RFROM // a 0 dcnt m e esign msign 
_ADR TRACE 
    _ADR FORMAT_FLOAT
_ADR TRACE 
    _ADR NROT 
    _ADR DDROP 
    _DOLIT -2 
9:  _ADR RFROM 
    _ADR BASE 
    _ADR STORE     
    _UNNEST    

/********************************
    NUMBER ( a -- int -1 | float -2 | a 0 )
    parse number, integer or float 
    if not a number return ( a 0 ) 
    if integer return ( int -1 ) 
    if float return ( float -2 )
**********************************/
    _HEADER NUMBER,6,"NUMBER"
    _NEST 
    _ADR INTQ
    _ADR QDUP 
    _QBRAN 2f 
    _UNNEST 
2:  _ADR FLOATQ
    _UNNEST 

