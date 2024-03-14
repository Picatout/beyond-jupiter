\ convert double integer 
\ to single integer 
\ overflow signaled by 0x80000000
: d>s ?dup if -1 = over 0< and if else drop $80000000 then then ;
