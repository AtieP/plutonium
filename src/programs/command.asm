; superleaf pls add the header here

org 100h
cpu 8086
use16

main:


; Prints a string
; IN: SI = Memory address of the string
; OUT: Nothing
puts:
    push ax
    mov ah, 0x0e

.print_chars:   
    lodsb
    test al, al
    jz .end
    int 10h
    jmp .print_chars

.end:
    pop ax
    ret

; Prints a char.
; IN: AL = Character
; OUT: Nothing
putchar:
    push ax

    mov ah, 0x0e
    int 10h

    pop ax
    ret

; Gets a key from the keyboard and print it.
; IN: Nothing
; OUT: Character in AL, keycode in AH
getchar:
    
    xor ax, ax
    int 16h

    call putchar
    
    ret