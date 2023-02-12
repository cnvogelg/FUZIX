        .include "bios.inc"
        .include "memmap.inc"

        .zeropage
code:   .res 1
mods:   .res 1
cook:   .res 1

        .segment "KERNEL"
        ; tag for loader
        .byte "FUZ",1
start:
        lda #<msg
        ldx #>msg
        jsr CPUTS

        map_io
loop:
        jsr KBDPOLL
        bcc loop
        sta code
        stx mods

        jsr CPUT_HEX8

        lda #32
        jsr CPUTC

        lda mods
        jsr CPUT_HEX8

        lda #32
        jsr CPUTC

        lda code
        jsr KBDCOOK
        sta cook

        jsr CPUT_HEX8

        lda #32
        jsr CPUTC

        lda cook
        jsr CPUTC

        jsr CNEWLINE

wait:
        jsr KBDPOLL
        bcs wait

        jmp loop

msg:    .byte "hello, kernel! press a key.",10,0