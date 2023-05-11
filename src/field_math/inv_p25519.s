; Inversion in GF(p25519)
; input Z in register r1
; output Z^-1 mod p25519 in register r1

inv_p25519_250:
    MUL25519 r2, r1, r1
    MUL25519 r4, r2, r1     ; r4 = x2

    MUL25519 r3, r4, r4
    MUL25519 r3, r3, r3
    MUL25519 r2, r4, r3     ;4

    MUL25519 r3, r2, r2
    MUL25519 r3, r3, r3
    MUL25519 r3, r3, r3
    MUL25519 r3, r3, r3
    MUL25519 r2, r2, r3     ;8

    MUL25519 r3, r2, r2
    MOVI r30, 7
inv_p25519_loop_8:
    MUL25519 r3, r3, r3
    SUBI r30, r30, 0x1
    BRNZ inv_p25519_loop_8

    MUL25519 r5, r2, r3     ; r5 = x16

    MUL25519 r3, r5, r5
    MOVI r30, 15
inv_p25519_loop_16_1:
    MUL25519 r3, r3, r3
    SUBI r30, r30, 1
    BRNZ inv_p25519_loop_16_1

    MUL25519 r2, r5, r3     ;32

    MUL25519 r3, r2, r2
    MOVI r30, 15
inv_p25519_loop_16_2:
    MUL25519 r3, r3, r3
    SUBI r30, r30, 1
    BRNZ inv_p25519_loop_16_2

    MUL25519 r2, r5, r3

    MUL25519 r2, r2, r2
    MUL25519 r2, r2, r2
    MUL25519 r5, r2, r4     ; r5 = x50

    MUL25519 r3, r5, r5
    MOVI r30, 49
inv_p25519_loop_50_1:
    MUL25519 r3, r3, r3
    SUBI r30, r30, 1
    BRNZ inv_p25519_loop_50_1

    MUL25519 r2, r5, r3     ; r2 = x100

    MUL25519 r3, r2, r2
    MOVI r30, 99
inv_p25519_loop_100:
    MUL25519 r3, r3, r3
    SUBI r30, r30, 1
    BRNZ inv_p25519_loop_100

    MUL25519 r2, r2, r3     ; r2 = x200

    MUL25519 r3, r2, r2
    MOVI r30, 49
inv_p25519_loop_50_2:
    MUL25519 r3, r3, r3
    SUBI r30, r30, 1
    BRNZ inv_p25519_loop_50_2

    MUL25519 r2, r3, r5     ; r2 = x250
    RET

inv_p25519:
    CALL inv_p25519_250
    MUL25519 r3, r2, r2
    MUL25519 r3, r3, r3
    MUL25519 r3, r3, r1
    MUL25519 r3, r3, r3
    MUL25519 r3, r3, r3
    MUL25519 r3, r3, r3
    MUL25519 r1, r3, r4
    RET
    