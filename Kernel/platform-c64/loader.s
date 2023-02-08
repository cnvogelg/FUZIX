; FUZIX REU loader for C64

        .include "zeropage.inc"
        .include "console.inc"
        .include "blkcopy.inc"
        .include "reu.inc"
        .macpack cbm

        .import __LOWCODE_RUN__
        .import __LOWCODE_LOAD__
        .import __LOWCODE_SIZE__
        .import bootstrap

MIN_REU_PAGES = $7f

        .export start
        .export reu_detect_buf

        ; use "free space"
reu_detect_buf := $d000 - $100

        .zeropage
ptr1:   .res    2
ptr2:   .res    2
tmp1:   .res    2

        ; here we begin
        .segment "STARTUP"
start:
        sei
        cld

        ; memory setup: RAM only + I/O
        map_io

        ; copy bootstrap to lo ram
        blkcopy __LOWCODE_LOAD__, __LOWCODE_RUN__, __LOWCODE_SIZE__

        ; setup console
        jsr cinit

        ; welcome message
        lda #<hello_msg
        ldx #>hello_msg
        jsr cputs

        ; detect reu
        jsr reu_detect_save
        jsr reu_detect
        sta reu_max_pages
        jsr cput_hex8
        jsr reu_detect_restore

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
        lda reu_max_pages
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
        lda #<bootstrap_msg
        ldx #>bootstrap_msg
        jsr cputs

        ; jump to bootstrap
        jmp bootstrap

error_end:
        jsr cputs

        lda #2 ; red
        sta $d020

        lda #<error_msg
        ldx #>error_msg
        jsr cputs

end:    jmp end

reu_max_pages: .res 1

hello_msg:
        .byte "FUZIX loader",10
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
bootstrap_msg:
        .byte "bootstrapping...",10,0
