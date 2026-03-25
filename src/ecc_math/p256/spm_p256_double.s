; ==============================================================================
;  file    src/ecc_math/p256/spm_p256_double.s
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
; Double Scalar Point Multiplication over P-256
;
; Inputs:
;   Scalars:
;       k1 : r28
;       k2 : r29
;   Points:
;       P1 : (r12, r13, r14)
;       P2 : (r15, r16, r17)
;
; Outputs:
;   Q = k1.P1 + k2.P2 : (r9, r10, r11)
;
; Expects:
;   P-256 field prime in r31
;   P-256 b*3 parameter in r8
;
; Modified registers:
;
; Subroutines:
;   point_add_p256
;   point_dbl_p256
;
; ==============================================================================

spm_p256_double:
    ST          r12, ca_dspm_point_P1x
    ST          r13, ca_dspm_point_P1y
    ST          r14, ca_dspm_point_P1z

    ST          r15, ca_dspm_point_P2x
    ST          r16, ca_dspm_point_P2y
    ST          r17, ca_dspm_point_P2z

    MOV         r9,  r15
    MOV         r10, r16
    MOV         r11, r17

    CALL        point_add_p256

    ST          r12, ca_dspm_point_P1P2x
    ST          r13, ca_dspm_point_P1P2y
    ST          r14, ca_dspm_point_P1P2z

    MOVI        r9,  0
    MOVI        r10, 1
    MOVI        r11, 0

    ST          r9,  ca_dspm_point_Ox
    ST          r10, ca_dspm_point_Oy
    ST          r11, ca_dspm_point_Oz

    ; Mask the scalars
    LD          r31, ca_q256
    GRV         r1
    SCB         r26, r28, r1
    GRV         r1
    SCB         r28, r29, r1
    LD          r31, ca_p256

    ROL8        r27, r27                                ; Move k1_high to position
    ROL8        r29, r29                                ; Move k2_high to position
    ROL         r29, r29

    MOVI        r15, 2                                  ; Main loop counter

    MOVI        r20, 0x100
    MOVI        r21, 0x200

spm_p256_double_main_loop:
    MOVI        r30, 256    ; i
    MOVI        r16, 0      ; j

spm_p256_double_loop:
    CALL        point_dbl_p256

    ROL         r27, r27
    ROL         r29, r29

    AND         r0,  r27, r20
    AND         r1,  r29, r21
    OR          r0,  r0,  r1

    ADDI        r0,  r0,  0x120

    LDR         r12, r0
    ADDI        r0,  r0,  0x20
    LDR         r13, r0
    ADDI        r0,  r0,  0x20
    LDR         r14, r0

    CALL        point_add_p256

    MOV         r9,  r12
    MOV         r10, r13
    MOV         r11, r14

    ; Inner loop counter update/check
    ADDI        r16, r16, 1                             ; j++
    SUBI        r30, r30, 1                             ; i--
    BRNZ        spm_p256_double_loop                    ; i == 0 ?
    CMPI        r16, 256                                ; j == 256 ?
    BRNZ        spm_p256_double_fail                    ; If i == 0 and j != 256 => Fail

    ; Move to low part of the scalers and move
    ROL8        r27, r26                                ; r27 <- k1 low
    ROL8        r29, r28                                ; r29 <- k2 low
    ROL         r29, r29

    ; Outer loop counter update/check
    SUBI        r15, r15, 1
    BRNZ        spm_p256_double_main_loop

    MOVI        r0,  pass_val
    RET

spm_p256_double_fail:
    MOVI        r0,  fail_val
    RET
