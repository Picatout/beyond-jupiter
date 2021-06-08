\ hi level floating point library 
\ From Forth Dimensions vol IV # 1
\ author Michael Jesch 

\ adapted to 32 bits system by PICATOUT

\ float format: 
\  seee eeee smmm mmmm mmmm mmmm mmmm mmmm 
\  'm' mantissa bits 
\  's' sign bit 
\  'e' exponent bits 
\ mantissa 24 bits 2's complement signed  
\ exponent 8 bits 2's complement signed  

PRESET

FLOAT \ forget float library if already loaded 

MARK FLOAT \ float vocabulary bound 

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

: SFZ ( f# -- f# ; z ) \ set zero flag from float on TOS 
    FER $FE AND OVER $FFFFFF AND 0= 1 AND OR FPSW C! ;

: SFN FER ( f# -- f# ; n ) \ set negative flag from float on TOS 
    $FD AND OVER $800000 AND 22 RSHIFT OR FPSW C! ;

: @EXPONENT ( F# -- m e ; z n ) \ split mantissa and exponent, set flags 
    FRESET SFZ SFN DUP 
    FNE IF $FF000000 OR ELSE $FFFFFF AND THEN SWAP  \ sign extend mantissa 
    24 RSHIFT \ exponent 
;

: !EXPONENT ( m e -- f# ; z n v ) 
\ format float from mantissa and exponent 
    DUP ABS 255 > IF 4 FPSW C! $FF AND THEN \ exponent overflow 
    OVER ABS $7FFFFF > IF 4 FPSW C! THEN \ mantissa overflow 
    24 LSHIFT SWAP 
    $FFFFFF AND OR 
    SFZ SFN ;

\ print float in scientific notation 
\ d.fffffE[-]ee 
: E. ( F# -- ) 
    SPACE
    DUP $FFFFFF AND 
    0= IF 
        DROP 
        ." 0.0"
    ELSE 
        SPACE 
        BASE @ >R
        FBASE @ BASE !  
        @EXPONENT
        SWAP  
        DUP >R  \ save mantissa copy 
        FNE IF ABS THEN  
        S>D 
        <#
        BEGIN 
            # ROT 1+ -ROT    
        OVER BASE @  U< UNTIL
        [CHAR] . HOLD 
        #S  R>  SIGN #> TYPE
        ?DUP IF 
            [CHAR] E EMIT 
            DUP 0< IF 
                ABS
                [CHAR] - EMIT 
            THEN 
            S>D  <# #S #> TYPE
        THEN 
        R> BASE ! 
    THEN 
;

: F. ( F# -- )
\ print float in fixed point format  
    DUP @EXPONENT >R
    I ABS 32 U> IF
        R> 2DROP E.
    ELSE
        SPACE 
        FNE IF ABS THEN 
        S>D  
        <#   
        I 0< IF
           I ABS 0 DO # LOOP [CHAR] . HOLD
        ELSE  
            [CHAR] . HOLD I IF
                I 0 DO [CHAR] 0 HOLD LOOP 
            THEN
        THEN 
        R> DROP  
        #S SWAP 8 LSHIFT SIGN #> TYPE
    THEN 
;

\  float product 
: F* ( F#1 F#2 -- F#3 )
    @EXPONENT >R 
    SWAP @EXPONENT R> + >R   
    M* DUP 31 RSHIFT -ROT     
    DABS  
    BEGIN 
    2DUP $7FFFFF S>D UD> WHILE
    10 D/MOD ROT DROP 
    R> 1+ >R
    REPEAT 
    DROP SWAP IF NEGATE $FFFFFF AND THEN  
    R> !EXPONENT  
;

\ float division 
: F/ ( F#1 F#2 -- F#1/F#2 )
    @EXPONENT >R 
    SWAP @EXPONENT R> + >R 
    SWAP / 
    R> !EXPONENT  
; 

\ align 2 floats to same exponent
\ for addition or substraction 
: ALIGN ( F#1 F#2 -- M1 M2 E )
    @EXPONENT >R 
    SWAP @EXPONENT ROT R>
    BEGIN 
        >R SWAP >R 
        J I <> WHILE
        J I < IF  \ J IS E2
            SWAP FBASE @ * SWAP R> 1- SWAP R>
        ELSE 
            R> SWAP FBASE @ * R> 1-
        THEN 
    REPEAT
    R> R> DROP 
;

\ add 2 floats 
: F+ ( f#1 f#2 -- f#1+f#2 )
    ALIGN 
    >R + 
    R> !EXPONENT
;

\ substract 2 floats
: F- ( f#1 f#2 -- f#1-f#2 )
    ALIGN 
    >R - 
    R> !EXPONENT 
;

\ increment number 
\ of digits displayed after '.' 
\ when using F. 
: RSCALE ( F# -- F# )
    @EXPONENT  
    1- 
    SWAP FBASE @ * 
    SWAP !EXPONENT 
;

\ decrement number 
\ of digits diplayed after '.'
\ when using F. 
: LSCALE ( f# -- f# )
    @EXPONENT 1+
    SWAP FBASE @ /
    SWAP !EXPONENT 
;

\ convert float to single 
: F>S ( F# -- S )
    @EXPONENT >R
    BEGIN 
        I WHILE 
            I 0> IF 
                FBASE @ * R> 1- >R 
            ELSE 
                FBASE @ / R> 1+ >R 
            THEN
    REPEAT
    R> DROP      
;

\ convert single to float 
: S>F ( s -- f# )
    DUP 0< IF 
        ABS -1
    ELSE 
        0 
    THEN 
    SWAP 
    0
    BEGIN 
        >R 
        DUP $7FFFFF > WHILE 
        FBASE @ / 
        R> 1+ 
    REPEAT
    SWAP 
    IF NEGATE $FFFFFF AND THEN 
    R> 24 LSHIFT OR  
;

\ convert double to float 
: D>F ( d -- f# )
    DUP 0< IF 
        DABS -1
    ELSE 
        0 
    THEN 
    -ROT 
    0 
    BEGIN 
        >R 
        2DUP $7FFFFF S>D UD> WHILE 
        FBASE @ D/ R> 1+ 
    REPEAT
    DROP 
    SWAP IF NEGATE $FFFFFF AND THEN 
    R> 24 LSHIFT OR
;

\  float absulute value 
: FABS ( f# -- f# )
    @EXPONENT 
    SWAP ABS 
    SWAP !EXPONENT 
;

\ float negate 
: FNEGATE ( f# -- f# )
    @EXPONENT 
    SWAP 
    NEGATE
    SWAP  
    !EXPONENT  
;

\ float min 
: FMIN ( f#1 f#2  -- smallest float )
    2DUP 
    ALIGN 
    DROP 
    < IF DROP ELSE SWAP DROP THEN 
;

\ float max 
: FMAX ( f#1 f#2 -- largest float )
    2DUP 
    ALIGN 
    DROP 
    < IF SWAP DROP ELSE DROP THEN 
; 

\ f#1 > f#2 
: F> ( f#1 f#2 -- f )
    ALIGN  
    DROP 
    > 
; 

\ f#1 < f#2 
: F< ( f#1 f#2 -- f )
    ALIGN  
    DROP 
    < 
; 

\ check for charcter c 
\ move pointer if true 
: C? ( a c -- a+ t | a f )
    SWAP  
    COUNT  
    ROT 
    = DUP NOT IF
        SWAP 1- SWAP 
    THEN 
;

\ parse digits 
\  d digits count 
\  n parsed integer
\  a+ updated pointer   
: PARSE_DIGITS ( d n a -- d+ n+ a+ )
    BEGIN 
        COUNT FBASE @ DIGIT? WHILE 
        ROT FBASE @ * + SWAP 
        ROT 1+ -ROT
    REPEAT
    DROP 
    1-  \ decrement a 
;

\ check for exponent 
: EXPONENT ( a -- e a+ )
    [CHAR] E C? IF 
        [CHAR] - C? >R 
        0 0 ROT 
        PARSE_DIGITS
        ROT DROP \ discard digits count  
        R> IF SWAP NEGATE SWAP THEN  
    ELSE 
        0 SWAP 
    THEN 
;

\ parse float number
: FLOAT? ( a -- f# -2 | a 0 )
\ simpler to find the end of null terminated string  
    DUP ASCIZ 
    0 0 ROT   \ -- a d n asciz  
\ check for sign  
    [CHAR] - C? >R  
    PARSE_DIGITS 
    ROT DROP \ d not used 
    0 -ROT   \ reset it 
\ check for '.'
    [CHAR] . C?
    IF  PARSE_DIGITS 
        ROT NEGATE -ROT \ negate digit count 
    THEN 
    EXPONENT 
\ a d n e asciz 
    COUNT 0= IF  
        DROP  \ a d n e 
        ROT +  \ a n e- 
        ROT DROP 
        SWAP 
        R> IF NEGATE THEN 
        SWAP !EXPONENT 
        -2 
    ELSE
        2DROP 2DROP  
        0 
    THEN 
;

FINIT 
