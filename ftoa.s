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

/*******************************************************
  words to format float32 
  adapted to forth from c code 
  ref: https://searchcode.com/codesearch/view/14753060/
********************************************************/


// used to round mantissa 
rounding:
 	.word  0x3F000000 // 0.5e0f
 	.word  0x3D4CCCCD // 0.5e-1f
 	.word  0x3BA3D70A // 0.5e-2f
 	.word  0x3A03126F // 0.5e-3f
    .word  0x3851B717 // 0.5e-4f
    .word  0x36A7C5AC // 0.5e-5f
    .word  0x350637BD // 0.5e-6f
 	.word  0x3356BF95 // 0.5e-7f
 	.word  0x31ABCC77 // 0.5e-8f

/****************************************
// round ( f n -- f )
// round float fraction to nth decimal 
// input:
//      f  float to round 
//      n  decimal to be rounded [1..7]
// output:
//      f  rounded float 
***************************************/
    _HEADER ROUND,5,"ROUND"
    _NEST
    _DOLIT 1  
    _ADR MAX  
    _DOLIT 8
    _ADR MIN 
    _DOLIT 2 
    _ADR LSHIFT 
    _DOLIT rounding 
    _ADR PLUS 
    _ADR AT   
    _ADR FPLUS 
    _UNNEST 

/*****************************
 c!+ (  c b -- b++ )
 store character in buffer 
 increment pointer 
*****************************/
    _HEADER CSTOP,3,"C!+"
    ldr T0,[DSP],#4
    strb T0,[TOS]  
    add TOS,#1
    _NEXT 

/********************************
 convert integer part to ascii 
 in buffer b 
 i>a ( i b -- b+ u )
*******************************/
    _HEADER ITOA,3,"I>A"
itoa:
    _NEST 
    _ADR TOR  // >R ( i r: b )
    _ADR STOD // ( dbl r: b )
    _ADR DUPP // ( dbl i r: b )
    _ADR TOR  // ( dbl r: b sign )
    _ADR DABS 
    _ADR BDIGS 
    _ADR DIGS 
    _ADR RFROM 
    _ADR SIGN 
    _ADR EDIGS // ( -- p u )
    _ADR DUPP  
    _ADR NROT // -rot ( -- u p u )
    _ADR RAT  // r@ ( -- u p u b )
    _ADR SWAP // ( -- u p b u )
    _ADR CMOVE // ( -- u ) 
    _ADR DUPP  // ( -- u u )
    _ADR RFROM // ( -- u u b )
    _ADR PLUS  // ( -- u b+ )
    _ADR SWAP  // ( -- b+ u )
    _UNNEST 


/*************************
\ SCALEUP ( f1 -- m f2 ) 
\ multiply fraction until 
\ f1 >= 0.1
\ input: 
\   f1  float
\ output:
\   m  log10 exponent 
\   f2  >= 0.1 
*************************/
    _HEADER SCALEUP,7,"SCALEUP" 
scaleup:
    _NEST 
    _DOLIT 0   // m 
    _ADR SWAP  // m f1 
1:  _ADR DUPP 
    _DOLIT onetenth 
    _ADR FLESS
    _QBRAN 2f
    _DOLIT ten 
    _ADR FSTAR
    // decrement m   
    _ADR SWAP
    _ADR ONEM 
    _ADR SWAP 
    _BRAN 1b
2:  _UNNEST 

/******************************
\ SCALEDOWN ( d f1 -- m d f2 )
\ divide by 10.0 until 
\ f < 10^d 
******************************/
    _HEADER SCALEDOWN,9,"SCALEDOWN"
scaledown: // ( d f1 -- m d f2 )
    _NEST 
    _ADR OVER 
    _ADR PWR10
    _DOLIT 0x31ABCC77 // 0.5e-8
    _ADR FSUBB 
    _ADR TOR
    _DOLIT 0 
    _ADR SWAP // d 0 f1 r: pwr10  
1:  _ADR DUPP
    _ADR RAT 
    _ADR FGREAT 
    _QBRAN 2f
    _DOLIT ten 
    _ADR FSLH 
    // increment m 
    _ADR SWAP 
    _ADR ONEP 
    _ADR SWAP 
    _BRAN 1b   
2:  _ADR RFROM 
    _ADR DROP
    _ADR SWAP // ( -- d f m ) 
    _ADR NROT // ( -- m d f )
    _UNNEST 


/***************************
convert exponant of float 
    EPART ( m b -- b+ )
input: 
    m   decimal exponent 
    b   string buffer 
output:
    b+   adjusted pointer 
****************************/
    _HEADER EPART,5,"EPART"
    _NEST
    _ADR SWAP
    _ADR QDUP    
    _QBRAN 2f 
    _ADR SWAP 
    _DOLIT 'E' // [char] E ( -- m b c )
    _ADR SWAP  
    _ADR CSTOP // c!+ ( -- m b ) 
    _ADR ITOA // ( i b -- b u )
    _ADR DROP // ( -- b+ )     
2:  _UNNEST 


