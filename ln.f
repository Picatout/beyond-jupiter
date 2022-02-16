\ calcul du logarithme népérien selon la méthode de Briggs
\ REF: https://www.lelivrescolaire.fr/page/14839379

: LN \ ( f -- ln(f) )
    dup 10.0 f> if 
        1  scaledown
        s>f ln10 f* 
        swap 
    else 
        dup 1.0 f< if 0 scaleup 
            s>f ln10 f* swap 
        else 
          0.0 swap 
        then
    then 
    >r \ r: x 
    1. 10. \ a b 
    0. ln10 \ ln(1.0) ln(10.0)
    begin 2 pick r@ f- fabs 1e-7 f> while 
        2>r 2dup f* sqrt   \ a b r
        2r> 2dup f+ 2. f/  -rot \ a b r m ln(a) ln(b)
        3 pick r@ f> if \ r > x  b=r, ln(b)=m 
            2>r \ a b r m  r: x ln(b) ln(a)
            rot drop \ a b' m 
            r> \ ln(a)
            swap \ a b' ln(a) ln(b)'
            r> drop \ a b' ln(a) ln(b)' 
        else \ a b r m ln(a) ln(b)  a=r ln(a)=m 
            2>r \ a b r m 
            >r rot drop swap r> \ a' b ln(a)'  
           r> \ a' b ln(a)' ln(a)
           drop \ a' b ln(a)' 
           r>  \ a' b ln(a)' ln(b) 
        then 
    repeat
    >r 2drop drop 
    r> 
    r> drop  \ drop x  
    f+
;

\ calcul du log base 10 de f 
: LOG ( f -- log10 )
    ln 
    ln10 f/ 
; 


