#!/bin/sh

#clear past stuff
rm -f bin/*

if [ ! -e disk ]
then
	mkdir -p disk || exit
fi

if [ ! -e bin ]
then
	mkdir -p bin || exit
fi

echo "ASSEMBLY :: Bootloader"
nasm -O0 -fbin -t -Wall src/boot/boot.asm -o bin/boot.sys
nasm -O0 -fbin -t -Wall src/kernel/kernel.asm -o bin/kernel.sys

if [ ! -e disk/pluto.flp ]
then
	mkdosfs -C disk/pluto.flp 1440 || exit
fi

dd conv=notrunc if=bin/boot.sys of=disk/pluto.flp || exit
rm -rf tmp-loop
mkdir tmp-loop
mount -o loop -t vfat disk/pluto.flp tmp-loop
rm -f bin/boot.sys

cp bin/* tmp-loop || exit

sleep 0.2
umount tmp-loop || exit
rm -rf tmp-loop

echo ":: End"
