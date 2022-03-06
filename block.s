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
       updated: byte; 
       free: byte; 
       block_nbr: word;  
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

    _UNNEST 


/********************************
    BUFFER ( u -- a-addr )
    assign a buffer to bock u 
input:
    u   block number 
output:
    a-addr   address of buffer 
********************************/
    _HEADRE BUFFER,6,"BUFFER"
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
    ADD TOS,SRC 
    _NEST 

/***************************************
    THRU  ( u1 u2 -- )
    LOAD blocks u1 .. u2 
****************************************/    
    _HEADER THRU,4,"THRU" 
    _NEST 

    _UNNEST 

