if test "`whoami`" != "root" ; then
	echo "You do not have sudo privileges!"
	exit
fi
sudo qemu-system-i386 Serranon.img -m 512M -d guest_errors -monitor stdio
