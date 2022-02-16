\ ENVIRONMENT? test 

: env?  token count environment? ;


env? /COUNTED-STRING   swap . .  ( 255 -1 )   \ counted string max length
env? /HOLD  swap . .  ( 80 -1 )  \ size of HOLD buffer 
env? /PAD   swap . .  ( 80 -1 )   \ size of PAD 
env? ADDRESS-UNIT-BITS swap . . ( 32 -1 )  \ size of one address in bits 
env? FLOORED ( -1 )  . ( -1 ) \ floored division by default 
env? MAX-CHAR swap . . ( 127 -1 )  \ maximum character value i.e. ASCII set 
env? MAX-D  -rot d. .  ( 9223372036854775807 -1 )  \ max size double integer 
env? MAX-N  swap . . ( 2147483647 -1 ) \ maximum integer 
env? MAX-U  swap u. . ( 4294967295 -1 ) \ maximum unsigned integer 
env? MAX-UD -rot ud. . ( 18446744073709551615 -1 ) \ max unsigned dble integer 
env? RETURN-STACK-CELLS swap . . ( 32 -1 ) \ number of cells on return stack 
env? STACK-CELLS swap . . ( 32 -1 ) \ number of cells on arguments stack 

