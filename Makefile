ASM=nasm

SCR_DIR=src
BUILD_DIR=build

#
# Floppy Image
#
floppy_image: $(BUILD_DIR)/main.img
$(BUILD_DIR)/main.img: kernel bootloader
	dd if=/dev/zero of=$(BUILD_DIR)/main.img bs=512 count=2880
	mkfs.fat -F 12 -n "JAZZOS" $(BUILD_DIR)/main.img
	dd if=$(BUILD_DIR)/bootloader.bin of=$(BUILD_DIR)/main.img conv=notrunc 
	mcopy -i $(BUILD_DIR)/main.img $(BUILD_DIR)/kernel.bin "::kernel.bin"


#
# Bootloader
#

bootloader: $(BUILD_DIR)/bootloader.bin
$(BUILD_DIR)/bootloader.bin:
	$(ASM) $(SCR_DIR)/bootloader/boot.asm -f bin -o $(BUILD_DIR)/bootloader.bin


#
# Kernel
#

kernel: $(BUILD_DIR)/kernel.bin
$(BUILD_DIR)/kernel.bin:
	$(ASM) $(SCR_DIR)/kernel/main.asm -f bin -o $(BUILD_DIR)/kernel.bin