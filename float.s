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
    adapted to this ARM-7M architecture.
    REF: docs/FD-V04N1.pdf 

Format:
    bit 23:0  6 digits signed mantissa
    bit 31:24 signed exponent 

*******************************************************/    

    MANTISSA_MASK = 0xffffff // biggest mantissa 
    MANTISSA_SIGN = 0x800000 

/*******************************
    FPSW  variable  ( -- a )
    floating point state flags 
    bit 0  zero flag 
    bit 1  negative flag 
    bit 2  overflow error 
*******************************/
    _HEADER FPSW,4,"FPSW"
    _PUSH 
    add TOS,UP,#VFPSW
    _NEXT  

/*******************************
    FBASE variable ( -- a )
    floating point numerical base
**********************************/
    _HEADER FBASE,5,"FBASE"
    _PUSH  
    add TOS,UP,#VFBASE 
    _NEXT  

/*****************************
    FRESET ( -- )
    reset state 
******************************/
    _HEADER FRESET,6,"FRESET"
    eor T0,T0 
    str T0,[UP,#VFPSW]
    _NEXT 

/******************************
    FINIT ( -- )
    initialise floating point 
******************************/
    _HEADER FINIT,5,"FINIT"
    _NEST 
    _ADR FRESET 
    _ADR BASE 
    _ADR AT 
    _ADR FBASE 
    _ADR STORE 
    _UNNEST 


/*******************************
    FER ( -- n )
    return FPSW value 
********************************/
    _HEADER FER,3,"FER"
    _PUSH 
    ldr TOS,[UP,#VFPSW]
    _NEXT 

/*******************************
    FZE ( -- flag )
    return zero flag 
*******************************/
    _HEADER FZE,3,"FZE"
    _PUSH 
    ldr TOS,[UP,#VFPSW]
    and TOS,#1
    _NEXT 

/*********************************
    FNE ( -- flag )
    return negative flag 
**********************************/
    _HEADER FNE,3,"FNE"
    _PUSH 
    ldr TOS,[UP,#VFPSW]
    and TOS,#2 
    _NEXT     

/**********************************
    FOV ( -- flag )
    return overflow flag 
***********************************/
    _HEADER FOV,3,"FOV"
    _PUSH 
    ldr TOS,[UP,#VFPSW]
    and TOS,#4 
    _NEXT 

/************************************
    SFZ ( F# -- f# ; z )
    set zero flag 
*************************************/
    _HEADER SFZ,3,"SFZ"
    ldr T0,[UP,#VFPSW]
    and T0,#-2
    and T1,TOS,#MANTISSA_MASK 
    cbz T1, 1f 
    orr T0,#1 
1:  str T0,[UP,#VFPSW]
    _NEXT 

/************************************
    SFN ( f# -- f# ; neg )
    set negative flag 
*************************************/
    _HEADER SFN,3,"SFN"
    ldr T0,[UP,#VFPSW]
    and T0,#-3
    and T1,TOS,#(1<<23)
    lsr T1,#22
    orr T0,T1
    str T0,[UP,#VFPSW]
    _NEXT 


/************************
    SFV (  -- )
    set overflow flag 
************************/
    _HEADER SFV,3,"SFV"
    ldr T0,[UP,#VFPSW]
    orr T0,#4 
    str T0,[UP,#VFPSW]
    _NEXT 

/*************************************
    @EXPONENT ( f# -- m e ; z n )    
    split exponent and mantissa 
    update FPSW flags 
*************************************/
    _HEADER AT_EXPONENT,9,"@EXPONENT"
    _NEST 
    _ADR FRESET 
    _ADR SFZ 
    _ADR SFN 
    _ADR DUPP 
    _ADR FNE 
    _QBRAN 1f 
    _DOLIT 0xFF000000 
    _ADR ORR  
    _BRAN 2f 
1:  _DOLIT MANTISSA_MASK 
    _ADR ANDD 
2:  _ADR SWAP 
    _DOLIT 24 
    _ADR RSHIFT 
    _UNNEST 

/*************************************
    !EXPONENT ( m e -- f# ; z n )
    format float from mantissa and
    exponent. Set flags 
**************************************/
    _HEADER STOR_EXPONENT,9,"!EXPONENT"
    _NEST
// exponent overflow?    
    _ADR DUPP 
    _ADR ABSS 
    _DOLIT 255 
    _ADR GREAT 
    _QBRAN 1f 
    _ADR SFV 
// mantissa overflow?     
1:  _ADR OVER 
    _ADR ABSS 
    _DOLIT 0x7ffffff 
    _ADR GREAT 
    _QBRAN 2f
    _ADR SFV 
2:  _DOLIT 24 
    _ADR LSHIFT 
    _ADR SWAP 
    _DOLIT MANTISSA_MASK
    _ADR ANDD  
    _ADR ORR 
    _UNNEST 
    
/******************************
    E. ( f# -- )
    print float in scientific 
    notation.
*******************************/
    _HEADER EDOT,2,"E."
    _NEST 
    _ADR SPACE 
    _ADR DUPP 
    _ADR ZEQUAL 
    _QBRAN 1f 
    _DOTQP 3,"0.0"
    _ADR DROP 
    _BRAN 9f
1:  _ADR BASE 
    _ADR AT 
    _ADR TOR 
    _ADR FBASE 
    _ADR AT 
    _ADR BASE 
    _ADR STORE
    _ADR AT_EXPONENT
    _ADR SWAP 
    _ADR DUPP 
    _ADR TOR // mantissa copy 
    _ADR FNE 
    _QBRAN 2f 
    _ADR ABSS 
2:  _ADR STOD 
    _ADR BDIGS
3:  _ADR DIG 
    _ADR ROT 
    _ADR ONEP 
    _ADR NROT 
    _ADR OVER 
    _ADR BASE 
    _ADR AT 
    _ADR ULESS 
    _QBRAN 3b
    _DOLIT '.' 
    _ADR HOLD 
    _ADR DIGS
    _ADR RFROM 
    _ADR SIGN 
    _ADR EDIGS
    _ADR TYPEE 
    _ADR QDUP 
    _QBRAN 8f
    _DOLIT 'E'
    _ADR EMIT 
    _ADR DUPP 
    _ADR ZLESS 
    _QBRAN 4f 
    _ADR ABSS 
    _DOLIT '-' 
    _ADR EMIT 
4:  _ADR STOD
    _ADR BDIGS 
    _ADR DIGS 
    _ADR EDIGS 
    _ADR TYPEE     
8:  _ADR RFROM 
    _ADR BASE 
    _ADR STORE 
9:  _UNNEST 

/******************************
    F. ( f# -- )
    print float in fixed point 
    format 
*******************************/
    _HEADER FDOT,2,"F."
    _NEST 
    _ADR DUPP 
    _ADR AT_EXPONENT 
    _ADR TOR 
    _ADR I 
    _ADR ABSS 
    _DOLIT 32 
    _ADR UGREAT 
    _QBRAN 1f
    _ADR RFROM 
    _ADR DROP 
    _ADR EDOT 
    _BRAN 9f 
1:  _ADR SPACE 
    _ADR FNE 
    _QBRAN 2f
    _ADR ABSS 
2:  _ADR STOD 
    _ADR BDIGS 
    _ADR I 
    _ADR ZLESS 
    _QBRAN 4f 
    _ADR I 
    _ADR ABSS 
    _DOLIT 0 
    _ADR TOR 
    _ADR TOR 
3:  _ADR DIG 
    _ADR RFROM 
    _ADR ONEP
    _ADR DUPP
    _ADR TOR  
    _ADR J 
    _ADR LESS 
    _QBRAN 3f
    _BRAN 3b 
3:  _ADR RFROM
    _ADR RFROM 
    _ADR DDROP 
    _DOLIT '.' 
    _ADR HOLD 
    _BRAN 6f 
4:  _DOLIT '.' 
    _ADR HOLD 
    _ADR I 
    _QBRAN 6f 
    _ADR I 
    _DOLIT 0 
    _ADR TOR 
    _ADR TOR 
5:  _DOLIT '0' 
    _ADR HOLD
    _ADR RFROM 
    _ADR ONEP 
    _ADR DUPP 
    _ADR TOR 
    _ADR J 
    _ADR LESS 
    _QBRAN 5f 
    _BRAN 5b
5:  _ADR RFROM 
    _ADR RFROM 
    _ADR DDROP 
6:  _ADR RFROM 
    _ADR DROP 
    _ADR DIGS 
    _ADR SWAP 
    _DOLIT 8
    _ADR LSHIFT 
    _ADR SIGN 
    _ADR EDIGS 
    _ADR TYPEE 
9:  _UNNEST 


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
    F>S ( f -- n )
    convert float to integer 
*******************************/
    _HEADER FTOS,3,"F>S"
    _NEST 

    _UNNEST 

/*******************************
    S>F ( s -- f )
    convert integer to float 
*******************************/
    _HEADER STOF,3,"S>F"
    _NEST 

    _UNNEST 

/*******************************
    D>F ( d -- f)
    convert double to float 
*******************************/
    _HEADER DTOF,3,"D>F"
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
    float ::=  [-]digit*'.'[digit]*[E[-]digit+]
    digit ::= '0'..'9' 
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

