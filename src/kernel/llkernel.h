typedef unsigned char byte;
typedef unsigned short word;
typedef unsigned int dword;
typedef unsigned long qword;
#define HEX_LOOKUP(i) "0123456789ABCDEF"[i]
#define REVERSE_BYTE_ORDER32(b) (b>>24 & 0x000000FF) | (b>>8 & 0x0000FF00) | (b<<8 & 0x00FF0000) | (b<<24 & 0xFF000000)
extern void PrintString(char* string, word offset, word colorClear); // asm function
void init_paging(unsigned int* tablesBaseAddr, unsigned int* directoryBaseAddr, unsigned int numTablesToInit);
void set_page_directory(unsigned int* address);
void log(char string[]);
extern byte console_line_no;
struct page_entry
{
   int present    : 1;
   int rw         : 1;
   int user       : 1;
   int accessed   : 1;
   int written    : 1;
   int zero       : 7;
   int page_addr  : 20;
}; // for paging
