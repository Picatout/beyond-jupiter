\ compute sinus 
\ angle in radians 
: sin 
  dup dup dup f*
  fnegate -rot 
  27 2 do
     2 pick f*   
     i i 1+ * s>f f/ 
     dup rot f+ swap 
  2 +loop 
  drop swap drop 
;

\ cosine 
: cos 
  pi 2. F/
  swap f- sin 
; 

\ tangeant 
: tan 
  dup sin 
  swap cos 
  f/ 
; 

