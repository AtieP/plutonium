;    Plutonium Kernel. Copyright (C) 2020 Plutonium Contributors
;
;    This program is free software: you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation, either version 3 of the License, or
;    (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with this program.  If not, see <https://www.gnu.org/licenses/>.

use16
cpu 8086
org 0700h

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

;
; Allocates a piece of memory
;
; AX = Number of bytes to allocate
;
; Returns DX:AX ( Segment:Offset )
; CF set on error
; If there is error the following error codes (in AX) may return
;		01h = Corrupt memory table
;		02h = No memory left
;
alloc:
	mov ax, 0060 ; Point at the memory table
	mov es, ax
	mov di, 0C00
	
	mov cx, word [es:di] ; Get the number of entries
	add bx, 2 ; Skip the word
	
	cmp cx, word [es:di] ; Zero?, Corrupt memory table
	jmp .corrupt_number
.find_free:
	;
	; Memory Table Entries
	; WORD - Segment
	; WORD - Offset
	; WORD - Size
	; WORD - Process ID
	; BYTE - Status
	;
	
	mov bx, word [es:di+04h] ; Size
	cmp ax, bx
	jge .found_big
	
	add bx, 9 ; Skip an entire entry
	
	loop .find_free
	jmp .no_free
.found_big:
	; We found a big block, the size is on the
	; BX register
	
	cmp ax, bx ; It's simple if it's equal
	je .found_equal
	
	; TODO: Add intelligent allocation
	jmp .error
.found_equal:
	; Simply set the memory as "used"
	mov bx, word [es:di+08h] ; Status
	
	; Set correct return value
	mov ax, word [es:di+00h] ; Segment
	mov dx, word [es:di+02h] ; Offset
	jmp .sucess
.sucess:
	clc
.end:
	ret
	
.error:
	xor ax, ax
	stc
	jmp short .end
	
.no_free:
	mov ax, 01h
	jmp .error
	
.corrupt_number:
	mov ax, 02h
	jmp .error
	
.tmp	times 12 db 0

;
; AX = Segment
; BX = Offset
; SI = Filename
;
; Reads file
;
read_file:
	; Transfer stuff to variables
	mov word [.filename], si
	mov word [.seg], ax
	mov word [.offs], bx

	; Read root directory entries (root directory starts at
	; sector 19)
	mov ax, 19
	call logical_sector_to_chs
	
	; Set int 13h to save read sectors into the root directory storage
	; place
	mov si, disk_buffer
	mov ax, ds
	mov es, ax
	mov bx, si
	
	mov al, 14
	call read_sector
	
	; We now have the root entries in our buffer, time to read them
	; and find the kernel
	
	mov ax, ds
	mov es, ax
	mov di, disk_buffer

	xor ax, ax
.find_kernel:
	mov si, .filename
	mov cx, 11 								; A FAT12 filename is 11 chars long
	rep cmpsb
	je short .found_file
	
	add ax, 20h 							; Skip one full entry
	
	mov di, disk_buffer
	add di, ax
	
	cmp byte [es:di], 0 					; Check if root directory has ended yet
	jnz short .find_kernel
	
	jmp fatal_error 						; File not found
.found_file:
	mov ax, word [es:di+0Fh]				; Get cluster from root directory entry
	mov word [.cluster], ax					; Save it for future use
	
	xor ax, ax								; Read sector 1, where the FAT is on
	inc ax
	call logical_sector_to_chs
	
	mov di, disk_buffer
	mov bx, di
	
	mov ax, word [sectors_per_fat]
	call read_sector
	
	mov ax, word [.seg]						; Make the readed sectors load at
	mov es, ax								; 0000h:0500h so we will have our kernel
	mov bx, word [.offs]					; ready there!
	
	mov ax, 0201h							; Read 1 sector from disk
	
	push ax
.load_file_sector:
	mov ax, word [.cluster]					; Retrieve cluster
	
	add ax, 31								; Cluster+31 = File data!
	call logical_sector_to_chs
	
	mov ax, word [.seg]						; Load those data into the
	mov es, ax								; place where the kernel is being loaded
	mov bx, word [.offs]					; on
	add bx, word [.pointer]
	
	pop ax
	push ax
	
	stc
	int 13h
	
	jnc short .next_cluster
	
	call reset_floppy
	jmp short .load_file_sector
;
; Now find the cluster by either knowing it's odd or even
; if it is even, then mask out 12 bits of the cluster, else
; shift it by 4 bits
;
.next_cluster:
	mov ax, word [.cluster]
	xor dx, dx
	mov bx, 3
	mul bx
	dec bx
	div bx
	
	mov si, disk_buffer
	add si, ax
	
	mov ax, word [ds:si]					; Get a cluster word
	
	or dx, dx								; Check if our cluster even or odd
	jz short .even_cluster
.odd_cluster:
	push cx
	mov cl, 4								; Shift our cluster by 4 bits
	shr ax, cl
	pop cx
	
	jmp short .check_eof
.even_cluster:
	and ax, 0FFFh							; Mask out all 12 bits
.check_eof:
	mov word [.cluster], ax					; Put cluster in cluster
	cmp ax, 0FF8h							; Check for EOF
	jae short .end							; All loaded, time to jump into kernel
	
	mov ax, [bytes_per_sector]				; Go to the next sector
	add word [.pointer], ax
	jmp short .load_file_sector
;
; Everything is set and no errors were made, time to jump into the kernel
; and do anthing from there
;
.end:										; File is now loaded in the ram
	pop ax									; Pop off ax
	
	stc
	
	ret
	
.cluster				dw 0
.pointer				dw 0
.filename				dw 0
.seg					dw 0
.offs					dw 0

;
; Reads a sector (use logical_sector_to_chs before calling!)
;
read_sector:
	mov ah, 2 								; INT 13H, AH 2: Read disk sectors
	push dx
.loop:
	pop dx 									; DX is destroyed by some buggy BIOSes
	push dx
	
	stc 									; Set carry flag for buggy BIOSes
	int 13h
	
	jnc short .end 							; End if no error
	
	call reset_floppy 						; Retry!
	jnc short .loop
	
	jmp fatal_error 						; Double error on floppy
.end:
	pop dx
	ret
	
;
; Converts logical sector (AX) to parameters for interrupt 13h
;
logical_sector_to_chs:
	push bx 								; Save registers
	push ax
	
	mov bx, ax 								; Calculate physical sector
	xor dx, dx
	div word [sectors_per_track]
	add dl, 01h								; Physical sectors starts at 1
	mov cl, dl 								; Place in CL
	
	mov ax, bx 								; Calculate head
	xor dx, dx
	div word [sectors_per_track]
	xor dx, dx 								; And calculate the track
	div word [sides]
	mov dh, dl 								; Place head
	mov ch, al 								; Place track
	
	pop ax 									; Restore registers
	pop bx
	
	; Set back the device number
	mov dl, byte [drive_number]
	
	ret 									; Return to caller
	
;
; Resets main floppy drive
;
reset_floppy:
	push ax
	push dx
	
	xor ax, ax ; INT 13H, AH 00H, Reset Drive
	mov dl, byte [drive_number] ; Set proper drive number
	
	stc ; Carry flag for bogus BIOS
	int 13h
	
	pop dx
	pop ax
	ret
	
;
; Fatal error, hangs and prints an exclamation mark
;
fatal_error:
	mov al, '<'
	mov ah, 0Eh
	int 10h
	
	jmp $ ; Hang

bytes_per_sector		dw 512				; Bytes per sector
sectors_per_cluster		db 1				; Sectors per cluster
root_directory_entries	dw 224				; Directory entries
sectors_per_fat			dw 9				; Sectors per FAT
sectors_per_track		dw 18				; Sectors per track
sides					dw 2				; Sides
drive_number			dw 0				; Drive number

disk_buffer:
