; ==============================================================================
;  file    ecc_math/curve25519/spm_curve25519.s
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
; Scalar Point Multiplication on Curve25519 with 512 bit scalar
; Uses CSWAP Montgomery Ladder method [https://eprint.iacr.org/2017/293]
; Uses differential x-coordinate only addition/doubling
;
; Inputs:
;               X    Z
;   Point P = (r11, r12)
;
;   Scalar k = (r28, r29)
;
; Output:
;                     X    Z
;   Point k.P     = (r7,  r8)
;   Point (k+1).P = (r9,  r10)
;
; Expects:
;   Curve25519 prime in r31
;
; Modified registers:
;   r6, r27, r26, r30
;
; Subroutines:
;   point_xadd_curve25519
;   point_xdbl_curve25519
;
; ==============================================================================

spm_curve25519_long:
    LD      r6,  ca_curve25519_a2d4
    MOV     r9,  r11
    MOV     r10, r12
    MOVI    r7,  1
    MOVI    r8,  0

    ; x0 = O = (r7, r8)
    ; x1 = P = (r9, r10)
    ; P  = R = (r11, r12)

    MOVI    r30, 256
    GRV     r27

    ; scalar bits 511 downto 256
spm_curve25519_long_loop_511_256:
    ROL     r27, r27
    ROL     r29, r29
    CSWAP   r7,  r9
    CSWAP   r8,  r10

    CALL    point_xadd_curve25519
    CALL    point_xdbl_curve25519

    CSWAP   r7,  r9
    CSWAP   r8,  r10

    SUBI    r30, r30, 1
    BRNZ    spm_curve25519_long_loop_511_256

    MOVI    r30, 256

    ; scalar bits 255 downto 0
spm_curve25519_long_loop_255_0:
    ROL     r27, r27
    ROL     r28, r28
    CSWAP   r7,  r9
    CSWAP   r8,  r10

    CALL    point_xadd_curve25519
    CALL    point_xdbl_curve25519

    CSWAP   r7,  r9
    CSWAP   r8,  r10

    SUBI    r30, r30, 1
    BRNZ    spm_curve25519_long_loop_255_0

    RET