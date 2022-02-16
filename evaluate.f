\  test EVALUATE 

: ge1 s" 123" ; immediate 
: ge2 s" 123 1+" ; immediate
: ge3 s" : ge4 345 ;" ; 
: ge5 evaluate ; immediate 
 ( TEST EVALUATE IN INTERP. STATE ) 
GE1 EVALUATE  . \ 123 
GE2 EVALUATE  . \  124 
GE3 EVALUATE    \ créé le mot GE4 
GE4 .           \  345 
 ( TEST EVALUATE IN COMPILE STATE ) 
: GE6 GE1 GE5 ;  
GE6 .           \ 123 
: GE7 GE2 GE5 ; 
GE7 .           \ 124 
