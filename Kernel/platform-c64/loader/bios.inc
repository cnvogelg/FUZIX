        BIOS_BASE := $200

        ; jump table of bios
        CPUTC       := BIOS_BASE
        CPUTS       := BIOS_BASE+3
        CCLRSCR     := BIOS_BASE+6
        CNEWLINE    := BIOS_BASE+9
        CPUT_HEX8   := BIOS_BASE+12
        CPUT_HEX16  := BIOS_BASE+15
        KBDPOLL     := BIOS_BASE+18
        KBDCOOK     := BIOS_BASE+21
