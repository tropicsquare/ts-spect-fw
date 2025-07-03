_start:
    HASH_IT
    HASH    r0, r0

    MOVI    r1,  0x800
data_in_loop:
    STR     r0,  r1
    SUBI    r1,  r1,  32
    BRNZ    data_in_loop

    MOVI    r1,  0x200
    MOVI    r2,  12
data_out_loop:
    SBIT    r3,  r1,  r2
    STR     r0,  r3
    SUBI    r1,  r1,  32
    BRNZ    data_out_loop

    MOVI    r1,  0x80
    MOVI    r2,  0x50
    ROL8    r2,  r2
emem_out_loop:
    OR      r3,  r1,  r2
    SUBI    r1,  r1,  32
    STR     r0,  r3
    BRNZ    emem_out_loop

    MOV     r1,  r0
    MOV     r2,  r0
    MOV     r3,  r0
    MOV     r4,  r0
    MOV     r5,  r0
    MOV     r6,  r0
    MOV     r7,  r0
    MOV     r8,  r0
    MOV     r9,  r0
    MOV     r10, r0
    MOV     r11, r0
    MOV     r12, r0
    MOV     r13, r0
    MOV     r14, r0
    MOV     r15, r0
    MOV     r16, r0
    MOV     r17, r0
    MOV     r18, r0
    MOV     r19, r0
    MOV     r20, r0
    MOV     r21, r0
    MOV     r22, r0
    MOV     r23, r0
    MOV     r24, r0
    MOV     r25, r0
    MOV     r26, r0
    MOV     r27, r0
    MOV     r28, r0
    MOV     r29, r0
    MOV     r30, r0
    MOV     r31, r0

    TMAC_IT r0
    TMAC_UP r0

    END