# Makefile for Plutonium

BIN_DIR = bin
SRC_DIR = src
DSK_DIR = disk

AA = nasm
AFLAGS = -Wall -f bin -O0

# Main targets
compile: $(DSK_DIR)/pluto.flp
	
# Assembly for the OS
$(BIN_DIR)/boot.sys: $(SRC_DIR)/boot/boot.asm
	$(AA) $(AFLAGS) $< -o $@

$(BIN_DIR)/kernel.sys: $(SRC_DIR)/kernel/kernel.asm
	$(AA) $(AFLAGS) $< -o $@

# Final disks
$(DSK_DIR)/pluto.flp: $(BIN_DIR)/boot.sys $(BIN_DIR)/kernel.sys
	dd conv=notrunc if=$< of=$@
	rm -rf tmp
	mkdir tmp
	mount -o loop -t vfat $@ tmp
	rm -rf $(BIN_DIR)/boot.sys
	cp $(BIN_DIR)/* tmp
	sleep 0.2
	umount tmp
	rm -rf tmp
	
# Folder creation
disk:
	mkdir disk
	
bin:
	mkdir bin
