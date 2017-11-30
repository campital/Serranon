ORG 0x7F00
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
    int 0 ; just a test to make sure the CPU is ok
    
    mov al, 10
    mov dx, 0x03D4
    out dx, al
    mov al, 0x20 ; disable cursor
    mov dx, 0x03D5
    out dx, al
    
    mov ecx, booted_string ; cls and write the string
    xor ebx, ebx
    mov bh, 0x07
    mov bl, 1
    call PrintString
    
    jmp $ ; infinite loop
    
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
    
    ; TODO: bsod
    
    pop ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    popad
    add esp, 4
    sti
    iret

PrintString: ; args: ECX: string location, ebx: high 16 - offset(in bytes) || bh - color and bl = 1 if reset whole screen
    pushad
    cmp bl, 1
    je .fill_screen
.continue:
    mov byte ah, bh ; color
    mov edi, 0xB8000
    push ebx
    shr ebx, 16
    add edi, ebx ; add offset
    pop ebx
    cld
    xor edx, edx
.loooop:
    mov byte al, [ecx+edx]
    cmp al, 0
    je .done
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
booted_string db 'Hello from protected mode!', 0
