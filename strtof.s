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

/*******************************
  float number parser 
*******************************/

/********************
    10^2^n  
    for n in [0..5]
********************/    

p10p2n:     .word  0x41200000  // 10.0 
            .word  0x42C80000  // 100.0
            .word  0x461C4000  // 10000.0 
            .word  0x4CBEBC20  // 1.0e8
            .word  0x5A0E1BCA  // 1.0e16 
            .word  0x749DC5AE  // 1.0e32 

fzero =  0x0
fone =  0x3F800000
fminus1 = 0xBF800000
ften = 0x41200000 

//  P10P2N@ ( idx -- f )
// fetch element from p10p2n array 
p10p2at: // ( idx -- f )
    _NEST 
    _DOLIT 2 
    _ADR LSHIFT 
    _DOLIT p10p2n 
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


//  mant_div ( 0 f e -- f )
// negative exponent, divide mantissa 
// to adjust from decimal to binary exponent.
// input: 
//  0  exponent bit counter  
//  f  mantissa converted float 
//  e  decimal exponent 
// output:
//   f float adjusted 
mant_div:
    _NEST 
    _ADR TOR // idx f R: e 
div_loop:
    _ADR RAT   // idx f e R: e 
    _ADR bit_state // idx f state 
    _QBRAN 1f   // bit reset 
    _ADR OVER 
    _ADR p10p2at // idx f pwr10 R: e
    _ADR FSLH  // idx f R: e 
1:  _ADR SWAP  // f idx R: e 
    _ADR ONEP   // F idx++ R: e 
    _ADR SWAP   // idx f  
    _ADR OVER   // idx f idx 
    _DOLIT 5 
    _ADR GREAT  // idx > 5
    _QBRAN div_loop 
    _ADR RFROM 
    _ADR DROP 
    _UNNEST 


// mant_mult ( 0  f e -- f )
// positive exponent, multiply mantissa 
// to adjust from decimal to binary exponent 
// input:
//  0  exponent bit counter  
//  f  mantissa converted float 
//  e  decimal exponent 
// output:
//   f float adjusted 
mant_mult:
    _NEST 
    _ADR TOR 
mult_loop:
    _ADR RAT   // idx f e R: e 
    _ADR bit_state // idx f state 
    _QBRAN 1f   // bit reset 
    _ADR OVER  
    _ADR p10p2at // idx f pwr10 R: e
    _ADR FSTAR  // idx f R: e 
1:  _ADR SWAP  // f idx R: e 
    _ADR ONEP   // F idx++ R: e 
    _ADR SWAP   // idx f  
    _ADR OVER   // idx f idx 
    _DOLIT 5 
    _ADR GREAT  // idx > 5
    _QBRAN mult_loop 
    _ADR RFROM 
    _ADR DROP 
    _UNNEST 


// float adjustment from decimal exponent  
// multiply or divide mantissa by exponent  
// if exponant < 0 divide 
// if exponant >0 multiply 
// if exponant == 0 done 
exp_adjust: // ( e f  -- f )
    _NEST 
    _ADR OVER  // e f e 
    _QBRAN 3f // exp==0,  done 
    _DOLIT 0  // e f idx  
    _ADR NROT // idx e f
    _ADR SWAP // idx f e   
    _ADR DUPP  // idx f e e 
    _ADR ZLESS
    _QBRAN pos_exp 
// negative exponent 
    _ADR ABSS 
    _ADR mant_div 
    _BRAN 3f 
pos_exp: // positive exponent 
    _ADR mant_mult 
// adjustment done 
3:  _ADR SWAP 
    _ADR DROP 
    _UNNEST 


/********************************
    integer ( a cnt -- a+ cnt- f# )
*********************************/
integer:
    _NEST 
    _DOLIT 0 
    _ADR DUPP 
    _ADR DSWAP // 0 0 a cnt 
    _ADR TONBR // d a+ cnt- 
    _ADR DTOR 
    _ADR DROP // drop hi word 
    _ADR DRFROM // i a+ cnt-  
    _ADR ROT  // a+ cnt- i
    _ADR STOF 
    _UNNEST 


