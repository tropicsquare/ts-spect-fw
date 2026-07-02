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
;   X25519 Public Key u in r16  (P)
;   X25519 Private Key k in r19 (expected already clamped)
;   DST in ca_gfp_gen_dst
;
; Outputs:
;   X25519(k, u) in r11
;
; Subroutines:
;   point_order_check_curve25519
;   point_check_curve25519
;   get_y_curve25519
;   hash_to_field
;   spm_curve25519
;   inv_p25519
;
; Masking methods:
;   1) Random Projective Coordinates -- (x, z) == (rx, rz)
;   2) Group Scalar Randomization -- k' = k + r * #E (mod p)
;   3) Additive Scalar Splitting -- k = k1 + k2 for random k1
;
; Full algorithm:
;   1) Recover P.y for P.x and randomize P
;   2) Split scalar k as k2 = k - k1 for random k1
;   3) Mask scalar k1 as k1' = k1 + rng * #E
;   4) Compute P1 = k1'.P
;   5) Mask scalar k2 as k2' = k2 + rng * #E
;   6) Re-randomize P
;   7) Compute P2 = k2'.P
;   8) Compute k.P = P1 + P2
;   9) Convert k.P to affine coordinates
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

    ; ==========================================================================
    ; 1) Recover P.y for P.x and randomize P
    ; ==========================================================================
    ; (r11, r12, r13) <- (Px, Pz, Py)
    CALL        get_y_curve25519
    BRNZ        x25519_pubkey_fail

    GRV         r2
    LD          r1, ca_gfp_gen_dst
    CALL        hash_to_field
    ORI         r12, r0,  1
    MUL25519    r11, r16, r12
    MUL25519    r13, r17, r12

    ; ==========================================================================
    ; 2) Split scalar k = k1 + k2 ... k1 <- rng, k2 = k - k1
    ; ==========================================================================
    ; We must use q*8 here as the modulus, since k is from [2^254, 2^255 - 8]
    LD          r31, ca_q25519_8
x25519_full_masked_scalar_split:
    GRV         r2
    LD          r1,  ca_gfp_gen_dst
    CALL        hash_to_field

    ; check k1 != 0
    XORI        r0,  r0,  0
    BRZ         x25519_full_masked_scalar_split ; Try again (prob. ~2^(-225))

    ; Split
    MOV         r28, r0                         ; r28 <- k1
    SUBP        r20, r19, r28                   ; r20 <- k2

    ; check k2 != 0 (i.e. k1 == k)
    MOVI        r0,  0
    XOR         r1,  r20, r0
    BRZ         x25519_full_masked_scalar_split ; Try again (prob. ~2^(-225))

    ; check k1 != k2
    XOR         r2,  r20, r28
    BRZ         x25519_full_masked_scalar_split ; Try again (prob. ~2^(-225))

    ; ... Now we know that k1.P != k2.P, k1.P != O and k2.P != O ...

    ; ==========================================================================
    ; 3) Mask scalar k1 as k1' = k1 + rng * #E
    ; ==========================================================================
    LD          r31, ca_q25519_8
    GRV         r30
    SCB         r28, r28, r30                   ; (r28, r29) <- k1'

    ; ==========================================================================
    ; 4) Compute P1 = k1'.P -> (r21, r22, r23)
    ; ==========================================================================
    CALL        spm_curve25519                  ; (r7, r8, r9) <- (r28, r29).P = P1

    ; call check
    LD          r4,  ca_call_check_level_1
    CMPI        r4,  call_check_level_1_id
    MOVI        r4,  0
    ST          r4,  ca_call_check_level_1
    BRNZ        x25519_point_integrity_err

    ; spm retval check
    CMPI        r0,  pass_val
    BRNZ        x25519_point_integrity_err

    ; point check
    CALL        point_check_curve25519
    BRNZ        x25519_point_integrity_err

    ; (r20, r21, r22) <- P1
    MOV         r21, r7
    MOV         r22, r8
    MOV         r23, r9

    ; ==========================================================================
    ; 5) Mask scalar k2 as k2' = k2 + rng * #E
    ; ==========================================================================
    LD          r31, ca_q25519_8
    GRV         r30
    SCB         r28, r20, r30                   ; (r28, r29) <- k2'

    ; ==========================================================================
    ; 6) Re-randomize P (X, Y, Z) <- (rX, rY, rZ)
    ; ==========================================================================
    LD          r31, ca_p25519
    GRV         r2
    LD          r1,  ca_gfp_gen_dst
    CALL        hash_to_field
    ORI         r0,  r0,  1                     ; Ensure that r != 0
    MUL25519    r11, r11, r0
    MUL25519    r12, r12, r0
    MUL25519    r13, r13, r0

    ; ==========================================================================
    ; 7) Compute P2 = k2'.P -> (r7, r8, r9)
    ; ==========================================================================
    CALL        spm_curve25519                  ; (r7, r8, r9) <- (r28, r29).P = P2

    ; call check
    LD          r4,  ca_call_check_level_1
    CMPI        r4,  call_check_level_1_id
    MOVI        r4,  0
    ST          r4,  ca_call_check_level_1
    BRNZ        x25519_point_integrity_err

    ; spm retval check
    CMPI        r0,  pass_val
    BRNZ        x25519_point_integrity_err

    ; point check
    CALL        point_check_curve25519
    BRNZ        x25519_point_integrity_err

    ; ==========================================================================
    ; 8) Compute k.P = k1'.P + k2'.P
    ; ==========================================================================
    ; (r11, r12, r13) <- P1
    MOV         r11, r21
    MOV         r12, r22
    MOV         r13, r23

    ; The addition routine will always work thanks to the checks during
    ; the scalar splitting
    LD          r31, ca_p25519
    CALL        point_add_curve25519            ; (r11, r12, r13) <- P1 + P2 = k.P

    ; ==========================================================================
    ; 9) Transform sP1.x to affine coordinate system
    ; ==========================================================================
    MOV         r1, r12
    CALL        inv_p25519                      ; r1 <- (k.P).z ^ (-1)
    MUL25519    r11, r11, r1
    MUL25519    r13, r13, r1
    MOVI        r12, 1

    ; Check validity of the final result
    CALL        point_check_curve25519
    BRNZ        x25519_point_integrity_err

; = RETURN =====================================================================
    MOVI        r0,  ret_op_success
    RET
x25519_pubkey_fail:
    MOVI        r0,  ret_x25519_err_inv_pub_key
    RET

x25519_point_integrity_err:
    MOVI        r0,  ret_point_integrity_err
    RET

    JMP         __err_void__
