#include <kernel.h>
#include <timer.h>
#include <kdata.h>
#include <printf.h>
#include <blkdev.h>
#include <devtty.h>
#include <bios.h>

uint8_t kernel_flag = 1;
uint16_t swap_dev = 0xFFFF;

void plt_idle(void)
{
    irqflags_t flags = di();
    tty_poll();
    irqrestore(flags);
}

void do_beep(void)
{
}

/*
 * Map handling: allocate 3 banks per process
 */

void pagemap_init(void)
{
    int i;
    /* Add the user banks, taking care to land 36 as the last one as we
       use that for init  (32-35 are the kernel) */
    for (i = 6; i >= 0; i--)
        pagemap_add(36 + i * 4);
}

void map_init(void)
{
}

uint8_t plt_param(char *p)
{
    return 0;
}

void plt_interrupt(void)
{
	tty_poll();
	timer_interrupt();
}
