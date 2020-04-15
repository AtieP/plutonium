#    Plutonium Makefile. Copyright (C) 2020 Plutonium Contributors
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Makefile for Plutonium

BIN_DIR = bin
SRC_DIR = src
DSK_DIR = disk

AA = nasm
AFLAGS = -Wall -f bin -O0

# Main targets
compile: $(DSK_DIR)/pluto.flp

run: $(DSK_DIR)/pluto.flp
	qemu-system-i386 -fda $< -m 8M -soundhw pcspk -serial mon:stdio
	
reset:
	mkdosfs -C disk/pluto.flp 1440
	
# Assembly for the OS
$(BIN_DIR)/boot.sys: $(SRC_DIR)/boot/boot.asm
	$(AA) $(AFLAGS) $< -o $@

$(BIN_DIR)/kernel.sys: $(SRC_DIR)/kernel/kernel.asm
	$(AA) $(AFLAGS) $< -o $@

# Final disks
$(DSK_DIR)/pluto.flp: $(BIN_DIR)/boot.sys $(BIN_DIR)/kernel.sys
	dd conv=notrunc if=$< of=$@
	
	rm -rf tmp-loop
	
	mkdir tmp-loop && mount -o loop -t vfat $@ tmp-loop
	
	rm $(BIN_DIR)/boot.sys
	cp $(BIN_DIR)/* tmp-loop
	
	sleep 0.2
	umount tmp-loop
	rm -rf tmp-loop
	
# Folder creation
disk:
	mkdir disk
	
bin:
	mkdir bin
