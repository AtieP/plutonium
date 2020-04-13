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

; -------------------------------
; Entry point for our bootloader
; -------------------------------

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
	
	; Check memory
    clc
    int 12h
    jc not_enough_memory

    ; int 12h returns the memory available in AX
    cmp ax, 64
    jl not_enough_memory

    jmp $
    
not_enough_memory:

    mov si, .STR
    call puts

    xor ax, ax
    int 16h

    int 19h

.STR: db "FATAL: Required 64KB of memory",0

; -------------------------
; Subroutines
; -------------------------

puts:
    push ax
    mov ah, 0x0e

.print_chars:
    lodsb
    test al, al
    jz .done
    int 10h
    jmp .print_chars

.done:
    pop ax
    ret

times 510 - ($ - $$) db 0
dw 0AA55h                                   ; Needed for booting (this is the magic number)