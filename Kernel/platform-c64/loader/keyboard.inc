        .global kbdinit
        .global kbdpoll
        .global kbdcook

        .globalzp key_mods
        .globalzp key_code

; modifiers
KEY_MOD_LSHIFT  :=  1
KEY_MOD_RSHIFT  :=  2
KEY_MOD_CONTROL :=  4
KEY_MOD_CBM     :=  8

; default keys
KEY_NONE        := $ff
KEY_RETURN      := $0d
KEY_DELETE      := $7f

; special keys
KEY_DOWN        := $80
KEY_RIGHT       := $82
KEY_POUND       := $84
KEY_HOME        := $86
KEY_ARROW       := $88
KEY_STOP        := $8a

KEY_F1          := $90
KEY_F3          := $92
KEY_F5          := $94
KEY_F7          := $96

; shifted special keys +1
KEY_UP          := $81
KEY_LEFT        := $83
KEY_SPOUND      := $85
KEY_SHOME       := $87
KEY_SARROW      := $89
KEY_SSTOP       := $8b

KEY_F2          := $91
KEY_F4          := $93
KEY_F6          := $95
KEY_F8          := $97
