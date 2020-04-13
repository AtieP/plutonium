; TODO: Add stuff

use16
cpu 8086
org 0

jmp short main
nop

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
DRV_NU: db 0                    ; Drive number
SIG_NU: db 41                   ; Signature
VOL_ID: dd 00000000h            ; Volume ID
VOL_LB: db "PLUTONIUM  "        ; Volume label
FSM_ID: db "FAT12   "           ; File system

main:
