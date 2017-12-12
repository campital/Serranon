#include "llkernel.h"

void kernel_c()
{
    PrintString("Hello from protected mode!", 0, 0x0107);
}

//base addr must be 4kb aligned
void init_paging(struct page_entry* baseAddr, unsigned int numTablesToInit) // is called from assembly code, single block of memory, directory first, then page tables. Identity page
{
    unsigned int baseAddr_int = (unsigned int)baseAddr;
    for(unsigned int i = 0; i < numTablesToInit; i++)
    {
        // filling up the page directory
        unsigned int dir_addr = baseAddr_int+4096+i*4096;
        dir_addr &= 0xFFFFF000;
        struct page_entry dir_entry = {};
        dir_entry.present = 1;
        dir_entry.rw = 1;
        dir_entry.page_addr = dir_addr>>12;
        baseAddr[i] = dir_entry;
    }
    //initialize identity pages
    unsigned int value = 0;
    for(unsigned int i = 0; i < numTablesToInit; i++)
    {
        for(unsigned int b = 0; b < 1024; b++)
        {
                struct page_entry* page_entry_addr = (struct page_entry*)((baseAddr_int+4096)+(i*4096+b*4)); // one int is 4 bytes
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
