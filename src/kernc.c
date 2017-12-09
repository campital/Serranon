typedef char byte;
void kernel_c()
{
    
}

void init_paging(unsigned int* baseAddr) // is called from assembly code, single block of memory, directory first, then page tables
{
    for(unsigned int i = 0; i < 1024; i++)
    {
        // filling up the page directory
        baseAddr[i] = (unsigned int)baseAddr+4096+i*4096;
    }
    unsigned int* currentPageTableStartAddr = baseAddr+4096;
    
}
