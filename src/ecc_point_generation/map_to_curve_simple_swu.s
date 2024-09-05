; ==============================================================================
;  file    ecc_point_generation/map_to_curve_simple_swu.s
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
; Map to curve algorithm using Simplified Shallue-van de Woestijne-Ulas method
; [https://www.rfc-editor.org/rfc/rfc9380.html#name-simplified-swu-method]
;
; Input:
;   u, an element of GF(p256) in r0
;
; Output:
;   Point on curve P-256 in projective coordinates (x, y, z) in (r17, r18, r19)
;
; Expects:
;   P-256 prime in r31
;
; ==============================================================================

map_to_curve_simple_swu:
    MOV     r20, r0
    LD      r0,  ca_p256_Z
    LD      r1,  ca_p256_a
    LD      r2,  ca_p256_b

    MUL256  r11, r20, r20
    MUL256  r11, r0,  r11
    MUL256  r12, r11, r11
    ADDP    r12, r12, r11
    MOVI    r4,  1
    ADDP    r13, r12, r4
    MUL256  r13, r2,  r13

    ; r14 = cmov(r0, (-r12), r12 != 0)
    MOVI    r4,  0
    SUBP    r14, r4,  r12
    XORI    r0,  r12, 0
    ZSWAP   r0,  r14

    MUL256  r14, r1,  r14
    MUL256  r12, r13, r13
    MUL256  r16, r14, r14
    MUL256  r15, r1,  r16
    ADDP    r12, r12, r15
    MUL256  r12, r12, r13
    MUL256  r16, r16, r14
    MUL256  r15, r2,  r16
    ADDP    r12, r12, r15
    MUL256  r17, r11, r13

    ; is_gx1_square, y1 = sqrt_ratio_3mod4(r12, r16)
    CALL    sqrt_ratio_3mod4
bp_swu_after_sqrt_ratio:
    MUL256  r18, r11, r20
    MUL256  r18, r18, r10

    ; r17 = cmov(r17, r13, is_gx1_square)
    ZSWAP   r17, r13

    ; r18 = cmov(r18, r10, is_gx1_square)
    ZSWAP   r18, r10

    MOVI    r1,  0
    SUBP    r1,  r1,  r18
    ; e1 = sgn0(r20) == sgn0(r18)
    XOR     r0,  r20, r18
    MOVI    r2,  1
    AND     r0,  r0,  r2

    ; r18 = cmov(r1, r18, e1)
    ZSWAP   r18, r1
    MOV     r18, r1
    MUL256  r18, r18, r14
    MOV     r19, r14

    RET
