\ print float fraction
\  frac. ( d f  -- )
\  d -> number of digits
\  f -> float < 1.0  
: frac.
    [char] . emit 
    begin over while 
        10.0 f* dup trunc
        dup 
        [char] 0 + emit  
        s>f f- 
        swap 1- swap  
    repeat 
    10.0 f* f>s  9 min  
    [char] 0 + emit 
    drop 
;

defer f. 

\ print float in scienfitic notation
\  e. (f d -- )
: e. 
    abs 2 max 7 min \ no more than 7 digits 
    space
    swap dup fexp \ d f exp  
    0 -rot \ d 0 f exp 
    0< if \ d 0 f 
        begin dup 1.0 f< while 
            10.0 f* 
            swap 1- swap 
        repeat
    else \ d 0 f 
        begin dup 10.0 f> while 
        10.0 f/ 
        swap 1+ swap 
        repeat 
    then \  d e f
    rot  
    f.
    [char] e emit 
    i>a 
    type
; 

\ defered definition for f. 
\ print float in fixed point notation 
: df.  ( f d -- )
    abs 2 max 7 min \ d range [2..7] digits 
    over fexp dup  \ f d exp exp  
    26 > over -23 < or if   
        drop e. \ 1e8<f<1e-7 
    else \ f d exp 
        space 
        >r \ f d R: exp 
        1- \ decrement d 
        swap dup  fsign 
        0< if [char] - emit fabs then      
        r> 0< if \ exp < 0 ? 
            [char] 0 emit  
            swap 1- swap 
            frac.
        else \ d f   
            dup trunc  \ d f  i
            dup s>f >r \ d f i R: fi  
            i>a    \ d f b u  R: fi 
            dup >r \ d f b u R: fi u 
            type 
            swap 
            r> - \ f d- R: fi  
            dup 0< if 
                2drop r> drop 
            else   
                swap \ d f R: fi  
                r> f- \ d f       
                frac.
            then
        then  
    then 
;

defer! df. f.  
