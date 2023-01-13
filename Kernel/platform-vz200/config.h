/*
 *	Build options
 *
 *	See README.CONFIG
 */

#define CONFIG_SD		/* SD card bitbanged on I/O port */
/*
 *	Platform configuration
 */

#define MEM_TOP		0xFFFF
#define PROC_SIZE	30
#define SWAP_SIZE	0x3F	/* FIXME */

/* Enable to make ^Z dump the inode table for debug */
#undef CONFIG_IDUMP
/* Enable to make ^A drop back into the monitor */
#undef CONFIG_MONITOR
/* Profil syscall support (not yet complete) */
#undef CONFIG_PROFIL
/* Multiple processes in memory at once */
#undef CONFIG_MULTI
/* Swap based one process in RAM */
#define CONFIG_SWAP_ONLY
/* Permit large I/O requests to bypass cache and go direct to userspace */
#define CONFIG_LARGE_IO_DIRECT(x)	1
/* One memory bank */
#define CONFIG_BANKS	1
#define TICKSPERSEC 50		/* Ticks per second - NTSC 60 ? FIXME */
#define PROGBASE    0x8800	/* also data base */
#define PROGLOAD    0x8800	/* also data base */
#define PROGTOP     0xFFFF	/* Top of program */
#define KERNTOP	    0xFFFF	/* Grow buffers up to top */

#define SWAPBASE    0x8800	/* start at the base of user mem */
#define SWAPTOP	    0xFFFF	/* Swap out program */
#define CONFIG_SPLIT_UDATA
#define UDATA_BLKS  1
#define UDATA_SIZE  0x200	/* One block */

#define MAX_SWAPS   16	    	/* We will size if from the partition */
/* Swap will be set up when a suitably labelled partition is seen */
#define CONFIG_DYNAMIC_SWAP
#define SWAPDEV     (swap_dev)	/* A variable for dynamic, or a device major/minor */
extern uint16_t swap_dev;

#define MAXTICKS    20		/* As we are pure swap */
#define CONFIG_PARENT_FIRST	/* For pure swap this is far faster */

#define CONFIG_PLATFORM_LATE_EI

/*
 *	When the kernel swaps something it needs to map the right page into
 *	memory using map_for_swap and then turn the user address into a
 *	physical address. For a simple banked setup there is no conversion
 *	needed so identity map it.
 */
#define swap_map(x)	((uint8_t *)(x))

/* We need a tidier way to do this from the loader */
#define CMDLINE	NULL  /* Location of root dev name */
#define BOOTDEVICENAMES "hd#"

#define CONFIG_DYNAMIC_BUFPOOL /* we expand bufpool to overwrite the _DISCARD segment at boot */
#define NBUFS    4        /* Number of block buffers, keep in line with space reserved in zeta-v2.s */
#define NMOUNTS	 2	  /* Number of mounts at a time */

#define MAX_BLKDEV 1	    /* SD */

#define SD_DRIVE_COUNT 1
#define SD_SPI_CALLTYPE __z88dk_fastcall

/* Device parameters */
#define NUM_DEV_TTY 1		/* Only a console */

/* Console */
#define CONFIG_VT

#define CONFIG_VT_SIMPLE
#define VT_WIDTH	32
#define VT_HEIGHT	16
#define VT_RIGHT	31
#define VT_BOTTOM	15
#define VT_BASE	((uint8_t *)0x7000)

extern unsigned char vt_mangle_6847(unsigned char c);
#define VT_MAP_CHAR(x)	vt_mangle_6847(x)

/* Video as the console */
#define BOOT_TTY (512 + 1)
#define TTY_INIT_BAUD B115200	/* Hardwired generally */

#define TTYDEV   BOOT_TTY /* Device used by kernel for messages, panics */

#define plt_copyright()
