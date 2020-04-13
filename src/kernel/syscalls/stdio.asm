; Standart Input and Output functions


; Gets a key from the keyboard and prints it.
; IN: Nothing
; OUT: AH = Scancode, AL = ASCII Key
getchar:

    xor ax, ax
    int 16h

    call putchar
    ret

; Prints a character
; IN: AL = ASCII Char
; OUT: Nothing
putchar:
    push ax
    mov ah, 0x0e
    int 10h
    pop ax
    ret
    
; Prints a string
; IN: SI = Address to string 
; OUT: Nothing

puts:
    push ax

.print_chars:
    lodsb
    test al, al
    jz .end
    int 10h
    jmp .print_chars

.end:
    pop ax 
    ret