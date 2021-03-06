#include "llkernel.h"
// base addr must be 4kb aligned
// level 4 pages
// num2mbits is how many 2 mebibyte pages to identity page
void init_paging(struct page_entry* base, unsigned int num2mbitsToInit)
{
    unsigned long base_cast = (unsigned long) base;
    unsigned int maxNumPML4E = (num2mbitsToInit / 262144) + 1;
    unsigned int maxPDEP = (num2mbitsToInit / 512) + 1;
    unsigned int combinedPDEP = 0;
    unsigned int combined2mb = 0;
    for(unsigned int pml4e = 0; pml4e < maxNumPML4E; pml4e++)
    {
        // for pointers to pointers to directories
        struct page_entry pml4entry = {};
        pml4entry.present = 1;
        pml4entry.rw = 1;
        pml4entry.addr = (base_cast + 4096 + (pml4e * 4096)) >> 12;
        base[pml4e] = pml4entry;
        
        for(unsigned int pdep = 0; pdep < 512; pdep++)
        {
            if(combinedPDEP++ >= maxPDEP)
                goto OUTLOOP;
            struct page_entry* PDPELoc = (struct page_entry*)((base_cast + 4096 + (pml4e * 4096)) + pdep*8);
            struct page_entry PDPEntry = {};
            PDPEntry.present = 1;
            PDPEntry.rw = 1;
            PDPEntry.addr = (base_cast + 4096 + 4096*512 + pdep*4096) >> 12;
            *PDPELoc = PDPEntry;
            for(unsigned int mb2count = 0; mb2count < 512; mb2count++)
            {
                if(combined2mb >= num2mbitsToInit)
                    goto OUTLOOP;
                map_page(base_cast, combined2mb, combined2mb, 1, 0, 1);
                combined2mb++;
            }
        }
    }
    OUTLOOP: return;
}

void map_page(unsigned int base, unsigned int virt_page, unsigned int physical_page_mapping, byte is_present, byte is_user_page, byte rw)
{
    struct page_entry_2mb pageEntry = {};
    pageEntry.present = is_present;
    pageEntry.rw = rw;
    pageEntry.ps = 1;
    pageEntry.user = is_user_page;
    pageEntry.addr = physical_page_mapping;
    struct page_entry_2mb* addressOfEntry = (struct page_entry_2mb*)((unsigned long)(base+4096+512*4096+virt_page*8));
    *addressOfEntry = pageEntry;
}

unsigned long* get_physical_address(unsigned long virt_address, unsigned long* base)
{
    unsigned long base_cast = (unsigned long) base;
    unsigned long virt_page = virt_address/0x200000; // page aligned
    unsigned long virt_extra = virt_address%0x200000;
    struct page_entry_2mb *entry = (struct page_entry_2mb*)(base_cast+4096+512*4096+virt_page*8);
    unsigned long return_value = entry->addr;
    return_value *= 0x200000;
    return (unsigned long*)(return_value+virt_extra);
}

//set page base also enters long mode (but still compatibility mode)
void set_page_base(unsigned int phys_address)
{
    __asm__ __volatile__
    ("movq %%cr4, %%rbx\n"
     "orq $0x20, %%rbx\n"
     "movq %%rbx, %%cr4\n"
     "jmp 1f\n"
     "1:\n"
     "movq %%rax, %%cr3\n"
     "jmp 2f\n"
     "2:\n"
     "movq $0xc0000080, %%rcx\n"
     "rdmsr\n"
     "orq $0x100, %%rax\n"
     "wrmsr\n"
     "movq %%cr0, %%rdx\n"
     "movq $0x80000000, %%rbx\n"
     "orq %%rbx, %%rdx\n"
     "movq %%rdx, %%cr0\n"
     "jmp 3f\n"
     "3:\n"
     :
     : "a" (phys_address)
     : "%rbx", "%rdx", "%rcx"
    );
}
