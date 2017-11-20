ORG 0x7F00

Start:
    mov ah, 0x0E ; print mode
    mov al, '!' ; exclamation
    mov bl, 0 ; Colors don't seem to be working
    mov bh, 0 ; we dont need to set the page mode
    int 0x10 ; print the char
    ret
