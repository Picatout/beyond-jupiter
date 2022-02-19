: see 
' cell+ begin 
dup @ 1- >nfa ?dup if 
.id cell+ else 
drop exit then 
key? until drop
;

