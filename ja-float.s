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

/*********************************************
    floating point math
    Jupiter ACE format 
    based on BCD  (binary Coded Decimal)
    ref. user's manual chapter 15
    FORTH words: F+, F-, F*, F/, 
                 FNEGATE, INT, UFLOAT, F. 
*********************************************/    

fpu_init:

    _RET 


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

/*****************************
   parse decimal integer 
   ( a -- a+ u sign )
   a+ point to first non digit  
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

