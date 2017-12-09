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
dw 256 ; number of root directory entries (32 bits for one short or long entry, 16 sectors)
dw 1440 ; how many logical sectors, so 1440 * 512 = 737280 bytes we can use
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
    cli ; disable interrupts
    mov ax, 0
    mov ss, ax; can't move direct value to ss, using ss so stack has a bottom
    mov sp, 0x7BFA ; move the stack to just before the bootloader (6 bytes?)
    sti ; restore them interrupts
    
    mov [disknumber], dl ; the bios should put the boot device number into dl
    mov ax, 0
    mov ds, ax ; reset data segment because we are using ORG
    
    mov ah, 2 ; set cursor pos
    mov bh, 0 ; no page number
    mov dh, 0
    mov dl, 0 ; col 0 row 0
    int 0x10 ; set pos
    
    mov bp, print_str
    call PrintString ; loading has begun
    call LoadKernel
    call EnableA20
    sti ; after enablea20
    jmp 0x7F00 ; execute the kernel code, still in real mode    

PrintString: ; location of string is in bp
    xor cx, cx ; set cx to 0
.loop:
    mov bx, cx
    add bx, bp
    mov al, [bx] ; char to print
    
    cmp al, 0
    je .done ; if the string is not terminated or longer than max string length, continue, or else ret
    
    mov ah, 0x0E ; print mode
    mov bl, 0 ; Colors don't seem to be working
    mov bh, 0 ; we dont need to set the page mode
    int 0x10 ; print the char
    inc cx ; increment the counter
    cmp cx, 200 ; max string length
    je .done
    jmp .loop
.done:
    ret

LoadKernel: ; FirstRootDirSecNum = BPB_ResvdSecCnt (1) + (BPB_NumFATs (2) * BPB_FATSz16 (16)) = 33 (16 secs for root directory)
    xor ah, ah ; for drive reset
    int 13h
    
    mov dl, [disknumber] ; set number to get info from
    mov ax, 0
    mov es, ax
    mov di, ax ; fix bugs
    mov ah, 8 ; code for get drive info
    clc
    int 0x13
    
    push cx
    and cx, 0x003F ; isolate the low 6 bits of cx; sectors per track
    mov [sectors_per_track], cx ; choose the sectors per track
    pop cx
    
    mov [hdd_head_amt], dh
    
    mov ax, 33 ; 33 is where the data starts
    mov bl, 16 ; read 16 sectors
    call LoadFileFromSector ; load
    
    mov si, 0x7EE0 ; 32 bytes before start of buffer
    mov di, kern_filename
    mov ax, si
    mov bx, di ; backup
.compare:
    add ax, 32
    mov si, ax
    mov di, bx
    mov cx, 9 ; the string is 9 bytes long
    rep cmpsb ; compare
    jne .compare
    
    mov si, ax ; reset
    xor dx, dx
    mov word ax, [si+28] ; length of file in bytes
    add ax, 512 ; +1
    mov bx, 512
    div bx ; divide 512
    mov bl, al ; result into number of sectors to read
    mov ax, [si+26] ; move the file location into here
    add ax, 47 ; put it at the start of data
    call LoadFileFromSector
    
    ret ; return

LoadFileFromSector: ; ax = sector number bl=number of sectors to read into 0x7F00
    inc ax ; muy neccesito
    xor bh, bh ; set bh to 0
    push bx ; save for later
    xor dx, dx ; set dx to zero for division
    div word [sectors_per_track] ; get number of sectors
    and dx, 0x003F ; should already be
    mov cx, dx
    
    xor dx, dx ; set dx to zero
    cmp ax, 0
    je .zero
    ; award for most time spent on a single line:
    div word [hdd_head_amt] ; track number is already in ax head number is found using a modulo formula
    jmp .normal
.zero:
    mov dx, ax ; ax is number of tracks
    xor ax, ax ; head number if 0 = 0
.normal:
    mov bx, ax ; extra register
    shl bx, 6 ; give space for sector number that is already in cx
    or cx, bx ; combine the track number into cx
    mov dh, dl ; should move the head number to dh
    
    pop ax ; put old bl into al
    mov ah, 2 ; read sector
    ; already have track number
    ; already have sector number
    ; already have head number
    mov dl, [disknumber]
    xor bx, bx ; set bx to 0
    mov es, bx ; just to make sure
    mov bx, 0x7F00 ; where to load 
    clc
    int 0x13 ; LOAD!
    jc .error
    ret
.error:
    mov bp, hd_error
    call PrintString
    jmp $ ; endless loop

EnableA20: ; see if the 21st bit of addressing is enables for protected mode, make sure to STI after
    cli
    mov bx, 0
    jmp .testA20 ; test and fix
.enableA20:
    cmp bx, 1
    je .fastA20 ; fast
    cmp bx, 2
    je .unavailable ; endless loop
    call .wait_cmd ; wait for finish
    mov al,0xAD ; disable kbd for a20 commands
    out 0x64,al
 
    call .wait_cmd ; wait for command to register
    mov al,0xD0 ; read command
    out 0x64,al
 
    call .wait_data
    in al,0x60 ; read
    push eax
 
    call .wait_cmd
    mov al,0xD1 ; write command
    out 0x64,al            
 
    call .wait_cmd
    pop eax ; reflect data back
    or al,2
    out 0x60,al
 
    call .wait_cmd
    mov al,0xAE ; re-enable 8042 kbd
    out 0x64,al
 
    call .wait_cmd ; final
    mov bx, 1 ; test after this
.testA20: ; if bx = 1, then do fast a20 after, if bx = 2, crash if not a20
    xor ax, ax
    mov es, ax
    mov byte [es:0x0510], 0x00 ; clear for testing
    push word [es:0x0510] ; so we dont mess up
    mov ax, 0xFFFF
    mov es, ax
    mov byte [es:0x0510], 0xCC ; byte to test
    push word [es:0x0510]
    xor ax, ax
    mov es, ax
    cmp byte [es:0x0510], 0xCC ; compare to see if gate 20 is enabled
    pushf ; in case restore changes flags
    mov ax, 0xFFFF
    mov es, ax
    pop word [es:0x0510]
    xor ax, ax
    mov es, ax
    pop word [es:0x0510] ; restore
    popf
    je .enableA20 ; if it wrapped around, enable a20
    ret ; if enabled, return
.wait_cmd:
    in al,0x64
    test al,2
    jnz .wait_cmd
    ret
.wait_data:
    in al,0x64
    test al,1
    jz .wait_data
    ret
.fastA20:
    in al, 0x92
    or al, 2
    out 0x92, al
    mov bx, 2
    jmp .testA20
.unavailable:
    mov bp, hd_error
    call PrintString
    jmp $
    
print_str db 'Loading...', 0 ; 0 is the standard termination
hd_error db 'A20/HDD Error!', 0
kern_filename db 'KERN    X', 0 ; we will be searching for the short entry in the root directory "FAT"
disknumber db 0
hdd_head_amt db 0
sectors_per_track dw 0
times 510 - ($ - $$) db 0 ; allow the boot signature to be in the last two bytes
dw 0xAA55 ; the boot sig
