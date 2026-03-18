; ==============================================================================
;  file    ecc_math/p256/spm_p256_short.s 
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
; Scalar Point Multiplication on curve P-256
; Uses CSWAP Montgomery Ladder method [https://eprint.iacr.org/2017/293]
;
; Inputs:
;   Point P = (r12, r13, r14)
;   Scalar k = (r28)
;
; Output:
;   Point Q = (r9,r10,r11)
;
; Expects:
;   p256 prime in r31
;   P-256 parameter b in r8
;       (b = 0x5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b)
;
; Modified registers:
;   r0-r7 -> intermediate values for point addition/doubling
;   r8 -> parameter b
;   (r9, r10, r11) -> Q0
;   r30 -> counter
;
; Subroutines:
;   point_add_p256
;   point_dbl_p256
;
; =============================================================================

spm_p256_short:
    ; Store call check
    MOVI        r0,  call_check_level_1_id
    ST          r0,  ca_call_check_level_1

    ; Store P for Montgomery ladder invariant check (Q1 - Q0 = P)
    ST          r12, ca_spm_internal_Px
    ST          r13, ca_spm_internal_Py
    ST          r14, ca_spm_internal_Pz

    ; (r9, r10, r11) = Q0 = "point at infinity O"
    MOVI    r9,  0
    MOVI    r10, 1
    MOVI    r11, 0

    MOVI    r30, 256    ; i
    MOVI    r16, 0      ; j
spm_p256_short_loop:
    ROL     r28, r28

    CSWAP   r9,  r12
    CSWAP   r10, r13
    CSWAP   r11, r14

    CALL    point_add_p256
    CALL    point_dbl_p256

    CSWAP   r9,  r12
    CSWAP   r10, r13
    CSWAP   r11, r14

    ADDI    r16, r16, 1     ; j++
    SUBI    r30, r30, 1     ; i--
    BRNZ    spm_p256_short_loop      ; i == 0 ?
    CMPI    r16, 256                 ; j == 256 ?
    BRNZ    spm_p256_short_invariant_failed

; === Check Montgomery ladder invariant ===
    ; R30 is 0 from the counter
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
    BRNZ        spm_p256_short_invariant_failed
    XOR         r30, r1,  r13
    BRNZ        spm_p256_short_invariant_failed

    MOVI        r0,  pass_val
    RET
spm_p256_short_invariant_failed:
    MOVI        r0,  fail_val
    RET
