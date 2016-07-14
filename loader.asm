org 0x0100

    mov ax, 0xb800
    mov gs, ax
    mov ah, 0x0c
    mov al, 'L'
    mov [gs:((80 * 16 + 39) * 2)], ax

end:
    hlt
    jmp end
