#include "llkernel.h"
#define KERNEL_PAGE_BASE 0x00100000
unsigned int get_is_x64();

byte console_line_no = 0;

void kernel_c()
{
    PrintString("Entered protected mode.", 0, 0x0107); // clear screen
    console_line_no++; // good practice after direct PrintString call
    // 1024 tables, load the page info at 1MiB
    if(!get_is_x64())
    {
        panic("PANIC: Processor does not seem to support x64 mode!");
    }
    log("Setting up paging...");
    init_paging((struct page_entry*)KERNEL_PAGE_BASE, 1024);
    //set page base also enters long mode (but still compatibility mode)
    set_page_base(KERNEL_PAGE_BASE);
    if(get_physical_address(0x9BFAFA, (unsigned int*)KERNEL_PAGE_BASE) != (unsigned int*)0x9BFAFA)
    {
        panic("PANIC: Paging could not be initialized properly.");
    }
    log("Done!");
}

unsigned int get_is_x64()
{
    unsigned int result;
    __asm__ __volatile__
    (
        "mov $0x80000000, %%eax\n" // cpuid is 64 bit allowed
        "cpuid\n"
        : "=a" (result)
        :: "%ebx", "%ecx", "%edx"
    );
    if(result < 0x80000001)
        return 0;
    __asm__ __volatile__
    (
        "mov $0x80000001, %%eax\n" // cpuid is 64 bit allowed
        "cpuid\n"
        : "=d" (result)
        :: "%eax", "%ebx", "%ecx"
    );
    return (result >> 29) & 0x01;
}

void log(char string[])
{
    PrintString(string, console_line_no*80, 0x0007);
    if(console_line_no >= 24)
    {
        console_line_no = 0;
        return;
    }
    console_line_no++;
}
