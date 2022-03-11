/**************************************************************************
 Copyright Jacques Deschênes 2021, 2022 
 This file is part of beyond-Jupiter 

     beyond-Jupiter is free software: you can redistribute it and/or modify
     it under the terms of the GNU General Public License as published by
     the Free Software Foundation, either version 3 of the License, or
     (at your option) any later version.

     beyond-Jupiter is distributed in the hope that it will be useful,
     but WITHOUT ANY WARRANTY without even the implied warranty of
     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
     GNU General Public License for more details.

     You should have received a copy of the GNU General Public License
     along with beyond-Jupiter.  If not, see <http://www.gnu.org/licenses/>.

***************************************************************************/

/**********************************
    SPI FLASH memory 
    U3 chip: Winbound W25Q128FV
    16 MBytes
    erase BLOCK are 4KB 
    write pages are 256 bytes
**********************************/

    PIN_F_SC = 4 
    PIN_SCK = 5 
    PIN_MISO = 6 
    PIN_MOSI = 7 

    FLASH_SECTOR_SIZE= 4096 

/*****************************
  initialize SPI peripheral 
  pinout:
     PA4 F_CS 
     PA5 SCK 
     PA6 MISO 
     PA7 MOSI    
******************************/
flash_spi_init:
    _MOV32 r0,GPIOA_BASE_ADR 
    mov r3,r0 
    mov r1,#PIN_F_SC 
    mov r2,#OUTPUT_PP
    _CALL gpio_config 
    mov r0,r3 
    mov r1,#PIN_F_SC  
    MOV r2,#1
    _CALL gpio_out 
    mov r0,r3 
    mov r1,#PIN_SCK  
    mov r2,#OUTPUT_AFPP
    _CALL gpio_config 
    mov r0,r3 
    mov r1,#PIN_MOSI 
    mov r2,#OUTPUT_AFPP 
    _CALL gpio_config 
    mov r0,r3
    mov r1,#PIN_MISO
    mov r2,#INPUT_AFO  
    _CALL gpio_config
// PA5:7 at max speed 
    mov r0,#0xCCAA
    strh r0,[r3,#GPIO_OSPEEDR]    
    _MOV32 r0,RCC_BASE_ADR
    ldr r1,[r0,#RCC_APB2ENR]
    orr r1,#(1<<12) // SPI1EN 
    str r1,[r0,#RCC_APB2ENR]
    _MOV32 r0, SPI1_BASE_ADR 
    mov r1,#(1<<2)+(1<<3)+(1<<6)+(1<<8)+(1<<9) //MSTR+SPE+SS+SSI, Fpclk/4 
    strh r1,[r0,#SPI_CR1]
    ldr r1,[r3,#GPIO_AFRL]
    eor r0,r0 
    movt r0,#0x5550 
    orr r0,r1 
    str r0,[r3,#GPIO_AFRL]
    _RET 


/**********************
    CHIP-SEL ( -- )
    drive F_SC low 
*********************/
    _HEADER CHIP_SEL,8,"CHIP-SEL"
    _MOV32 r0,GPIOA_BASE_ADR
    mov r1,#PIN_F_SC 
    mov r2,#0 
    _CALL gpio_out 
    _NEXT 


/*********************
    CHIP-DSEL 
    drive F_SC high 
*********************/
    _HEADER CHIP_DSEL,9,"CHIP-DSEL"
    _MOV32 T0,SPI1_BASE_ADR
1:  ldrh T1,[T0,#SPI_SR]
    tst T1,(1<<7) // BSY 
    bne 1b 
    _MOV32 r0,GPIOA_BASE_ADR
    mov r1,#PIN_F_SC 
    mov r2,#1 
    _CALL gpio_out 
    _NEXT 


/****************************
    WB-BUFF ( -- a-adr )
    return address of 
    flash write back buffer 
****************************/
    _HEADER WB_BUF,7,"WB-BUFF"
    _PUSH 
    _MOV32     TOS,WB_BUFF
    _NEXT

/****************************
    RD-SECTOR ( a -- )
    read a W25Q128FV sector 
    in WB-BUFFER 
****************************/ 
    _HEADER RD_SECT,9,"RD-SECTOR"
    _NEST 
    _DOLIT  WB_BUFF 
    _DOLIT  FLASH_SECTOR_SIZE 
    _ADR    ROT 
    _ADR    RD_BLK 
    _UNNEST 

/*****************************
    WR-SECTOR ( a -- )
    write WB-BUFF to W25Q128FV
    at address 'a' 
input:
    a   flash chip address
        a is sector aligned 
        The sector must be erased
******************************/
    _HEADER WR_SECT,9,"WR-SECTOR"
    _NEST 
    _ADR    WB_BUF // a b
    _ADR    SWAP   // b a 
    _ADR    DDUP   // b a b a   
    _DOLIT  16 
    _ADR    TOR 
    _BRAN   4f 
1:  _DOLIT  256
    _ADR    SWAP  // b a b 256 a    
    _ADR    WR_BLK  
    _DOLIT  256  //  b a 256 
    _ADR    DUPP  // b a 256 256  
    _ADR    DPLUS // b+256 a+256
    _ADR    DDUP // b a b a 
4:  _DONXT  1b
    _ADR    DDROP
    _ADR    DDROP           
    _UNNEST 


/****************************
    RD-BYTE ( -- )
    read flash byte 
***************************/
    _HEADER RD_BYTE,7,"RD-BYTE"
    _MOV32 T0,SPI1_BASE_ADR 
0:  ldrh T1,[T0,#SPI_SR]
    tst T1,#(1<<1) //TXE
    beq 0b 
    mvn T1,#0 
    strb T1,[T0,#SPI_DR]
1:  ldrh T1,[T0,#SPI_SR]
    tst T1,#(1<<0) // RXNE  
    beq 1b     
2:  
    _PUSH 
    ldrb TOS,[T0,#SPI_DR]
    _NEXT 


/*********************************
    WR-BYTE  ( c -- )
    write flash byte 
*************************/
    _HEADER WR_BYTE,7,"WR-BYTE"
    _MOV32 T0,SPI1_BASE_ADR 
0:  ldrh T1,[T0,#SPI_SR]
    tst T1,#(1<<1) //TXE
    beq 0b 
    strb TOS,[T0,#SPI_DR]
1:  ldrh T1,[T0,#SPI_SR]
    tst T1,#(1<<0) // RXNE  
    beq 1b 
    ldrh T1,[T0,#SPI_DR]
    _POP 
    _NEXT 

/*************************
    WR-DIS ( -- )
    write disable 
    reset WEL bit 
*************************/
    _HEADER WR_DIS,6,"WR-DIS"
    _NEST 
    _ADR CHIP_SEL 
    _DOLIT 4
    _ADR WR_BYTE
    _ADR CHIP_DSEL
    _UNNEST

/*************************
    WR-ENBL ( -- )
    set WEL flag in SR0 
************************/
    _HEADER WR_ENBL,7,"WR-ENBL"
    _NEST 
    _ADR CHIP_SEL 
    _DOLIT 6 
    _ADR WR_BYTE 
    _ADR CHIP_DSEL 
    _UNNEST 

/********************************
    RD-SR ( n -- c )
    read status register  
********************************/
    _HEADER RD_SR,5,"RD-SR"
    _NEST
    _ADR CHIP_SEL  
    _DOLIT sr_cmd 
    _ADR PLUS 
    _ADR CAT
    _ADR WR_BYTE
    _ADR RD_BYTE
    _ADR CHIP_DSEL  
    _UNNEST 
sr_cmd: .byte 5,0x35,0x15      

/*********************************
    SEND-ADR ( a -- )
    send 24 bits address 
*******************************/
    _HEADER SEND_ADR,8,"SEND-ADR"
    _NEST 
    _ADR DUPP 
    _DOLIT 16
    _ADR RSHIFT 
    _ADR WR_BYTE 
    _ADR DUPP
    _DOLIT 8 
    _ADR RSHIFT 
    _ADR WR_BYTE 
    _ADR WR_BYTE 
    _UNNEST 

/**********************************
    WAIT-DONE ( -- )
    wait write operation completed 
**********************************/
    _HEADER WAIT_DONE,9,"WAIT-DONE"
    _NEST 
1:  _DOLIT 0 
    _ADR RD_SR 
    _DOLIT 3 
    _ADR ANDD 
    _QBRAN 2f
    _BRAN 1b
2:  _UNNEST 


/****************************
   ERASE-SECTOR ( a -- )
   erase 4Ko sector 
input:
    a     sector address on 
          flash memory.
***************************/
    _HEADER ERASE_SECT,12,"ERASE-SECTOR"
    _NEST 
    _ADR WR_ENBL
    _ADR CHIP_SEL 
    _DOLIT 0x20 
    _ADR WR_BYTE 
    _ADR SEND_ADR
    _ADR CHIP_DSEL 
    _ADR WAIT_DONE 
    _UNNEST 

/******************************
    ERASE-CHIP ( -- )
    erase all data 
******************************/
    _HEADER ERASE_CHIP,10,"ERASE-CHIP"
    _NEST 
    _ADR WR_ENBL 
    _ADR CHIP_SEL
    _DOLIT 0x60
    _DOLIT 0xC7 
    _ADR WR_BYTE 
    _ADR WR_BYTE 
    _ADR CHIP_DSEL 
    _ADR WAIT_DONE
    _UNNEST 


/******************************
    RD-BLK ( buff n a --  )
    read n bytes in buff 
    starting at address a  
******************************/
    _HEADER RD_BLK,6,"RD-BLK"
    _NEST
    _ADR CHIP_SEL 
    _DOLIT 3 
    _ADR WR_BYTE 
    _ADR SEND_ADR
    _ADR TOR   
    _BRAN 2f
1:  _ADR RD_BYTE
    _ADR OVER 
    _ADR CSTOR
    _ADR ONEP 
2:  _DONXT 1b
    _ADR DROP 
    _ADR CHIP_DSEL 
    _UNNEST 

/*****************************
    WR-BLK ( buff n a -- )
    write up to 256 bytes 
    in erased flash
****************************/
    _HEADER WR_BLK,6,"WR-BLK"
    _NEST 
    _ADR WR_ENBL
    _ADR CHIP_SEL
    _DOLIT 2 
    _ADR WR_BYTE 
    _ADR SEND_ADR
    _ADR TOR
    _BRAN 2f 
1:  _ADR DUPP 
    _ADR CAT 
//    _ADR DUPP 
//    _ADR HDOT
    _ADR WR_BYTE 
    _ADR ONEP
2:  _DONXT 1b 
    _ADR DROP
    _ADR CHIP_DSEL
    _ADR WAIT_DONE 
    _UNNEST


/********************************
   FILES structures 
   -----------------
   name: 16 bytes null padded 
   size: 4 bytes
   sectors count: 4 bytes
   update counter: 4 bytes
   signature: IMAG for image files, DATA for others  
   sector size: 4KB 
   free sector: first byte 0xFF 
   erased file: first byte 0xFF
********************************/

/*******************************
    SEARCH-FILE 'name' ( -- adr )
    search file in flash 
********************************/
    _HEADER SEARCH_FILE,11,"SEARCH-FILE"
    _NEST 
    
    _UNNEST 

 /******************************
    ERASE-FILE 'name' ( -- )
    delete a file 
*******************************/
    _HEADER ERASE_FILE,10,"ERASE-FILE"
    _NEST 

    _UNNEST 

/*******************************
    DIR ( -- )
    print files list 
*******************************/
    _HEADER DIR,3,"DIR"
    _NEST 

    _UNNEST 

/*******************************
    SAVE 'name' ( -- ) 
    save current data space image 
    on flash chip. 
    This file can be reloaded 
    using LOAD 
    This file as an IMAG signature  
********************************/
    _HEADER SAVE,4,"SAVE"
    _NEST 

    _UNNEST 


/*********************************
    LOAD 'name' ( i*x -- j*x )
    load image file previously saved 
    using SAVE. The file must 
    have an IMAG signature 
********************************/
    _HEADER LOAD,4,"LOAD"
    _NEST 

    _UNNEST 

    

    