#include "llkernel.h"
#define KERNEL_PAGE_TABLE 0x00101000
#define KERNEL_PAGE_DIRECTORY 0x00100000

byte console_line_no = 0;

void kernel_c()
{
    PrintString("Entered protected mode.", 0, 0x0107); // clear screen
    console_line_no++; // good practice after direct PrintString call
    // 1024 tables, load the page info at 1MiB
    log("Setting up paging...");
    init_paging((unsigned int*)KERNEL_PAGE_TABLE, (unsigned int*)KERNEL_PAGE_DIRECTORY, 1024);
    set_page_directory((unsigned int*)KERNEL_PAGE_DIRECTORY);
    log("Done!");
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
