        .include "keyboard.inc"

        .export kbdinit
        .export kbdpoll

        .exportzp key_mods
        .exportzp key_code
        .exportzp key_coord

        .zeropage
key_mods:  .res 1
key_code:  .res 1
key_coord: .res 1
        .segment "STARTUP"

.proc kbdinit
        ; CIA1
        lda #$0
        sta $dc03   ; port b ddr (input)
        lda #$ff
        sta $dc02   ; port a ddr (output)

        ; copy key map
        ldx #0
copy:
        lda key_map,x
        sta KEY_MAP_ADDR,x
        inx
        bne copy

        rts
.endproc

        .segment "LOWCODE"

; set carry if key and key code in A
.proc kbdpoll
        lda #$00
        sta $dc00
        lda $dc01
        cmp #$ff
        beq no_key

        ; --- scan modifiers first
        lda #0
        sta key_mods

        ldx #3
mod_loop:
        lda mod_row,x
        sta $dc00
        lda $dc01
        and mod_mask,x
        bne no_mod

        lda mod_bit,x
        ora key_mods
        sta key_mods

no_mod:
        dex
        bpl mod_loop

        ; --- scan key matrix
        ; scan rows
        ; set bit to zero
        ; start with bit 7
        ldx #7
        lda #$7f ; start with top most bit to zero
row_scan:
        sta key_code ; use as temp var

        sta $dc00
        lda $dc01
        ora key_mod_mask,x

        cmp #$ff
        bne got_key

        lda key_code
        sec
        ror a

        dex
        bpl row_scan
        bmi no_key ; should never happen

got_key:
        ; A -> Y as column index
        ; converted from mask bit
        eor #$ff ; only 1 bit is now set
        ldy #0
shift:
        clc
        ror a
        beq col_found
        iny
        cpy #8
        bne shift
col_found:
        ; Y=column, X=row -> convert to coord: row*8 + col
        sty key_code ; temp storage
        txa
        asl
        asl
        asl
        ora key_code
        sta key_coord

        ; now finally retrieve key code from the key coord
        sta mod+1
mod:    lda KEY_MAP_ADDR
        sta key_code

        sec
        rts
no_key:
        lda #KEY_NONE
        sta key_code
        clc
        rts
.endproc

; ORA these values in the keyboard matrix scan to mute the modifiers
key_mod_mask:
        .byte 0,$80,0,0,0,0,$10,$24

; row byte for modifier
mod_row:
        ;      lshift    rshift    control   cbm
        .byte %11111101,%10111111,%01111111,%01111111
mod_mask:
        .byte %10000000,%00010000,%00000100,%00100000
mod_bit:
        .byte KEY_MOD_LSHIFT, KEY_MOD_RSHIFT, KEY_MOD_CONTROL, KEY_MOD_CBM

        .segment "STARTUP"
; keymap will be copied from loader to KEY_MAP_ADDR on init
key_map:
        .byte KEY_DELETE, KEY_RETURN, KEY_RIGHT, KEY_F7, KEY_F1, KEY_F3, KEY_F5, KEY_DOWN
        .byte "3wa4zse",0
        .byte "5rd6cftx"
        .byte "7yg8bhuv"
        .byte "9ij0mkon"
        .byte "+pl-.:@,"
        .byte KEY_POUND, "*;", KEY_HOME, 0, "=^/"
        .byte "1", KEY_ARROW, 0, "2 ", 0, "q", KEY_STOP

; +----+----------------------+-------------------------------------------------------------------------------------------------------+
; |    |                      |                                Peek from $dc01 (code in paranthesis):                                 |
; |row:| $dc00:               +------------+------------+------------+------------+------------+------------+------------+------------+
; |    |                      |   BIT 7    |   BIT 6    |   BIT 5    |   BIT 4    |   BIT 3    |   BIT 2    |   BIT 1    |   BIT 0    |
; +----+----------------------+------------+------------+------------+------------+------------+------------+------------+------------+
; |1.  | #%11111110 (254/$fe) | DOWN  ($  )|   F5  ($  )|   F3  ($  )|   F1  ($  )|   F7  ($  )| RIGHT ($  )| RETURN($  )|DELETE ($  )|
; |2.  | #%11111101 (253/$fd) |LEFT-SH($  )|   e   ($05)|   s   ($13)|   z   ($1a)|   4   ($34)|   a   ($01)|   w   ($17)|   3   ($33)|
; |3.  | #%11111011 (251/$fb) |   x   ($18)|   t   ($14)|   f   ($06)|   c   ($03)|   6   ($36)|   d   ($04)|   r   ($12)|   5   ($35)|
; |4.  | #%11110111 (247/$f7) |   v   ($16)|   u   ($15)|   h   ($08)|   b   ($02)|   8   ($38)|   g   ($07)|   y   ($19)|   7   ($37)|
; |5.  | #%11101111 (239/$ef) |   n   ($0e)|   o   ($0f)|   k   ($0b)|   m   ($0d)|   0   ($30)|   j   ($0a)|   i   ($09)|   9   ($39)|
; |6.  | #%11011111 (223/$df) |   ,   ($2c)|   @   ($00)|   :   ($3a)|   .   ($2e)|   -   ($2d)|   l   ($0c)|   p   ($10)|   +   ($2b)|
; |7.  | #%10111111 (191/$bf) |   /   ($2f)|   ^   ($1e)|   =   ($3d)|RGHT-SH($  )|  HOME ($  )|   ;   ($3b)|   *   ($2a)|   £   ($1c)|
; |8.  | #%01111111 (127/$7f) | STOP  ($  )|   q   ($11)|COMMODR($  )| SPACE ($20)|   2   ($32)|CONTROL($  )|  <-   ($1f)|   1   ($31)|
; +----+----------------------+------------+------------+------------+------------+------------+------------+------------+------------+
; taken from https://codebase64.org/doku.php?id=base:reading_the_keyboard
