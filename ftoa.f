\ c!+ (  b c -- b++ )
\ store character in buffer 
\ increment pointer 
: c!+ 
    over c! 1+ 
;

\ f<# ( f -- f )
\ check sign of float 
\ and print it 


\ print float integer part
\ int. ( d i -- d- )
\  d -> maximum digits count 
\  i -> integer to print 
\  d- -> n# digits left to print 
: int. 
    i>a  \ d b u 
    dup >r \ d b u  R: u  
    rot dup >r \ b u d r: u d  
    min 
    type 
    2r> - \ d-  
;

\ float fraction
\  frac>a ( d f b  -- b+ )
\  d -> number of digits
\  f -> float < 1.0 
\  output:
\     b+ incremented pointer  
: frac>a
    >r \ d f r: b 
    begin over while 
        10.0 f* dup trunc
        dup 
        [char] 0 +  
        r> swap c!+ >r 
        s>f f- 
        swap 1- swap \ decrement d   
    repeat
    \ 0 f r: b+  
    10.0 f* f>s  9 min  
    [char] 0 +
    r> swap c!+ \ 0 b+ 
    swap drop   
;

\ frac* ( f1 -- m f2 ) 
\ multiply fraction until 
\ f1 >= 0.1
\ input: 
\   f1  float
\ output:
\   m  log10 exponent 
\   f2  >= 0.1 
: frac* 
    0 swap 
    begin dup 0.1 f< while 
        10.0 f* 
        swap 1- swap 
    repeat
;


\  f>a ( b d f -- b u )
\ convert float to string
\ input: 
\   b  output buffer  
\   d n# of digits [2..7] to convert 
\   f float to convert 
\  output: 
\   b output buffer 
\    u length of string 
: f>a ( b d f -- b u )
    rot \ d f b 
    dup >r \ d f b r: b 
    32 c!+ \ d f b+ 
    \ check for sign 
    over fsign  
    0< if 
        [char] - 
        c!+
        swap  
        fabs 
        swap \ d +f b+ 
    then 
    over 1.0 f< if 
        \ no integer part
        [char] 0 c!+
        [char] . c!+
        rot 1- -rot \ decrement d
        swap frac* 
        swap >r
        swap  \ d f b 
        frac>a \ d f b -- b+
        r@ 0< if
            [char] e c!+
            r> 
            i>a \ b s u 
            >r over r@ cmove 
            r> +   
        else
            r> drop
        then 
        r@ - r> swap \ b u         
    else \ d f b 
         >r \ d f r: b 
         dup trunc \ d f i  
         dup  \ d f i i 
         s>f f- \ d f R: b i 
         r> i>a \ d f i -- d f bsrc u 
         swap over \ d f u src u  
         r@ swap cmove \ d f u r: b 
         >r swap r@ - swap \ d- f r: b u  
         r> r@ + \ d f b+ r: b
         [char] . c!+ 
         2 pick 0 > if 
            frac>a \ d f b -- b+ 
         else 
            r@ - >r 2drop 
            r> r> swap 
         then   

    then
;


\ print float
\ input:
\    f -> float to print 
\    d -> n# digits in printout 
: f.  ( f d -- )
    2 max 7 min \ d range [2..7] digits 
    swap \ d f 
    here >r \ d f  
    16 allot  \ d f    
    r@ 16 0 fill \ fill buffer with 0s
    r> -rot \ b d f 
    f>a \ b d f -- b u 
trace 
    type
    -16 allot \ free buffer  
;  

