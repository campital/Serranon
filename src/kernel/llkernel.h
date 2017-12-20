typedef unsigned char byte;
typedef unsigned short word;
typedef unsigned int dword;
typedef unsigned long qword;
#define HEX_LOOKUP(i) "0123456789ABCDEF"[i]
#define REVERSE_BYTE_ORDER32(b) (b>>24 & 0x000000FF) | (b>>8 & 0x0000FF00) | (b<<8 & 0x00FF0000) | (b<<24 & 0xFF000000)
struct page_entry_2mb
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
struct page_entry
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
extern void PrintString(char* string, word offset, word colorClear); // asm function
void init_paging(struct page_entry* base, unsigned int num2mbitsToInit);
void set_page_base(unsigned int phys_address);
unsigned int* get_physical_address(unsigned int virt_address, unsigned int* base);
void map_page(unsigned int base, unsigned int virt_page, unsigned int physical_page_mapping, byte is_present, byte is_user_page, byte rw);
void panic(char* error_message);
void log(char string[]);
extern byte console_line_no;
