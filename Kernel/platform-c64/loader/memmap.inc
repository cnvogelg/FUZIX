        .macro map_io
                ; memory setup: RAM only + I/O
                lda $1
                and #%11111000
                ora #%00000101
                sta $1
        .endmacro

        .macro map_ram
                ; memory setup: RAM only + NO I/O
                lda $1
                and #%11111000
                sta $1
        .endmacro

        .macro map_rom_io
                ; default setup BASIC+KERNAL+IO
                lda $1
                and #%11111000
                ora #%00000111
                sta $1
        .endmacro
