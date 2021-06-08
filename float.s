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
    REF: docs/FD-V04N1.pdf ,  page 23

Format:
    bit 23:0  6 digits signed mantissa
    bit 31:24 signed exponent 

*******************************************************/    

    MANTISSA_MASK = 0xffffff // biggest mantissa 
    MANTISSA_SIGN = 0x800000 
    MANTISSA_MAX = 0x7fffff 

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
    _ADR SFN 
    _ADR SFZ 
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
    _DOLIT MANTISSA_MASK 
    _ADR ANDD  
    _ADR ZEQUAL 
    _QBRAN 1f 
    _ADR DROP 
    _DOTQP 3,"0.0"
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
    _ADR FNE 
    _QBRAN 4f 
    _DOLIT '-'
    _ADR HOLD 
4:  _ADR EDIGS
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


/*****************************
  format integer part 
/******************************
    F. ( f# -- )
    print float in fixed point 
    format 
*******************************/
    _HEADER FDOT,2,"F."
    _NEST
    _ADR BASE 
    _ADR AT 
    _ADR TOR 
    _ADR FBASE
    _ADR AT  
    _ADR BASE 
    _ADR STORE 
    _ADR SPACE 
    _ADR BDIGS
    _DOLIT '0'
    _ADR HOLD   
    _ADR AT_EXPONENT 
    _ADR SWAP  
    _ADR ABSS
    _ADR STOD 
    _ADR ROT  
    _ADR DUPP 
    _ADR ZLESS 
    _QBRAN POS_E // positive exponent   
// negative exponent
1:  _ADR DUPP 
    _QBRAN POS_E   
    _ADR NROT  
    _ADR DIG  
    _ADR ROT   
    _ADR ONEP 
    _BRAN 1b  
POS_E:
    _DOLIT '.'
    _ADR HOLD 
1:  _ADR DUPP 
    _QBRAN 8f 
    _DOLIT '0'
    _ADR HOLD 
    _ADR ONEM 
    _BRAN 1b
8:  _ADR DROP 
    _ADR DIGS 
    _ADR FNE
    _QBRAN 9f 
    _DOLIT '-'
    _ADR HOLD 
9:  _ADR EDIGS 
    _ADR TYPEE 
    _ADR RFROM 
    _ADR BASE 
    _ADR STORE 
    _UNNEST 


/*******************************
    F* ( f1 f2 -- f1*f2 )
    multiply 2 float 
******************************/
    _HEADER FSTAR,2,"F*"
    _NEST 
    _ADR AT_EXPONENT 
    _ADR TOR 
    _ADR SWAP 
    _ADR AT_EXPONENT 
    _ADR RFROM 
    _ADR PLUS  // e1+e2
    _ADR TOR 
    _ADR MSTAR // m1*m2 
    _ADR DUPP 
    _DOLIT 31 
    _ADR RSHIFT // product sign  
    _ADR NROT  // put it on back burner
    _ADR DABS 
1:  _ADR DDUP 
    _DOLIT MANTISSA_MAX     
    _DOLIT 0 
    _ADR UDGREAT 
    _QBRAN 2f 
    _ADR FBASE 
    _ADR AT 
    _ADR DSLMOD 
    _ADR ROT 
    _ADR DROP
    _ADR RFROM 
    _ADR ONEP 
    _ADR TOR 
    _BRAN 1b 
2:  _ADR ROT  // product sign 
    _QBRAN 3f 
    _ADR DNEGA 
3:  _ADR RFROM 
    _ADR STOR_EXPONENT
    _UNNEST  


/*******************************
    F/ ( f1 f2 -- f1/f2 )
    divide f1 by f2 
*******************************/
    _HEADER FSLH,2,"F/"
    _NEST 
    _ADR AT_EXPONENT 
    _ADR TOR 
    _ADR SWAP 
    _ADR AT_EXPONENT 
    _ADR RFROM
    _ADR PLUS 
    _ADR TOR  
    _ADR SWAP 
    _ADR SLASH 
    _ADR RFROM 
    _ADR STOR_EXPONENT
    _UNNEST 


