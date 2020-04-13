;  This program is free software; you can redistribute it and/or modify
;  it under the terms of the GNU General Public License as published by
;  the Free Software Foundation; either version 2 of the License, or
;  (at your option) any later version.
;  
;  This program is distributed in the hope that it will be useful,
;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;  GNU General Public License for more details.
;  
;  You should have received a copy of the GNU General Public License
;  along with this program; if not, write to the Free Software
;  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
;  MA 02110-1301, USA.
;  

use16
cpu 8086
org 0500h

jmp start

start:
	xor ax, ax
	cli ; Set our stack
	mov ss, ax
	mov sp, ax
	mov sp, 0FFFFh ; Put stack very far away from kernel
	sti ; Restore interrupts
	
	cld ; Go up in RAM
	
	xor ax, ax ; Segmentate to
	mov es, ax ; all data and extended segment into the
	mov ds, ax ; kernel segment
	
	mov al, '$'
	mov ah, 0Eh
	int 10h
	
	jmp $