/*****************************
   decimals ( a cnt -- a+ cnt- fdec )
   parse digits after '.' 
   convert to float 
*****************************/
decimals:
    _NEST 
    _ADR DUPP 
    _ADR TOR 
    _DOLIT 0
    _ADR DUPP
    _ADR DSWAP 
    _ADR TONBR // -- d a+ cnt-  
    _ADR DSWAP  // a+ cnt- d
    _ADR DROP   // a+ cnt- i 
    _ADR STOF  // convert integer to float 
    _ADR RFROM  // a+ cnt- f# cnt 
    _DOLIT 2 
    _ADR  PICK  
    _ADR SUBB 
    _DOLIT 9 
    _ADR MIN 
    _ADR PWR10
    _ADR FSLH  // a+ cnt- fdec 
    _UNNEST 


/************************************
   exponent ( a cnt -- a+ cnt- exp )
   parse float exponent 
************************************/
exponent: 
    _NEST 
    _ADR NEGQ 
    _ADR TOR 
    _DOLIT 0 
    _ADR DUPP 
    _ADR DSWAP // 0 0 a cnt  
    _ADR TONBR // d a cnt   
    _ADR DSWAP
    _ADR DROP  // hi word 
    _ADR RFROM 
    _QBRAN 1f 
    _ADR NEGAT 
1:  
    _UNNEST  // -- a+ cnt- exp   


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
    // use decimal base  
    _ADR DECIM 
	_DOLIT	0      // failed flag   
	_ADR	OVER   // a 0 a     R: base
    _ADR	COUNT  // a 0 a+ cnt  // cnt is length of string 
// check for '-'|'+' save sign on R: 
    _ADR   NEGQ
    _ADR   TOR // -- a 0 a+ cnt-  R: base sign 
    _ADR   DUPP 
    _ADR   TOR  // a 0 a+ cnt r: base sign cnt 
    _ADR  integer // a 0 a+ cnt- fint 
    _ADR  OVER  
    _ADR  RFROM  
    _ADR  EQUAL
    _ADR  SWAP
    _ADR  TOR  //  a 0 a+ cnt- flag r: base sign fint  
    _TBRAN expect_dot  
// must be '.' or 'E'     
    _DOLIT '.' 
    _ADR CHARQ
    _TBRAN get_fraction  
    _DOLIT 'E'
    _ADR  CHARQ 
    _TBRAN get_exponent 
    _BRAN error2
expect_dot:
    _DOLIT '.' 
    _ADR CHARQ 
    _QBRAN error2
get_fraction:      
    _ADR decimals 
    _ADR  TOR    // a 0 a+ cnt- r: base sign fint ffrac 
// if next char is 'E' get exponent 
    _DOLIT 'E' 
    _ADR CHARQ
    _TBRAN get_exponent 
    _DOLIT fzero 
    _ADR TOR   // a 0 a+ cnt- r: base sign fint ffrac fexp 
    _BRAN build_float
get_exponent: 
    _ADR exponent // -- a 0 a+ cnt- exp
    _ADR TOR   // a 0 a+ cnt- r: base sign fint ffrac exp 
    _ADR DUPP 
    _TBRAN error4   // count must be 0 
build_float: // a 0 a+ cnt- R: base sign fint fdec exp 
    _ADR DDROP 
    _ADR DDROP 
    _ADR RFROM 
    _ADR DRFROM 
    _ADR FPLUS 
    _ADR exp_adjust
    _ADR RFROM 
    _QBRAN 1f 
    _DOLIT fminus1
    _ADR FSTAR 
1:  _DOLIT -2 
    _BRAN restore_base  
error2: // a 0 a cnt R: base sign fint 
    _ADR DDROP  
    _BRAN e4  
error3: // a 0 a cnt R: base sign fint fdec  
    _ADR DDROP  // a 0 a R: base sign
    _ADR RFROM 
    _ADR DROP 
    _BRAN e4  
error4: // a 0 a+ cnt- r: base sign fint ffrac fexp  
    _ADR DDROP 
    _ADR DRFROM 
    _ADR DDROP 
e4: _ADR DRFROM 
    _ADR DDROP 
restore_base: 
    _ADR RFROM 
    _ADR BASE 
    _ADR STORE 
    _UNNEST 

