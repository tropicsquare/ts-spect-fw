; ==============================================================================
;  file    src/ecc_math/ed25519/spm_ed25519_double.s
;  author  vit.masek@tropicsquare.com
;
;  Copyright (c) 2023-2026 Tropic Square s.r.o. (https://tropicsquare.com/)
;  This work is subject to the license terms of the LICENSE.txt file in the root
;  directory of this source tree.
;  If a copy of the LICENSE file was not distributed with this work, you can
;  obtain one at (https://tropicsquare.com/license).
;
; ==============================================================================
;
; Double Scalar Point Multiplication over Ed25519
;
; Inputs:
;   Scalars:
;       k1 : r28
;       k2 : r29
;   Points:
;       P1 : (r11, r12, r13, r14)
;       P2 : (r15, r16, r17, r18)
;
; Outputs:
;   Q = k1.P1 + k2.P2 : (r7, r8, r9, r10)
;
; Expects:
;   Ed25519 prime in r31
;   Ed25519 parameter d in r6
;
; Subroutines:
;   point_add_ed25519
;   point_dbl_ed25519
;
; ==============================================================================

spm_ed25519_double:
    MOVI    r0,  0
    MOVI    r1,  1

    ST      r0,  ca_dspm_point_Ox
    ST      r1,  ca_dspm_point_Oy
    ST      r1,  ca_dspm_point_Oz
    ST      r0,  ca_dspm_point_Ot

    ST      r11, ca_dspm_point_P1x
    ST      r12, ca_dspm_point_P1y
    ST      r13, ca_dspm_point_P1z
    ST      r14, ca_dspm_point_P1t

    ST      r15, ca_dspm_point_P2x
    ST      r16, ca_dspm_point_P2y
    ST      r17, ca_dspm_point_P2z
    ST      r18, ca_dspm_point_P2t

    MOV     r7,  r15
    MOV     r8,  r16
    MOV     r9,  r17
    MOV     r10, r18

    CALL    point_add_ed25519

    ST      r11, ca_dspm_point_P1P2x
    ST      r12, ca_dspm_point_P1P2y
    ST      r13, ca_dspm_point_P1P2z
    ST      r14, ca_dspm_point_P1P2t

    MOVI    r7,  0
    MOVI    r8,  1
    MOVI    r9,  1
    MOVI    r10, 0

    ROL8    r28, r28
    ROL8    r29, r29
    ROL     r29, r29

    MOVI    r30, 256

    MOVI    r15, 0x100
    MOVI    r16, 0x200

spm_ed25519_double_loop:
    CALL    point_dbl_ed25519

    ROL     r28, r28
    ROL     r29, r29

    AND     r0,  r28, r15
    AND     r1,  r29, r16
    OR      r0,  r0,  r1

    ADDI    r0,  r0,  0x120

    LDR     r11, r0
    ADDI    r0,  r0,  0x20
    LDR     r12, r0
    ADDI    r0,  r0,  0x20
    LDR     r13, r0
    ADDI    r0,  r0,  0x20
    LDR     r14, r0
    ADDI    r0,  r0,  0x20

    CALL    point_add_ed25519

    MOV     r7,  r11
    MOV     r8,  r12
    MOV     r9,  r13
    MOV     r10, r14

    SUBI    r30, r30, 1
    BRNZ    spm_ed25519_double_loop

    RET
