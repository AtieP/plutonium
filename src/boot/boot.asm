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
bytes_per_sector		dw 512				; Bytes per sector
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

	; Check that there is enough memory before trying to load root directory
	clc
	int 12h
	jc fatal_memory_error

	; INT 12H returns the memory available in (AX)
	cmp ax, 64 ; Check for 640 KB
	jl fatal_memory_error
	
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
	mov cx, 11 								; A FAT12 filename is 11 chars long
	
	rep cmpsb
	je short .found_file
	
	add ax, 32 								; Skip one full entry
	
	mov di, root_dir_entry_storage
	add di, ax
	
	cmp byte [di], 0 						; Check if root directory has ended yet
	jnz short .find_kernel
	
	jmp fatal_error 						; File not found
	
.found_file:
	mov ax, word [es:di+0Fh]				; Get cluster from root directory entry
	mov word [cluster], ax					; Save it for future use
	
	xor ax, ax								; Read sector 1, where the FAT is on
	inc ax
	call logical_sector_to_chs
	
	mov di, fat_storage
	mov bx, di
	
	xor ax, ax								; Make the readed sectors load at
	mov es, ax								; 0000h:0500h so we will have our kernel
	mov bx, 0500h							; ready there!
	
	mov ah, 2								; Read 1 sector from disk
	mov al, 1
	
	push ax
.load_file_sector:
	mov ax, word [cluster]					; Retrieve cluster
	
	add ax, 31								; Cluster+31 = File data!
	call logical_sector_to_chs
	
	xor ax, ax								; Load those data into the
	mov es, ax								; place where the kernel is being loaded
	mov bx, 0500h							; on
	mov bx, word [pointer]
	
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
	mov ax, word [cluster]
	xor dx, dx
	mov bx, 3
	mul bx
	dec bx
	div bx
	
	mov si, fat_storage
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
	mov word [cluster], ax					; Put cluster in cluster
	cmp ax, 0FF8h							; Check for EOF
	jae short .end							; All loaded, time to jump into kernel
	
	push ax
	mov ax, [bytes_per_sector]				; Go to the next sector
	add word [pointer], ax
	pop ax
	
	jmp short .load_file_sector
;
; Everything is set and no errors were made, time to jump into the kernel
; and do anthing from there
;
.end:										; File is now loaded in the ram
	pop ax									; Pop off ax
	mov dl, byte [drive_number]				; Give kernel device number
	
	jmp 0000h:0500h							; Jump to kernel

cluster			dw 0
pointer			dw 0
kernelName		db "KERNEL  SYS"
	
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
	inc dl 									; Physical sectors starts at 1
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
	mov al, '^'
	mov ah, 0Eh
	int 10h
	
	jmp $ ; Hang
	
fatal_memory_error:
	mov al, '%'
	mov ah, 0Eh
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
fat_storage:
