; ==============================================================================
;  file    ecc_math/p256/spm_p256_full_masked.s
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
; Fully masked scalar point multiplication on NIST curve P-256
;
; Inputs:
;   Scalar k in r27
;   Point P in affine coordinates in (r22, r23)
;   DST in ca_gfp_gen_dst
;
; Outputs:
;   k.P in affine coordinates in (r22, r23)
;
; Modified registers:
;   r1, r2, r9-14, r22-25, r27-31
;
; Subroutines:
;   hash_to_field
;   point_check_p256
;   spm_p256_long
;   point_add_p256
;   inv_p256
;
; Masking methods:
;   1) Random Projective Coordinates -- (x, y, z) == (rx, ry, rz)
;   2) Group Scalar Randomization -- k' = k + r * #E
;   3) Additive Scalar Splitting -- k = k1 + k2 for random k1
;
; Full algorithm:
;   1) Convert P to randomized projective coordinates
;   2) Split scalar k as k2 = k - k1 for random k1
;   3) Mask scalar k1 as k1' = k1 + rng * #E
;   4) Compute P1 = k1'.P
;   5) Mask scalar k2 as k2' = k2 + rng * #E
;   6) Re-randomize P
;   7) Compute P2 = k2'.P
;   8) Compute k.P = P1 + P2
;   9) Convert k.P to affine coordinates

; ==============================================================================

spm_p256_full_masked:
    ; Store call check
    MOVI    r0,  call_check_level_2_id
    ST      r0,  ca_call_check_level_2

    ; ==========================================================================
    ; 1) Convert P to randomized projective coordinates
    ; ==========================================================================
    LD      r31, ca_p256
    GRV     r2
    LD      r1,  ca_gfp_gen_dst
    CALL    hash_to_field
    ORI     r24, r0,  1                     ; Ensure that Z != 0
    MUL256  r22, r22, r24
    MUL256  r23, r23, r24

    ; Store the randomized point
    ST      r22, ca_spm_internal_Px
    ST      r23, ca_spm_internal_Py
    ST      r24, ca_spm_internal_Pz

    ; ==========================================================================
    ; 2) Split scalar k = k1 + k2 ... k1 <- rng, k2 = k - k1
    ; ==========================================================================
    LD      r31, ca_q256
    GRV     r2
    LD      r1,  ca_gfp_gen_dst
    CALL    hash_to_field
    MOV     r28, r0                         ; r28 <- k1
    SUBP    r25, r27, r28                   ; r25 <- k2

    ; ==========================================================================
    ; 3) Mask scalar k1 as k1' = k1 + rng * #E
    ; ==========================================================================
    LD      r31, ca_q256
    GRV     r30
    SCB     r28, r28, r30                   ; (r28, r29) <- k1'

    ; ==========================================================================
    ; 4) Compute P1 = k1'.P
    ; ==========================================================================
    CALL    spm_p256_long                   ; (r9, r10, r11) <- (r28, r29).P = P1

    ; call check
    LD      r4,  ca_call_check_level_1
    CMPI    r4,  call_check_level_1_id
    MOVI    r4,  0
    ST      r4,  ca_call_check_level_1
    BRNZ    x25519_point_integrity_err

    ; spm retval check
    CMPI    r0,  pass_val
    BRNZ    spm_p256_integrity_fail

    ; point check
    CALL    point_check_p256
    BRNZ    spm_p256_integrity_fail

    ; (r22, r23, r24) <- P1
    MOV     r22, r9
    MOV     r23, r10
    MOV     r24, r11

    ; ==========================================================================
    ; 5) Mask scalar k2 as k2' = k2 + rng * #E
    ; ==========================================================================
    LD      r31, ca_q256
    GRV     r30
    SCB     r28, r25, r30                   ; (r28, r29) <- k2'

    ; ==========================================================================
    ; 6) Re-randomize P (X, Y, Z) <- (rX, rY, rZ)
    ; ==========================================================================
    ; Load point P
    LD      r9,  ca_spm_internal_Px
    LD      r10, ca_spm_internal_Py
    LD      r11, ca_spm_internal_Pz

    ; Re-randomize
    LD      r31, ca_p256
    GRV     r2
    LD      r1,  ca_gfp_gen_dst
    CALL    hash_to_field
    ORI     r0, r0,  1                      ; Ensure that r != 0
    MUL256  r9,  r9,  r0
    MUL256  r10, r10, r0
    MUL256  r11, r11, r0

    ; Store the re-randomized point back
    ST      r9,  ca_spm_internal_Px
    ST      r10, ca_spm_internal_Py
    ST      r11, ca_spm_internal_Pz

    ; ==========================================================================
    ; 7) Compute P2 = k2'.P
    ; ==========================================================================
    CALL    spm_p256_long                   ; (r9, r10, r11) <- (r28, r29).P = P2

    ; call check
    LD      r4,  ca_call_check_level_1
    CMPI    r4,  call_check_level_1_id
    MOVI    r4,  0
    ST      r4,  ca_call_check_level_1
    BRNZ    x25519_point_integrity_err

    ; spm retval check
    CMPI    r0,  pass_val
    BRNZ    spm_p256_integrity_fail

    ; point check
    CALL    point_check_p256
    BRNZ    spm_p256_integrity_fail

    ; ==========================================================================
    ; 8) Compute k.P = k1'.P + k2'.P
    ; ==========================================================================
    ; (r12, r13, r14) <- P1
    MOV     r12, r22
    MOV     r13, r23
    MOV     r14, r24

    ; Load P-256 parameter b
    LD      r8,  ca_p256_b
    CALL    point_add_p256                  ; (r12, r13, r14) <- P1 + P2 = k.P

    ; Check if k.P is valid point on P-256
    MOV     r9,  r12
    MOV     r10, r13
    MOV     r11, r14
    CALL    point_check_p256
    BRNZ    spm_p256_integrity_fail

    ; ==========================================================================
    ; 9) Convert k.P to affine coordinates
    ; ==========================================================================
    ; We convert it from registers (r9, r10, r11) since these are the registers
    ; checked for point validity
    MOV     r1,  r11
    CALL    inv_p256
    MUL256  r22, r9,  r1
    MUL256  r23, r10, r1

; = RETURN =====================================================================
    MOVI    r0,  pass_val
    RET

spm_p256_integrity_fail:
    MOVI    r0,  fail_val
    RET
