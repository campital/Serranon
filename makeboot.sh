if test "`whoami`" != "root" ; then
	echo "You do not have sudo privileges!"
	exit
fi

rm Serranon.img
cd Bootloader
nasm -fbin bootload.asm -o bootload.x

cd ..
cd src
for i in *.asm
do
nasm -fbin $i -o `basename $i .asm`.x
done

cd ..
dd if=/dev/zero of=Serranon.img bs=4194304 count=1
dd status=noxfer conv=notrunc if=Bootloader/bootload.x of=Serranon.img bs=512
mkdir programs_temp
mount -o loop Serranon.img programs_temp
sleep .01
cp src/kern.x programs_temp/
sleep .01
umount programs_temp
rm -rf programs_temp
