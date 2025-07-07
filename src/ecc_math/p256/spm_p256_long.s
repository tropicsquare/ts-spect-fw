; ==============================================================================
;  file    ecc_math/p256/spm_p256_long.s
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
; Scalar Point Multiplication on curve P-256
; Uses CSWAP Montgomery Ladder method [https://eprint.iacr.org/2017/293]
;
; Inputs:
;   Point P = (r12, r13, r14)
;   Scalar k = (r28,r29)
;
; Output:
;   Point Q = (r9,r10,r11)
;
; Expects:
;   p256 prime in r31
;   P-256 parameter b in r8
;
; Intermediate value registers:
;   r0-r7 -> intermediate values for point addition/doubling
;   r8 -> parameter b
;   (r9, r10, r11) -> Q0
;   r30 -> counter
;
; ==============================================================================

spm_p256_long:
    ; Store P for Montgomery ladder invariant check (Q1 - Q0 = P)
    ST          r12, ca_spm_internal_Px
    ST          r13, ca_spm_internal_Py
    ST          r14, ca_spm_internal_Pz

    ; (r9, r10, r11) = Q0 = "point at infinity O"
    MOVI    r9,  0
    MOVI    r10, 1
    MOVI    r11, 0

    MOVI    r30, 256
    GRV     r15

    ; scalar bits 511 downto 256
spm_p256_long_loop_511_256:
    ROL     r15, r15
    ROL     r29, r29

    CSWAP   r9,  r12
    CSWAP   r10, r13
    CSWAP   r11, r14

    CALL    point_add_p256
    CALL    point_dbl_p256

    CSWAP   r9,  r12
    CSWAP   r10, r13
    CSWAP   r11, r14

    SUBI    r30, r30, 1
    BRNZ    spm_p256_long_loop_511_256

    MOVI    r30, 256

    ; scalar bits 255 downto 0
spm_p256_long_loop_255_0:
    ROL     r15, r15
    ROL     r28, r28

    CSWAP   r9,  r12
    CSWAP   r10, r13
    CSWAP   r11, r14

    CALL    point_add_p256
    CALL    point_dbl_p256

    CSWAP   r9,  r12
    CSWAP   r10, r13
    CSWAP   r11, r14

    SUBI    r30, r30, 1
    BRNZ    spm_p256_long_loop_255_0

    ; === Check Montgomery ladder invariant ===
    MOVI    r30, 0
    SUBP    r10, r30, r10       ; Q0 -> -Q0

    CALL    point_add_p256      ; -Q0 + Q1 -> (r12, r13, r14)

    SUBP    r10, r30, r10       ; fix Q0 back

    ; Load the input point P
    LD          r0,  ca_spm_internal_Px
    LD          r1,  ca_spm_internal_Py
    LD          r2,  ca_spm_internal_Pz

    ; Convert the two points to common Z-coordinate
    MUL256      r0,  r0,  r14
    MUL256      r1,  r1,  r14
    MUL256      r12, r12, r2
    MUL256      r13, r13, r2

    ; Compare X and Y coordinates
    XOR         r30, r0,  r12
    BRNZ        spm_p256_long_invariant_failed
    XOR         r30, r1,  r13
    BRNZ        spm_p256_long_invariant_failed

    MOVI        r0,  0
    RET
spm_p256_long_invariant_failed:
    MOVI        r0,  1
    RET