/***************************
conver fraction part of float 
    FPART ( d f b -- b+ )
input:
    d   digit left to display 
    f   float to convert
    b   string* buffer  
output:
    b+  updated string* 
****************************/
    _HEADER FPART,5,"FPART"
    _NEST
    _DOLIT '.' 
    _ADR SWAP 
    _ADR CSTOP 
    _ADR TOR // >r ( d f r: b ) 
    // round to next digit 
    _ADR OVER 
    _ADR ROUND 
1:  _ADR SWAP  
    _ADR QDUP 
    _QBRAN 2f
    _ADR ONEM // 1- ( -- f d- r: b )
    _ADR SWAP // swap ( -- d f r: b )
    _DOLIT ten // ( d f 10.0 ) 
    _ADR FSTAR // f*
    _ADR DUPP  
    _ADR TRUNC // d f i
    _ADR DUPP  // d f i i  
    _DOLIT '0' 
    _ADR PLUS 
    _ADR RFROM // R> ( d f c b )
    _ADR CSTOP // ( d f i b+ )
    _ADR TOR  // >r ( -- d f i r: b )
    _ADR STOF // s>f ( -- d f f r: b ) 
    _ADR FSUBB 
    _BRAN 1b 
2:  _ADR DROP 
    _ADR RFROM 
    _UNNEST 

/***************************
 convert integer part of float 
    IPART ( d f b -- m d f b )
input:
    d   digit# to display 
    f   float to convert 
    b   string* buffer 
output:
    m   decimal exponent 
    d   digit# to display left 
    f   float fraction 
    b   update str* 
****************************/
    _HEADER IPART,5,"IPART"
    _NEST 
    _ADR TOR // ( -- d f r: b )
    _ADR DUPP 
    _DOLIT fone 
    _ADR FLESS 
    _QBRAN 1f 
    _DOLIT '0' 
    _ADR RFROM 
    _ADR CSTOP 
    _ADR TOR 
    _ADR scaleup
    _ADR SWAP 
    _ADR NROT 
    // decrement d 
    _ADR SWAP 
    _ADR ONEM 
    _ADR SWAP 
    _ADR RFROM // r> ( -- m d f b )  
    _UNNEST 
1:  _ADR scaledown // ( -- m d f r: b)
    _ADR DUPP  // ( -- m d f f r: b )
    _ADR TRUNC // ( -- m d f i r: b )
    _ADR DUPP  // ( -- m d f i i r: b )
    _ADR TOR   // ( -- m d f i r: b i ) 
    _ADR STOF  // ( -- m d f f )
    _ADR FSUBB // ( -- m d f r: b i )
    _ADR RFROM // ( -- m d f i r: b )
    _ADR RFROM  // ( -- m d f i b )  
    _ADR ITOA // -- m d f b u )
    _ADR TOR  // >r ( -- m d f b r: u )
    _ADR ROT
    _ADR RFROM // r> ( -- m f b d u ) 
    _ADR SUBB // ( -- m f b d- )
    _ADR NROT // ( -- m d f b )
    _UNNEST


/***************************************
\  f>a ( d f b -- b u )
\ convert float to string
\ input: 
\   b  output buffer  
\   d n# of digits [1..7] to convert 
\   f float to convert 
\  output: 
\   b output buffer 
\    u length of string 
****************************************/
    _HEADER FTOA,3,"F>A" // ( b d f -- b u )
    _NEST 
    _ADR DUPP // dup ( -- d f b b )
    _ADR TOR // >r   ( d f b r: b )  
    // store space first buffer char. 
    _ADR BLANK   //  bl ( -- d f b c r: b )
    _ADR SWAP 
    _ADR CSTOP  // c!+ ( -- d f b+ r: b )
    // check float sign 
    _ADR OVER  // over ( -- d f b f r: b ) 
    _ADR FSIGN // fsign ( -- d f b 0|-1 r: b )
    _QBRAN 1f  // 0branch 1f 
    // negative number add '-' to buffer 
    _DOLIT '-'  // [char] - ( -- d f b+ c r: b )
    _ADR SWAP 
    _ADR CSTOP  // c!+  ( -- d f b+ r: b )
1:  _ADR IPART  // ( d f b+ -- m d- f- b+ r: b )  
    _ADR FPART   // ( m d- f- b+ -- m b+ r: b )
    _ADR EPART    // ( m b+ -- b+ r: b  )
    _ADR RAT 
    _ADR SUBB 
    _ADR RFROM 
    _ADR SWAP 
    _UNNEST 


/***********************************
    F. (  f d -- )
    print float32 number  
    f -> float to print 
    d -> string digits# 
***********************************/
    _HEADER FDOT,2,"F."
    _NEST 
    // limit digits range [1..7]
    _DOLIT 1 
    _ADR MAX 
    _DOLIT 7 
    _ADR MIN
    _ADR SWAP // ( -- d f )
    // allocate convertion buffer 
    _ADR HERE
    _ADR TOR  
    _DOLIT 16 
    _ADR ALLOT 
    // fill it with zero's 
    _ADR RAT 
    _DOLIT 16 
    _DOLIT 0 
    _ADR FILL 
    _ADR RFROM // ( d f b )
    _ADR FTOA 
    _ADR TYPEE 
    // free buffer 
    _DOLIT -16 
    _ADR ALLOT
    _UNNEST 



