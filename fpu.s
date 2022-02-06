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
onetenth = 0x3DCCCCCD // 0.1 

     .word  0x3089705F // 1e-9
     .word  0x322BCC77 // 1e-8
     .word  0x33D6BF95 // 1e-7
     .word  0x358637BD // 1e-6 
     .word  0x3727C5AC // 1e-5 
     .word  0x38D1B717 // 1e-4 
     .word  0x3A83126F // 1e-3 
     .word  0x3C23D70A // 1e-2 
     .word  0x3DCCCCCD // 1e-1 
p10:
     .word  0x3F800000 // 1.0 
     .word  0x41200000 // 1e1 
     .word  0x42C80000 // 1e2 
     .word  0x447A0000 // 1e3 
     .word  0x461C4000 // 1e4 
     .word  0x47C35000 // 1e5 
     .word  0x49742400 // 1e6 
     .word  0x4B189680 // 1e7
     .word  0x4CBEBC20 // 1e8 
     .word  0x4E6E6B28 // 1e9  

/***********************
    PWR10 
    return powers of 10
    from 1e-7..1e7
***********************/    
    _HEADER PWR10,5,"PWR10"
    lsl TOS,#2  
    ldr t0, =p10 
    add TOS,TOS,T0
    ldr TOS,[TOS]  
    _NEXT  
    


/*****************************
   initialize FPU
****************************/
fpu_init: 
   ldr.w r0,=CPACR 
   ldr R1,[R0]
   orr r1,r1,#(0xf<<20)
   str r1,[r0]
   dsb 
   ldr r0,=FPC_BASE_ADR
   eor r1,r1 
   str r1,[r0,FPCCR]
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
   CLR_FPSCR ( mask -- )
   clear FPSCR bits 
input:
    mask  and mask 
************************/
   _HEADER CLR_FPSCR,9,"CLR_FPSCR"
   vmrs T0,FPSCR 
   dsb 
   and TOS,T0  
   vmsr FPSCR,TOS 
   dsb 
   _NEXT 


/*******************************
    >S0 variable ( f# --  )
    send float to fpu S0 
**********************************/
    _HEADER TOS0,3,">S0"
    vmov.f32 S0,TOS 
    _POP 
    _NEXT  

/*******************************
    >S1 variable ( f# --  )
    send float to fpu S1 
**********************************/
    _HEADER TOS1,3,">S1"
    vmov.f32 S1,TOS 
    _POP 
    _NEXT  

/*******************************
    >S2 variable ( f# --  )
    send float to fpu S2 
**********************************/
    _HEADER TOS2,3,">S2"
    vmov.f32 S2,TOS 
    _POP 
    _NEXT  

/*******************************
    S0>  ( -- f )
    push fpu S0 
*******************************/
    _HEADER S0FROM,3,"S0>"
    _PUSH 
    vmov.f32 TOS,S0 
    _NEXT 

/*******************************
    S1>  ( -- f )
    push fpu S1 
*******************************/
    _HEADER S1FROM,3,"S1>"
    _PUSH 
    vmov.f32 TOS,S1 
    _NEXT 

/*******************************
    S2>  ( -- f )
    push fpu S2 
*******************************/
    _HEADER S2FROM,3,"S2>"
    _PUSH 
    vmov.f32 TOS,S2 
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
    _HEADER FSUBB,2,"F-"
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
    eor T0,T0 
    mvn T0,T0 
    lsr T0,#1 
    and TOS,T0 
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
    _ADR FSUBB
    _ADR FZLESS
    _ADR INVER     
    _UNNEST 

/*****************************
    F< ( f#1 f#2 -- flag )
    f#1<f#2 ? 
*****************************/
    _HEADER FLESS,2,"F<"
    _NEST 
    _ADR FSUBB 
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
    FSIGN ( f -- n )
    return float sign 
*******************************/
    _HEADER FSIGN,5,"FSIGN"
    eor T0,T0 
    movt T0,#0X8000
    and TOS,T0
    asr TOS,#31  
    _NEXT 

/*******************************
    FEXP ( f --  n )
    return binary exponent of f 
*******************************/
    _HEADER FEXP,4,"FEXP"
    _MOV32 T0,0X7F800000
    and TOS,T0 
    lsr TOS,#23
    sub TOS,#127 
    _NEXT  

/*******************************
   FMANT ( f -- n )
   return float mantisssa 
********************************/
    _HEADER FMANT,5,"FMANT"
    _MOV32 T0, 0X7FFFFF
    AND TOS,T0 
    EOR T0,T0 
    MOVT T0,0x80
    ORR TOS,T0 
    _NEXT 


/*******************************
    PI  ( -- f )
    return 3.14159265
*******************************/
    _HEADER PI,2,"PI"
    _PUSH 
    _MOV32 TOS, 0x40490FDB
    _NEXT
 
/********************************
    LOG2 ( -- f)
    return log10(2)
*******************************/
    _HEADER LOG2,4,"LOG2"
    _PUSH 
    _MOV32 TOS,0x3E9A209A
    _NEXT 

/********************************
    LOG2>10 ( f -- exp )
    convert float base2 exponent 
    to base10
********************************/
    _HEADER LOG2TO10,7,"LOG2>10" 
    _NEST
    _ADR FEXP 
    _ADR STOF 
    _ADR LOG2
    _ADR FSTAR 
    _ADR TRUNC  
    _ADR DUPP 
    _ADR ZLESS 
    _QBRAN 1f 
    _ADR ONEM
1:  _UNNEST 

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
