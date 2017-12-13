BITS 16
%define GDT_START 0x800
%define NUM_GDT_ENTRIES 5 ; MUST CHANGE THIS=======IMPORTANT=======
%define IDT_START 0
%macro ISR_NOERRCODE 1 ; this macro part is taken from jamesmolloy.co.uk
    ; I wasn't very familiar with macros
  isr%1:
    cli
    push dword 0
    mov byte [temp_isr_code], %1
    jmp HandleInterrupt
%endmacro

%macro ISR_ERRCODE 1
  isr%1:
    cli
    mov byte [temp_isr_code], %1
    jmp HandleInterrupt
%endmacro
GLOBAL start ; for the linker script
GLOBAL PrintString
EXTERN kernel_c ; the c part of the kernel
EXTERN init_paging ; sets up page dir and tables
EXTERN page_fault_handler ; c handler
start:
    mov esi, 0 ; base
    mov [GDT_START], esi
    mov [GDT_START+4], esi ; create null entry
    mov edi, 0xFFFFFFFF ; limit
    
    mov al, 0b10010010 ; ring level 0, data segment
    mov bx, 8 ; had a null entry
    call AddGDTEntry ; add it
    
    mov al, 0b10011010 ; ring level 0, code segment
    add bx, 8
    call AddGDTEntry ; add it
    
    mov al, 0b11110010 ; ring level 3, data segment
    add bx, 8
    call AddGDTEntry ; add it

    mov al, 0b11111010 ; ring level 3, code segment
    add bx, 8
    call AddGDTEntry ; add it
    
    mov word [gdt_register], (NUM_GDT_ENTRIES*8)-1 ; 8 bytes per entry low bits
    mov dword [gdt_register+2], GDT_START ; high bits
    ; remapping and masking the PIC. Master PIC is at IO port 0x20 and slave is at 0xA0
    mov al, 0x11
    out 0x20, al ; init master (in case bios doesn't)
    call .wait_a_second ; waste time
    out 0xA0, al ; init slave
    call .wait_a_second ; waste time
    
    mov al, 32
    out 0x21, al ; start at idt 32, isrs at 0-31
    call .wait_a_second
    mov al, 40
    out 0xA1, al ; after other one
    call .wait_a_second
    
    mov al, 4
    out 0x21, al ; identify each other
    call .wait_a_second
    mov al, 2
    out 0xA1, al
    call .wait_a_second
    
    mov al, 1
    out 0x21, al ; finish initializing
    call .wait_a_second
    out 0xA1, al
    call .wait_a_second
    
    mov al, 0xFF ; mask all interrupts from the PICs CHANGE IF USING HARDWARE INTERRUPTS=======================================IMPORTANT=======================================
    out 0x21, al
    call .wait_a_second
    out 0xA1, al
    call .wait_a_second
    
    jmp .done_wait
    .wait_a_second:
        ret
    .done_wait:
    
    lgdt [gdt_register] ; load it

    mov eax, cr0
    or eax, 1
    mov cr0, eax ; enable protected mode
    jmp 16:ProtectedMode ; set cs to 16 (2nd not null entry)

; parameters: esi: base, edi: limit, al: access, bx: offset
AddGDTEntry:
    push bx ; preserve
    push esi
    push edi
    push ax
    mov word [GDT_START + bx], di ; mov the lower 16 bits of edi into gdt entry
    add bx, 2 ; 2 bytes
    
    mov word [GDT_START + bx], si ; move low 16 bits of base in
    add bx, 2
    
    mov ecx, esi ; preserve esi
    shr ecx, 16 ; get just the next 8 bits into cl
    mov byte [GDT_START + bx], cl ; move the middle byte in
    inc bx ; only one byte
    
    mov byte [GDT_START + bx], al ; move the access parameters in (ring level, segment type)
    inc bx ; one byte
    
    mov byte [GDT_START + bx], 0b11001111 ; 1KB granularity, high 4 bytes of limit (CHANGE IF NOT FFFF...)=======IMPORTANT=======
    inc bx ; one byte
    
    mov byte [GDT_START + bx], ch ; already in ch
    pop ax
    pop edi
    pop esi
    pop bx
    ret

EnableA20: ; see if the 21st bit of addressing is enables for protected mode, make sure to STI after
    cli
    mov bx, 0
    jmp .testA20 ; test and fix
.enableA20:
    ; zero is bios, here
    cmp bx, 1
    je .kbdA20
    cmp bx, 2
    je .fastA20 ; fast
    cmp bx, 3
    je .unavailable ; endless loop
    
    mov     ax,2403h ; is bios a20 supported
    int     15h
    mov bx, 1 ; for 8042 chip attempt
    jb      .testA20
    cmp     ah,0
    jnz     .testA20
    
    mov ax,2401h ; enable 
    int 15h
    mov bx, 1 ; for 8042 chip attempt (bios may have edited bx)
    jb .testA20 ; bios was unable to find a method of enabling a20 gate
    cmp ah,0
    jnz .testA20

    jmp .testA20
.testA20: ; if bx = 0, do bios, bx = 1, do kbd, if bx = 2, then do fast a20 after, if bx = 3, error
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
.kbdA20:
    call .wait_cmd ; wait for start
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
    mov bx, 2 ; fast after this
    jmp .testA20
.fastA20:
    in al, 0x92
    or al, 2
    out 0x92, al ; other A20 enable
    mov bx, 3
    jmp .testA20
.unavailable:
    mov bp, A20_error
    call BIOSPrintString
    jmp $

BIOSPrintString: ; location of string is in bp ==FROM BOOTLOADER==
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

BITS 32
ProtectedMode:
    mov ax, 8 ; data segment
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    cld ; direction up
    mov ax, 0
    mov edi, 0
    mov ecx, 0x800 ; fill up the idt with zeroes
    rep stosb ; blast the bits
    
    mov ebx, 0
    mov ecx, 0 ; for now
    mov edx, 16 ; code segment selector is at 16 offset
    mov eax, isr0
    call CreateIDTEntry ; call 0
    mov eax, isr1
    call CreateIDTEntry ; call 1
    mov eax, isr2
    call CreateIDTEntry ; call 2
    mov eax, isr3
    call CreateIDTEntry ; call 3
    mov eax, isr4
    call CreateIDTEntry ; call 4
    mov eax, isr5
    call CreateIDTEntry ; call 5
    mov eax, isr6
    call CreateIDTEntry ; call 6
    mov eax, isr7
    call CreateIDTEntry ; call 7
    mov eax, isr8
    call CreateIDTEntry ; call 8
    mov eax, isr9
    call CreateIDTEntry ; call 9
    mov eax, isr10
    call CreateIDTEntry ; call 10
    mov eax, isr11
    call CreateIDTEntry ; call 11
    mov eax, isr12
    call CreateIDTEntry ; call 12
    mov eax, isr13
    call CreateIDTEntry ; call 13
    mov eax, isr14
    call CreateIDTEntry ; call 14
    mov eax, isr15
    call CreateIDTEntry ; call 15
    mov eax, isr16
    call CreateIDTEntry ; call 16
    mov eax, isr17
    call CreateIDTEntry ; call 17
    mov eax, isr18
    call CreateIDTEntry ; call 18
    mov eax, isr19
    call CreateIDTEntry ; call 19
    mov eax, isr20
    call CreateIDTEntry ; call 20
    mov eax, isr21
    call CreateIDTEntry ; call 21
    mov eax, isr22
    call CreateIDTEntry ; call 22
    mov eax, isr23
    call CreateIDTEntry ; call 23
    mov eax, isr24
    call CreateIDTEntry ; call 24
    mov eax, isr25
    call CreateIDTEntry ; call 25
    mov eax, isr26
    call CreateIDTEntry ; call 26
    mov eax, isr27
    call CreateIDTEntry ; call 27
    mov eax, isr28
    call CreateIDTEntry ; call 28
    mov eax, isr29
    call CreateIDTEntry ; call 29
    mov eax, isr30
    call CreateIDTEntry ; call 30
    mov eax, isr31
    call CreateIDTEntry ; call 31

    mov word [idt_register], (256*8)-1
    mov dword [idt_register + 2], 0
    lidt [idt_register] ; done!
    mov al, 10
    mov dx, 0x03D4
    out dx, al
    mov al, 0x20 ; disable cursor
    mov dx, 0x03D5
    out dx, al
    
    call kernel_c ; enter c kernel
    
    hlt ; halt
    
CreateIDTEntry: ; parameters: eax: base, ebx: offset into table (in bytes), ecx: priviledge ring called from, edx: cs selector (ring 0)
    push eax
    push ecx
    push edx
    mov word [IDT_START + ebx], ax ; low 16 base
    add ebx, 2
    mov word [IDT_START + ebx], dx ; selector
    add ebx, 2
    mov byte [IDT_START + ebx], 0 ; reserved
    inc ebx
    mov dl, 0b10001110 ; flags
    shl cl, 5
    or dl, cl ; combine
    mov byte [IDT_START + ebx], dl ; push flags
    inc ebx
    shr eax, 16 ; get high bits
    mov word [IDT_START + ebx], ax
    add ebx, 2
    pop edx
    pop ecx
    pop eax
    ret
    
HandleInterrupt:
    pushad ; push 32 bit registers
    mov ax, ds
    push ax
    mov ax, 8 ; data segment
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    cmp byte [temp_isr_code], 0x0E
    je .isPageFault ; special code
    xor edx, edx ; clear the upper bits if edx
    mov byte dl, [temp_isr_code]
    and dl, 0xF0 ; get the high 4 bits
    shr dl, 4 ; push down
    mov dl, [hex_lookup+edx]
    mov byte [bsod_string+bsod_len-3], dl ; should get to the hex code (may need to change if bsod string is changed)
    xor edx, edx ; clear the upper bits if edx
    mov byte dl, [temp_isr_code] ; replenish
    and dl, 0x0F ; get the low 4 bits
    mov dl, [hex_lookup+edx]
    mov byte [bsod_string+bsod_len-2], dl
    push dword 0x011F ; all at once
    push dword 0 ; no offset
    push dword bsod_string ; cls and write the string
    call PrintString
    add esp, 8
    hlt
    
    pop ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    popad
    add esp, 4
    ; pops eflags, no need for sti
    iret
.isPageFault:
    mov eax, cr2
    push eax ; can't push cr2 directly
    call page_fault_handler ; c code
    add esp, 4
    hlt ; maybe not hlt later

PrintString: ; args (char* string, short offset, short colorClear); COLORCLEAR: ex - 0x0107 is normal colors and clear screen
; in asm, push all as dwords
; 0x0007 would be no clear, normal colors
    pushad
    add esp, 36 ; account for pushad and call instruction (32 + 4)
    pop dword ecx ; string location
    pop dword ebx
    shl ebx, 16 ; move to high half
    pop dword edx ; temp, for V ABI stack thing
    mov bx, dx
    xchg bl, bh ; flip byte order
    sub esp, 36+12 ; make sure c can pop it off (sub esp, 36+12<-lengthofargs)====IMPORTANT====
    
    cmp bl, 1
    je .fill_screen
.continue:
    mov byte ah, bh ; color
    mov edi, 0xB8000
    push ebx
    shr ebx, 16
    lea ebx, [ebx*2]
    add edi, ebx ; add offset
    pop ebx
    cld
    xor edx, edx
    xor esi, esi
.loooop:
    mov byte al, [ecx+esi]
    inc esi
    cmp al, 0
    je .done
    cmp al, 10 ; if it is a line ending
    je .end_line
    mov word [edi+edx*2], ax
    inc edx
    jmp .loooop
.fill_screen:
    pushad
    mov ah, bh
    mov al, 0
    mov edi, 0xB8000
    mov ecx, 2000
    rep stosw
    popad
    jmp .continue
.end_line:
    push ecx
    push eax
    push ebx
    
    push edx
    shr ebx, 16
    add edx, ebx ; add offset to edx for modulo
    mov eax, edx ; get ready for div
    xor edx, edx ; ready
    mov ebx, 80
    div ebx ; screen is 80 chars wide
    sub ebx, edx ; get how many chars to EOL
    pop edx
    add edx, ebx
    
    pop ebx
    pop eax
    pop ecx
    jmp .loooop
.done:
    popad
    ret
    
    
ISR_NOERRCODE 0
ISR_NOERRCODE 1
ISR_NOERRCODE 2
ISR_NOERRCODE 3
ISR_NOERRCODE 4
ISR_NOERRCODE 5
ISR_NOERRCODE 6
ISR_NOERRCODE 7
ISR_ERRCODE 8
ISR_NOERRCODE 9
ISR_ERRCODE 10
ISR_ERRCODE 11
ISR_ERRCODE 12
ISR_ERRCODE 13
ISR_ERRCODE 14
ISR_NOERRCODE 15
ISR_NOERRCODE 16
ISR_NOERRCODE 17
ISR_NOERRCODE 18
ISR_NOERRCODE 19
ISR_NOERRCODE 20
ISR_NOERRCODE 21
ISR_NOERRCODE 22
ISR_NOERRCODE 23
ISR_NOERRCODE 24
ISR_NOERRCODE 25
ISR_NOERRCODE 26
ISR_NOERRCODE 27
ISR_NOERRCODE 28
ISR_NOERRCODE 29
ISR_NOERRCODE 30
ISR_NOERRCODE 31

done_string db 'Done!', 0
gdt_register dq 0
temp_isr_code db 0
idt_register dq 0
A20_error db 'Error while enabling gate 20! Try again or report a bug.', 0
hex_lookup db '0123456789ABCDEF', 0 ; for blue screen of death
bsod_string db 'Serranon OS has encountered an error...', 10, 'Your computer will now restart.', 10, 'Technical information:', 10, 'ISR RECIEVED AT VECTOR: 0x00', 0 ; adjust the vector number
bsod_len equ $-bsod_string
