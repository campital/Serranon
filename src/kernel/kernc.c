#include "llkernel.h"
unsigned int get_is_x64();

byte console_line_no = 0;

void kernel_c_64()
{
    if(get_physical_address(0x9BFAFA, (unsigned long*)KERNEL_PAGE_BASE) != (unsigned long*)0x9BFAFA)
    {
        panic("PANIC: Paging could not be initialized properly.");
    }
    log("Done!");
}

void log(char string[])
{
    PrintString64(string, console_line_no*80, 0x0007);
    if(console_line_no >= 24)
    {
        console_line_no = 0;
        return;
    }
    console_line_no++;
}
