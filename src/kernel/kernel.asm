; TODO: Add stuff

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
