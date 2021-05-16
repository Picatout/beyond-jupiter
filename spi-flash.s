/**************************************************************************
 Copyright Jacques Deschênes 2021 
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
**********************************/

    PIN_F_SC = 4 
    PIN_SCK = 5 
    PIN_MISO = 6 
    PIN_MOSI = 7 

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
   ERASE-SEC ( a -- )
   erase 4Ko sector 
***************************/
    _HEADER ERASE_SEC,9,"ERASE-SEC"
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
    _ADR RD_BYTE 
    _ADR DROP   
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
    _ADR WR_BYTE 
    _ADR ONEP
2:  _DONXT 1b 
    _ADR DROP
    _ADR CHIP_DSEL
    _ADR WAIT_DONE 
    _UNNEST

