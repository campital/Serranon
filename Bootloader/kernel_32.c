#include "low32.h"

void kernel_c()
{
    PrintString("Entered protected mode.", 0, 0x0107); // clear screen
    console_line_no++; // good practice after direct PrintString call
    // 1024 tables, load the page info at 1MiB
    if(!get_is_x64__32())
    {
        panic__32("PANIC: Processor does not seem to support x64 mode!");
    }
    log__32("Setting up paging...");
    init_paging__32((struct page_entry__32*)KERNEL_PAGE_BASE, 1024);
    //set page base also enters long mode (but still compatibility mode)
    //asm("hlt");
    set_page_base_enter_x64__32(KERNEL_PAGE_BASE, kernel_c_64);
    kernel_c_64();
}

void log__32(char string[])
{
    PrintString(string, console_line_no*80, 0x0007);
    if(console_line_no >= 24)
    {
        console_line_no = 0;
        return;
    }
    console_line_no++;
}

void panic__32(char* error_message)
{
    PrintString(error_message, 0, 0x011F);
    __asm__ __volatile__("hlt");
}

unsigned int get_is_x64__32()
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
