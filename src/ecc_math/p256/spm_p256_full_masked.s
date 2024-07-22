; ==============================================================================
;  file    ecc_math/p256/spm_p256_full_masked.s
;  author  vit.masek@tropicsquare.com
;
;  Copyright © 2023 Tropic Square s.r.o. (https://tropicsquare.com/)
;  This work is subject to the license terms of the LICENSE.txt file in the root
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
;   DST_ID  in r25
;
; Outputs:
;   k.P in affine coordinates in (r22, r23)
;
; Masking methods:
;   1) Random Projective Coordinates -- (x, y, z) == (rx, ry, rz)
;   2) Group Scalar Randomization -- k' = k + r * #E
;   3) Point Splitting -- k.P1 = k.P2 + k.P3 for P = P1 + P2
;
; Full algorithm:
;   1) Convert P to randomized projective coordinates
;   2) Generate randpom point P2 (See str2point.md)
;   3) Mask scalar k as k2 = k + rng2 * #E
;   4) Compute k2.P2
;   5) Compute P3 = P1 - P2
;   6) Mask scalar k as k3 = k + rng3 * #E
;   7) Compute k3.P3
;   8) Compute k.P = k2.P2 + k3.P3
;   9) Convert k.P to affine coordinates
;
; ==============================================================================

spm_p256_full_masked:
    ; 1) Convert P to randomized projective coordinates
    LD      r31, ca_p256

spm_p256_full_masked_z_randomize:
    GRV     r24
    MOVI    r0,  0
    REDP    r24, r0,  r24
    ORI     r24, r24, 1         ; Ensure that Z != 0
    MUL256  r22, r22, r24
    MUL256  r23, r23, r24

    ; 2) Generate randpom point P2 (See str2point.md)
    LD      r1, ca_dst_template
    OR      r1, r1, r25
    ROL8    r1, r1
    CALL    p256_point_generate

    MOV     r9,  r17
    MOV     r10, r18
    MOV     r11, r19

    CALL    point_check_p256
    BRNZ    spm_p256_integrity_fail
    
    ; 3) Mask scalar k as k2 = k + rng2 * #E
    LD      r31, ca_q256
    GRV     r30
    SCB     r28, r27, r30
    ; 4) Compute k2.P2
    LD      r31, ca_p256
    LD      r8,  ca_p256_b

    MOV     r12, r17
    MOV     r13, r18
    MOV     r14, r19

    CALL    spm_p256_long
    CALL    point_check_p256
    BRNZ    spm_p256_integrity_fail 

    ; 5) Compute P3 = P1 - P2
    XOR     r0,  r0,  r0
    ZSWAP   r9,  r22
    ZSWAP   r10, r23
    ZSWAP   r11, r24
    MOV     r12, r17
    MOV     r13, r18
    MOV     r14, r19

    SUBP    r13, r0, r13    ; invert P2

    CALL    point_add_p256  ; r9.. = P1, r12.. = P3, r22.. = k2.P2
    
    ; 6) Mask scalar k as k3 = k + rng3 * #E
    LD      r31, ca_q256
    GRV     r30
    SCB     r28, r27, r30

    ; 7) Compute k3.P3
    LD      r31, ca_p256
    CALL    spm_p256_long
    CALL    point_check_p256
    BRNZ    spm_p256_integrity_fail

    ; 8) Compute k.P = k2.P2 + k3.P3
    MOV     r12, r22
    MOV     r13, r23
    MOV     r14, r24

    CALL    point_add_p256

    MOV     r9,  r12
    MOV     r10, r13
    MOV     r11, r14
    CALL    point_check_p256
    BRNZ    spm_p256_integrity_fail

    ; 9) Convert k.P to affine coordinates
    MOV     r1,  r14
    CALL    inv_p256
    MUL256  r22, r12, r1
    MUL256  r23, r13, r1

    MOVI    r0,  0

    RET

spm_p256_integrity_fail:
    MOVI    r0,  ret_point_integrity_err
    RET

spm_p256_full_masked_z_fail:
    MOVI    r0,  ret_grv_err
    RET
