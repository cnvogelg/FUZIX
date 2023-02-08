; REU functions

        .include "reu.inc"

        .import reu_detect_buf

        .segment "STARTUP"

; detect a REU and return the max page in A
.proc reu_detect
        ; write something into REU register and try to retrieve it
        lda #$aa
        sta REU_REUADDR
        lda REU_REUADDR
        cmp #$aa
        bne no_reu

        lda #$55
        sta REU_REUADDR
        lda REU_REUADDR
        cmp #$55
        bne no_reu

        ; fill each REU page with a byte denoting the pages
        ; backwards starting from $ff down to 0
        ldx #$ff
        ldy #OP_COPYTO_ALOAD
floop:
        stx test_byte
        jsr reu_transfer_byte
        dex
        cpx #$ff
        bne floop

        inx ; -> 0
        ; now check if REU page bytes are still there and
        ; are not overwritten by mirrored pages
        ; now starting from 0 up to $ff
        ldy #OP_COPYFROM_ALOAD
cloop:  jsr reu_transfer_byte
        cpx test_byte
        bne found
        inx
        bne cloop
found:
        dex
        txa
        rts
no_reu:
        lda #0
        rts
.endproc

; backup the test bytes of the REU into C64 RAM
; so the detect routine does not garble existing REU space
; a $100 sized buffer needs to be given -> reu_detect_buf
.proc reu_detect_save
        ldx #0
        ldy #OP_COPYFROM_ALOAD
loop:
        jsr reu_transfer_byte
        lda test_byte
        sta reu_detect_buf,x
        inx
        bne loop
        rts
.endproc

; restore the test bytes in REU
; A=<buffer X=>buffer
.proc reu_detect_restore
        ldx #0
        ldy #OP_COPYTO_ALOAD
loop:
        lda reu_detect_buf,x
        sta test_byte
        jsr reu_transfer_byte
        inx
        bne loop
        rts
.endproc

; X = page and byte to transfer
; Y = transfer op
.proc reu_transfer_byte
        ; page
        stx REU_REUADDR+2
        ; clear refs
        lda #0
        sta REU_REUADDR
        sta REU_REUADDR+1
        sta REU_COUNT+1
        sta REU_CONTROL
        ; test byte addr
        lda #<test_byte
        sta REU_C64ADDR
        lda #>test_byte
        sta REU_C64ADDR+1
        lda #1
        sta REU_COUNT
        ; go!
        sty REU_COMMAND
        rts
.endproc

; A=max reu pages -> A=lo size, X=hi size
.proc reu_size
        sta test_byte
        ldy #0
loop:
        lda reu_pages,y
        cmp test_byte
        beq found
        iny
        cpy #reu_pages_end - reu_pages
        bne loop
        ; not found
        lda #0
        tax
        rts
found:
        tya
        asl
        tay
        lda reu_sizes,y
        ldx reu_sizes+1,y
        rts
.endproc

test_byte: .byte 0

reu_pages: .byte $ff,  $7f, $3f, $1f, $f,  7,  3,  1
reu_pages_end:
reu_sizes: .word 16384,8192,4096,2048,1024,512,256,128
