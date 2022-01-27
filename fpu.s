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


/*************************************
   Floating point using FPU 
*************************************/
  .cpu cortex-m4
  .fpu vfpv4
  .thumb

minus1 = 0xBF800000  // -1.0  to invert mantissa sign 
plus1 = 0x3F800000  // 1.0  
ten = 0x41200000  // 10.0  


/*****************************
   initialize FPU
****************************/
fpu_init: 
   ldr.w r0,=CPACR 
   ldr R1,[R0]
   orr r1,r1,#(0xf<<20)
   str r1,[r0]
   dsb 
   ldr r0,=FPCCR
   eor r1,r1 
   str r1,[r0]
   dsb 
   mov r0,#FPU_IRQ 
   _CALL nvic_enable_irq
   _RET

/***************************
   FPSCR ( -- u )
   stack fpu SCR register 
***************************/
   _HEADER FPSCR,5,"FPSCR"
   _PUSH 
   vmrs TOS,FPSCR
   dsb  
   _NEXT 


/**************************
   CLR_FPSCR ( -- )
************************/
   _HEADER CLR_FPSCR,9,"CLR_FPSCR"
   eor T0,T0 
   vmsr FPSCR,T0
   dsb 
   _NEXT 


/*******************************
    FBASE variable ( -- a )
    floating point numerical base
**********************************/
    _HEADER FBASE,5,"FBASE"
    _PUSH  
    add TOS,UP,#VFBASE 
    _NEXT  


/*******************************
    F>S ( f -- n )
    convert float to integer 
    round to nearest integer 
*******************************/
    _HEADER FTOS,3,"F>S"
    vmov.f32 S0,TOS
    vcvtr.s32.f32 s0,s0 
    vmov.f32 TOS,s0 
    _NEXT 
    
/*******************************
    TRUNC (f - n )
    truncate float to integer 
*******************************/
    _HEADER TRUNC,5,"TRUNC"
    vmov.f32 S0,TOS 
    vcvt.s32.f32 s0,s0 
    vmov.f32 TOS,S0 
    _NEXT 

/*******************************
    S>F ( s -- f )
    convert integer to float 
*******************************/
    _HEADER STOF,3,"S>F" 
    vmov.f32 S0,TOS
    vcvt.f32.s32 s0,s0 
    vmov.f32 TOS,s0 
   _NEXT 

/*******************************
    F+ ( f1 f2 -- f1+f2 )
    add 2 floats 
*******************************/
    _HEADER FPLUS,2,"F+"
   vmov.f32 s0,TOS 
   _POP 
   vmov.f32 s1,TOS 
   vadd.f32 s0,s0,s1 
   vmov.f32 TOS,s0
   _NEXT 

   
/*******************************
    F- ( f1 f2 -- f1-f2 )
    substract 2 float 
*******************************/
    _HEADER FMINUS,2,"F-"
   vmov.f32 s0,TOS 
   _POP 
   vmov.f32 s1,TOS 
   vsub.f32 s0,s1,s0 
   vmov.f32 TOS,s0
   _NEXT 



/*******************************
    F* ( f1 f2 -- f1*f2 )
    multiply 2 float 
******************************/
   _HEADER FSTAR,2,"F*"
   vmov.f32 s0,TOS 
   _POP 
   vmov.f32 s1,TOS 
   vmul.f32 s0,s1,s0 
   vmov.f32 TOS,s0
   _NEXT 


/*******************************
    F/ ( f1 f2 -- f1/f2 )
    divide f1 by f2 
*******************************/
    _HEADER FSLH,2,"F/"
   vmov.f32 s0,TOS 
   _POP 
   vmov.f32 s1,TOS 
   vdiv.f32 s0,s1,s0 
   vmov.f32 TOS,s0
   _NEXT 


