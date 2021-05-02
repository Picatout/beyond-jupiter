// PS/2 scancode set 2 
    
// keyboard control commands 
KBD_CMD_RESET =	0xFF  // RESET keyboard 
KBD_CMD_LED =	0xED  // keyboard LEDS control 
KBD_CMD_RESEND =  0xFE  // resend command 
 
// keyboard state codes 
BAT_OK =	0xAA // keyboard test OK 
KBD_ACK =	0xFA // keyboard ACK code 
KEY_REL =	0xF0 // key released code 
XT_KEY =	0xE0 // extended key 
XT2_KEY =	0xE1 // start  8 codes PAUSE key sequence 

// keyboard LEDS 
LED_CAPLOCK = 4 
LED_NUMLOCK = 2
LED_SCROLL = 1 
  
// control keys 
SC_TAB =	    0x0D    //standard
SC_ENTER =	    0x5A    //standard
SC_CAPS =	    0x58    //standard
SC_NUM =	    0x77    //standard
SC_SCROLL   =	    0x7E    //standard
SC_LSHIFT =	    0x12    //standard
SC_RSHIFT =	    0x59    //standard
SC_LCTRL =	    0x14    //standard
SC_LALT =	    0x11    //standard
SC_BKSP =	    0x66    //standard
SC_ESC =	    0x76    //standard
SC_F1 =	    0x05    //standard
SC_F2 =	    0x06    //standard
SC_F3 =	    0x04    //standard
SC_F4 =	    0x0c    //standard
SC_F5 =	    0x03    //standard
SC_F6 =	    0x0b    //standard
SC_F7 =	    0x83    //standard
SC_F8 =	    0x0a    //standard
SC_F9 =	    0x01    //standard
SC_F10 =	    0x09    //standard
SC_F11 =	    0x78    //standard
SC_F12 =	    0x07    //standard
SC_KPMUL =	    0x7c    //standard
SC_KPMINUS =	    0x7b    //standard
SC_KPPLUS =	    0x79    //standard
SC_KPDOT =	    0x71    //standard
SC_KP0 =	    0x70    //standard
SC_KP1 =	    0x69    //standard
SC_KP2 =	    0x72    //standard
SC_KP3 =	    0x7a    //standard
SC_KP4 =	    0x6b    //standard
SC_KP5 =	    0x73    //standard
SC_KP6 =	    0x74    //standard
SC_KP7 =	    0x6c    //standard
SC_KP8 =	    0x75    //standard
SC_KP9 =	    0x7d    //standard

// extended keycode, i.e. preceded by 0xe0
SC_RCTRL =   0x14
SC_LGUI =    0x1f
SC_RGUI =    0x27 
SC_RALT =    0x11
SC_APPS =    0x2f
SC_UP	 =    0x75
SC_DOWN =    0x72
SC_LEFT =    0x6B
SC_RIGHT =   0x74
SC_INSERT =  0x70
SC_HOME =    0x6c
SC_PGUP =    0x7d
SC_PGDN =    0x7a
SC_DEL	 =    0x71
SC_END	 =    0x69
SC_KPDIV =   0x4a
SC_KPENTER = 0x5a
SC_LWINDOW = 0x1f
SC_RWINDOW = 0x27
SC_MENU = 0x5d 
 
 
//virtual key codes   
VK_BACK =	8
VK_TAB =	9
VK_ESC =	27
VK_ENTER =	'\r'
VK_SPACE =	' ' 
VK_DELETE =	127 
VK_F1 =	128
VK_F2 =	129
VK_F3 =	130
VK_F4 =	131
VK_F5 =	132
VK_F6 =	133
VK_F7 =	134
VK_F8 =	135
VK_F9 =	136
VK_F10 =	138
VK_F11 =	139
VK_F12 =	140
VK_UP =	141
VK_DOWN =	142
VK_LEFT =	143
VK_RIGHT =	144
VK_HOME =	145
VK_END =	146
VK_PGUP =	147
VK_PGDN =	148
VK_INSERT =	149
VK_APPS =	151
VK_PRN	=	152
VK_PAUSE =	153
VK_NLOCK =    154 // numlock
VK_CLOCK =	155 // capslock
VK_LSHIFT =	156
VK_LCTRL =	157
VK_LALT =	158
VK_RSHIFT =	159
VK_LGUI =	160
VK_RCTRL =	161
VK_RGUI =	162
VK_RALT =	163
VK_SCROLL =	164
VK_NUM	=	165 
VK_CAPS =	168
//<SHIFT>-<KEY> 
VK_SUP	=	169
VK_SDOWN =	170
VK_SLEFT =	171
VK_SRIGHT =	172
VK_SHOME =	173
VK_SEND	=	174
VK_SPGUP =	175
VK_SPGDN =	176
VK_SDEL  =    191
//<CTRL>-<KEY>
VK_CUP	=	177
VK_CDOWN =	178	
VK_CLEFT =	179
VK_CRIGHT =	180
VK_CHOME =	181
VK_CEND =	182
VK_CPGUP =	183
VK_CPGDN =	184
VK_CDEL  =    185
VK_CBACK =    186
VK_LWINDOW =  187
VK_RWINDOW =  188
VK_MENU	=   189
VK_SLEEP =	190

