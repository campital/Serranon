#include "low32.h"
// base addr must be 4kb aligned
// level 4 pages
// num2mbits is how many 2 mebibyte pages to identity page
void init_paging__32(struct page_entry__32* base, unsigned int num2mbitsToInit)
{
    unsigned int base_cast = (unsigned int) base;
    unsigned int maxNumPML4E = (num2mbitsToInit / 262144) + 1;
    unsigned int maxPDEP = (num2mbitsToInit / 512) + 1;
    unsigned int combinedPDEP = 0;
    unsigned int combined2mb = 0;
    for(unsigned int pml4e = 0; pml4e < maxNumPML4E; pml4e++)
    {
        // for pointers to pointers to directories
        struct page_entry__32 pml4entry = {};
        pml4entry.present = 1;
        pml4entry.rw = 1;
        pml4entry.addr = (base_cast + 4096 + (pml4e * 4096)) >> 12;
        base[pml4e] = pml4entry;
        
        for(unsigned int pdep = 0; pdep < 512; pdep++)
        {
            if(combinedPDEP++ >= maxPDEP)
                goto OUTLOOP;
            struct page_entry__32* PDPELoc = (struct page_entry__32*)((base_cast + 4096 + (pml4e * 4096)) + pdep*8);
            struct page_entry__32 PDPEntry = {};
            PDPEntry.present = 1;
            PDPEntry.rw = 1;
            PDPEntry.addr = (base_cast + 4096 + 4096*512 + pdep*4096) >> 12;
            *PDPELoc = PDPEntry;
            for(unsigned int mb2count = 0; mb2count < 512; mb2count++)
            {
                if(combined2mb >= num2mbitsToInit)
                    goto OUTLOOP;
                map_page__32(base_cast, combined2mb, combined2mb, 1, 0, 1);
                combined2mb++;
            }
        }
    }
    OUTLOOP: return;
}

void map_page__32(unsigned int base, unsigned int virt_page, unsigned int physical_page_mapping, byte is_present, byte is_user_page, byte rw)
{
    struct page_entry_2mb__32 pageEntry = {};
    pageEntry.present = is_present;
    pageEntry.rw = rw;
    pageEntry.ps = 1;
    pageEntry.user = is_user_page;
    pageEntry.addr = physical_page_mapping;
    struct page_entry_2mb__32* addressOfEntry = (struct page_entry_2mb__32*)((unsigned int)(base+4096+512*4096+virt_page*8));
    *addressOfEntry = pageEntry;
}

//set page base also enters long mode (but still compatibility mode)
void set_page_base_enter_x64__32(unsigned int phys_address, void* x64kernel)
{
    __asm__ __volatile__
    ("movl %%cr4, %%ebx\n"
     "orl $0x20, %%ebx\n"
     "movl %%ebx, %%cr4\n"
     "jmp 1f\n"
     "1:\n"
     "movl %%eax, %%cr3\n"
     "jmp 2f\n"
     "2:\n"
     "movl $0xc0000080, %%ecx\n"
     "rdmsr\n"
     "orl $0x100, %%eax\n"
     "wrmsr\n"
     "movl %%cr0, %%edx\n"
     "movl $0x80000000, %%ebx\n"
     "orl %%ebx, %%edx\n"
     "movl %%edx, %%cr0\n"
     "jmp 3f\n"
     "3:\n"
     :
     : "a" (phys_address)
     : "%ebx", "%edx", "%ecx"
    );
    jump_to_x64(x64kernel);
}
