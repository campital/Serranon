#include "llkernel.h"

//base addr must be 4kb aligned
// is called from assembly code, single block of memory, directory first, then page tables. Identity page
void init_paging(unsigned int* tablesBaseAddr, unsigned int* directoryBaseAddr, unsigned int numTablesToInit)
{
    unsigned int tableBaseAddr_int = (unsigned int)tablesBaseAddr;
    for(unsigned int i = 0; i < numTablesToInit; i++)
    {
        // filling up the page directory
        unsigned int dir_addr = tableBaseAddr_int+i*4096;
        dir_addr &= 0xFFFFF000;
        struct page_entry dir_entry = {};
        dir_entry.present = 1;
        dir_entry.rw = 1;
        dir_entry.page_addr = dir_addr>>12;
        ((struct page_entry*)directoryBaseAddr)[i] = dir_entry;
    }
    //initialize identity pages
    unsigned int value = 0;
    for(unsigned int i = 0; i < numTablesToInit; i++)
    {
        for(unsigned int b = 0; b < 1024; b++)
        {
                struct page_entry* page_entry_addr = (struct page_entry*)(tableBaseAddr_int+(i*4096+b*4)); // one int is 4 bytes
                // identity page
                struct page_entry page_entry_s = {};
                page_entry_s.present = 1;
                page_entry_s.rw = 1;
                page_entry_s.page_addr = value;
                *page_entry_addr = page_entry_s; // supervisor page
                value++;
        }
    }
}

void set_page_directory(unsigned int* address)
{
    asm volatile
    ("movl %%eax, %%cr3\n"
     "movl %%cr0, %%ebx\n"
     "orl $0x80000000, %%ebx\n"
     "movl %%ebx, %%cr0\n"
     :
     : "a" (address)
     : "%ebx"
    );
}
