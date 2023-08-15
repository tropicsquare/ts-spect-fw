; ==============================================================================
;  file    field_math/256/inv_p256.s
;  author  vit.masek@tropicsquare.com
;  license TODO
; ==============================================================================
;
; Inversion in GF(p256) where p256 = NIST P-256 prime.
; Uses Little Fermat's Theorem - Z^(-1) = Z^(p-2) mod p
;
; Inputs:
;   Z in register r1
;
; Outputs:
;   Z^(-1) mod p256 in register r1
;
; ==============================================================================

inv_p256_c1:
    MUL256  r3,  r1,  r1
    MUL256  r4,  r3,  r1
    ; r4 : e = 3

    MUL256  r3,  r4,  r4
    MUL256  r3,  r3,  r3
    MUL256  r2,  r3,  r4
    ; r2 : e = f

    MUL256  r3,  r2,  r2
    MUL256  r3,  r3,  r3
    MUL256  r3,  r3,  r3
    MUL256  r3,  r3,  r3
    MUL256  r3,  r3,  r2
    MUL256  r3,  r3,  r3
    MUL256  r3,  r3,  r3
    MUL256  r5,  r3,  r4
    ; r5 : e = 3ff

    MUL256  r3,  r5,  r5
    MOVI    r30, 9
inv_p256_loop_10_1:
    MUL256  r3,  r3,  r3
    SUBI    r30, r30, 1
    BRNZ    inv_p256_loop_10_1

    MUL256  r3,  r3,  r5
    
    MOVI    r30, 10
inv_p256_loop_10_2:
    MUL256  r3,  r3,  r3
    MUL256  r3,  r3,  r3
    SUBI    r30, r30, 2
    BRNZ    inv_p256_loop_10_2

    MUL256  r5,  r3,  r5
    ; r5 : e = 0x3fffffff

    MUL256  r3,  r5,  r5 
    MUL256  r3,  r3,  r3
    MUL256  r2,  r3,  r4
    ; r2 : e = 0xffffffff

    MUL256  r3,  r2,  r2
    MUL256  r3,  r3,  r3

    MOVI    r30, 30
inv_p256_loop_30_1:
    MUL256  r3,  r3,  r3
    MUL256  r3,  r3,  r3
    MUL256  r3,  r3,  r3
    SUBI    r30, r30, 3
    BRNZ    inv_p256_loop_30_1

    MUL256  r3,  r3,  r1
    ; e = 0xffffffff 00000001

    MOVI    r30, 128
inv_p256_loop_128:
    MUL256  r3,  r3,  r3
    MUL256  r3,  r3,  r3
    MUL256  r3,  r3,  r3
    MUL256  r3,  r3,  r3
    SUBI    r30, r30, 4
    BRNZ    inv_p256_loop_128

    MUL256  r3,  r3,  r2
    ; e = 0xffffffff 00000001 00000000 00000000 00000000 ffffffff

    MOVI    r30, 32
inv_p256_loop_32:
    MUL256  r3, r3, r3
    MUL256  r3, r3, r3
    MUL256  r3, r3, r3
    MUL256  r3, r3, r3
    SUBI    r30, r30, 4
    BRNZ    inv_p256_loop_32

    MUL256  r3, r3, r2
    ; e = 0xffffffff 00000001 00000000 00000000 00000000 ffffffff ffffffff

    MOVI    r30, 30
inv_p256_loop_30_2:
    MUL256  r3,  r3,  r3
    MUL256  r3,  r3,  r3
    MUL256  r3,  r3,  r3
    SUBI    r30, r30, 3
    BRNZ    inv_p256_loop_30_2

    MUL256  r3,  r3,  r5
    RET

inv_p256:
    CALL    inv_p256_c1
    MUL256  r3,  r3,  r3
    MUL256  r3,  r3,  r3
    ; e = 0xffffffff 00000001 00000000 00000000 00000000 ffffffff ffffffff fffffffc
    MUL256  r1,  r3,  r1
    ; e = 0xffffffff 00000001 00000000 00000000 00000000 ffffffff ffffffff fffffffd
    RET