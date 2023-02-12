        .include "bios.inc"
        .include "console.inc"
        .include "keyboard.inc"

        .segment "BIOS"

        ; jump table
        jmp     cputc
        jmp     cputs
        jmp     cclrscr
        jmp     cnewline
        jmp     cput_hex8
        jmp     cput_hex16
        jmp     kbdpoll
        jmp     kbdcook
