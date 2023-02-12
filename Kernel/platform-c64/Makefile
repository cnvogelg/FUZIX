
CSRCS = devtty.c devhd.c
CSRCS += devices.c main.c

ASRCS = c64.s crt0.s
ASRCS += tricks.s commonmem.s

DSRCS = ../dev/blkdev.c
DISCARD_DSRCS =

COBJS = $(CSRCS:.c=$(BINEXT))
AOBJS = $(ASRCS:.s=$(BINEXT))
DOBJS = $(patsubst ../dev/%.c,%.o, $(DSRCS))
DISCARD_DOBJS = $(patsubst ../dev/%.c,%.o, $(DISCARD_DSRCS))

OBJS  = $(COBJS) $(AOBJS) $(DOBJS) $(DISCARD_DOBJS)

CROSS_CCOPTS += -I../dev/
ASOPTS += -Iloader

all:	$(OBJS)

$(COBJS): %$(BINEXT): %.c
	$(CROSS_CC) $(CROSS_CCOPTS) $(CROSS_CC_SEG1) $<

$(AOBJS): %$(BINEXT): %.s
	$(CROSS_AS) $(ASOPTS) $< -o $*$(BINEXT)

$(DOBJS): %$(BINEXT): ../dev/%.c
	$(CROSS_CC) $(CROSS_CCOPTS) $(CROSS_CC_SEG1) -c $<
	mv ../dev/$*.o .

$(DISCARD_DOBJS): %$(BINEXT): ../dev/%.c
	$(CROSS_CC) $(CROSS_CCOPTS) $(CROSS_CC_SEGDISC) -c $<
	mv ../dev/$*.o .

clean:
	rm -f $(OBJS) *.o core *~ fuzix.img fuzix.bin

image:
	$(CROSS_LD) -o ../fuzix.bin --mapfile ../fuzix.map -C ld65.cfg \
	-Ln fuzix.lab \
	crt0.o commonmem.o \
	c64.o ../start.o ../version.o ../lowlevel-6502.o \
	tricks.o main.o ../timer.o ../kdata.o devices.o \
	devhd.o \
	../devio.o ../filesys.o ../process.o ../inode.o ../syscall_fs.o \
	../syscall_proc.o ../syscall_other.o ../mm.o ../bankfixed.o \
	../tty.o ../devsys.o ../syscall_fs2.o ../syscall_fs3.o \
	../syscall_exec16.o ../syscall_exec.o ../blk512.o \
	../usermem.o ../usermem_std-6502.o devtty.o
	dd if=../fuzix.bin of=fuzix.img

IMAGES = $(FUZIX_ROOT)/Images/$(TARGET)

diskimage: image
	# create empty REU image
	dd if=/dev/zero of=$(IMAGES)/img.reu bs=1024 count=16384
	# Add the file system (at the end)
	dd if=$(IMAGES)/filesys8.img of=$(IMAGES)/img.reu bs=1024 seek=8192 conv=notrunc
	# Add the kernel
	dd if=fuzix.img of=$(IMAGES)/img.reu bs=1024 conv=notrunc
