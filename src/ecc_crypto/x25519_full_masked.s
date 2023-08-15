; ==============================================================================
;  file    ecc_crypto/x25519_full_masked.s
;  author  vit.masek@tropicsquare.com
;  license TODO
; ==============================================================================
;
; Fully masked and randomized X25519 algorithm
;
; Inputs:
;   X25519 Public Key u in r16
;   X25519 Private Key k in r19
;   DST_ID for point generation in r20
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
;    2) Randomize P1.z
;    3) Mask the scalar s as s2 = s + r2 * #E
;    4) Generate random point P2 (See str2point.md)
;    5) Compute sP2.x = s2.P2
;    6) Recover sP2.y
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

    ; 1) Compute P1.y from P1.x
    CALL        get_y_curve25519
    BRNZ        x25519_pubkey_fail

    ; 2) Randomize P1.z
    MOVI        r1,  3
x25519_full_masked_z_randomize:
    SUBI        r1,  r1, 1
    BRZ         x25519_full_masked_z_fail
    GRV         r18
    MOVI        r0,  0
    REDP        r18, r0,  r18
    XORI        r0,  r18, 0                     ; Z must not be 0
    BRZ         x25519_full_masked_z_randomize
    MUL25519    r16, r16, r18
    MUL25519    r17, r17, r18

    ; 3) Mask the scalar s as s2 = s + r2 * #E
    GRV         r30
    LD          r31, ca_q25519_8
    SCB         r28, r19, r30

    ; 4) Generate random point P2
    LD          r31, ca_p25519
    LD          r1, ca_dst_template
    OR          r1, r1, r20
    ROL8        r1, r1
    CALL        curve25519_point_generate

    ; 5) Compute sP2 = s2.P2
    CALL        spm_curve25519

    ; 6) Recover sP2.y
    CALL        y_recovery_curve25519
    MOV         r23, r7
    MOV         r24, r8
    MOV         r25, r9
    CALL        point_check_curve25519
    BRNZ        x25519_spm_fail

    ; 7) Compute P3 = P2 + P1
    MOV         r7,  r16
    MOV         r8,  r18
    MOV         r9,  r17
    CALL        point_add_curve25519

    ; 8) Mask scalar s as s3 = s + r3 * #E
    GRV         r30
    LD          r31, ca_q25519_8
    SCB         r28, r19, r30

    ; 9) Compute sP3.x = s3.P3
    LD          r31, ca_p25519
    CALL        spm_curve25519

    ;10) Recover sP3.y
    CALL        y_recovery_curve25519
    CALL        point_check_curve25519
    BRNZ        x25519_spm_fail

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
    BRNZ        x25519_spm_fail

    MOVI        r0,  0

    RET
x25519_pubkey_fail:
    MOVI        r0,  ret_x25519_err_inv_pub_key
    RET

x25519_spm_fail:
    MOVI        r0,  ret_point_integrity_err
    RET

x25519_full_masked_z_fail:
    MOVI        r0,  ret_grv_err
    RET