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
    _RET 


/**********************
    CHIP-SEL ( -- )
    drive F_SC low 
*********************/
    _HEADER CHIPSEL,8,"CHIP-SEL"
    _MOV32 r0,GPIOA_BASE_ADR
    mov r1,#PIN_F_SC 
    mov r2,#0 
    _CALL gpio_out 
    _NEXT 


/*********************
    _CHIP-DSEL 
    drive F_SC high 
*********************/
    _HEADER CHIPDSEL,9,"CHIP-DSEL"
    _MOV32 r0,GPIOA_BASE_ADR
    mov r1,#PIN_F_SC 
    mov r2,#1 
    _CALL gpio_out 
    _NEXT 


