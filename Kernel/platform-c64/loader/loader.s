; FUZIX REU loader for C64

        .include "console.inc"
        .include "keyboard.inc"
        .include "blkcopy.inc"
        .include "reu.inc"
        .include "kernel.inc"
        .include "memmap.inc"

        .import __BIOS_RUN__
        .import __BIOS_LOAD__
        .import __BIOS_SIZE__

        .import __BOOTSTRAP_RUN__
        .import __BOOTSTRAP_LOAD__
        .import __BOOTSTRAP_SIZE__

        .import __KEYDATA_RUN__
        .import __KEYDATA_LOAD__
        .import __KEYDATA_SIZE__

        .import bootstrap

MIN_REU_PAGES = $7f

        .export start
        .export reu_detect_buf

        ; use "free space"
reu_detect_buf := $d000 - $100

        ; here we begin
        .segment "STARTUP"
start:
        sei
        cld

        ; memory setup: RAM only + I/O
        map_io

        ; copy bios, bootstrap and keydata to run location
        blkcopy __BIOS_LOAD__, __BIOS_RUN__, __BIOS_SIZE__
        blkcopy __KEYDATA_LOAD__, __KEYDATA_RUN__, __KEYDATA_SIZE__
        blkcopy __BOOTSTRAP_LOAD__, __BOOTSTRAP_RUN__, __BOOTSTRAP_SIZE__

        ; setup console and keyboard
        jsr cinit
        jsr kbdinit

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
        ; report kernel copy
        lda #<copy_msg
        ldx #>copy_msg
        jsr cputs

        lda #<kernel_begin
        ldx #>kernel_begin
        jsr cput_hex16

        lda #<dot_msg
        ldx #>dot_msg
        jsr cputs

        lda #<kernel_end
        ldx #>kernel_end
        jsr cput_hex16

        jsr cnewline

        ; kernel start
        lda #<check_msg
        ldx #>check_msg
        jsr cputs

        lda #<kernel_start
        ldx #>kernel_start
        jsr cput_hex16

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
copy_msg: .byte "copy kernel to $",0
dot_msg:  .byte " ... $",0
check_msg: .byte "start $",0
