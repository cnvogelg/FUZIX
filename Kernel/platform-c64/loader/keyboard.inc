        .global kbdinit
        .global kbdpoll

        .globalzp key_mods
        .globalzp key_code
        .globalzp key_coord

; must be page aligned!
KEY_MAP_ADDR    := $fe00

KEY_MOD_LSHIFT  :=  1
KEY_MOD_RSHIFT  :=  2
KEY_MOD_CONTROL :=  4
KEY_MOD_CBM     :=  8

KEY_NONE        := $ff
KEY_RETURN      := $0d
KEY_DELETE      := $7f

KEY_DOWN        := $80
KEY_RIGHT       := $81
KEY_POUND       := $82
KEY_HOME        := $83
KEY_ARROW       := $84
KEY_STOP        := $85

KEY_F1          := $86
KEY_F3          := $87
KEY_F5          := $88
KEY_F7          := $89