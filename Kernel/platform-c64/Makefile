all: disk.d64 img.reu

run: disk.d64 img.reu
	x64sc -autostart $< -reu -reusize 16384 -reuimage img.reu

run8: disk.d64
	x64sc -autostart $< -reu -reusize 8192

run4: disk.d64
	x64sc -autostart $< -reu -reusize 4096

run0: disk.d64
	x64sc -autostart $<

clean:
	rm -f disk.d64 img.reu loader.prg *.o *.map *.lab

disk.d64: loader.prg
	c1541 -format "disk,00" d64 $@
	c1541 -attach $@ -write $<

img.reu:
	dd if=/dev/zero of=img.reu bs=1024 count=16384

LOADER_FILES = exehdr.o reu_init.o bios.o console.o blkcopy.o bootstrap.o loader.o

loader.prg: $(LOADER_FILES) loader.cfg
	ld65 -Ln $(basename $@).lab -C loader.cfg -o $@ -m $(basename $@).map $(LOADER_FILES)
	@ls -la $@

%.o: %.s
	ca65 -g -o $@ $<

