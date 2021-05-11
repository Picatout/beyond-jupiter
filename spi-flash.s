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
    MOV r1,#1
    _CALL gpio_out 
    mov r0,r3 
    mov r1,#PIN_SCK  
    mov r2,#OUTPUT_AFPP
    _CALL gpio_config 
    mov r0,r3 
    mov r1,#PIN_MOSI 
    mov r2,#OUTPUT_AFPP 
    _CALL gpio_config 
    _MOV32 r0,RCC_BASE_ADR
    ldr r1,[r0,#RCC_APB2ENR]
    orr r1,#(1<<12) // SPI1EN 
    str r1,[r0,#RCC_APB2ENR]
    _MOV32 r0, SPI1_BASE_ADR 
    mov r1,#(1<<2)+(1<<8)+(1<<9) //MSTR+SS+SSI 
    strh r1,[r0,#SPI_CR1]
    ldr r1,[r3,#GPIO_AFRL]
    eor r0,r0 
    movt r0,#0x555<<4
    orr r0,r1 
    str r0,[r3,#GPIO_AFRL]
    _RET 


/**********************
    CHIP-SEL ( -- )
    drive F_SC low 
*********************/
    _HEADER CHIPSEL,8,"CHIP-SEL"
    _MOV32 r0,SPI1_BASE_ADR 
    ldr r1,[r0,#SPI_CR1]
    orr r1,#(1<<6) //SPE 
    str r1,[r0,#SPI_CR1]
    _MOV32 r0,GPIOA_BASE_ADR
    mov r1,#PIN_F_SC 
    mov r2,#0 
    _CALL gpio_out 
    _NEXT 


/*********************
    CHIP-DSEL 
    drive F_SC high 
*********************/
    _HEADER CHIPDSEL,9,"CHIP-DSEL"
    _MOV32 r0,SPI1_BASE_ADR 
    ldrh r1,[r0,#SPI_CR1]
    bic r1,#(1<<6) //SPE 
    strh r1,[r0,#SPI_CR1]
    _MOV32 r0,GPIOA_BASE_ADR
    mov r1,#PIN_F_SC 
    mov r2,#1 
    _CALL gpio_out 
    _NEXT 


/****************************
    READ-BYTE ( -- )
    read flash byte 
***************************/
    _HEADER READ_BYTE,9,"READ-BYTE"
    _MOV32 T0,SPI1_BASE_ADR 
    _PUSH 
0:  ldrh T1,[T0,#SPI_SR]
    tst T1,#(1<<1) //TXE
    beq 0b 
    eor T1,T1 
    strb T1,[T0,#SPI_DR]
1:  ldr T1,[T0,#SPI_SR]
    tst T1,#(1<<0) // RXNE 
    beq 1b     
    ldrb TOS,[T0,#SPI_DR]
    _NEXT 

/*********************************
    WRITE-BYTE  ( c -- )
    write flash byte 
*************************/
    _HEADER WRITE_BYTE,10,"WRITE-BYTE"
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

/********************************
    FLASH-RDSR ( n -- c )
    read status register  
********************************/
    _HEADER FLASH_RDSR,10,"FLASH-RDSR"
    _NEST 
    _ADR CHIPSEL 
    _DOLIT sr_cmd 
    _ADR PLUS 
    _ADR CAT
    _ADR WRITE_BYTE
    _ADR READ_BYTE 
    _ADR CHIPDSEL 
    _UNNEST 
sr_cmd: .byte 5,0x35,0x15      

