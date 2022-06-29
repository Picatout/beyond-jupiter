\ calcul du logarithme népérien selon la méthode de Briggs
\ REF: https://www.lelivrescolaire.fr/page/14839379

: calc_R  ( A B -- A B R )
    2dup f* sqrt  
;

: calc_M ( lnA lnB -- lnA lnB M )
    2dup f+ 2.0 f/
;

: LN \ ( f -- ln(f) )
    dup 10.0 f> if 
        1  scaledown
        s>f ln10 f* 
    else 
        dup 1.0 f< if 0 scaleup 
            s>f ln10 f* 
        else 
          0.0 
        then
    then
    swap  
    >r \ r: x 
    1.0 10.0 \ a b 
    0.0 ln10 \ ln(1.0) ln(10.0)
    begin 2 pick r@ f- fabs  1.0e-7 f>  while 
        2>r calc_R  
        2r> calc_M  
        -rot \ a b r m ln(a) ln(b)
        3 pick r@ f> if \ r > x  b=r, ln(b)=m 
            2>r \ a b r m  r: x ln(b) ln(a)
            rot drop \ a b' m 
            2r> \ a b' m ln(a) ln(b)
            drop swap \ a b' ln(a) ln(b)'
        else \ a b r m ln(a) ln(b)  a=r ln(a)=m 
            2>r \ a b r m 
            >r rot drop swap r> \ a' b ln(a)'  
           2r> \ a' b ln(a)' ln(a) ln(b)
           swap drop \ a' b ln(a)' ln(b)
        then 
    repeat
    >r 2drop drop 
    r> 
    r> drop  \ drop x  
    .s 
    f+
;

\ calcul du log base 10 de f 
: LOG ( f -- log10 )
    ln 
    ln10 f/ 
; 


