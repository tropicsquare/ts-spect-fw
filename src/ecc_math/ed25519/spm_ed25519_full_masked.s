; ==============================================================================
;  file    ecc_math/ed25519/spm_edd25519_full_masked.s
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
; Fully masked scalar point multiplication on Twisted Edwards curve Ed25519
;
; Inputs:
;   Scalar k in r27
;   Point P in affine coordinates in (r21, r22)
;   DST_ID in r25
;
; Outputs:
;   k.p in affine coordinates in (r21, r22)
;
; Masking methods:
;   1) Randomized Coordinates       -- (x, y, z, t) == (rx, ry, rz, rt)
;   2) Group Scalar Randomization   -- k' = k + r * #E
;   3) Point Splitting              -- k.P1 = k.P2 + k.P3 for P = P1 + P2
;
; Full algorithm:
;   1) Convert P to randomized extended coordinates
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

spm_ed25519_full_masked:
    ; 1) Convert P to randomized extended coordinates
    LD          r31, ca_p25519
    
spm_ed25519_full_masked_z_randomize:
    GRV         r23
    MOVI        r0,  0
    REDP        r23, r23, r0                    ; Z
    ORI         r23, r23, 1                     ; Ensure that Z != 0
    MUL25519    r21, r21, r23                   ; X = x * Z
    MUL25519    r24, r21, r22                   ; T = x * y * Z = X * y
    MUL25519    r22, r22, r23                   ; Y = y * Z

    ; 2) Generate randpom point P2 (See str2point.md)
    LD          r1,  ca_dst_template
    OR          r1,  r1,  r25
    ROL8        r1,  r1
    CALL        ed25519_point_generate

    ; 3) Mask scalar k as k2 = k + rng2 * #E
    LD          r31, ca_q25519_8
    GRV         r30
    SCB         r28, r27, r30

    ; 4) Compute k2.P2
    LD          r31, ca_p25519
    LD          r6,  ca_ed25519_d

    ST          r11, ca_ed25519_smp_P2x
    ST          r12, ca_ed25519_smp_P2y
    ST          r13, ca_ed25519_smp_P2z
    ST          r14, ca_ed25519_smp_P2t

    CALL        spm_ed25519_long
    CALL        point_check_ed25519
    BRNZ        ed25519_spm_fail

    ; 5) Compute P3 = P1 - P2
    LD          r11, ca_ed25519_smp_P2x
    LD          r12, ca_ed25519_smp_P2y
    LD          r13, ca_ed25519_smp_P2z
    LD          r14, ca_ed25519_smp_P2t
    ST          r7,  ca_ed25519_smp_P2x
    ST          r8,  ca_ed25519_smp_P2y
    ST          r9,  ca_ed25519_smp_P2z
    ST          r10, ca_ed25519_smp_P2t
    MOV         r7,  r21
    MOV         r8,  r22
    MOV         r9,  r23
    MOV         r10, r24

    MOVI        r0,  0
    SUBP        r11, r0,  r11
    SUBP        r14, r0,  r14

    CALL        point_add_ed25519

    ; 6) Mask scalar k as k3 = k + rng3 * #E
    LD          r31, ca_q25519_8
    GRV         r30
    SCB         r28, r27, r30

    ; 7) Compute k3.P3
    LD          r31, ca_p25519
    LD          r6,  ca_ed25519_d

    CALL        spm_ed25519_long
    CALL        point_check_ed25519
    BRNZ        ed25519_spm_fail

    ; 8) Compute k.P = k2.P2 + k3.P3
    LD          r11, ca_ed25519_smp_P2x
    LD          r12, ca_ed25519_smp_P2y
    LD          r13, ca_ed25519_smp_P2z
    LD          r14, ca_ed25519_smp_P2t

    CALL        point_add_ed25519

    MOV         r7,  r11
    MOV         r8,  r12
    MOV         r9,  r13
    MOV         r10, r14
    CALL        point_check_ed25519
    BRNZ        ed25519_spm_fail

    ; 9) Convert k.P to affine coordinates
    MOV         r1,  r13
    CALL        inv_p25519
    MUL25519    r21, r11, r1
    MUL25519    r22, r12, r1

    MUL25519    r1,  r21, r21
    MUL25519    r2,  r22, r22
    SUBP        r3,  r2,  r1                    ; (y^2 - x^2)

    MUL25519    r4,  r1,  r2
    MUL25519    r4,  r4,  r6
    MOVI        r0,  1
    ADDP        r4,  r4,  r0                    ; 1 + d x^2 y^2

    XOR         r0,  r3,  r4
    BRNZ        ed25519_spm_fail

    MOVI        r0,  ret_op_success

    RET

ed25519_spm_fail:
    MOVI        r0,  ret_point_integrity_err
    RET

spm_ed25519_full_masked_z_fail:
    MOVI        r0,  ret_grv_err
    RET
