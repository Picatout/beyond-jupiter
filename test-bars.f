( video output color bar generator )

: vbar ( x high y -- ) 
    do dup i 1 plot loop drop ;

: rec ( w x0 h y0 -- )
    do 2dup i -rot vbar loop 2drop ;

: t ( -- ) 
16 0 2dup do i pen-color ! 
>r >r 40 0 r> r@ rec r> 16 + 
dup 16 + swap loop ;

