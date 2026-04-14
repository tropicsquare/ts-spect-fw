; ==============================================================================
;  file    ecc_crypto/x25519_full_masked.s
;  author  vit.masek@tropicsquare.com
;
;  Copyright © 2023-2026 Tropic Square s.r.o. (https://tropicsquare.com/)
;  This work is subject to the license terms of the LICENSE file in the root
;  directory of this source tree.
;  If a copy of the LICENSE file was not distributed with this work, you can 
;  obtain one at (https://tropicsquare.com/license).
;
; ==============================================================================
;
; Fully masked and randomized X25519 algorithm
;
; Inputs:
;   X25519 Public Key u in r16
;   X25519 Private Key k in r19
;   DST in ca_gfp_gen_dst
;
; Outputs:
;   X25519(k, u) in r11
;
; Masking methods:
;   1) Random Projective Coordinates -- (x, 1) == (r * x, r)
;   2) Group Scalar Randomization -- k = k + r * #E (mod p)
;   3) Point Splitting -- k.P1 = k.P2 + k.P3 for P = P1 + P2
;
; Full algorithm:
;    1) Compute P1.y from P1.x
;    2) Mask the scalar s as s2 = s + r2 * #E
;    3) Generate random point P2 (See str2point.md)
;    4) Compute sP2.x = s2.P2
;    5) Recover sP2.y
;    6) Randomize P1.z
;    7) Compute P3 = P2 + P1
;    8) Mask scalar s as s3 = s + r3 * #E
;    9) Compute sP3.x = s3.P3
;   10) Recover sP3.y
;   11) Compute sP1 = sP2 - sP3
;   12) Transform sP1.x to affine coordinate system
;
; ==============================================================================

x25519_full_masked:
    LD          r31, ca_p25519

    ; Check u is in GF(p25519)
    MOVI        r0,  0
    REDP        r0,  r0,  r16
    XOR         r0,  r0,  r16
    BRNZ        x25519_pubkey_fail

    ; Check ord(P) > 8
    CALL        point_order_check_curve25519
    BRZ         x25519_pubkey_fail

    ; 1) Compute P1.y from P1.x
    CALL        get_y_curve25519
    BRNZ        x25519_pubkey_fail

    ; 2) Mask the scalar s as s2 = s + r2 * #E
    GRV         r30
    LD          r31, ca_q25519_8
    SCB         r28, r19, r30

    ; 3) Generate random point P2
    LD          r31, ca_p25519
    CALL        curve25519_point_generate

    ; And check that P2 != +-P1 (P1.x * P2.z != P2x)
    MUL25519    r0,  r16, r12
    XOR         r0,  r0,  r11
    BRZ         x25519_point_integrity_err          ; We fail as the probability is ~ 2^(-253)

    ; 4) Compute sP2 = s2.P2
    CALL        spm_curve25519_long
    ; invariant check
    CMPI        r0,  0
    BRNZ        x25519_point_integrity_err
    ; call check
    LD          r4,  ca_call_check_level_1
    CMPI        r4,  call_check_level_1_id
    MOVI        r4,  0
    ST          r4,  ca_call_check_level_1
    BRNZ        x25519_point_integrity_err
    ; sP2 != O -> P2 was low order point (~ 2^(-253) probability)
    XOR         r4,  r4,  r8
    BRZ         x25519_point_integrity_err

    ; 5) Recover sP2.y
    CALL        y_recovery_curve25519
    MOV         r23, r7
    MOV         r24, r8
    MOV         r25, r9
    CALL        point_check_curve25519
    BRNZ        x25519_point_integrity_err

    ; 6) Randomize P1.z
    GRV         r2
    LD          r1, ca_gfp_gen_dst
    CALL        hash_to_field
    ORI         r8, r0,  1                     ; Ensure that Z != 0
    MUL25519    r7, r16, r8
    MUL25519    r9, r17, r8

    ; 7) Compute P3 = P2 + P1
    ; We need to swap the P2 and P1, so we preserve the P2 in (r7, r8, r9)
    XOR         r0,  r0,  r0
    ZSWAP       r7,  r11
    ZSWAP       r8,  r12
    ZSWAP       r9,  r13
    CALL        point_add_curve25519

    ; And check that P3 != +-P2 (P2.x * P3.z != P3.x * P2.z)
    MUL25519    r0,  r7,  r12
    MUL25519    r1,  r11, r8
    XOR         r0,  r0,  r1
    BRZ         x25519_point_integrity_err          ; We fail as the probability is ~ 2^(-253)

    ; 8) Mask scalar s as s3 = s + r3 * #E
    GRV         r30
    LD          r31, ca_q25519_8
    SCB         r28, r19, r30

    ; 9) Compute sP3.x = s3.P3
    LD          r31, ca_p25519
    CALL        spm_curve25519_long
    ; invariant check
    CMPI        r0,  0
    BRNZ        x25519_point_integrity_err
    ; call check
    LD          r4, ca_call_check_level_1
    CMPI        r4, call_check_level_1_id
    MOVI        r4, 0
    ST          r4, ca_call_check_level_1
    BRNZ        x25519_point_integrity_err
    ; sP3 != O
    XOR         r4,  r4,  r8
    BRZ         x25519_point_integrity_err

    ;10) Recover sP3.y
    CALL        y_recovery_curve25519
    CALL        point_check_curve25519
    BRNZ        x25519_point_integrity_err

    ; 11) Compute sP1 = sP2 - sP3
    MOVI        r0,  0
    SUBP        r9,  r0,  r9
    MOV         r11, r23
    MOV         r12, r24
    MOV         r13, r25
    CALL        point_add_curve25519

    ; 12) Transform sP1.x to affine coordinate system
    MOV         r1, r12
    CALL        inv_p25519
    MUL25519    r11, r11, r1
    MUL25519    r13, r13, r1
    MOVI        r12, 1

    CALL        point_check_curve25519
    BRNZ        x25519_point_integrity_err

    MOVI        r0,  ret_op_success

    RET
x25519_pubkey_fail:
    MOVI        r0,  ret_x25519_err_inv_pub_key
    RET

x25519_point_integrity_err:
    MOVI        r0,  ret_point_integrity_err
    RET

    JMP         __err_void__
