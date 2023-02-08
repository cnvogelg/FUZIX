        .include "zeropage.inc"

        .global blkcopy_helper

        .segment "STARTUP"

; from=ptr1, to=ptr2, size_lo=a, size_hi=x
.proc blkcopy_helper
        pha
        lda #0
        tay
        cpx #0
        beq skip

        ; copy pages
copy1:  lda (ptr1),y
        sta (ptr2),y
        iny
        bne copy1
        inc ptr1+1
        inc ptr2+1
        dex
        bne copy1

        ; copy remainder
skip:
        pla
        tax
        beq end
copy2:  lda (ptr1),y
        sta (ptr2),y
        iny
        dex
        bne copy2
end:
        rts
.endproc