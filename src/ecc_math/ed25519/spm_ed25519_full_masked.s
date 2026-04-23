; ==============================================================================
;  file    ecc_math/ed25519/spm_edd25519_full_masked.s
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
; Fully masked scalar point multiplication on Twisted Edwards curve Ed25519
;
; Inputs:
;   Scalar k in r27
;   Point P in affine coordinates in (r21, r22)
;   DST in ca_gfp_gen_dst
;
; Outputs:
;   k.p in affine coordinates in (r21, r22)
;
; Modified registers:
;   r0-4, r6-14, r21-24, r27, r28, r30, r31
;
; Subroutines:
;   hash_to_field
;   ed25519_point_generate
;   spm_ed25519_long
;   point_valid_check_ed25519
;   point_add_ed25519
;
; Masking methods:
;   1) Random Projective Coordinates -- (x, y, z) == (rx, ry, rz)
;   2) Group Scalar Randomization -- k' = k + r * #E
;   3) Additive Scalar Splitting -- k.P = k1.P + k2.P
;
; Full algorithm:
;   1) Convert P to randomized projective coordinates
;   2) Split scalar k as k2 = k1 + k2 for random k1
;   3) Mask scalar k1 as k1' = k1 + rng * #E
;   4) Compute P1 = k1'.P
;   5) Mask scalar k2 as k2' = k2 + rng * #E
;   6) Compute P2 = k2'.P
;   7) Compute k.P = P1 + P2
;   8) Convert k.P to affine coordinates
;
; ==============================================================================

spm_ed25519_full_masked:
    ; Store call check
    MOVI        r0,  call_check_level_2_id
    ST          r0,  ca_call_check_level_2

    ; ==========================================================================
    ; 1) Convert P to randomized extended coordinates
    ; ==========================================================================
    LD          r31, ca_p25519
    GRV         r2
    LD          r1, ca_gfp_gen_dst
    CALL        hash_to_field
    ORI         r23, r0,  1                     ; Ensure that Z != 0
    MUL25519    r21, r21, r23                   ; X = x * Z
    MUL25519    r24, r21, r22                   ; T = x * y * Z = X * y
    MUL25519    r22, r22, r23                   ; Y = y * Z

    ; Store the randomized point
    ST          r21, ca_spm_internal_Px
    ST          r22, ca_spm_internal_Py
    ST          r23, ca_spm_internal_Pz
    ST          r24, ca_spm_internal_Pt

    ; ==========================================================================
    ; 2) Split scalar k = k1 + k2 -> k1 <- rng, k2 = k - k1
    ; ==========================================================================
    ; We must use q*8 here as the modulus, since k is from [2^254, 2^255 - 8]
    LD          r31, ca_q25519_8
    GRV         r2
    LD          r1,  ca_gfp_gen_dst
    CALL        hash_to_field
    MOV         r28, r0                         ; r28 <- k1
    SUBP        r25, r27, r28                   ; r25 <- k2

    ; ==========================================================================
    ; 3) Mask scalar k1 as k1' = k1 + rng * #E
    ; ==========================================================================
    LD          r31, ca_q25519_8
    GRV         r30
    SCB         r28, r28, r30                   ; (r28, r29) <- k1'

    ; ==========================================================================
    ; 4) Compute P1 = k1'.P
    ; ==========================================================================
    CALL        spm_ed25519_long                ; (r7,  r8,  r9,  r10) <- (r28, r29).P = P1

    ; call check
    LD          r4,  ca_call_check_level_1
    CMPI        r4,  call_check_level_1_id
    MOVI        r4,  0
    ST          r4,  ca_call_check_level_1
    BRNZ        x25519_point_integrity_err

    ; spm retval check
    CMPI        r0,  pass_val
    BRNZ        spm_ed25519_integrity_fail

    ; point check
    CALL        point_valid_check_ed25519
    BRNZ        spm_ed25519_integrity_fail

    ; (r21, r22, r23, r24) <- P1
    MOV         r21, r7
    MOV         r22, r8
    MOV         r23, r9
    MOV         r24, r10

    ; ==========================================================================
    ; 5) Mask scalar k2 as k2' = k2 + rng * #E
    ; ==========================================================================
    LD          r31, ca_q25519_8
    GRV         r30
    SCB         r28, r25, r30                   ; (r28, r29) <- k2'

    ; ==========================================================================
    ; 6) Compute k2'.P
    ; ==========================================================================
    CALL        spm_ed25519_long                ; (r7,  r8,  r9,  r10) <- (r28, r29).P = P2

    ; call check
    LD          r4,  ca_call_check_level_1
    CMPI        r4,  call_check_level_1_id
    MOVI        r4,  0
    ST          r4,  ca_call_check_level_1
    BRNZ        x25519_point_integrity_err

    ; spm retval check
    CMPI        r0,  pass_val
    BRNZ        spm_ed25519_integrity_fail

    ; point check
    CALL        point_valid_check_ed25519
    BRNZ        spm_ed25519_integrity_fail

    ; ==========================================================================
    ; 7) Compute k.P = k1'.P + k2'.P
    ; ==========================================================================
    ; (r11, r12, r13, r14) <- P1
    MOV         r11, r21
    MOV         r12, r22
    MOV         r13, r23
    MOV         r14, r24

    LD          r6,  ca_ed25519_d
    CALL        point_add_ed25519               ; (r11, r12, r13, r14) <- P1 + P2 = k.P

    ; Check if k.P is valid point on Ed25519
    MOV         r7,  r11
    MOV         r8,  r12
    MOV         r9,  r13
    MOV         r10, r14

    CALL        point_valid_check_ed25519
    BRNZ        spm_ed25519_integrity_fail

    ; ==========================================================================
    ; 8) Convert k.P to affine coordinates
    ; ==========================================================================
    MOV         r1,  r13
    CALL        inv_p25519                      ; r1 <- (k.P).z ^ (-1)
    MUL25519    r21, r11, r1
    MUL25519    r22, r12, r1

    MOVI        r0,  ret_op_success
    RET

spm_ed25519_integrity_fail:
    MOVI        r0,  ret_point_integrity_err
    RET
