op_clear:
    MOVI    r0,  0

    MOVI    r1,  0x800
clear_data_in_loop:
    SUBI    r1,  r1,  32
    STR     r0,  r1
    BRNZ    clear_data_in_loop

    MOVI    r1,  0x200
    MOVI    r2,  12
clear_data_out_loop:
    SUBI    r1,  r1,  32
    SBIT    r3,  r1,  r2      
    STR     r0,  r3
    BRNZ    clear_data_out_loop

    MOVI    r1,  0
    MOVI    r2,  0
    MOVI    r3,  0
    MOVI    r4,  0
    MOVI    r5,  0
    MOVI    r6,  0
    MOVI    r7,  0
    MOVI    r8,  0
    MOVI    r9,  0
    MOVI    r10, 0
    MOVI    r11, 0
    MOVI    r12, 0
    MOVI    r13, 0
    MOVI    r14, 0
    MOVI    r15, 0
    MOVI    r16, 0
    MOVI    r17, 0
    MOVI    r18, 0
    MOVI    r19, 0
    MOVI    r20, 0
    MOVI    r21, 0
    MOVI    r22, 0
    MOVI    r23, 0
    MOVI    r24, 0
    MOVI    r25, 0
    MOVI    r26, 0
    MOVI    r27, 0
    MOVI    r28, 0
    MOVI    r29, 0
    MOVI    r30, 0
    CMP     r30, r31
    MOVI    r31, 0

    HASH_IT
    TMAC_IT r0

    END