/******************************
    F-ALIGN ( f#1 f#2 -- m1 m2 e )
    align 2 floats for f+ or f- 
    operation 
*********************************/
    _HEADER FALIGN,7,"F-ALIGN" 
    _NEST 
    _ADR AT_EXPONENT 
    _ADR TOR 
    _ADR SWAP 
    _ADR AT_EXPONENT
    _ADR RFROM 
    _ADR DDUP 
    _ADR LESS 
    _QBRAN 4f 
    _ADR SWAP 
    _ADR TOR 
    _ADR ROT // M1 E2 M2 R: E1         
1:  _ADR OVER 
    _ADR RAT 
    _ADR DIFF 
    _QBRAN 2f 
    _ADR FBASE 
    _ADR STAR 
    _ADR SWAP 
    _ADR ONEM 
    _ADR SWAP
    _BRAN 1b 
2:  _ADR SWAP  
    _BRAN 8f 
4:  _ADR TOR 
    _ADR SWAP // M2 E1 M1 R: E2 
5:  _ADR OVER 
    _ADR RAT 
    _ADR DIFF 
    _QBRAN 6f 
    _ADR FBASE 
    _ADR STAR 
    _ADR SWAP 
    _ADR ONEM 
    _ADR SWAP 
    _BRAN 5b 
6:  _ADR NROT 
8:  _ADR RFROM 
    _ADR DROP  // M1 M2 E     
    _UNNEST 

/*******************************
    F+ ( f1 f2 -- f1+f2 )
    add 2 floats 
*******************************/
    _HEADER FPLUS,2,"F+"
    _NEST 
    _ADR FALIGN 
    _ADR TOR 
    _ADR PLUS 
    _ADR RFROM 
    _ADR STOR_EXPONENT
    _UNNEST 

/*******************************
    F- ( f1 f2 -- f1-f2 )
    substract 2 float 
*******************************/
    _HEADER FMINUS,2,"F-"
    _NEST 
    _ADR FALIGN 
    _ADR TOR 
    _ADR SUBB 
    _ADR RFROM 
    _ADR STOR_EXPONENT
    _UNNEST 


/********************************
    FNEGATE ( f -- -f )
    negate floating point 
********************************/
    _HEADER FNEG,7,"FNEGATE"
    mov T0,TOS 
    _MOV32 T1,MANTISSA_MASK 
    and T0,T1 
    lsl T0,#8 
    asr T0,#8 
    rsb T0,#0 
    and T0,T1 
    mvn T1,T1 
    and TOS,T1 
    orr TOS,T0 
    _NEXT 

/**********************************
    FABS ( f -- f )
    return absolute value 
******************************/
    _HEADER FABS,4,"FABS"
    mov T0,TOS 
    _MOV32 T1,MANTISSA_MASK 
    and T0,T1 
    mvn T1,T1 
    tst T0,#(1<<23)
    beq 1f
    mvn T1,T1  
    eor T0,T1 
1:  and TOS,T1 
    orr TOS,T0 
    _NEXT 

/*******************************
    FMIN ( f#1 f#2 -- smallest )
********************************/
    _HEADER FMIN,4,"FMIN"
    _NEST 
    _ADR DDUP 
    _ADR FALIGN 
    _ADR DROP 
    _ADR GREAT   
    _QBRAN 1f 
    _ADR SWAP 
1:  _ADR DROP 
    _UNNEST 

/*******************************
    FMAX (f#1 f#2 -- largest )
*******************************/
    _HEADER FMAX,4,"FMAX"
    _NEST 
    _ADR DDUP 
    _ADR FALIGN 
    _ADR DROP 
    _ADR LESS 
    _QBRAN 1f 
    _ADR SWAP 
1:  _ADR DROP 
    _UNNEST 

/*****************************
    F> ( f#1 f#2 -- flag )
    f#1>f#2 ? 
*****************************/
    _HEADER FGREAT,2,"F>"
    _NEST 
    _ADR FALIGN
    _ADR DROP 
    _ADR GREAT  
    _UNNEST 

/*****************************
    F< ( f#1 f#2 -- flag )
    f#1<f#2 ? 
*****************************/
    _HEADER FLESS,2,"F<"
    _NEST 
    _ADR FALIGN
    _ADR DROP 
    _ADR LESS   
    _UNNEST 

