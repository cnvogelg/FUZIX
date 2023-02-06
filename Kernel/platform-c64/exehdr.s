        .import start

        ; magic for PRG address bytes at the beginning
        .export         __LOADADDR__: absolute = 1
        .segment "LOADADDR"
        .addr   *+2

        .export         __EXEHDR__: absolute = 1
        .segment "EXEHDR"
basic_header:
        .addr   next
        .word   .version        ; Line number
        .byte   $9E             ; SYS token
        .byte   <(((start /  1000) .mod 10) + '0')
        .byte   <(((start /   100) .mod 10) + '0')
        .byte   <(((start /    10) .mod 10) + '0')
        .byte   <(((start /     1) .mod 10) + '0')
        .byte   $00             ; End of BASIC line
next:   .word   0               ; BASIC end marker
