\ check if NEST binary code 
: nest? (  u -- f )
    $BF004750 = 
;

\ check if unnest cfa 
: unnest? ( u -- u f )
    dup $80030BB = 
;

\ print address 
: adr ( a -- a )
    dup h. 2 spaces 
;
\  disassemble colon definition 
: see ( "name" )
    cr 
    ' 1- adr  
    dup @ nest? if 
        ."  {nest}" cr cell+ 
        begin 
            adr 
            dup @ unnest? if adr 2drop ."  {unnest}" cr exit then 
            >nfa ?dup if 
                .id 
            else 
                dup @ h. space ."  {no name}" 
            then  
            cr cell+  
            key? until 
        drop
    else 
        drop  
        ." code word" cr 
    then 
;

