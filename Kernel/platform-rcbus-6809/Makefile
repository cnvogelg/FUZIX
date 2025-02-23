CSRCS = devices.c main.c libc.c devtty.c

CDSRCS = discard.c

DSRCS = ../dev/blkdev.c ../dev/devide.c

DDSRCS = ../dev/devide_discard.c ../dev/mbr.c

ASRCS = crt0.s rcbus-6809.s ide.s
ASRCS += tricks.s commonmem.s mem-rcbus.s 

COBJS = $(CSRCS:.c=$(BINEXT))
CDOBJS = $(CDSRCS:.c=$(BINEXT))
AOBJS = $(ASRCS:.s=$(BINEXT))
DOBJS = $(patsubst ../dev/%.c,%.o, $(DSRCS))
DDOBJS = $(patsubst ../dev/%.c,%.o, $(DDSRCS))
OBJS  = $(COBJS) $(CDOBJS) $(AOBJS) $(DOBJS) $(DDOBJS)

CROSS_CCOPTS += -I../dev/

all: $(OBJS)

$(COBJS): %$(BINEXT): %.c
	$(CROSS_CC) $(CROSS_CCOPTS) $(CROSS_CC_SEG2) -c $<

$(CDOBJS): %$(BINEXT): %.c
	$(CROSS_CC) $(CROSS_CCOPTS) $(CROSS_CC_SEGDISC) -c $<

$(DOBJS): %$(BINEXT): ../dev/%.c
	$(CROSS_CC) $(CROSS_CCOPTS) $(CROSS_CC_SEG2) -c $<

$(DDOBJS): %$(BINEXT): ../dev/%.c
	$(CROSS_CC) $(CROSS_CCOPTS) $(CROSS_CC_SEGDISC) -c $<

$(AOBJS): %$(BINEXT): %.s
	$(CROSS_AS) $(ASOPTS) $< -o $*.o

clean:
	rm -f *.o *~

image:
	$(CROSS_LD) -o ../fuzix.bin -Map=../fuzix.map --script=fuzix.link --oformat=decb \
	crt0.o commonmem.o mem-rcbus.o \
	rcbus-6809.o ../bankfixed.o \
	../start.o ../version.o ../lowlevel-6809.o \
	tricks.o main.o ../timer.o ../kdata.o devices.o ../blk512.o \
	../devio.o ../filesys.o ../process.o ../inode.o ../syscall_fs.o \
	../syscall_proc.o ../syscall_other.o ../mm.o ../swap.o \
	../tty.o ../devsys.o ../usermem.o ../syscall_fs2.o ../syscall_fs3.o \
	../syscall_exec16.o ../syscall_exec.o devtty.o libc.o devide.o blkdev.o ide.o \
	devide_discard.o mbr.o discard.o
	../tools/pad256 ../fuzix.bin
	../tools/lw-checkmap ../fuzix.map
	../tools/decb-image <../fuzix.bin fuzix.img
	# Pack the image down
	dd if=fuzix.img bs=49152 skip=1 >fuzix.high
	dd if=fuzix.high of=fuzix.img bs=40960 seek=1
	#rm fuzix.high

IMAGES = $(FUZIX_ROOT)/Images/$(TARGET)

diskimage:
	# Make a blank disk image with partition
	dd if=$(FUZIX_ROOT)/Standalone/filesystem-src/parttab.40M of=$(IMAGES)/disk.img bs=40017920 conv=sync
	# Add the bootstrap loader
	dd if=$(IMAGES)/filesys.img of=$(IMAGES)/disk.img bs=512 seek=2048 conv=notrunc
	# Add the kernel
	dd if=fuzix.img of=$(IMAGES)/disk.img bs=512 seek=2 conv=notrunc
	# Make an emulator image of it
	cat $(FUZIX_ROOT)/Standalone/filesystem-src/idehdr.40M $(IMAGES)/disk.img > $(IMAGES)/emu-ide.img
