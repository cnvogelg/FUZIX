
        .include "reu.inc"
        .include "console.inc"
        .include "kernel.inc"

        .export bootstrap

        .segment "LOWCODE"

bootstrap:
        ; copy kernel from REU
        reu_copyfrom kernel_begin, kernel_reu_page, kernel_begin, kernel_size
        map_ram
        reu_trigger

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

go_msg:   .byte " ok!",10,0
error_msg: .byte " ERROR!",0
