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



MANTISSA_MASK = 0 
MANTISSA_MAX = 0x7fffffff

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



/******************************
    F-ALIGN ( f#1 f#2 -- m1 m2 e )
    align 2 floats for f+ or f- 
    operation 
*********************************/
    _HEADER FALIGN,7,"F-ALIGN" 
    _NEST 
    _ADR AT_EXPONENT // F#1 M2 E2 
    _ADR TOR  // F#1 M2 R: E2
    _ADR SWAP // M2 F#1
    _ADR AT_EXPONENT // M2 M1 E1 
    _ADR ROT    // M1 E1 M2
    _ADR SWAP  // M1 M2 E1  
    _ADR RFROM  // M1 M2 E1 E2 
    _ADR DDUP   
    _ADR LESS  
    _QBRAN 4f 
// E1 < E2     
    _ADR SWAP // M1 M2 E2 E1  
    _ADR TOR  // M1 M2 E2 R: E1 
1:  _ADR DUPP 
    _ADR RAT 
    _ADR DIFF   
    _QBRAN 8f 
    _ADR SWAP 
    _ADR FBASE
    _ADR AT  
    _ADR STAR 
    _ADR SWAP 
    _ADR ONEM 
    _BRAN 1b 
// E2 <= E1     
4:  _ADR TOR  // M1 M2 E1 R: E2   
    _ADR ROT   // M2 E1 M1 R: E2
    _ADR SWAP // M2 M1 E1 R: E2  
5:  _ADR DUPP  
    _ADR RAT 
    _ADR DIFF 
    _QBRAN 6f
    _ADR SWAP  
    _ADR FBASE 
    _ADR AT 
    _ADR STAR 
    _ADR SWAP 
    _ADR ONEM 
    _BRAN 5b 
6:  _ADR ROT  // M1 E1 M2 
    _ADR SWAP  // m1 m2 E1 
8:  _ADR RFROM 
    _ADR DROP  // M1 M2 E     
    _UNNEST 





