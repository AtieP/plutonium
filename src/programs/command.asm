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
; IN: CF set = Echo
; OUT: Character in AL, keycode in AH
getchar:
    
    xor ax, ax
    int 16h

    jc .echo
    ret

.echo:

    call putchar

    ret

; Gets a string from the keyboard.
; IN: CX = Lenght, DI = String location
; OUT: Nothing
gets:
    push ax
    push bx
    push cx
    push dx

    mov dx, cx          ; initial possition

.get_chars:

    test cx, cx
    jz .done

    clc
    call get_chars

    cmp ah, 0x1C        ; key enter
    je .done

    cmp ah, 0x0E        ; key backspace
    je .handle_backspace

    call putchar        ; print ASCII key
    stosb               ; store it

    dec cx

    jmp .get_chars

.handle_backspace:

    cmp dx, cx          ; check if its on the inital position
    je .get_chars

    dec di
    inc cx

    ; get cursor position
    mov ah, 0x03
    xor bh, bh
    int 10h

    ; go back
    mov ah, 0x02
    dec dl
    xor bh, bh
    int 10h

    ; print a space
    mov ah, 0x0e
    mov al, ' '
    int 10h

    stosb

    jmp .get_chars
.done:
    xor al, al
    stosb

    pop dx
    pop cx
    pop bx
    pop ax

    ret
