/* memory regions */
MEMORY
{
FLASH (rx)     : ORIGIN = 0x08000000, LENGTH = 512K
RAM (xrw)      : ORIGIN = 0x20000000, LENGTH = 128K
}

ENTRY(reset_handler)

_mstack_size = 0x80; /* main stack size used by exceptions and interrupts */
_mstack = 0x20020000; /* main stack top */
_rstack_size = 0x80; /* size of return stack */
_rstack = 0x2001FF80;    /* growing down */
_tib = 0x2001FEB0; /* transaction input buffer */
_tib_size = 0x50 ; /* tib buffer size */
_dstack_size = 0x80; /* size of data stack */
_dstack = 0x2001FEB0; /* growing down */
_vid_buffer = 0x20018130; /* video buffer */ 
_vid_buffer_size = 0x7d00 ; /* vide buffer size */ 


SECTIONS
{
  /* The startup code goes first into FLASH */
  .isr_vector :
  {
    . = ALIGN(4);
    KEEP(*(.isr_vector)) /* Startup code */
    . = ALIGN(4);
  } >FLASH

  /* The program code and other data goes into FLASH */
  .text :
  {
    . = ALIGN(4);
    *(.text)           /* .text sections (code) */
    *(.text*)          /* .text* sections (code) */


    . = ALIGN(4);
    _etext = .;        /* define a global symbols at end of code */
  } >FLASH


  .  = ALIGN(4);        

  .rodata : 
  {
    . = ALIGN(4)  ;
    KEEP(*(.data))
    _sdata = . ;
    __data_start = _sdata ;
      *(.data)      /* Data memory */
    . = ALIGN(4) ;
    _edata = . ;
    _data_size = _edata - _sdata ;
  } >FLASH  

  . = ALIGN(10);
  .user : 
  {
    KEEP(*(.user))   
  } > FLASH 

  .bss :
  {
      . = ALIGN(4) ;
      _sbss = . ;
      __bss_start__ = _sbss;
      *(.bss)       /* Zero-filled run time allocate data memory */
      . = ALIGN(4) ;
      _ebss = . ;
      _bss_size = _ebss - _sbss ;  
  } >RAM

}  
