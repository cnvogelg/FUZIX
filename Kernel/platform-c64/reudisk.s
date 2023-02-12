        .include "reu.inc"
        .include "memmap.inc"

        .export _reudisk_set_lba
        .export _reudisk_read_blk
        .export _reudisk_write_blk

BLKSIZE := 512
DISK_OFFSET := $80 ; for 16MB REU (TODO: adjust to REU size)

        .zeropage
reu_blk_addr: .res 2

        .segment "SEG1"

; LBA block number in (A;X)
.proc _reudisk_set_lba
        ; the REU addr is with LBA (x) and page offset (o) of disk in REU
        ;  xxxxxxxx xxxxxxx0 00000000
        ; +oooooooo
        ;  rba+1    rba   (=reu_blk_addr)
        asl
        sta reu_blk_addr
        bcs wbit
        lda #DISK_OFFSET
        bne skip ; always
wbit:   lda #DISK_OFFSET+1 ; take the shifted bit from lo addr into account
skip:   sta reu_blk_addr+1 ; temp
        txa
        asl
        clc
        adc reu_blk_addr+1
        sta reu_blk_addr+1
        rts
.endproc

; c64 addr in (A;X), Y=op
.proc do_transfer
        pha

        map_io

        pla
        sta REU_C64ADDR
        stx REU_C64ADDR+1

        lda #0
        sta REU_REUADDR
        lda reu_blk_addr
        sta REU_REUADDR+1
        lda reu_blk_addr+1
        sta REU_REUADDR+2

        lda #<BLKSIZE
        sta REU_COUNT
        lda #>BLKSIZE
        sta REU_COUNT+1

        lda #0
        sta REU_CONTROL
        sty REU_COMMAND

        map_ram

        reu_trigger

        rts
.endproc

; target addr in (A;X)
.proc _reudisk_read_blk
        ldy #OP_COPYFROM
        jmp do_transfer
.endproc

; target addr in (A;X)
.proc _reudisk_write_blk
        ldy #OP_COPYTO
        jmp do_transfer
.endproc
