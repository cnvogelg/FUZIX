
        .include "reu.inc"
        .include "console.inc"

        .export bootstrap

kernel_begin := $800
kernel_end   := $ffff
kernel_size  := kernel_end - kernel_begin + 1
kernel_reu_page  := 0
kernel_start := $4000

        .segment "LOWCODE"

bootstrap:
        ; copy kernel from REU
        reu_copyfrom kernel_begin, kernel_reu_page, kernel_begin, kernel_size
        map_ram
        reu_trigger

        ; report copy
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

        ; check kernel image
        lda #<check_msg
        ldx #>check_msg
        jsr cputs

        lda #<kernel_start
        ldx #>kernel_start
        jsr cput_hex16

        ; signature found? 'FUZ\001'
        lda kernel_start
        cmp #'F'
        bne error
        lda kernel_start+1
        cmp #'U'
        bne error
        lda kernel_start+2
        cmp #'Z'
        bne error
        lda kernel_start+3
        cmp #1
        bne error

        ; ok. go!
        lda #<go_msg
        ldx #>go_msg
        jsr cputs

        ; jump to kernel
        jmp kernel_start+4

error:
        lda #<error_msg
        ldx #>error_msg
        jsr cputs

        map_io
        lda #2 ; red
        sta $d020

die:    jmp die

copy_msg: .byte "copied kernel to $",0
dot_msg:  .byte " ... $",0
check_msg:   .byte "check $",0
go_msg:   .byte " ok",10,"go!",10,0
error_msg: .byte " ERROR!",0
