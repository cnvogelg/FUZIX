; FUZIX REU loader for C64

        .include "zeropage.inc"
        .include "console.inc"
        .include "blkcopy.inc"
        .include "reu.inc"
        .macpack cbm

        .import __LOCOPY_RUN__
        .import __LOCOPY_LOAD__
        .import __LOCOPY_SIZE__

MIN_REU_PAGES = $7f

        .export start

        .zeropage
ptr1:   .res    2
ptr2:   .res    2
tmp1:   .res    2

;
        bsize := tmp1

        ; here we begin
        .segment "STARTUP"
start:
        sei
        cld

        ; memory setup: RAM only + I/O
        lda $1
        and #%11111000
        ora #%00000101
        sta $1

        ; setup console
        jsr cinit

        ; welcome message
        lda #<hello_msg
        ldx #>hello_msg
        jsr cputs

        ; detect reu
        jsr reu_detect
        sta reu_max_pages
        jsr cput_hex8

        ; no REU?
        lda reu_max_pages
        cmp #0
        bne reu_found
        lda #<no_reu_msg
        ldx #>no_reu_msg
        jmp error_end

reu_found:
        lda #<size_msg
        ldx #>size_msg
        jsr cputs
        ; reu size
        jsr reu_size
        jsr cput_hex16
        lda #<kb_msg
        ldx #>kb_msg
        jsr cputs

        ; check size
        lda reu_max_pages
        cmp #MIN_REU_PAGES
        bcs reu_ok
        lda #<too_small_msg
        ldx #>too_small_msg
        jmp error_end

reu_ok:
        ; copy low range to lo ram
        blkcopy __LOCOPY_LOAD__, __LOCOPY_RUN__, __LOCOPY_SIZE__

        jmp __LOCOPY_RUN__

error_end:
        jsr cputs

        lda #2 ; red
        sta $d020

        lda #<error_msg
        ldx #>error_msg
        jsr cputs

end:    jmp end

        .segment "LOCOPY"
low_start:
        lda $d012
        sta $d020
        jmp low_start        
low_end:

        .data
reu_max_pages: .res 1

        .rodata
hello_msg:
        .byte "FUZIL/lallafa v1",10
        .byte "-----",10
        .byte "REU: pages=$",0
size_msg:
        .byte " size=$",0
kb_msg: .byte " KiB",10,0
no_reu_msg:
        .byte 10,"NOT FOUND!",0
too_small_msg:
        .byte "TOO SMALL!",0
error_msg:
        .byte 10,10,"ERROR! ABORT.",0
