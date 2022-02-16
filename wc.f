\ print count of words in dictionary 
: wc 
    0 last  begin 
                @ dup while 
                swap 1+ swap 
                cell- 
            repeat 
            drop . 
;