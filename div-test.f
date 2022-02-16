\  SM/REM test 

       0 S>D              1 SM/REM swap . .  \  0       0 
       1 S>D              1 SM/REM swap . .  \  0       1 
       2 S>D              1 SM/REM swap . .  \  0       2 
      -1 S>D              1 SM/REM swap . .  \  0      -1 
      -2 S>D              1 SM/REM swap . .  \  0      -2 
       0 S>D             -1 SM/REM swap . .  \  0       0 
       1 S>D             -1 SM/REM swap . .  \  0      -1 
       2 S>D             -1 SM/REM swap . .  \  0      -2 
      -1 S>D             -1 SM/REM swap . .  \  0       1 
      -2 S>D             -1 SM/REM swap . .  \  0       2 
       2 S>D              2 SM/REM swap . .  \  0       1 
      -1 S>D             -1 SM/REM swap . .  \  0       1 
      -2 S>D             -2 SM/REM swap . .  \  0       1 
       7 S>D              3 SM/REM swap . .  \  1       2 
       7 S>D             -3 SM/REM swap . .  \  1      -2 
      -7 S>D              3 SM/REM swap . .  \  1      -2 
      -7 S>D             -3 SM/REM swap . .  \ -1       2 
 MAX-INT S>D              1 SM/REM swap . .  \  0 MAX-INT 
 MIN-INT S>D              1 SM/REM swap . .  \  0 MIN-INT 
 MAX-INT S>D        MAX-INT SM/REM swap . .  \  0       1 
 MIN-INT S>D        MIN-INT SM/REM swap . .  \  0       1 
       2 MIN-INT M*       2 SM/REM swap . .  \  0 MIN-INT 
       2 MIN-INT M* MIN-INT SM/REM swap . .  \  0       2 
       2 MAX-INT M*       2 SM/REM swap . .  \  0 MAX-INT 
       2 MAX-INT M* MAX-INT SM/REM swap . .  \  0       2 
 MIN-INT MIN-INT M* MIN-INT SM/REM swap . .  \  0 MIN-INT 
 MIN-INT MAX-INT M* MIN-INT SM/REM swap . .  \  0 MAX-INT 
 MIN-INT MAX-INT M* MAX-INT SM/REM swap . .  \  0 MIN-INT 
 MAX-INT MAX-INT M* MAX-INT SM/REM swap . .  \  0 MAX-INT 

\ FM/MOD test

       0 S>D              1 FM/MOD swap . . \  0       0 
       1 S>D              1 FM/MOD swap . . \  0       1 
       2 S>D              1 FM/MOD swap . . \  0       2 
      -1 S>D              1 FM/MOD swap . . \  0      -1 
      -2 S>D              1 FM/MOD swap . . \  0      -2 
       0 S>D             -1 FM/MOD swap . . \  0       0 
       1 S>D             -1 FM/MOD swap . . \  0      -1 
       2 S>D             -1 FM/MOD swap . . \  0      -2 
      -1 S>D             -1 FM/MOD swap . . \  0       1 
      -2 S>D             -1 FM/MOD swap . . \  0       2 
       2 S>D              2 FM/MOD swap . . \  0       1 
      -1 S>D             -1 FM/MOD swap . . \  0       1 
      -2 S>D             -2 FM/MOD swap . . \  0       1 
       7 S>D              3 FM/MOD swap . . \  1       2 
       7 S>D             -3 FM/MOD swap . . \ -2      -3 
      -7 S>D              3 FM/MOD swap . . \  2      -3 
      -7 S>D             -3 FM/MOD swap . . \ -1       2 
 MAX-INT S>D              1 FM/MOD swap . . \  0 MAX-INT 
 MIN-INT S>D              1 FM/MOD swap . . \  0 MIN-INT 
 MAX-INT S>D        MAX-INT FM/MOD swap . . \  0       1 
 MIN-INT S>D        MIN-INT FM/MOD swap . . \  0       1 
       1 MIN-INT M*       1 FM/MOD swap . . \  0 MIN-INT 
       1 MIN-INT M* MIN-INT FM/MOD swap . . \  0       1 
       2 MIN-INT M*       2 FM/MOD swap . . \  0 MIN-INT 
       2 MIN-INT M* MIN-INT FM/MOD swap . . \  0       2 
       1 MAX-INT M*       1 FM/MOD swap . . \  0 MAX-INT 
       1 MAX-INT M* MAX-INT FM/MOD swap . . \  0       1 
       2 MAX-INT M*       2 FM/MOD swap . . \  0 MAX-INT 
       2 MAX-INT M* MAX-INT FM/MOD swap . . \  0       2 
 MIN-INT MIN-INT M* MIN-INT FM/MOD swap . . \  0 MIN-INT 
 MIN-INT MAX-INT M* MIN-INT FM/MOD swap . . \  0 MAX-INT 
 MIN-INT MAX-INT M* MAX-INT FM/MOD swap . . \  0 MIN-INT 
 MAX-INT MAX-INT M* MAX-INT FM/MOD swap . . \  0 MAX-INT
