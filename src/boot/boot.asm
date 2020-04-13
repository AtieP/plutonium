use16
cpu 8086
org 0

;
; Once the BIOS loads our bootloader into 07C0:0000 we will have complete
; control of the system!. And it will be time to make a short jump to
; skip the BIOS Parameter Block
;
jmp short main
nop

;
; BIOS Parameter block
; As per the FAT12 specification of the 1.44 MB 3.5" Inch IBM Floppy
; Diskette. Byte 0F0h indicates that this is a Floppy Diskette.
;
oem_id db				"BOOTDISK"			; OEM ID
bytes_per_sectors		dw 512				; Bytes per sector
sectors_per_cluster		db 18				; Sectors per cluster
reserved_sectors		dw 2				; Reserved sectors
number_of_fats			db 2				; FATs on the storage media
root_directory_entries	dw 224				; Directory entries
total_logical_sectors	dw 2880				; Total of sectors in the logical volume
media_descriptor		db 0F0h				; Media descriptor type
sectors_per_fat			dw 9				; Sectors per FAT
sectors_per_track		dw 18				; Sectors per track
sides					dw 2				; Sides
hidden_sectors			dd 0				; Hidden sectors
large_sectors			dd 0				; Large sectors
drive_number			db 0				; Drive number
signature				db 41				; Signature
volume_id				dd 00000000h		; Volume ID
volume_label			db "PLUTONIUM  "	; Volume label
file_system_signature	db "FAT12   "		; File system

;
; Entry point for our bootloader
;
main:
	; Set the stack 544 bytes away from the bootloader
	mov ax, 07C0h+544
	cli
	mov ss, ax
	mov sp, 4096
	sti
	
	; Set the correct data segment
	mov ax, 07C0h
	mov ds, ax

	; Check that there is engough memory before trying to load root directory
	clc
	int 12h
	jc fatal_error

	; INT 12H returns the memory available in (AX)
	cmp ax, 640 ; Check for 640 KB
	jl fatal_error
	
;
; Reads kernel and bootstraps it
; else returns error
;
read_kernel:
	; Read root directory entries (root directory starts at
	; sector 19)
	mov ax, 19
	call logical_sector_to_chs
	
	; Set int 13h to save read sectors into the root directory storage
	; place
	mov ax, ds
	mov es, ax
	mov bx, root_dir_entry_storage
	
	mov al, 14
	call read_sector
	
	; We now have the root entries in our buffer, time to read them
	; and find the kernel
	
	mov ax, ds
	mov es, ax
	mov di, root_dir_entry_storage
	
	xor ax, ax
.find_kernel:
	mov si, kernelName
	mov cx, 11 ; A FAT12 filename is 11 chars lenghty
	
	rep cmpsb
	je short .found_file
	
	add ax, 32 ; Skip one full entry
	
	mov di, root_dir_entry_storage
	add di, ax
	
	cmp byte [di], 0 ; Check if root directory has ended yet
	jnz short .find_kernel
	
	jmp fatal_error ; File not found
.found_file:
	mov ah, 0Eh
	mov al, 'Y'
	int 10h

	jmp $
	
	
kernelName		db "KERNEL  SYS"
	
;
; Reads a sector (use logical_sector_to_chs before calling!)
;
read_sector:
	mov ah, 2 ; INT 13H, AH 2: Read disk sectors
	push dx
.loop:
	pop dx ; DX is destroyed by some bogus BIOS
	push dx
	stc ; Set carry flag for bogus BIOS
	int 13h
	
	jnc short .end ; End if no error
	
	call reset_floppy ; Retry!
	jnc short .loop
	
	jmp fatal_error ; Double error on floppy
.end:
	pop dx
	ret
	
;
; Converts logical sector (AX) to parameters for interrupt 13h
;
logical_sector_to_chs:
	push bx ; Save registers
	push ax
	
	mov bx, ax ; Calculate physical sector
	xor dx, dx
	div word [sectors_per_track]
	inc dl ; Physical sectors starts at 1
	mov cl, dl ; Place in CL
	
	mov ax, bx ; Calculate head
	xor dx, dx
	div word [sectors_per_track]
	xor dx, dx ; And calculate the track
	div word [sides]
	mov dh, dl ; Place head
	mov ch, al ; Place track
	
	pop ax ; Restore registers
	pop bx
	
	; Set back the device number
	mov dl, byte [device_number]
	
	ret ; Return to caller
	
;
; Fatal error, (prints?) something and then (reboots?)
;
fatal_error:
	; No real need for super long messages, just a simple character
	; would help, we also need to save bootstrapper space for
	; routines like read_disk and root_directory loading
	
	mov ah, 0Eh
	mov al, '!'
	int 10h
	
	jmp $ ; Hang
	
;
; Include the Floppy Disk Bootloader signature this signature is needed
; by legacy BIOSes and various virtualization programs like QEMU or
; Bochs, without it, our bootloader will be rendered as unusable.
;
times 510-($-$$) db 0
dw 0AA55h

root_dir_entry_storage:
