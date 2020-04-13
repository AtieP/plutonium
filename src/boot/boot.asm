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

<<<<<<< HEAD
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
=======
; Parameter block
; Needed for FAT12

OEM_ID: db "BOOTDISK"           ; OEM ID
BYT_SC: dw 512                  ; Bytes per sector
SEC_CL: db 18                   ; Sectors per cluster
RES_SC: dw 2                    ; Reserved sectors
FAT_SM: db 2                    ; FATs on the storage media
DIR_EN: dw 224                  ; Directory entries
TOT_SC: dw 2880                 ; Total of sectors in the logical volume
MED_DT: db 0xF0                 ; Media descriptor type
SEC_FT: dw 9                    ; Sectors per FAT
SEC_TR: dw 18                   ; Sectors per track
SIDES:  dw 2                    ; Sides
HID_SC: dd 0                    ; Hidden sectors
LRG_SC: dd 0                    ; Large sectors
DRV_NU: dw 0                    ; Drive number
SIG_NU: db 41                   ; Signature
VOL_ID: dd 00000000h            ; Volume ID
VOL_LB: db "PLUTONIUM  "        ; Volume label
FSM_ID: db "FAT12   "           ; File system
>>>>>>> 3c3694d1a821257daf63c245113e2f80d404cc31

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
	
	; Set the corret data segment
	mov ax, 07C0h
	mov ds, ax
	
	; TODO: Add read
	
;
; Include the Floppy Disk Bootloader signature this signature is needed
; by legacy BIOSes and various virtualization programs like QEMU or
; Bochs, without it, our bootloader will be rendered as unusable.
;
times 510-($-$$) db 0
dw 0AA55h
