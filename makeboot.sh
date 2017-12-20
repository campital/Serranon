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
nasm -felf $i -o ../kernel_bin/`basename $i .asm`.o
done
for i in *.c
do
gcc $i -o ../kernel_bin/`basename $i .c`.o -Wall -O3 -fstrength-reduce -m32 -fomit-frame-pointer -finline-functions -fno-stack-protector -nostdinc -fno-builtin -fno-pie -c
done
cd ../..
ld -T c_link.ld -m elf_i386 -o kern.x src/kernel_bin/kern.o src/kernel_bin/kernc.o src/kernel_bin/exceptions.o src/kernel_bin/paging.o
dd if=/dev/zero of=Serranon.img bs=737280 count=1
dd status=noxfer conv=notrunc if=Bootloader/bootload.x of=Serranon.img bs=512
mkdir programs_temp
mount -o loop Serranon.img programs_temp
sleep .01
cp kern.x programs_temp/
sleep .01
umount programs_temp
rm -rf programs_temp
