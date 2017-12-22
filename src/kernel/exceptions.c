#include "llkernel.h"

char pageFaultString[] = "Serranon OS has encountered an error...\nPage fault at address: 0x        ";

// page fault handler is set up in assembly(kern.asm)
// possibly terminate program?
void page_fault_handler(unsigned long cr2)
{
    for(int i = 0; i < 8; i++)
    {
        char* hexLocation = (char*)(pageFaultString + sizeof(pageFaultString) - i - 2); // instead of 8, because null terminated
        *hexLocation = HEX_LOOKUP((cr2>>(i*4)) & 0xF);
    }
    PrintString64(pageFaultString, 0, 0x011F);
}

void panic(char* error_message)
{
    PrintString64(error_message, 0, 0x011F);
    __asm__ __volatile__("hlt");
}
