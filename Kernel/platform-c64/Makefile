
all: disk.d64

run: disk.d64
	x64sc -autostart $< -reu -reusize 16384

run8: disk.d64
	x64sc -autostart $< -reu -reusize 8192

run4: disk.d64
	x64sc -autostart $< -reu -reusize 4096

run0: disk.d64
	x64sc -autostart $<

clean:
	rm -f disk.d64 loader.prg *.o *.map *.lab

disk.d64: loader.prg
	c1541 -format "disk,00" d64 $@
	c1541 -attach $@ -write $<

LOADER_FILES = exehdr.o reu_init.o console.o blkcopy.o loader.o

loader.prg: $(LOADER_FILES) loader.cfg
	ld65 -Ln $(basename $@).lab -C loader.cfg -o $@ -m $(basename $@).map $(LOADER_FILES)
	@ls -la $@

%.o: %.s
	ca65 -g -o $@ $<