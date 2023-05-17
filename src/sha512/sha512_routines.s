sha512_one_block:
    LD r3, 0x0020
    LD r2, 0x0040
    LD r1, 0x0060
    LD r0, 0x0080

    SWE r3, r3
    SWE r2, r2
    SWE r1, r1
    SWE r0, r0

    HASH r4, r0
    RET

sha512_init:
    HASH_IT
    MOVI r0, 0
    ST r0, 0x1000
    END

sha512_update:
    CALL sha512_one_block
    MOVI r0, 0
    ST r0, 0x1000
    END

sha512_final:
    CALL sha512_one_block
    ST r4, 0x1020
    ST r5, 0x1040
    HASH_IT
    MOVI r0, 0
    ST r0, 0x1000
    END