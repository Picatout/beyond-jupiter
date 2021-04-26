//  MCSaite keyboard scancode to ASSCII

    .include "ps2_codes.inc"
    

    // SCAN 2 ASCII translation
sc_ascii:
   .byte 0x1c,'a' 
   .byte 0x32,'b'
   .byte 0x21,'c'
   .byte 0x23,'d'
   .byte 0x24,'e'
   .byte 0x2b,'f'
   .byte 0x34,'g'
   .byte 0x33,'h'
   .byte 0x43,'i'
   .byte 0x3B,'j'
   .byte 0x42,'k'
   .byte 0x4b,'l'
   .byte 0x3a,'m'
   .byte 0x31,'n'
   .byte 0x44,'o'
   .byte 0x4d,'p'
   .byte 0x15,'q'
   .byte 0x2d,'r'
   .byte 0x1b,'s'
   .byte 0x2c,'t'
   .byte 0x3c,'u'
   .byte 0x2a,'v'
   .byte 0x1d,'w'
   .byte 0x22,'x'
   .byte 0x35,'y'
   .byte 0x1a,'z'
   .byte 0x45,'0'
   .byte 0x16,'1'
   .byte 0x1e,'2'
   .byte 0x26,'3'
   .byte 0x25,'4'
   .byte 0x2e,'5'
   .byte 0x36,'6'
   .byte 0x3d,'7'
   .byte 0x3e,'8'
   .byte 0x46,'9'
   .byte 0x0e,'`'
   .byte 0x4e,'-'
   .byte 0x55,'='
   .byte 0x5d,'\\'
   .byte 0x54,'['
   .byte 0x5b,']'
   .byte 0x4c,';'
   .byte 0x52,'\''
   .byte 0x41,','
   .byte 0x49,'.'
   .byte 0x7c,'*'
   .byte 0x79,'+'
   .byte 0x29,' '
   .byte SC_ENTER,'\r'
   .byte SC_BKSP,8
   .byte SC_TAB,9
   .byte SC_ESC,27
   .byte SC_LALT,VK_LALT 
   .byte SC_LSHIFT,VK_LSHIFT
   .byte SC_LCTRL,VK_LCTRL
   .byte SC_SCROLL,VK_SCROLL
   .byte SC_NUM,VK_NLOCK 
   .byte SC_CAPS,VK_CLOCK 
   .byte SC_F1,VK_F1
   .byte SC_F2,VK_F2
   .byte SC_F3,VK_F3
   .byte SC_F4,VK_F4
   .byte SC_F5,VK_F5
   .byte SC_F6,VK_F6
   .byte SC_F7,VK_F7
   .byte SC_F8,VK_F8
   .byte SC_F9,VK_F9
   .byte SC_F10,VK_F10
   .byte SC_F11,VK_F11
   .byte SC_F12,VK_F12
   .byte SC_KP0,'0'
   .byte SC_KP1,'1'
   .byte SC_KP2,'2'
   .byte SC_KP3,'3'
   .byte SC_KP4,'4'
   .byte SC_KP5,'5'
   .byte SC_KP6,'6'
   .byte SC_KP7,'7'
   .byte SC_KP8,'8'
   .byte SC_KP9,'9'
   .byte SC_KPMUL,'*'
   .byte SC_KPDIV,'/'
   .byte SC_KPPLUS,'+'
   .byte SC_KPMINUS,'-'
   .byte SC_KPDOT,'.'
   .byte SC_KPENTER,'\r'
   .byte 0,0
   
// shifted key 
shifted:
   .byte 'a','A'
   .byte 'b','B'
   .byte 'c','C'
   .byte 'd','D'
   .byte 'e','E'
   .byte 'f','F'
   .byte 'g','G'
   .byte 'h','H'
   .byte 'i','I'
   .byte 'j','J'
   .byte 'k','K'
   .byte 'l','L'
   .byte 'm','M'
   .byte 'n','N'
   .byte 'o','O'
   .byte 'p','P'
   .byte 'q','Q'
   .byte 'r','R'
   .byte 's','S'
   .byte 't','T'
   .byte 'u','U'
   .byte 'v','V'
   .byte 'w','W'
   .byte 'x','X'
   .byte 'y','Y'
   .byte 'z','Z'
   .byte '1','!'
   .byte '2','@'
   .byte '3','#'
   .byte '4','$'
   .byte '5','%'
   .byte '6','^'
   .byte '7','&'
   .byte '8','*'
   .byte '9','('
   .byte '0',')'
   .byte '-','_'
   .byte '=','+'
   .byte '`','~'
   .byte '\'','"'
   .byte ',','<'
   .byte '.','>'
   .byte '/','?'
   .byte '\\','|'
   .byte ';',':'
   .byte '[','{'
   .byte ']','}'
   .byte 0,0
   
//alt char keys 
altchar:
   .byte '1','\\'
   .byte '2','@'
   .byte '3','/'
//   .byte '4','�'
//   .byte '5','�'
   .byte '6','?'
   .byte '7','|'
//   .byte '8','�'
   .byte '9','{'
   .byte '0','}'
//   .byte '-','�'
//   .byte '=','�'
   .byte 0,0
   
// extended keycodes 
extended:
    .byte SC_RCTRL,VK_RCTRL
    .byte SC_LGUI,VK_LGUI
    .byte SC_RGUI,VK_RGUI 
    .byte SC_RALT,VK_RALT
    .byte SC_APPS,VK_APPS
    .byte SC_UP,VK_UP
    .byte SC_DOWN,VK_DOWN
    .byte SC_LEFT,VK_LEFT
    .byte SC_RIGHT,VK_RIGHT
    .byte SC_INSERT,VK_INSERT
    .byte SC_HOME,VK_HOME
    .byte SC_PGUP,VK_PGUP
    .byte SC_PGDN,VK_PGDN
    .byte SC_DEL,VK_DELETE
    .byte SC_END,VK_END
    .byte SC_KPDIV,'/'
    .byte SC_KPENTER,'\r'
    .byte 0x12,0
    .byte 0x7c,0
    .byte 0,0
    
   
// CTRL-n  keycodes 
controls:
   .byte SC_LGUI,VK_LGUI
   .byte SC_RCTRL,VK_RCTRL
   .byte SC_RGUI,VK_RGUI
   .byte SC_RALT,VK_RALT
   .byte SC_APPS,VK_APPS
   .byte SC_INSERT,VK_INSERT
   .byte SC_HOME,VK_HOME
   .byte SC_PGUP,VK_PGUP
   .byte SC_DEL,VK_DELETE
   .byte SC_END,VK_END
   .byte SC_PGDN,VK_PGDN
   .byte SC_UP,VK_UP
   .byte SC_LEFT,VK_LEFT
   .byte SC_DOWN,VK_DOWN
   .byte SC_RIGHT,VK_RIGHT
   .byte SC_KPDIV,'/'
   .byte SC_ENTER,VK_ENTER
   .byte SC_LSHIFT,VK_LSHIFT
   .byte SC_LCTRL,VK_LCTRL
   .byte SC_LALT,VK_LALT
   .byte SC_RSHIFT,VK_RSHIFT
   .byte SC_KPENTER,VK_ENTER
   .byte SC_ESC,VK_ESC
   .byte SC_NUM,VK_NLOCK
   .byte SC_CAPS,VK_CLOCK
   .byte 0,0


