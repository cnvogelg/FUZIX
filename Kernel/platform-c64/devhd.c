/* 
 * REUdisc for C64
 */

#include <kernel.h>
#include <kdata.h>
#include <printf.h>
#include <devhd.h>

extern void __fastcall__ reudisk_set_lba(uint16_t lba);
extern void __fastcall__ reudisk_read_blk(uint16_t addr);
extern void __fastcall__ reudisk_write_blk(uint16_t addr);

static int hd_transfer(uint8_t minor, bool is_read, uint8_t rawflag)
{
    uint16_t dptr, nb;
    irqflags_t irq;
    uint8_t err;

    /* FIXME: add swap */
    if(rawflag == 1 && d_blkoff(9))
        return -1;

    dptr = (uint16_t)udata.u_dptr;
    nb = udata.u_nblock;
        
    while (udata.u_nblock--) {
        reudisk_set_lba(udata.u_block);

        irq = di();
        if (is_read)
            reudisk_read_blk(dptr);
        else
            reudisk_write_blk(dptr);
        irqrestore(irq);

        udata.u_block++;
        dptr += 512;
    }
    return nb << BLKSHIFT;
}

int hd_open(uint8_t minor, uint16_t flag)
{
    uint8_t err;

    used(flag);
    used(minor);
#if 0
    err = *diskstat;
    *disknum = minor;
    if(err) {
        udata.u_error = ENODEV;
        return -1;
    }
#endif
    return 0;
}

int hd_read(uint8_t minor, uint8_t rawflag, uint8_t flag)
{
    used(flag);
    return hd_transfer(minor, true, rawflag);
}

int hd_write(uint8_t minor, uint8_t rawflag, uint8_t flag)
{
    used(flag);
    return hd_transfer(minor, false, rawflag);
}

