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

// used as multiply factor 
pwr10m9: 
    .word 0x322BCC77  // 10e-9
    .word 0x33D6BF95  // 10e-8
    .word 0x358637BD  // 10e-7
    .word 0x3727C5AC  // 10e⁻6
    .word 0x38D1B717  // 10e-5
    .word 0x3A83126F  // 10e-4
    .word 0x3C23D70A  // 10e-3
    .word 0x3DCCCCCD  // 10e-2
    .word 0x3F800000  // 10e-1
pwr10e0:    
    .word 0x41200000  // 10e0 
    .word 0x42C80000  // 10e1 
    .word 0x447A0000  // 10e2
    .word 0x461C4000  // 10e3 
    .word 0x47C35000  // 10e4 
    .word 0x49742400  // 10e5 
    .word 0x4B189680  // 10e6 
    .word 0x4CBEBC20  // 10e7 
    .word 0x4E6E6B28  // 10e8 
    .word 0x501502F9  // 10e8 


// used to round mantissa 
rounding:
    .word  0x2CAFEBFF // 0.5e-11f,   < 0.00001 
    .word  0x2E5BE6FF // 0.5e-10f,   0.00001 - 0.0001 
 	.word  0x3009705F // 0.5e-9f,   0.0001 - 0.001
 	.word  0x31ABCC77 // 0.5e-8f,   0.001 - 0.01
 	.word  0x3356BF95 // 0.5e-7f,   0.01 - 0.1
    .word  0x350637BD // 0.5e-6f,   0.1 - 1     
    .word  0x36A7C5AC // 0.5e-5f,   1 - 10    : 0.000005
    .word  0x3851B717 // 0.5e-4f,   10 - 100 
 	.word  0x3A03126F // 0.5e-3f,   100 - 1000 
 	.word  0x3BA3D70A // 0.5e-2f,   1000 - 10000 
 	.word  0x3D4CCCCD // 0.5e-1f,   10000 - 100000 
 	.word  0x3F000000 // 0.5e0f,    100000 - 1000000 


/***********************************
    E. ( f w -- )
    print in scientific notation 
    f -> float to print 
    w -> maximum string width
***********************************/
    _HEADER EDOT,2,"E."
    _NEST

    _UNNEST 


/***********************************
    F. ( f w -- )
    print in fixed point format 
    f -> float to print 
    w -> maximum string width 
***********************************/
    _HEADER FDOT,2,"F."
    _NEST 
    _DOLIT 40 // width <= 40
    _ADR MIN 
    _ADR SWAP
    _ADR DUPP 
    _ADR FEXP 
    _DOLIT 31 
    
    _UNNEST 


// convert integer to string 
// in buffer b 
// return pstr 
itoa: // ( s b -- pstr )
    _NEST 
    _ADR HLD 
    _ADR STORE 
    _DOLIT 0  // convert to double 
    _ADR DIGS 
    _ADR 
    _UNNEST 

