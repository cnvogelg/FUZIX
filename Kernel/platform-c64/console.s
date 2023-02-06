; console I/O

        .include "zeropage.inc"
        .include "console.inc"
        .include "blkcopy.inc"
        .macpack cbm

        .export cinit
        .export cclrscr
        .export cput_hex16
        .export cput_hex8
        .export cputc
        .export cputs

        .zeropage
screen_ptr:     .res 2
cptr:           .res 2
ctmp:           .res 1

COLRAM_ADDR := $d800
MAX_X = 40
MAX_Y = 25

        .code

.proc cinit
        ; vic bank $c000-$ffff
        lda $dd02
        ora #3
        sta $dd02
        lda $dd00
        and #%11111100
        sta $dd00

        ; vic screen at $f800, font at $f000
        lda #%11101100
        sta $d018

        ; color
        lda #0
        sta $d020
        sta $d021

        ; fill color RAM
        ldx #0
        lda #5 ; green
loop:   sta COLRAM_ADDR,x
        sta COLRAM_ADDR+250,x
        sta COLRAM_ADDR+500,x
        sta COLRAM_ADDR+750,x
        inx
        cpx #250
        bne loop

        ; clear screen
        jsr cclrscr

        ; copy font
        blkcopy font_src, $f000, 2048

        rts
.endproc

.proc cclrscr
        ldx #0
        lda #32   ; space
loop:   sta SCREEN_ADDR,x
        sta SCREEN_ADDR+250,x
        sta SCREEN_ADDR+500,x
        sta SCREEN_ADDR+750,x
        inx
        cpx #250
        bne loop

        ; reset cursor
        lda #0
        sta cursor_x
        sta cursor_y

        ; reset screen ptr
        lda #<SCREEN_ADDR
        sta screen_ptr
        lda #>SCREEN_ADDR
        sta screen_ptr+1

        rts
.endproc

; A=petsii char
.proc cputc
        ; CR = reset cursor
        cmp     #$0d
        bne     no_ret
        lda     #0
        sta     cursor_x
        rts

        ; NL = newline
no_ret: cmp     #$0a
        beq     cnewline

        ; char conversion
        cmp     #32
        bcc     out             ;  <=0x20
        bmi     hichar          ;  >=0x80
        cmp     #$60
        bcc     out
        and     #$1F
        bne     out ; always

out:
        ldy cursor_x
        sta (screen_ptr),y
        inc cursor_x
        ldy cursor_x
        cpy #MAX_X
        beq cnewline
        rts

hichar:
        and     #$7F
        cmp     #$7F            ; PI?
        bne     no_pi
        lda     #$5E            ; Load screen code for PI
no_pi:  ora     #$40
        bne     out ; always

.endproc

cnewline:
        ; reset cursor X
        ldx #0
        stx cursor_x
        ; inc cursor Y
        ldx cursor_y
        cpx #MAX_Y
        beq @end
        inc cursor_y

        ; inc screen ptr
        clc
        lda screen_ptr
        adc #MAX_X
        sta screen_ptr
        bcc @end
        inc screen_ptr+1
@end:
        rts

; A=lo X=hi
cputs:
        sta cptr
        stx cptr+1
        ldy #0
@loop:
        lda (cptr),y
        beq @end
        sty ctmp
        jsr cputc
        ldy ctmp
        iny
        bne @loop ; alway
@end:
        rts

; X=hi A=lo
cput_hex16:
        pha
        txa
        jsr     cput_hex8
        pla
        ; fall through

; A=byte
cput_hex8:
        pha
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        tay
        lda     hextab,y
        jsr     cputc
        pla
        and     #$0F
        tay
        lda     hextab,y
        jmp     cputc

        .data
cursor_x: .res 1
cursor_y: .res 1

        .rodata
hextab: .byte "0123456789abcdef"
font_src:
        .incbin "font.bin"
