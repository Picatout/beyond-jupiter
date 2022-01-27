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

******************************************************
    powers of 10 used in parsing float numbers 
*******************************************************/    

powersof10:  .word  0x41200000  // 10.0 
             .word  0x42C80000  // 100.0
             .word  0x461C4000  // 10000.0 
             .word  0x4CBEBC20  // 1.0e8
             .word  0x5A0E1BCA  // 1.0e16 
             .word  0x749DC5AE  // 1.0e32 



// check first char for sign 
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
1:  _ADR ONEM 
    _ADR SWAP
    _ADR ONEP 
    _ADR SWAP 
2:  _ADR RFROM 
    _UNNEST 
4:  _DOLIT '+' 
    _ADR EQUAL 
    _QBRAN 2b
    _BRAN 1b 

// get mantissa size 
// m -> mantissa size including '.'
mant_size: // ( a cnt -- a+ cnt- m )
    _NEST 
    _DOLIT 0 
    _ADR NROT   // mantissa size   -- m a cnt 
// check for cnt==0     
1:  _ADR DUPP 
    _ADR ZEQUAL 
    _QBRAN 2f 
    _BRAN 6f  // end of string 
2:  _ADR OVER 
    _ADR CAT 
    _ADR DIGTQ 
    _QBRAN 4f  // not a digit 
    _ADR ROT 
    _ADR ONEP 
    _ADR NROT 
    _ADR ONEM 
    _ADR SWAPP 
    _ADR ONEP 
    _ADR SWAPP 
    _BRAN 1b
4: // is this a '.' ?
    _ADR OVER 
    _ADR CAT 
    _DOLIT '.' 
    _ADR EQUAL 
    _QBRAN 6f
    _ADR ONEM 
    _ADR SWAPP 
    _ADR ONEP 
    _ADR SWAPP 
    _ADR ROT 
    _ADR ONEP 
    _ADR NROT 
6:  _ADR ROT     
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
	_ADR	COUNT  // a 0 a+ cnt 
	_ADR	OVER   // a 0 a+ cnt a+
	_ADR	CAT    // a 0 a+ cnt  
    _ADR    get_sign 
    _ADR    TOR 
    _DOLIT  -1 // decPt 
    _ADR    TOR // a 0 a+ cnt R: base sign decPt 
    _ADR   mant_size 

not_float: 
    _ADR DDROP 
    _ADR DROP 
    _ADR DRFROM 
    _ADR DDROP  
    // restore base 
    _ADR RFROM 
    _ADR BASE 
    _ADR STORE 
    _UNNEST 

