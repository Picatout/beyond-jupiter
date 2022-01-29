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

/****************************************************************************************
  float number parser 

  adapted from  following C code 
  ref: https://github.com/ochafik/LibCL/blob/master/src/main/resources/LibCL/strtof.c

****************************************************************************************/

/******************************************************
    powers of 10 used in parsing float numbers 
*******************************************************/    

powersof10:  .word  0x41200000  // 10.0 
             .word  0x42C80000  // 100.0
             .word  0x461C4000  // 10000.0 
             .word  0x4CBEBC20  // 1.0e8
             .word  0x5A0E1BCA  // 1.0e16 
             .word  0x749DC5AE  // 1.0e32 

fzero =  0x0
fone =  0x3F800000
fminus1 = 0xBF800000
ften = 0x41200000 


// fetch element from powersof10 array 
power10: // ( idx -- f )
    _NEST 
    _DOLIT 2 
    _ADR LSHIFT 
    _DOLIT powersof10
    _ADR PLUS 
    _ADR AT 
    _UNNEST 


// get sign 
// a is update if *a is '-'|'+'
get_sign: // a -- a sign 
    _NEST 
    _DOLIT '.' 
    _ADR CHARQ
    _ADR DUPP  
    _QBRAN 1f 
    _BRAN 2f
1:  _DOLIT '+'
    _ADR CHARQ 
    _ADR DROP 
2:  _UNNEST 


// check if exponent bit at idx position is 
// set or reset   
bit_state: // ( idx f e -- idx f bit )
    _NEST 
    _DOLIT 1  // idx f e 1
    _DOLIT 3  // idx f e 1 3 
    _ADR PICK  // idx f e 1 idx 
    _ADR LSHIFT // idx f e bit_mask 
    _ADR ANDD   // idx f bit, i.e. 0||1<<idx  
    _UNNEST 

// exponent adjustment 
// multiply or divide mantissa by exponent  
// if exponant < 0 divide 
// if exponant >0 multiply 
// 8f exponant == 0 done 
mult_div_exp: // ( e f  -- f )
    _NEST 
    _ADR OVER  // e f e 
    _QBRAN 4f // exp==0,  done 
    _DOLIT 0  // e f idx  
    _ADR NROT // idx e f
    _ADR SWAP // idx f e   
    _ADR DUPP  // idx f e e 
    _ADR ZLESS
    _QBRAN pos_exp 
// negative exponent 
    _ADR ABSS 
    _ADR TOR //  -- idx f R: e 
div_loop:
    _ADR RAT   // idx f e R: e 
    _ADR bit_state // idx f state 
    _QBRAN 1f   // bit reset 
    _ADR OVER 
    _ADR power10 // idx f pwr10 R: e
    _ADR FSLH  // idx f R: e 
1:  _ADR SWAP  // f idx R: e 
    _ADR ONEP   // F idx++ R: e 
    _ADR SWAP   // idx f  
    _ADR OVER   // idx f idx 
    _DOLIT 5 
    _ADR GREAT  // idx > 5
    _QBRAN div_loop 
    _BRAN 3f 
pos_exp: // positive exponent 
    _ADR TOR // idx f  R: e 
mult_loop:
    _ADR RAT   // idx f e R: e 
    _ADR bit_state // idx f state 
    _QBRAN 1f   // bit reset 
    _ADR OVER  
    _ADR power10 // idx f pwr10 R: e
    _ADR FSTAR  // idx f R: e 
1:  _ADR SWAP  // f idx R: e 
    _ADR ONEP   // F idx++ R: e 
    _ADR SWAP   // idx f  
    _ADR OVER   // idx f idx 
    _DOLIT 5 
    _ADR GREAT  // idx > 5
    _QBRAN mult_loop 
// adjustment done 
3:  _ADR RFROM 
    _ADR DROP 
4:  _ADR SWAP 
    _ADR DROP 
    _UNNEST 

// divide fraction by 
// 10^d 
div_fract: // ( d f -- f )
    _NEST 
    _ADR SWAP 
    _ADR TOR 
    _DOLIT fone  
    _BRAN 2 
1: // create 10^d 
    _DOLIT ften 
    _ADR FSTAR 
2:  _DONXT 1b   
    _ADR RFROM 
    _ADR FSLH
    _UNNEST 

/**********************************
    FLOAT? ( a -- f# -2 | a 0 )
    parse float number 
    return a 0 if not float 
**********************************/
    _HEADER FLOATQ,6,"FLOAT?"
    _NEST
    // always use base 10 
    // hexadecimal float not accepted 
    _ADR BASE 
    _ADR AT 
    _ADR TOR 
    // set BASE TO 10 
    _ADR DECIM 
	_DOLIT	0      // failed flag   
	_ADR	OVER   // a 0 a     R: base
	_ADR	COUNT  // a 0 a+ cnt  // cnt is length of string 
    _ADR    DROP   // can drop cnt as there is a 0 at end of string 
// check for '-'|'+' save sign on R: 
    _ADR get_sign 
    _ADR   TOR // -- a 0 a  R: base sign 
2:  _DOLIT 0 
    _ADR DUPP 
    _ADR ROT 
    _ADR PARSE_DIGITS   
    _ADR NROT // a 0 a d n 
    _ADR S>F  // convert n to float 
    _ADR TOR  //  send it to R: 
    _ADR DROP // d not needed
 _ADR DOTS 
// must be '.' or 'E' 
    _DOLIT '.' 
    _ADR CHARQ 
    _QBRAN 3f 
// parse fraction 
    _DOLIT 0 
    _ADR DUPP 
    _ADR ROT 
    _ADR PARSE_DIGITS
    _ADR NROT // a 0 a d n 
    _ADR STOF  // convert integer n to float 
    _ADR div_fract // frac/10^d 
_ADR DOTS 
    _ADR TOR  // a 0 a R: base sign fn ffrac 
    _DOLIT 'E' 
    _ADR CHARQ 
    _QBRAN 2f
    _BRAN 4f
2: // no exponent 
    _DOLIT 0 
    _ADR TOR  // a 0 a R: base sign fn ffrac exp 
    _BRAN 6f        
3:  _DOLIT 'E' 
    _ADR CHARQ 
    _QBRAN error2     
5: // get_exponent 
    _ADR get_sign 
    _ADR TOR 
    _DOLIT 0 
    _ADR DUPP 
    _ADR ROT 
    _ADR PARSE_DIGITS 
    _ADR RFROM // exponent sign 
    _QBRAN 6f 
    _ADR NEGAT 
6: // build float 
    _ADR DROP 
    _ADR DDROP 
    _ADR RFROM 
    _ADR DRFROM 
    _ADR FPLUS 
    _ADR mult_div_exp
    _DOLIT 2 
    _UNNEST 
error1: // a 0 a R: base sign 
    _ADR RFROM 
    _ADR DROP 
    _BRAN 9f 
error2: // a 0 cnt a R: base sign 0.0 
    _ADR DRFROM 
    _ADR DDROP  // a 0 cnt a R: base 
9:  _ADR DROP // a 0 a -- a 0 R: base 
restore_base: 
    _ADR RFROM 
    _ADR BASE 
    _ADR STORE 
    _UNNEST 

