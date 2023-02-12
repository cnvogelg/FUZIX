REU_STATUS  := $DF00                 ; Status register
REU_COMMAND := $DF01                 ; Command register
REU_C64ADDR := $DF02                 ; C64 base address register
REU_REUADDR := $DF04                 ; REU base address register
REU_COUNT   := $DF07                 ; Transfer count register
REU_IRQMASK := $DF09                 ; IRQ mask register
REU_CONTROL := $DF0A                 ; Control register

REU_TRIGGER := $FF00                 ; REU command trigger memory address

OP_COPYFROM := $ED
OP_COPYTO   := $EC

OP_COPYFROM_ALOAD := $B1
OP_COPYTO_ALOAD   := $B0

        ; declare in your code:
        .global reu_detect_buf

        .global reu_detect
        .global reu_detect_save
        .global reu_detect_restore
        .global reu_size

        .macro reu_trigger
                lda REU_TRIGGER
                sta REU_TRIGGER
        .endmacro

        .macro reu_copy c64_addr, reu_page, reu_addr, count, op
                lda #<reu_addr
                sta REU_REUADDR
                lda #>reu_addr
                sta REU_REUADDR+1
                lda #reu_page
                sta REU_REUADDR+2

                lda #<c64_addr
                sta REU_C64ADDR
                lda #>c64_addr
                sta REU_C64ADDR+1

                lda #<count
                sta REU_COUNT
                lda #>count
                sta REU_COUNT+1

                lda #0
                sta REU_CONTROL
                lda #op
                sta REU_COMMAND
        .endmacro

        .macro reu_copyto_auto c64_addr, reu_page, reu_addr, count
                reu_copy c64_addr, reu_page, reu_addr, count, OP_COPYTO_ALOAD
        .endmacro

        .macro reu_copyfrom_auto c64_addr, reu_page, reu_addr, count
                reu_copy c64_addr, reu_page, reu_addr, count, OP_COPYFROM_ALOAD
        .endmacro

        .macro reu_copyto c64_addr, reu_page, reu_addr, count
                reu_copy c64_addr, reu_page, reu_addr, count, OP_COPYTO
        .endmacro

        .macro reu_copyfrom c64_addr, reu_page, reu_addr, count
                reu_copy c64_addr, reu_page, reu_addr, count, OP_COPYFROM
        .endmacro