/*******************************
    F>S ( f -- n )
    convert float to integer 
*******************************/
    _HEADER FTOS,3,"F>S"
    mov T0,TOS
    _MOV32 T1,MANTISSA_MASK  
    and T0,T1
    lsl T0,#8 
    asr T0,#8
0:  asr TOS,#24 // exponent 
    ldr T2,[UP,#VFBASE]
    tst TOS,#(1<<31)
    bne 2f 
// positive exponent 
1:  cbz TOS,8f 
    cbz T0,8f 
    mul T0,T2 
    sub TOS,#1 
    b 1b 
// negative exponent 
2:  cbz TOS,8f 
    cbz T0,8f 
    sdiv T0,T2 
    add TOS,#1
    b 2b 
8:  mov TOS,T0 
    _NEXT 
    

/*******************************
    S>F ( s -- f )
    convert integer to float 
*******************************/
    _HEADER STOF,3,"S>F" 
    eor T0,T0 // exponent 
    eor T2,T2 // sign 
    ldr T1,[UP,#VFBASE]
    _MOV32 T3,MANTISSA_MAX 
    tst TOS,#(1<<31)
    beq 1f 
    rsb TOS,#0 
    mvn T2,T2 // - integer  
1:  cmp TOS,T3 
    bmi 2f 
    udiv TOS,TOS,T1 
    add T0,#1 
    b 1b
2:  cbz T2,3f 
    rsb TOS,#0 
    _MOV32 T3,MANTISSA_MASK 
    and TOS,T3
3:  lsl T0,#24 
    orr TOS,T0 
    _NEXT 


/********************************
 check for exponent 
********************************/
EXPONENT: // ( a -- e a+ )
    _NEST 
    _DOLIT 'E'
    _ADR CHARQ 
    _QBRAN 2f 
    _DOLIT '-'
    _ADR CHARQ
    _ADR TOR
    _DOLIT 0 
    _ADR DUPP  
    _ADR ROT 
    _ADR PARSE_DIGITS
    _ADR ROT
    _ADR DROP // discard digits count  
    _ADR RFROM 
    _QBRAN 8f 
    _ADR SWAP
    _ADR NEGAT
    _ADR SWAP
    _BRAN 8f    
2:  _DOLIT 0 
    _ADR SWAP     
8:  _UNNEST 


/**********************************
    FLOAT? ( a -- f# -2 | a 0 )
    parse float number
**********************************/
    _HEADER FLOATQ,6,"FLOAT?"
    _NEST
    _ADR BASE 
    _ADR AT 
    _ADR TOR 
    _ADR FBASE 
    _ADR AT 
    _ADR BASE 
    _ADR STORE 
    _ADR DUPP
    _ADR COUNT 
    _ADR DROP  // count not used  
    _DOLIT 0 
    _ADR DUPP 
    _ADR ROT   // -- a 0 0 a+  
// check for sign  
    _DOLIT '-'
    _ADR  CHARQ 
    _ADR  TOR  
    _ADR PARSE_DIGITS 
    _ADR ROT 
    _ADR DROP // d not used 
    _DOLIT 0 
    _ADR NROT   // reset it ( -- a 0 n a+ ) R: base sign  
// check for '.'
    _DOLIT '.'
    _ADR  CHARQ
    _QBRAN 1f 
    _ADR PARSE_DIGITS 
    _ADR ROT 
    _ADR NEGAT
    _ADR  NROT // negate digit count ( -- a d n a+ )
1:  _ADR EXPONENT // a d n e a+  
    _ADR COUNT 
    _ADR ZEQUAL 
    _QBRAN 4f   
    _ADR  DROP  // a d n e 
    _ADR  ROT 
    _ADR  PLUS  // a n e- 
    _ADR  ROT
    _ADR  DROP 
    _ADR  SWAP 
    _ADR  RFROM
    _QBRAN 3f
    _ADR NEGAT 
3:  _ADR SWAP
    _ADR STOR_EXPONENT 
    _DOLIT -2
    _BRAN 8f  
4:  _ADR RFROM 
    _ADR DROP 
    _ADR  DDROP
    _ADR  DDROP  
    _DOLIT 0 
8:
    _ADR RFROM 
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

