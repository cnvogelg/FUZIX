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

        .global reu_detect
        .global reu_size
