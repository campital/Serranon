typedef unsigned char byte;
typedef unsigned short word;
typedef unsigned int dword;
typedef unsigned long qword;
#define HEX_LOOKUP(i) "0123456789ABCDEF"[i]
#define REVERSE_BYTE_ORDER32(b) (b>>24 & 0x000000FF) | (b>>8 & 0x0000FF00) | (b<<8 & 0x00FF0000) | (b<<24 & 0xFF000000)
#define KERNEL_PAGE_BASE 0x00100000
struct page_entry_2mb
{
   unsigned long present    : 1;
   unsigned long rw         : 1;
   unsigned long user       : 1;
   unsigned long pwt        : 1;
   unsigned long pcd        : 1;
   unsigned long accessed   : 1;
   unsigned long dirty      : 1;
   unsigned long ps         : 1;
   unsigned long global     : 1;
   unsigned long resvd1     : 3;
   unsigned long pat        : 1;
   unsigned long resvd2     : 8;
   unsigned long addr       : 30;
   unsigned long resvd      : 12;
   unsigned long xd         : 1; // execute disable (may not be available or enabled)
}; // for paging
struct page_entry
{
   unsigned long present    : 1;
   unsigned long rw         : 1;
   unsigned long user       : 1;
   unsigned long pwt        : 1;
   unsigned long pcd        : 1;
   unsigned long accessed   : 1;
   unsigned long zero       : 6;
   unsigned long addr       : 32;
   unsigned long resvd      : 19;
   unsigned long xd         : 1; // execute disable (may not be available or enabled)
}; // for paging
extern void PrintString64(char* string, word offset, word colorClear); // asm function
extern void PrintString(char* string, word offset, word colorClear); // asm function
void init_paging(struct page_entry* base, unsigned int num2mbitsToInit);
void set_page_base(unsigned int phys_address);
unsigned long* get_physical_address(unsigned long virt_address, unsigned long* base);
void map_page(unsigned int base, unsigned int virt_page, unsigned int physical_page_mapping, byte is_present, byte is_user_page, byte rw);
void panic(char* error_message);
void log(char string[]);
void kernel_c_64();
extern byte console_line_no;
