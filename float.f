\ hi level floating point library 
\ From Forth Dimensions vol IV # 1
\ author Michael Jesch 

\ adapted to 32 bits system by PICATOUT

\ float format: 
\  seee eeee smmm mmmm mmmm mmmm mmmm mmmm 
\  'm' mantissa bits 
\  's' sign bit 
\  'e' exponent bits 
\ mantissa 23 bits + sign 
\ exponent 7 bits + sign 

FORGET FPSW 

VARIABLE FPSW \ floating point state flags  
VARIABLE FBASE \ floating point base 
: FRESET ( -- ) \ reset state 
    0 FPSW C! ; 

: FINIT ( -- ) \ initialize floating point library
    FRESET BASE @ FBASE ! ;

: FER FPSW C@ ; \ return all flags 

: FZE  ( -- zeroflag ) \ return zero flag 
    FER 1 AND 0= NOT ; 

: FNE FER ( -- negflag ) \ return negative flag 
    2 AND 0= NOT ; 

: FOV  ( -- ovf_flag ) \ return overflow flag  
    FER 4 AND 0= NOT ; 

: SFZ ( F# -- ; z ) \ set zero flag from float on TOS 
    FER $FE AND OVER $FFFFFF AND 0= 1 AND OR FPSW C! ;

: SFN FER ( f# -- ; n ) \ set negative flag from float on TOS 
    $FD AND OVER $800000 AND 22 RSHIFT OR FPSW C! ;

: @EXPONENT ( F# -- m e ; z n ) \ split mantissa and exponent, set flags 
    FRESET SFZ SFN DUP $FF000000 AND 24 RSHIFT >R \ exponent 
    FNE IF $FF000000 OR ELSE $FFFFFF AND THEN R> ; \ sign extend mantissa 

: !EXPONENT ( m e -- ; z n v ) 
\ format float from mantissa and exponent 
    DUP ABS 255 > IF 4 FPSW C! THEN \ exponent overflow 
    OVER ABS $FFFFFF > IF 4 FPSW C! THEN \ mantissa overflow 
    24 LSHIFT SWAP 
    $FFFFFF AND OR 
    SFZ SFN ;

: E. ( F# -- ) 
\ print float in scientific notation 
    SPACE
    @EXPONENT  
    OVER 0= IF 
        ." 0.0" 2DROP 
    ELSE  
        >R 
        FNE IF 
            45 EMIT ABS THEN 
        <#
        BEGIN 
        # DUP FBASE @ R> 1+ >R U< UNTIL
        46 HOLD # 
        #> TYPE 
        R> DUP 0= NOT IF 
            ." E" 
            DUP 0< IF 
                45 EMIT ABS THEN
            <# #S #> TYPE THEN 
        THEN 
;

: F. ( F# -- )
\ print float in fixed point format  
    DUP @EXPONENT >R
    I ABS 32 U> IF
        R> 2DROP E.
    ELSE
        SPACE FNE IF ABS THEN 
        <#  
        I 0< IF
            I ABS 0 DO # LOOP 46 HOLD
        ELSE
            46 HOLD I IF
                I 0 DO 48 HOLD LOOP 
            THEN
        THEN
        R> DROP
        #S SWAP 8 LSHIFT SIGN #> TYPE
    THEN 
;

: F* ( F#1 F#2 -- F#3 )
    @EXPONENT >R 
    SWAP @EXPONENT R> + >R
    M* DUP 31 RSHIFT DUP >R -ROT    
    R> IF DABS THEN 
    BEGIN
    2DUP $7FFFFF 0 UD> WHILE TRACE 
    10 UD/
    R> 1+ >R 
    REPEAT
    DROP SWAP IF NEGATE $FFFFFF AND THEN  
    R> !EXPONENT 
;

FINIT 
