;    Plutonium Standard I/O. Copyright (C) 2020 Plutonium Contributors
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
