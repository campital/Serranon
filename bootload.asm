; directives
BITS 16 ; bootloader is in 16 bits
ORG 0x7C00

;================================================================FAT16 BPB HEADERS=======================================================================;
; All information obtained from fatgen103.doc
jmp short start ; jmp to start
nop ; for BS_jmpBoot
db 'MSWIN4.1' ; BS_OEMName, for maximum compatibility
dw 512 ; BPB_BytsPerSec, use 512 bytes per sector
db 1 ; dont really use clusters, BPB_SecPerClus
dw 1 ; how many sectors are reserved for boot
db 2 ; there are two file allocation tables...
dw 512 ; number of directory entries so may need to change this when I actually understand how FAT works
dw 65535 ; how many logical sectors, so 65535 * 512 = 33553920 bytes we can use
db 0xF8 ; media type
dw 16 ; use sixteen sectors per FAT
dw 32 ; dont think tracks matter, NUM SECTORS PER TRACK
dw 2 ; dont think we need heads either
dd 0 ; HIDDEN SECTORS? SNEAKY
dd 0 ; already fit 65535 into logical sectors

db 0 ; useless drive number...
db 0 ; useless
db 0x29 ; tell the bios were still here, signature
dd 57834203 ; random number to identify drive
db 'SERRANON   ' ; drive name
db 'FAT16   ' ; useless identification for compatibility


start:
    cli
    mov ax, 0x0700
    mov ss, ax; can't move direct value to ss, using ss so stack has a bottom
    mov sp, 0x0BFA ; move the stack to just before the bootloader (6 bytes?)
    sti ; restore them interrupts
    
    mov ax, 0
    mov ds, ax ; reset data segment because we are using ORG
    
    call PrintString ; print the string
    jmp $ ; halt the processor, program ended

PrintString: ; location of string is in bp
    xor cx, cx ; set cx to 0
.loop:
    mov bx, cx
    mov al, [print_str + bx] ; char to print
    
    cmp al, 0
    je .done ; if the string is not terminated or longer than max string length, continue, or else ret
    
    mov ah, 0x0E ; print mode
    mov bl, 0 ; Colors don't seem to be working
    mov bh, 0 ; we dont need to set the page mode
    int 10h ; print the char
    inc cx ; increment the counter
    cmp cx, 200 ; max string length
    je .done
    jmp .loop
.done:
    ret

print_str db 'Loading the operating system...', 0 ; 0 is the standard termination
times 510 - ($ - $$) db 0 ; allow the boot signature to be in the last two bytes
dw 0xAA55 ; the boot sig
