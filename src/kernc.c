void kernel_c()
{
    unsigned char* single_character = (unsigned char *)0xB8000;
    *single_character = 'B';
}
