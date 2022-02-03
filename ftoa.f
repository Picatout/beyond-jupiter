\ c!+ (  b c -- b++ )
\ store character in buffer 
\ increment pointer 
: c!+ 
    over c! 1+ 
;

\ convert integer part 
: I>A ( i b -- b+ u )
    >r \ i r: b 
    s>d 
    dup >r
    dabs   
    <#
    #s 
    r> sign  
    #> \ p u r: b 
    \ copy p to b  
    dup -rot \ u p u  
    r@ swap cmove \ u r: b 
    dup r> + swap \ b+ u    
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

\ pwr10 ( n -- f )
\ compute 10^n
: pwr10
    1.0 
    begin over while
        10.0 f* 
        swap 1- swap 
    repeat
    swap drop   
;


\ SCALEUP ( f1 -- m f2 ) 
\ multiply fraction until 
\ f1 >= 0.1
\ input: 
\   f1  float
\ output:
\   m  log10 exponent 
\   f2  >= 0.1 
: scaleup 
    0 swap 
    begin dup 0.1 f< while 
        10.0 f* 
        swap 1- swap 
    repeat
;


\ SCALEDOWN ( d f1 -- d m f2 )
\ divide by 10.0 until 
\ f < 2e7 
: scaledown ( d f1 -- m f2 )
    over pwr10 0.5e-8 f- >r 
    0 swap \ d 0 f1 r: pwr10    
    begin dup r@ f> while 
        10.0 f/ 
        swap 1+ swap
    repeat
    r> drop  
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
    over 1.0 f< if \ d f b 
        \ no integer part
        [char] 0 c!+
        [char] . c!+
        rot 1- -rot \ decrement d
        swap scaleup \ d b m f   
        swap >r \ d b f r: b m 
        swap  \ d f b  
        frac>a \ d f b -- b+
        r@ 0< if \ exp < 0 ? 
            [char] E c!+
            r> swap \ e b 
            i>a \ b  u
            drop  
        else
            r> drop
        then 
    else \ d f b 
         >r \ d f r: b b+ 
         scaledown \ d m f r: b b+ 
         >r swap r> \ m d f r: b b+  
         dup trunc \ m d f i  
         dup >r \ m d f i r: b b+ i  
         s>f f- \ m d f R: b b+ i 
         2r> i>a \  m d f i b -- m d f b+ u r: b 
        >r rot r> - -rot \ m d- f b+    
         2 pick 0 > if 
            [char] . c!+ 
            rot 1- -rot 
            frac>a \ m d f b -- m b+ 
         else \ m d f b+
            >r 2drop 
            r>  \ m b+ 
         then   
         over 0 > if 
            [char] E c!+
            i>a \ b+ u r: b
            drop 
        else 
            swap drop 
         then 
    then
    r@ - r> swap 
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
    type
    -16 allot \ free buffer  
;  