/********************************
    FNEGATE ( f -- -f )
    negate floating point 
********************************/
    _HEADER FNEG,7,"FNEGATE"
    vmov.f32 s0,TOS 
    vneg.f32 S0,S0 
    vmov.f32 TOS,S0    
    _NEXT 

/**********************************
    FABS ( f -- f )
    return absolute value 
******************************/
    _HEADER FABS,4,"FABS"
    vmov.f32 s0,TOS 
    vabs.f32 S0,S0 
    vmov.f32 TOS,S0    
    _NEXT 


/*****************************
     SQRT  ( f -- f )
     compute square root 
*****************************/
     _HEADER SQRT,4,"SQRT"
     vmov.f32 s0,TOS 
     vsqrt.f32 s0,s0 
     vmov.f32 TOS,s0 
     _NEXT 


/*****************************
   F0<   ( f -- flag )
*****************************/
    _HEADER FZLESS,3,"F0<"
    vmov.f32 s0,TOS 
    vcmp.f32 s0, #0.0 
    vmrs TOS,FPSCR
    dsb  
    asr TOS,#31   
    _NEXT 

/*****************************
    F> ( f#1 f#2 -- flag )
    f#1>f#2 ? 
*****************************/
    _HEADER FGREAT,2,"F>"
    _NEST 
    _ADR FMINUS
    _ADR FZLESS
    _ADR INVER     
    _UNNEST 

/*****************************
    F< ( f#1 f#2 -- flag )
    f#1<f#2 ? 
*****************************/
    _HEADER FLESS,2,"F<"
    _NEST 
    _ADR FMINUS 
    _ADR FZLESS
    _UNNEST 


/*******************************
    FMIN ( f#1 f#2 -- smallest )
********************************/
    _HEADER FMIN,4,"FMIN"
    _NEST 
   _ADR OVER 
   _ADR OVER 
   _ADR FGREAT 
   _QBRAN 1f 
   _ADR SWAP  
1: _ADR DROP 
    _UNNEST 

/*******************************
    FMAX (f#1 f#2 -- largest )
*******************************/
    _HEADER FMAX,4,"FMAX"
    _NEST 
    _ADR OVER 
    _ADR OVER 
    _ADR FLESS 
    _QBRAN 1f
    _ADR SWAP   
1:  _ADR DROP 
    _UNNEST 


/*******************************
    PI  ( -- f )
    return 3.14159265
*******************************/
    _HEADER PI,2,"PI"
    _PUSH 
    _MOV32 TOS, 0x40490FDB
    _NEXT
 

/*********************************
     float printing 
*********************************/

/*********************************
    @EXPONENT ( f -- n )
    extract exponent from float 
********************************/
    _HEADER AT_EXPONENT,9,"@EXPONENT"
    _NEST 
    _DOLIT 23
    _ADR RSHIFT 
    _DOLIT 255  
    _ADR ANDD 
    _DOLIT 127 
    _ADR SUBB  
    _UNNEST 

/**************************************
    E. ( f -- )
    print float in scientific notation
***************************************
    _HEADER EDOT,2,"E."
    _NEST 

    _UNNEST 

frac_digit: 
    vmov.f32 s2,#ten 
    vmul.f32 s1,s0,s2 

/********************************
    F. ( f -- )
    print float in fixed point 
*********************************/
    _HEADER FDOT,2,"F."
    _NEST 
    _ADR DUPP 
    _ADR FZLESS 
    _QBRAN 1f 
    _DOLIT '-'
    _ADR EMIT 
    _ADR FNEG
1:  _ADR DUPP 
    _DOLIT plus1 
    _ADR FLESS 
    _QBRAN 2f // float > 0 
// float < 0 
    _DOLIT '0' 
    _ADR EMIT 
    _DOLIT '.' 
    _ADR EMIT 
    _DOLIT 7 
    _ADR TOR
    _DOLIT ten 

1:      

2: // float > 0         
    _UNNEST 

/*********************************
    float parsing 
*********************************/


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
