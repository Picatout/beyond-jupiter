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

// check first char for '-'|'+' 
// update pointer if found 
get_sign: // ( a cnt -- a cnt 0 | a+ cnt- -1 )
    _NEST
    _ADR OVER 
    _ADR CAT 
    _ADR DUPP 
    _DOLIT '-' 
    _ADR EQUAL 
    _ADR DUPP 
    _ADR TOR 
    _QBRAN 4f
    _ADR DROP  
1:  _ADR padv  
2:  _ADR RFROM 
    _UNNEST 
4:  _DOLIT '+' 
    _ADR EQUAL 
    _QBRAN 2b
    _BRAN 1b 

/*
// get mantissa size 
// m -> digits count in mantissa 
mant_size: // ( a cnt -- a+ cnt- m )
    _NEST 
    _DOLIT 0 
    _ADR NROT   // mantissa size   -- m a cnt 
// check for cnt==0     
1:  _ADR DUPP 
    _ADR ZEQUAL 
    _QBRAN 2f 
    _BRAN 4f  // end of string 
2:  _ADR OVER 
    _ADR CAT 
    _ADR DIGTQ // return u flag  
    _ADR SWAP 
    _ADR DROP  // don't keep u  
    _QBRAN 4f  // not a digit 
    _ADR ROT 
    _ADR ONEP 
    _ADR NROT 
    _ADR padv 
    _BRAN 1b
4:  _ADR ROT     
    _UNNEST 
*/

// parse integer part 
parse_int: // ( a cnt -- a+ cnt- fi )
    _NEST 
    _DOLIT fzero
    _ADR NROT  // 0.0 a cnt 
1: // check for end fo string 
    _ADR DUPP 
    _ADR ZEQUAL 
    _QBRAN 2f 
    _BRAN 4f // end of string 
2:  _ADR OVER 
    _ADR CAT 
    _ADR DIGTQ 
    _QBRAN 3f  
    _ADR STOF // convert digit to float 
    _ADR TOR  
    _ADR ROT  
    _DOLIT ften 
    _ADR FSTAR 
    _ADR RFROM 
    _ADR FPLUS 
    _ADR NROT 
    _ADR padv 
    _BRAN 1b 
3:  _ADR DROP 
4:  _ADR ROT
    _UNNEST 


// parse fraction part 
parse_frac: // ( a cnt -- a+ cnt- ff ) 
    _NEST 
    _DOLIT fzero  
    _ADR TOR 
    _DOLIT fone 
    _ADR NROT 
1:  // check for end of string 
    _ADR DUPP 
    _ADR ZEQUAL 
    _QBRAN 2f 
    _BRAN 4f // end of string 
2:  _ADR OVER 
    _ADR CAT 
    _ADR DIGTQ 
    _QBRAN 3f  
    _ADR STOF // convert digit to float 
    _ADR TOR  
    _ADR ROT 
    _ADR ften 
    _ADR FSTAR
    _ADR DUPP  
    _ADR RFROM 
    _ADR FSLH
    _ADR RFROM 
    _ADR FPLUS 
    _ADR TOR 
    _ADR NROT
    _ADR padv  
    _BRAN 1b 
3:  _ADR DROP 
4:  _ADR ROT 
    _ADR DROP 
    _ADR RFROM 
    _UNNEST 

// parse exponent part 
parse_exp: // ( a cnt -- a+ cnt- exp ) 
    _NEST
    _ADR get_sign
    _ADR TOR 
    _DOLIT 0 
    _ADR NROT 
1:  // check for end of string 
    _ADR DUPP 
    _ADR ZEQUAL 
    _QBRAN 2f 
    _BRAN 4f // end of string 
2:  _ADR OVER 
    _ADR CAT 
    _ADR DIGTQ 
    _QBRAN 3f  
    _ADR TOR 
    _ADR ROT 
    _DOLIT 10 
    _ADR STAR
    _ADR RFROM 
    _ADR PLUS 
    _ADR NROT 
    _ADR padv 
    _BRAN 1f 
3:  _ADR DROP 
4:  _ADR ROT 
    _ADR RFROM // sign 
    _QBRAN 5f 
    _ADR NEGAT 
5:  _UNNEST 

// fetch element from powersof10 array 
power10: // ( idx -- f )
    _NEST 
    _DOLIT 2 
    _ADR LSHIFT 
    _DOLIT powersof10
    _ADR PLUS 
    _ADR AT 
    _UNNEST 


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

// move pointer forward and decrement count 
padv: // ( a cnt -- a++ cnt-- )
    _NEST 
    _ADR ONEM 
    _ADR SWAP 
    _ADR ONEP 
    _ADR SWAP 
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
    _DOLIT 10 
    _ADR BASE 
    _ADR STORE
	_DOLIT	0      // failed flag   
	_ADR	OVER   // a 0 a     R: base
	_ADR	COUNT  // a 0 a+ cnt  // cnt is length of string 
// get sign and save it on R: 
    _ADR    get_sign 
    _ADR    TOR // -- a 0 a+ cnt R: base sign 
// check for end of string 
    _ADR    DUPP 
    _ADR   ZEQUAL 
    _QBRAN  int_part
    _BRAN  error1
int_part: // parse integer part. 
    _ADR   parse_int // -- a 0 a+ cnt- fi R: base sign 
    _ADR   TOR    // -- a 0 a+ cnt- R: base sign fi 
// check for end of string 
    _ADR   DUPP 
    _ADR   ZEQUAL  
    _QBRAN  dot_or_e 
    _BRAN  not_float  // if end of string it's not a float, missing '.' or 'E'.  
dot_or_e: // next character must be '.' or 'E'   
    _ADR   OVER 
    _ADR   CAT 
    _ADR   DUPP 
    _DOLIT '.' 
    _ADR  EQUAL 
    _QBRAN test_E // not '.' 
// skip decimal point 
    _ADR  DROP // drop character  
    _ADR  padv  
    _ADR  parse_frac
    _ADR  RFROM 
    _ADR  FPLUS // int_part+frac_part  
    _ADR  TOR 
// check of end of string     
    _ADR  DUPP  // a 0 a+ cnt- cnt-  
    _ADR  ZEQUAL 
    _QBRAN test_E  // next char must be 'E' 
// end of float 
    _BRAN is_float 
test_E: 
    _DOLIT 'E' 
    _ADR  EQUAL 
    _QBRAN not_float  
    _ADR padv 
    _ADR parse_exp
    _ADR TOR 
    _ADR DUPP 
    _ADR EQUAL 
    _QBRAN not_float // character left in string. 
    _ADR RFROM  
exp_to_bin: // convert decimal exponent to binary exponent  
    _ADR mult_div_exp 
is_float: // a 0 a+ cnt- R: base float  
    _ADR DDROP 
    _ADR DDROP 
    _ADR RFROM  // float  
    _ADR RFROM // sign 
    _QBRAN 1f
    _DOLIT fminus1  
    _ADR FSTAR 
1:  _DOLIT 2  // flag indicating a float 
    _BRAN restore_base 
not_float: // a 0 a+ cnt- R: base sign float 
    _ADR RFROM 
    _ADR DROP  
error1:
    _ADR RFROM 
    _ADR DROP 
    _ADR DDROP 
restore_base: 
    _ADR RFROM 
    _ADR BASE 
    _ADR STORE 
    _UNNEST 

