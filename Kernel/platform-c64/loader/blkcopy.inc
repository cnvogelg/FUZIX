        .global blkcopy_helper
        .globalzp ptr1
        .globalzp ptr2

.macro blkcopy from, to, size
        lda #<from
        sta ptr1
        lda #>from
        sta ptr1+1

        lda #<to
        sta ptr2
        lda #>to
        sta ptr2+1

        lda #<size
        ldx #>size

        jsr blkcopy_helper
.endmacro
