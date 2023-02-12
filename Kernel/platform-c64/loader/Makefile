all: disk.d64 img.reu

REU_IMG = ../../../Images/c64/img.reu

runk: disk.d64 $(REU_IMG)
	x64sc -autostart $< -reu -reusize 16384 -reuimage $(REU_IMG)

run: disk.d64 img.reu
	x64sc -autostart $< -reu -reusize 16384 -reuimage img.reu

run8: disk.d64
	x64sc -autostart $< -reu -reusize 8192

run4: disk.d64
	x64sc -autostart $< -reu -reusize 4096

run0: disk.d64
	x64sc -autostart $<

clean:
	rm -f disk.d64 img.reu loader.prg *.o *.map *.lab test.bin

disk.d64: loader.prg
	c1541 -format "disk,00" d64 $@
	c1541 -attach $@ -write $<

img.reu: test.bin
	# empty image
	dd if=/dev/zero of=img.reu bs=1024 count=16384
	# add testkernel
	dd if=test.bin of=img.reu bs=1024 seek=16 conv=notrunc

LOADER_FILES = exehdr.o reu_init.o bios.o console.o keyboard.o blkcopy.o bootstrap.o loader.o

loader.prg: $(LOADER_FILES) loader.cfg
	ld65 -Ln $(basename $@).lab -C loader.cfg -o $@ -m $(basename $@).map $(LOADER_FILES)
	@ls -la $@

test.bin: testkernel.o test.cfg
	ld65 -Ln $(basename $@).lab -C test.cfg -o $@ -m $(basename $@).map testkernel.o

%.o: %.s
	ca65 -g -o $@ $<

