/**************************************************************************
 Copyright Jacques Deschênes 2021,2022 
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

/***********************************
    block words set 
    according to Forth 2012 standard
    see forth-2012.pdf in docs 
************************************/

/**********************************************************************************************************
                                    EXCERPT from forth-2012.pdf chapter 7 

7.2 Additional terms

block: 1024 characters of data on mass storage, designated by a block number.

block buffer: A block-sized region of data space where a block is made temporarily available for use. The
current block buffer is the block buffer most recently accessed by BLOCK, BUFFER, LOAD, LIST,
or THRU.

NOTE:  these blocks will be stored on the flash memory on board of BLACK PILL. 

************************************************************************************************************/

/*******************************
   BLKN[4]

   record {
       block_nbr: word;  
       updated: byte; 
       not_used: byte; // this byte is not used   
   }

*******************************/

/*****************************
    BLK ( -- a-addr )
    address of system variable 
    containing the active 
    block #
******************************/
    _HEADER BLK,3,"BLK"
    _PUSH 
    MOV     TOS,UP 
    ADD TOS,#BLKID
    _NEXT 


/*******************************
    IN-BUFFER? ( u -- n )
   check if block u is in 
   a buffer 
input:
    U   block number 
output: 
    n   buffer number | -1 
********************************/
IN_BUFFERQ: 
    MOV     T1,#BLKN 
0:  LDRH    T0,[UP,T1]
    CMP     T0,TOS 
    BNE     1f
    SUB     T1,#BLKN  
    LSR     TOS,T1,#2  
    _NEXT 
1:  ADD     T1,#8
    CMP     T1,#BLKN+32  
    BLT     0b    
    MOV     TOS,#-1 
    _NEXT 


/******************************
    BUFF-ADR ( n -- a-addr )
    return address of buffer n 
input:
    n       buffer number 
output:
    a-addr  buffer address
******************************/
    _HEADER BUFF_ADR,8,"BUFF-ADR" 
    ADD     T0,UP,#BLKB 
    LSL     TOS,#10 // N*1024 
    ADD     TOS,T0 
    _NEXT 

/******************************
    BUFF-FREE? ( -- n )
    check for a free buffer 
output:
    n       free buffer# | -1 
*******************************/
    _HEADER BUFF_FREE,9,"BUFF-FREE"
    _PUSH 
    MOV     T0,#BLKN  
1:  LDRH    T1,[UP,T0]
    CBZ     T1, 2f 
    ADD     T0,#4 
    CMP     T0,#BLKN+16 
    BLT     1b 
    MOV     TOS,#-1 
    _NEXT 
2:  SUB     TOS,T0,#BLKN     
    LSR     TOS,#2
    _NEXT 


/*****************************
    BUFF-NEXT  ( -- n )
    return the oldest buffer#
*****************************/
BUFF_OLD:     
    _PUSH 
    EOR     TOS,TOS 
    EOR     T2,T2 
    MOV     T0,#BLKN+3 
1:  LDRB    T1,[UP,T0]
    CMP     T1,T2 
    BLT     2f 
    MOV     T2,T1 

/******************************
    BLOCK ( u -- a-addr )
    select block number u 
    load in buffer if not already 
    loaded 
input:
    u   block nbr to select 
output:
    a-addr  buffer address 
*********************************/
    _HEADER BLOCK,5,"BLOCK"
    _NEST 
    _ADR    DUPP 
    _ADR    IN_BUFFERQ
    _ADR    DUPP 
    _ADR    ZLESS 
    _TBRAN  4f 
    _ADR    OVER  
    _ADR    BLKID  
    _ADR    STORE
    _ADR    BUFF_ADR  
    _UNNEST 
4:  _ADR    BUFF_FREE 
    _ADR    DUPP 
    _ADR    ZLESS 
    _QBRAN  8f     // free buffer 
//  no free buffer free one 


/********************************
    BUFFER ( u -- a-addr )
    assign a buffer to bock u 
input:
    u   block number 
output:
    a-addr   address of buffer 
********************************/
    _HEADER BUFFER,6,"BUFFER"
    _NEST 

    _UNNEST 

/*******************************
    FLUSH (-- )
    unassign all buffers 
    save modified ones.
******************************/
    _HEADER FLUSH,5,"FLUSH"
    _NEST 

    _UNNEST 

/*****************************
    LOAD ( u -- )
    interpret block u 
    load in buffer if not 
    already 
*****************************/
    _HEADER LOAD,4,"LOAD"
    _NEST 

    _UNNEST 

/******************************
    SAVE-BUFFERS ( -- )
    save all modified buffers
    mark as unmodified 
******************************/
    _HEADER SAVE_BUFFERS,12,"SAVE-BUFFERS"
    _NEST 

    _UNNEST 

/*********************************
    UPDATE ( -- )
    mark current block as modified 
**********************************/
    _HEADER UPDATE,6,"UPDATE"
    _NEST 

    _UNNEST 


/***********************************
    EMPTY-BUFFERS ( -- )
    unassign all buffers 
    don't save modified
***********************************/
    _HEADER EMPTY_BUFFERS,13,"EMPTY-BUFFERS"
    _NEST

    _UNNEST 
    
/*************************************
    LIST ( U -- )
    display content of block u 
*************************************/
    _HEADER LIST,4,"LIST"
    _NEST 

    _UNNEST 

/************************************
    SRC ( -- a-addr )
    addres of SRC variable 
    content last listed block number 
**************************************/
    _HEADER SRC,3,"SRC"
    _PUSH 
    MOV TOS,UP
    ADD TOS,#SRCID 
    _NEST 

/***************************************
    THRU  ( u1 u2 -- )
    LOAD blocks u1 .. u2 
****************************************/    
    _HEADER THRU,4,"THRU" 
    _NEST 

    _UNNEST 

