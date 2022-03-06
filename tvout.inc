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
  .equ HRES, 320  // horizontal resolution
  .equ VRES, 200   // vertical resolution
  .equ BPP, 4     // bits per pixel
  .equ BPR, (HRES*BPP/8)  // bytes per row
  .equ VIDEO_BUFFER_SIZE, (VRES*BPR) // bytes 

  .equ CHAR_WIDTH, 6 
  .equ CHAR_HEIGHT, 8
  
