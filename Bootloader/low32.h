#include "../src/kernel/llkernel.h"
struct page_entry_2mb__32
{
   unsigned long long present    : 1;
   unsigned long long rw         : 1;
   unsigned long long user       : 1;
   unsigned long long pwt        : 1;
   unsigned long long pcd        : 1;
   unsigned long long accessed   : 1;
   unsigned long long dirty      : 1;
   unsigned long long ps         : 1;
   unsigned long long global     : 1;
   unsigned long long resvd1     : 3;
   unsigned long long pat        : 1;
   unsigned long long resvd2     : 8;
   unsigned long long addr       : 30;
   unsigned long long resvd      : 12;
   unsigned long long xd         : 1; // execute disable (may not be available or enabled)
}; // for paging
struct page_entry__32
{
   unsigned long long present    : 1;
   unsigned long long rw         : 1;
   unsigned long long user       : 1;
   unsigned long long pwt        : 1;
   unsigned long long pcd        : 1;
   unsigned long long accessed   : 1;
   unsigned long long zero       : 6;
   unsigned long long addr       : 32;
   unsigned long long resvd      : 19;
   unsigned long long xd         : 1; // execute disable (may not be available or enabled)
}; // for paging
void set_page_base_enter_x64__32(unsigned int phys_address, void* x64kernel);
extern void jump_to_x64(void* x64entry); // asm function, jumps to kernel and enables long mode
void map_page__32(unsigned int base, unsigned int virt_page, unsigned int physical_page_mapping, byte is_present, byte is_user_page, byte rw);
void init_paging__32(struct page_entry__32* base, unsigned int num2mbitsToInit);
void log__32(char string[]);
void panic__32(char* error_message);
unsigned int get_is_x64__32();
