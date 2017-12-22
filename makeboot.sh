if test "`whoami`" != "root" ; then
	echo "You do not have sudo privileges!"
	exit
fi

rm Serranon.img
cd Bootloader
nasm -fbin bootload.asm -o bootload.x

cd ..
cd src/kernel
for i in *.asm
do
nasm -felf64 $i -o ../kernel_bin/`basename $i .asm`.o
done
for i in *.c
do
gcc $i -o ../kernel_bin/`basename $i .c`.o -Wall -O3 -fstrength-reduce -fomit-frame-pointer -finline-functions -fno-stack-protector -nostdinc -fno-builtin -fno-pie -c
done
echo "Done compiling main c kernel."
cd ../../Bootloader
for i in *.c
do
gcc $i -o `basename $i .c`.o -Wall -O3 -m32 -fstrength-reduce -fomit-frame-pointer -finline-functions -fno-stack-protector -nostdinc -fno-builtin -fno-pie -c
done
objcopy -O elf64-x86-64 kernel_32.o kernel_32.o
objcopy -O elf64-x86-64 paging_32.o paging_32.o
cd ..
echo "Done compiling early 32 bit kernel."
ld -T c_link.ld -o kern.x src/kernel_bin/kern.o src/kernel_bin/kernc.o src/kernel_bin/exceptions.o src/kernel_bin/paging.o Bootloader/paging_32.o Bootloader/kernel_32.o
dd if=/dev/zero of=Serranon.img bs=737280 count=1
dd status=noxfer conv=notrunc if=Bootloader/bootload.x of=Serranon.img bs=512
mkdir programs_temp
mount -o loop Serranon.img programs_temp
sleep .01
cp kern.x programs_temp/
sleep .01
umount programs_temp
rm -rf programs_temp
