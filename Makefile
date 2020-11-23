CC = i386-elf-gcc
CC_FLAGS = -nostdlib -ffreestanding -Wall -O0 -c
LD = i386-elf-ld
LD_FLAGS = -T linker.ld
OBJCOPY = objcopy
OBJCOPY_FLAGS = -O binary -j .text

all:
	$(MAKE) os
	$(MAKE) run

os: kernel.bin
	nasm -f bin boot.asm -o $@

kernel.bin: kernel
	$(OBJCOPY) $(OBJCOPY_FLAGS) $< $@

kernel.o:
	$(CC) $(CC_FLAGS) kernel.c -o $@

kernel: kernel.o
	$(LD) $(LD_FLAGS) $< -o $@

run: os
	qemu-system-i386 -hda os

clean: os kernel.bin kernel.o kernel
	rm $^
