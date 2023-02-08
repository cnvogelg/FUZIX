        .include "bios.inc"
        .include "console.inc"

        .segment "LOWCODE"

        ; jump table
        jmp     cputc
        jmp     cputs
