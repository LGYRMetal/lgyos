# Makefile of lgyos
BIN := boot.bin
BIN += loader.bin

.PHONY : all

all : boot.bin
	dd if=boot.bin of=a.img bs=512 count=1 conv=notrunc

$(BIN) : boot.asm loader.asm
	nasm boot.asm -o boot.bin -l boot.lst
	nasm loader.asm -o loader.bin -l loader.lst

.PHONY : clean

clean:
	rm *.bin *.lst *.sys *.com bochsout.txt
